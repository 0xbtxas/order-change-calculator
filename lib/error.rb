class BreakfastAppError < StandardError; end
class InvalidOrderError < BreakfastAppError; end
class InvalidPriceListError < BreakfastAppError; end
class MalformedJSONError < BreakfastAppError; end