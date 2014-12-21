require "jparallel"

class Collection
  attr_accessor :data
  def initialize data
    @data = data

    @jp = Jparallel.new 6
  end

  def calculate_true_range
    @data[1..-1].each_with_index do |bar, index|
      previous_close = @data[index - 1].close
      bar.tr = [
        bar.high - bar.low,
        (bar.high - previous_close).abs,
        (previous_close - bar.low).abs
      ].max
    end
  end

  def calculate_atr period
    (period+1...@data.length).each do |i|
      sum_last_period_tr = (i-period..i).reduce(0) do |sum, index_of_tr|
        sum += @data[index_of_tr].tr
      end

      @data[i].atr = sum_last_period_tr / period
    end
  end
end
