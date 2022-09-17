# frozen_string_literal: true

require 'optparse'
require 'etc'
require 'date'

options = ARGV.getopts('l',
                       'long format(-l)  use a long listing format.')

# columns to display on the screen
COLUMN_MAX = 3

def count_group_size(file_names)
  file_names.size / COLUMN_MAX + 1
end

def divide_into_groups(file_names)
  file_names
    .map { |fname| fname.ljust(file_names.map(&:size).max) }
    .each_slice(count_group_size(file_names))
    .to_a
end

def list_files(file_names)
  file_names_in_groups = divide_into_groups(file_names)
  column = file_names_in_groups.size - 1
  row = count_group_size(file_names)
  (0..row).each do |r|
    (0..column).each do |c|
      print "#{file_names_in_groups[c][r]} "
    end
    puts '' unless r == row
  end
end

def count_blocks(file_names)
  number_of_files = file_names.size - 1
  (0..number_of_files).map do |nf|
    fs = File::Stat.new(file_names[nf])
    fs.blocks / 2
  end.sum
end

def list_file_type(file_mode)
  file_type = file_mode[0] + file_mode[1]
  case file_type
  when '04'
    'd'
  when '10'
    '-'
  when '12'
    'l'
  end
end

def list_special_perm_suid(file_mode, file_permissions)
  if file_mode[2] == 4 && file_permissions[2] == 'x'
    file_permissions[2] = 'S'
  elsif file_mode[2] == 4
    file_permissions[2] = 's'
  end
end

def list_special_perm_sgid(file_mode, file_permissions)
  if file_mode[2] == 2 && file_permissions[5] == 'x'
    file_permissions[5] = 'S'
  elsif file_mode[2] == 2
    file_permissions[5] = 's'
  end
end

def list_special_perm_sticky(file_mode, file_permissions)
  if file_mode[2] == 1 && file_permissions[8] == 'x'
    file_permissions[8] = 'T'
  elsif file_mode[2] == 1
    file_permissions[8] = 't'
  end
end

def list_file_perm(file_mode)
  file_permissions = []
  file_mode_r = file_mode
  (3..5).map do |fp|
    if file_mode_r[fp].to_i >= 4
      file_mode_w = file_mode_r[fp].to_i - 4
      file_permissions.push('r')
    else
      file_mode_w = file_mode_r[fp].to_i
      file_permissions.push('-')
    end
    if file_mode_w >= 2
      file_mode_x = file_mode_w - 2
      file_permissions.push('w')
    else
      file_mode_x = file_mode_w
      file_permissions.push('-')
    end
    if file_mode_x >= 1
      file_permissions.push('x')
    else
      file_permissions.push('-')
    end
  end
  list_special_perm_suid(file_mode, file_permissions)
  list_special_perm_sgid(file_mode, file_permissions)
  list_special_perm_sticky(file_mode, file_permissions)
  file_permissions.join
end

def list_files_in_long_format(file_names)
  number_of_files = file_names.size - 1
  print 'total '
  puts count_blocks(file_names)
  (0..number_of_files).each do |nf|
    fs = File::Stat.new(file_names[nf])
    file_mode_octal = fs.mode.to_s(8).split(//)
    file_mode_octal.unshift('0') if file_mode_octal.size == 5
    number_of_hard_links = fs.nlink
    user_name = Etc.getpwuid(fs.uid).name
    group_name = Etc.getgrgid(fs.gid).name
    file_size = fs.size
    time_stamp = fs.mtime.to_a
    date = Date.new(time_stamp[5], time_stamp[4], time_stamp[3])
    month = date.strftime('%b')
    day = time_stamp[3]
    hour = time_stamp[2]
    minutes = time_stamp[1]
    print "#{list_file_type(file_mode_octal)}#{list_file_perm(file_mode_octal)}"
    puts " #{number_of_hard_links} #{user_name} #{group_name} #{file_size} #{month} #{day} #{hour}:#{minutes} #{file_names[nf]}"
  end
end

if options['l']
  list_files_in_long_format(Dir.glob('*'))
else
  list_files(Dir.glob('*'))
end
