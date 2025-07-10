require 'spec_helper'
require 'json'
require 'benchmark'
require 'breakfast_app'
require 'error'

RSpec.describe 'BreakfastApp' do
  let(:default_price_list) do
    [
      { id: 'flat-white', name: 'Flat White', price: 3.0 },
      { id: 'espresso', name: 'Espresso', price: 2.0 },
      { id: 'bacon-egg-roll', name: 'Bacon & Egg Roll', price: 5.0 },
      { id: 'bbq-sauce', name: 'BBQ Sauce', price: 0.0 }
    ]
  end

  let(:price_list_json) { JSON.generate(default_price_list) }

  shared_examples 'order processing' do |orders, expected_changes|
    it 'returns correct changes' do
      orders_json = JSON.generate(orders)
      result = JSON.parse(BreakfastApp.call(price_list_json, orders_json))
      expect(result).to eq(expected_changes)
    end
  end

  describe 'Core functionality' do
    include_examples 'order processing',
      [
        { name: 'dave', money: 10.0, items: ['flat-white', 'bacon-egg-roll', 'bbq-sauce'] },
        { name: 'jenny', money: 5.0, items: ['espresso'] }
      ],
      [
        { 'name' => 'dave', 'change' => 2.0 },
        { 'name' => 'jenny', 'change' => 3.0 }
      ]
  end

  describe 'Edge cases' do
    include_examples 'order processing',
      [{ name: 'empty', money: 5.0, items: [] }],
      [{ 'name' => 'empty', 'change' => 5.0 }]

    include_examples 'order processing',
      [{ name: 'exact', money: 5.0, items: ['bacon-egg-roll'] }],
      [{ 'name' => 'exact', 'change' => 0.0 }]

    include_examples 'order processing',
      [{ name: 'under', money: 1.0, items: ['flat-white'] }],
      [{ 'name' => 'under', 'change' => -2.0 }]

    include_examples 'order processing',
      [{ name: 'double-shot', money: 10.0, items: ['espresso', 'espresso'] }],
      [{ 'name' => 'double-shot', 'change' => 6.0 }]
  end

  describe 'Invalid input handling' do
    include_examples 'order processing',
      [{ name: 'ghost', money: 5.0, items: ['unicorn-frappe'] }],
      [{ 'name' => 'ghost', 'change' => 5.0 }]

    it 'raises InvalidOrderError for missing fields' do
      orders_json = JSON.generate([{ name: 'no-items', money: 5.0 }])
      expect { BreakfastApp.call(price_list_json, orders_json) }.to raise_error(InvalidOrderError)
    end

    it 'raises MalformedJSONError for malformed JSON' do
      malformed_json = '[{ name: "bob", items: [espresso] '
      expect { BreakfastApp.call(price_list_json, malformed_json) }.to raise_error(MalformedJSONError)
    end

    it 'raises InvalidPriceListError for missing price in price list' do
      malformed_price_list = JSON.generate([{ id: 'coffee', name: 'Coffee' }])
      orders_json = JSON.generate([{ name: 'bob', money: 5.0, items: ['coffee'] }])
      expect { BreakfastApp.call(malformed_price_list, orders_json) }.to raise_error(InvalidPriceListError)
    end

    it 'raises InvalidPriceListError for duplicate item IDs in price list' do
      malformed_price_list = JSON.generate([
        { id: 'coffee', name: 'Coffee', price: 3.0 },
        { id: 'coffee', name: 'Espresso', price: 2.0 }
      ])
      orders_json = JSON.generate([{ name: 'bob', money: 10.0, items: ['coffee'] }])
      expect { BreakfastApp.call(malformed_price_list, orders_json) }.to raise_error(InvalidPriceListError)
    end
  end

  describe 'Scalability and performance' do
    let(:orders_json) do
      orders = Array.new(10000) { |i| { name: "user#{i}", money: 10.0, items: ['espresso', 'flat-white'] } }
      JSON.generate(orders)
    end

    it 'handles large datasets correctly' do
      result = JSON.parse(BreakfastApp.call(price_list_json, orders_json))
      expect(result.size).to eq(10000)
      expect(result.first).to include('name', 'change')
    end

    it 'executes within reasonable time' do
      time = Benchmark.realtime { BreakfastApp.call(price_list_json, orders_json) }
      expect(time).to be < 1.0
    end
  end

  describe 'Special cases' do
    it 'allows duplicate user names' do
      orders_json = JSON.generate([
        { name: 'alex', money: 5.0, items: ['espresso'] },
        { name: 'alex', money: 6.0, items: ['flat-white'] }
      ])
      res = JSON.parse(BreakfastApp.call(price_list_json, orders_json))
      expect(res.count).to eq(2)
    end

    it 'handles item with zero price' do
      orders_json = JSON.generate([{ name: 'bbq', money: 2.0, items: ['bbq-sauce'] }])
      res = JSON.parse(BreakfastApp.call(price_list_json, orders_json))
      expect(res.first['change']).to eq(2.0)
    end

    it 'handles high-precision price calculation' do
      price_list = JSON.generate([{ id: 'weird-coffee', name: 'Weird Coffee', price: 2.3333 }])
      orders_json = JSON.generate([{ name: 'precision', money: 5.0, items: ['weird-coffee', 'weird-coffee'] }])
      res = JSON.parse(BreakfastApp.call(price_list, orders_json))
      expect(res.first['change']).to be_within(0.01).of(0.33)
    end
  end

  describe 'Security vulnerability check' do
    it 'raises InvalidOrderError for XSS-style names' do
      orders_json = JSON.generate([{ name: '<script>alert("x")</script>', money: 5.0, items: ['espresso'] }])
      expect { BreakfastApp.call(price_list_json, orders_json) }.to raise_error(InvalidOrderError, /invalid characters/i)
    end
  end
end
