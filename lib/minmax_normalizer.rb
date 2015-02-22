# Copyright 2015 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

class MinmaxNormalizer
  def initialize data
    @source = data[100..-50]
    @normalized_data = []
  end

  def normalize
    # 1. walk over @source and get the aggregate values
    # - max and min of all attributes of the Bar in @source
    # - save in object

    # 2. Use the object and walk over @source
    # - Run the appropriate calculations
    # - store the new Bar in @normalized_data

    # And you are done!

    @source.map do |bar|
      # TODO : Parallelize
      indicators.each do |indicator|
        bar.send("#{indicator}=", normalized_score(bar, indicator))
      end
      bar
    end
  end

  private
  def normalized_score(bar, indicator)
    # http://intelligencemining.blogspot.ca/2009/07/data-preprocessing-normalization.html
    ( (bar.send(indicator) - min_max_of_all_inputs[indicator][:min]) /
      (min_max_of_all_inputs[indicator][:max] - min_max_of_all_inputs[indicator][:min])
    ) *
      (2 - -1) +             # range of output
      -1                   # minimum output
  rescue => e
    binding.pry
  end

  def indicators
    @source.first.class::INDICATORS
  end

  def min_max_of_all_inputs
    @min_max_of_all_inputs ||= indicators.each_with_object({}) do |indicator, final|
      # TODO : Parallelize
      final[indicator] = min_max_of_indicator(indicator)
    end
  end

  def min_max_of_indicator(indicator)
    min_max = @source.minmax_by { |a| a.send(indicator) }
    {
      min: min_max.first.send(indicator),
      max: min_max[1].send(indicator)
    }
  rescue => e
    binding.pry
  end
end
