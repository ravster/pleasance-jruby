# Copyright 2014 Ravi Desai
# This program is licenced under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

require "bundler"
Bundler.setup :default
require "pry"
require "csv"
require File.dirname(__FILE__) + "/../lib/bar.rb"
require File.dirname(__FILE__) + "/../lib/collection.rb"

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

puts "begin indicator calculations"

dataset = Collection.new bar_array
dataset.calculate_true_range
dataset.calculate_atr(20)
dataset.calculate_moving_average 20
dataset.calculate_moving_average_difference 20
dataset.calculate_target_close_difference
dataset.calculate_dm
dataset.calculate_di
dataset.calculate_average_di 20
dataset.calculate_dmi 20
dataset.calculate_adx 20
binding.pry
