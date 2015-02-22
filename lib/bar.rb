# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

class Bar
  attr_reader :open, :high, :low, :close, :time
  attr_accessor :tr, :atr, :ma_20, :target_close, :ma_20_difference,
    :plus_dm, :minus_dm, :plus_di, :minus_di, :plus_di_average, :minus_di_average,
    :dmi, :adx, :stochastic_oscillator, :moving_average_stochastic_oscillator,
    :slow_stochastic_oscillator, :rate_of_change, :momentum, :disparity_5, :disparity_10,
    :price_oscillator

  INDICATORS = [:tr, :atr, :ma_20, :target_close, :ma_20_difference,
    :plus_dm, :minus_dm, :plus_di, :minus_di, :plus_di_average, :minus_di_average,
    :dmi, :adx, :stochastic_oscillator, :moving_average_stochastic_oscillator,
    :slow_stochastic_oscillator, :rate_of_change, :momentum, :disparity_5, :disparity_10,
    :price_oscillator]

  def initialize open, high, low, close, time
    @open = open.to_f
    @high = high.to_f
    @low = low.to_f
    @close = close.to_f
    @time = time
  end
end
