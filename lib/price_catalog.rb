class PriceCatalog
  def initialize(price_list)
    validate_price_list!(price_list)
    @price_map = build_price_map(price_list)
  end

  def price_for(item_id)
    @price_map.fetch(item_id) { nil }
  end

  private

  def validate_price_list!(price_list)
    seen = {}
    price_list.each do |item|
      unless item['id'] && item.key?('price')
        raise InvalidPriceListError, "Missing id or price in price list item: #{item.inspect}"
      end

      if seen[item['id']]
        raise InvalidPriceListError, "Duplicate item id: #{item['id']}"
      end

      seen[item['id']] = true
    end
  end

  def build_price_map(price_list)
    price_list.to_h { |item| [item['id'], item['price']] }
  end
end
