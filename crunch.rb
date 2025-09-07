#!/usr/bin/env ruby

require 'fileutils'

# Check if ffmpeg is installed
def ffmpeg_installed?
  `which ffmpeg`.chomp != ''
end

# Calculate the target bitrate to achieve the desired file size (25 MB)
def calculate_target_bitrate(file_path, target_size_mb)
  file_size_kb = File.size(file_path).to_f / 1024
  target_size_kb = target_size_mb * 1024
  duration_seconds = `ffprobe -i "#{file_path}" -show_entries format=duration -v quiet -of csv="p=0"`.to_f
  target_bitrate = if duration_seconds > 0
                     ((target_size_kb - file_size_kb) * 8) / duration_seconds
                   else
                     0
                   end
  target_bitrate.to_i
end

# Process the MP3 file to reduce its size
def process_mp3(file_path, target_size_mb)
  unless ffmpeg_installed?
    puts "Error: ffmpeg is not installed."
    return
  end

  target_bitrate = calculate_target_bitrate(file_path, target_size_mb)

  if target_bitrate <= 0
    puts "Error: Could not calculate target bitrate or duration is zero."
    return
  end

  output_file = File.basename(file_path, File.extname(file_path)) + "_compressed.mp3"
  system("ffmpeg -y -i \"#{file_path}\" -b:a #{target_bitrate}k \"#{output_file}\"")

  if File.size(output_file).to_f / (1024 * 1024) > target_size_mb
    puts "Error: Compressed file is still larger than #{target_size_mb} MB."
  else
    puts "Success: File compressed to #{target_size_mb} MB or less."
  end
end

# Main execution
if ARGV.length != 1
  puts "Usage: #{$PROGRAM_NAME} <file_path>"
  exit
end

file_path = ARGV[0]
target_size_mb = 25

process_mp3(file_path, target_size_mb)