# frozen_string_literal: true

require 'optparse'

# options and description of them
options = ARGV.getopts('a',
                       'all(-a)    list all files including hidden files.')

# columns to display on the screen
COLUMN_MAX = 3

def group_file_names(option)
  if option == a
    Dir.glob('*', File::FNM_DOTMATCH)
  else
    Dir.glob('*')
  end
end

def length_max(array)
  array.map(&:size).max
end

def count_group_size(array, groups)
  array.size / groups + 1
end

def divide_into_groups(array)
  array
    .sort
    .map { |a| a.ljust(file_length_max(array)) }
    .each_slice(count_group_size(array))
    .to_a
end

def list_files(file_names, lines = COLUMN_MAX)
  group_in_groups = divide_into_groups(file_names)
  column = group_in_groups.size - 1
  row = count_group_size(file_names, lines)
  (0..row).each do |r|
    (0..column).each do |c|
      print "#{group_in_groups[c][r]} "
    end
    puts '' unless r == row
  end
end

if option['a']
  list_files(group_file_names(a))
else
  list_files(group_file_names)
end
