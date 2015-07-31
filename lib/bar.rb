# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# The "Bar" class holds all the information for a bar of data (For whatever the relevant time period is).
class Bar
  attr_reader :open, :high, :low, :close, :time
  attr_accessor :tr, :atr, :ma_20, :direction_of_change, :magnitude_of_change, :ma_20_difference,
    :plus_dm, :minus_dm, :plus_di, :minus_di, :plus_di_average, :minus_di_average,
    :dmi, :adx, :stochastic_oscillator, :moving_average_stochastic_oscillator,
    :slow_stochastic_oscillator, :rate_of_change, :momentum, :disparity_5, :disparity_10,
    :price_oscillator

  EXPLANATORY_VARIABLES = [:atr, :ma_20, :ma_20_difference,
    :adx, :stochastic_oscillator, :moving_average_stochastic_oscillator,
    :slow_stochastic_oscillator, :rate_of_change, :momentum, :disparity_5, :disparity_10,
    :price_oscillator]

  TARGET_VARIABLES = [:direction_of_change]

  # Create a new Bar
  #
  # @param open [#to_f]
  # @param high [#to_f]
  # @param low [#to_f]
  # @param close [#to_f]
  # @param time [String]
  def initialize open, high, low, close, time
    @open = open.to_f
    @high = high.to_f
    @low = low.to_f
    @close = close.to_f
    @time = time
  end

  def explanatory_variables
    EXPLANATORY_VARIABLES.map do |var|
      self.send(var)
    end
  end

  def target_variables
    TARGET_VARIABLES.map do |var|
      self.send(var)
    end
  end
end
