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
