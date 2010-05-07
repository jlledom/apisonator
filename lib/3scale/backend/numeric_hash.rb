# This is a hash whose values are numbers (of number-like objects).
# It has some convenient operations like sum or difference.  
class NumericHash < Hash
  def initialize(data = {})
    replace(data)
  end

  def + (other)
    self.class.new(other.inject(dup) do |memo, (key, value)|
      memo[key] ||= 0
      memo[key] += value
      memo
    end)
  end

  def - (other)
    self.class.new(other.inject(dup) do |memo, (key, value)|
      memo[key] ||= 0
      memo[key] -= value
      memo
    end)
  end

  def nonzero?
    values.any? { |value| value != 0 }
  end

  def reset!
    replace({})
  end

  def inspect
    "#{self.class}(#{super})"
  end  
end
