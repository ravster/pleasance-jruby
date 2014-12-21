# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

class Bar
  attr_reader :open, :high, :low, :close, :time
  attr_accessor :tr, :atr

  def initialize open, high, low, close, time
    @open = open.to_f
    @high = high.to_f
    @low = low.to_f
    @close = close.to_f
    @time = time
  end
end
