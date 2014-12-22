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

  def calculate_moving_average_difference period
    (period+1...@data.length).each do |i|
      @data[i].ma_20_difference = @data[i].close - @data[i].ma_20
    end
  end

  def calculate_target_close_difference
    (0...@data.length-5).each do |i|
      @data[i].target_close = @data[i+5].close - @data[i].close
    end
  end

  def calculate_dm
    @data[1..-1].each_with_index do |bar, i|
      up = bar.high - @data[i-1].high
      down = @data[i-1].low - bar.low

      if up > down
        bar.plus_dm = [up, 0].max
        bar.minus_dm = 0
      else
        bar.plus_dm = 0
        bar.minus_dm = [down, 0].max
      end
    end
  end

  def calculate_di
    @data[1..-1].each do |bar|
      if bar.tr.zero?
        bar.plus_di = bar.minus_di = 0
      else
        bar.plus_di = bar.plus_dm / bar.tr
        bar.minus_di = bar.minus_dm / bar.tr
      end
    end
  end

  def calculate_average_di period
    (period..@data.length-1).each do |i|
      @data[i].plus_di_average = (i-(period-1)..i).reduce(0) do |final, j|
        final + @data[j].plus_di
      end / period

      @data[i].minus_di_average = (i-(period-1)..i).reduce(0) do |final, j|
        final + @data[j].minus_di
      end / period
    end
  end

  def calculate_dmi period
    (period..@data.length-1).each do |i|
      bar = @data[i]

      bar.dmi = (bar.plus_di_average - bar.minus_di_average).abs / (bar.plus_di_average + bar.minus_di_average)
    end
  end

  def calculate_adx period
    (period*2-1..@data.length-1).each do |i|
      @data[i].adx = (i-period+1..i).reduce(0) do |final, j|
        final + @data[j].dmi
      end / period
    end
  end

  def calculate_stochastic_oscillator period
    (period..@data.length-1).each do |i|
      highest_high = (i-period+1..i).map do |j|
        @data[j].high
      end.max
      lowest_low = (i-period+1..i).map do |j|
        @data[j].low
      end.min

      @data[i].stochastic_oscillator =
        ( @data[i].close - lowest_low ) /
        ( highest_high - lowest_low )
    end
  end
end
