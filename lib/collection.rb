# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

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

  def calculate_moving_average period
    (period+1...@data.length).each do |i|
      @data[i].ma_20 = (i-period..i).reduce(0) do |total, j|
        total += @data[j].close / 20
      end
    end
  end

  def calculate_target_close_difference
    (0...@data.length-5).each do |i|
      @data[i].target_close = @data[i+5].close - @data[i].close
    end
  end
end
