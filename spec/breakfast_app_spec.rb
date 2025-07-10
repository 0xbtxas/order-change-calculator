require 'spec_helper'
require 'breakfast_app'

describe 'Breakfast App' do
  subject(:breakfast_app_result) { BreakfastApp.call(price_list_json, orders_json) }

  let(:price_list_json) do
    <<-JSON
    [
      { "id": "flat-white", name: "Flat White", price: 3.0 },
      { "id": "espresso", name: "Espresso", price: 2.0 },
      { "id": "bacon-egg-roll", name: "Bacon & Egg Roll", price: 5.0 },
      { "id": "bbq-sauce", name: "BBQ Sauce", price: 0.0 },
    ]
    JSON
  end

  let(:orders_json) do
    <<-JSON
    [
      { "name": "dave", "money": 10.0, "items": ["flat-white", "bacon-egg-roll", "bbq-sauce"] },
      { "name": "jenny", "money": 5.0, "items": ["espresso"] }
    ]
    JSON
  end

  let(:result_json) do
    <<-JSON
    [
      { "name": "dave", change: 2.0 },
      { "name": "jenny", change: 3.0 },
    ]
    JSON
  end

  let(:parsed_result) { JSON.load(breakfast_app_result) }

  it 'should match the expected result' do
    expect(parsed_result).to eq JSON.load(result_json)
  end

  it 'should contain 2 records' do
    expect(parsed_result.count).to eq 2
  end

  it 'should provide the correct change' do
    expect(parsed_result[0]['change']).to eq 2.0
    expect(parsed_result[1]['change']).to eq 3.0
  end
end
