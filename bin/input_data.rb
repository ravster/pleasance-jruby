# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

require "bundler"
Bundler.setup :default
require "pry"
require "csv"
require File.dirname(__FILE__) + "/../lib/bar.rb"
require File.dirname(__FILE__) + "/../lib/collection.rb"
require File.dirname(__FILE__) + "/../lib/minmax_normalizer.rb"
require "slf4j-api.jar" # -I /usr/share/java
require "neuroph-core-2.9.jar" # -I dir/containing/jar-file

filename = ARGV.first
bar_array = []

CSV.foreach(filename, headers: true) do |row|
  bar_array << Bar.new(
    row["<OPEN>"],
    row["<HIGH>"],
    row["<LOW>"],
    row["<CLOSE>"],
    Time.strptime("#{row["<DATE>"]} #{row["<TIME>"]}", "%Y%m%d %H:%M:%S")
  )
end

dataset = Collection.new bar_array

# TODO Pass dataset to an actor that will process it through a normalization process.  The default normalization process will be Min-Max.  We might want to try something else in the future.
puts "normalizing data"

normalized_data = dataset.normalize_data MinmaxNormalizer

nn_dataset = org.neuroph.core.data.DataSet.new(20,1)

normalized_data.each do |bar|
  explanatory_vars = bar.explanatory_variables.map do |var|
    java.lang.Double.new var
  end
  target_vars = bar.target_variables.map do |var|
    java.lang.Double.new var
  end

  nn_dataset.add_row(
    org.neuroph.core.data.DataSetRow.new(
      java.util.ArrayList.new(explanatory_vars),
      java.util.ArrayList.new(target_vars)
    )
  )
end

nn = org.neuroph.nnet.MultiLayerPerceptron.new(org.neuroph.util.TransferFunctionType::TANH, 20, 20, 1)
nn.learn_in_new_thread(nn_dataset)
sleep(60)
nn.stop_learning

binding.pry
