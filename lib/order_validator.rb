class OrderValidator
  NAME_REGEX = /\A[\w\s'-]+\z/

  def self.validate!(order)
    order.fetch_values('name', 'money', 'items')
    name = order['name']
    unless name.is_a?(String) && name.match?(NAME_REGEX)
      raise InvalidOrderError, "Invalid characters in name: #{name.inspect}"
    end

    unless order['items'].is_a?(Array)
      raise InvalidOrderError, "'items' must be an array"
    end

    unless order['money'].is_a?(Numeric)
      raise InvalidOrderError, "'money' must be numeric"
    end
  rescue KeyError => e
    raise InvalidOrderError, "Missing field: #{e.message}"
  end
end
