# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

require "jparallel"

# A collection of {Bar} objects
class Collection
  attr_accessor :data

  # Pass in an array of {Bar} objects and calculate all the indicators for them.
  #
  # @param data [Array] Array of {Bar}
  # @todo Parallelize ALL of this.  Its a lot of math, and while its quick, everyone likes things running faster.
  def initialize data
    @data = data
    @jp = Jparallel.new 6

    # TODO Some of the calculations are independent of others.  They are open to being done in parallel.
    # TODO Alternately, and possibly even better, would be to make each method parallel.  Then we wouldn't have to concern application code with ordering any more than it absolutely requires.

    puts "calculating..."
    calculate_true_range
    calculate_atr 20
    calculate_moving_average 20
    calculate_moving_average_difference 20
    calculate_stochastic_oscillator 20
    calculate_moving_stochastic_oscillator 20
    calculate_slow_stochastic_oscillator 20
    calculate_rate_of_change 20
    calculate_momentum 20

    calculate_disparity_5
    calculate_disparity_10
    calculate_price_oscillator

    calculate_direction_of_change
    calculate_magnitude_of_change
    calculate_dm
    calculate_di
    calculate_average_di 20
    calculate_dmi 20
    calculate_adx 20
    puts "calculations done."
  end

  # Normalize the data according to a given Normalizer and save it in an attribute.
  #
  # @param normalizing_class [Class] Class that can normalize an array of {Bar}.
  # @return [Array] Array of {Bar} with normalized indicator scores.
  # @example normalize_data({MinmaxNormalizer})
  def normalize_data normalizing_class
    @normalized_data = normalizing_class.new(@data).normalize
  end

  private
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

  def calculate_direction_of_change
    (0...@data.length-5).each do |i|
      @data[i].direction_of_change =
        if (@data[i+5].close - @data[i].close) > 0
          1
        else
          0
        end
    end
  end

  def calculate_magnitude_of_change
    (0...@data.length-5).each do |i|
      @data[i].magnitude_of_change = (@data[i+5].close - @data[i].close).abs
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

  def calculate_moving_stochastic_oscillator period
    (period*2..@data.length-1).each do |i|
      @data[i].moving_average_stochastic_oscillator =
        (i-period+1..i).reduce(0) do |final, j|
          final + @data[j].stochastic_oscillator
        end / period
    end
  end

  def calculate_slow_stochastic_oscillator period
    (period*3..@data.length-1).each do |i|
      @data[i].slow_stochastic_oscillator =
        (i-period+1..i).reduce(0) do |final, j|
          final +@data[j].moving_average_stochastic_oscillator
        end / period
    end
  end

  def calculate_rate_of_change period
    (period..@data.length-1).each do |i|
      @data[i].rate_of_change = @data[i].close / @data[i-period].close
    end
  end

  def calculate_momentum period
    (period..@data.length-1).each do |i|
      @data[i].momentum = @data[i].close - @data[i-period].close
    end
  end

  def calculate_disparity_5
    # Return close/average-of-last-5-closes.
    (5..@data.length-1).each do |i|
      @data[i].disparity_5 = @data[i].close / (i-5-1..i).reduce(0) do |final, j|
        final + @data[j].close
      end / 5
    end
  end

  def calculate_disparity_10
    # Return close/average-of-last-10-closes.
    (10..@data.length-1).each do |i|
      @data[i].disparity_10 = @data[i].close / (i-10-1..i).reduce(0) do |final, j|
        final + @data[j].close
      end / 10
    end
  end

  def calculate_price_oscillator
    # (MA_5 - MA_10) / MA_5
    (10..@data.length-1).each do |i|
      close_ma_5 = (i-5-1..i).reduce(0) do |final, j|
        final + @data[j].close
      end / 5

      close_ma_10 = (i-10-1..i).reduce(0) do |final, j|
        final + @data[j].close
      end / 10

      @data[i].price_oscillator = (close_ma_5 - close_ma_10) / close_ma_5
    end
  end
end
