require 'order_validator'
require 'price_catalog'

class BreakfastApp
  def self.call(price_list_json, orders_json)
    price_list = parse_json(price_list_json)
    orders = parse_json(orders_json)

    catalog = PriceCatalog.new(price_list)

    results = orders.map do |order|
      begin
        OrderValidator.validate!(order)
      rescue InvalidOrderError => e
        raise e
      end

      total_cost, unknown_items = calculate_total_cost(order['items'], catalog)

      if unknown_items.any?
        warn "[BreakfastApp] Skipping unknown items for #{order['name']}: #{unknown_items.join(', ')}"
      end

      change = (order['money'] - total_cost).round(2)
      { 'name' => order['name'], 'change' => change }
    end

    results.to_json
  end

  private_class_method def self.parse_json(json_str)
    JSON.parse(json_str)
  rescue JSON::ParserError => e
    raise MalformedJSONError, "Malformed JSON: #{e.message}"
  end

  private_class_method def self.calculate_total_cost(items, catalog)
    unknown_items = []
    total_cost = items.sum do |item_id|
      price = catalog.price_for(item_id)
      if price.nil?
        unknown_items << item_id
        0.0
      else
        price
      end
    end
    [total_cost, unknown_items]
  end
end
