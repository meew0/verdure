require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'mini_magick'
require 'kmeans-clusterer'

require_relative 'colour'

# Ensure the public directory is used for static files
set :public_folder, 'public'

K = 2

def main_colours(image_path)
  image = MiniMagick::Image.open(image_path)
  pixels = image.get_pixels
  hsv = pixels.flatten(1).map { |r, g, b| RGB.new(r, g, b).to_hsv }
  kmeans = KMeansClusterer.run(K, hsv)
  lengths = kmeans.clusters.map(&:points).map(&:length)
  indices = lengths.each_with_index.sort_by(&:first).map(&:last)
  secondary, primary = indices.map { |e| kmeans.clusters[e].centroid.data.to_a }

  primary_hex = HSV.new(primary[0] % 360, primary[1], primary[2]).to_hex
  secondary_hex = HSV.new(secondary[0] % 360, secondary[1], secondary[2]).to_hex

  [primary_hex, secondary_hex]
end

def main_colours_palette(image_path)
  result, status = Open3.capture2e('java', '-jar', '/home/miras/Projects/sa_image_palette/app/build/libs/app-all.jar', image_path)
  if status != 0
    raise result
  end

  result.lines.map(&:chomp)
end

get '/:filename' do
  filename = params[:filename]
  file_path = File.join(settings.public_folder, 'static', "#{filename}.ogg")

  if File.exist?(file_path)
    metadata = get_metadata(file_path)
    image_path = File.join('public/static', filename)
    has_image = File.exist?(image_path)
    stream = metadata['streams'].select { |e| e['codec_type'] == 'audio' }.first
    tags = Hash[stream['tags'].map { |k, v| [k.downcase.to_sym, v] }]
    tags[:duration] = metadata['format']['duration'].to_f
    pp tags
    colors = has_image ? main_colours_palette(image_path) : ['#ffffffff', '#000000ff', '#777777ff']
    if tags[:track]&.include? '/'
      tags[:track], tags[:totaltracks] = tags[:track].split('/')
    end
    erb :index, locals: { filename: filename, tags: tags, colors: colors, has_image: has_image }
  else
    status 404
    "File not found"
  end
end

def get_metadata(file_path)
  output = `ffprobe -v quiet -print_format json -show_format -show_streams "#{file_path}"`
  JSON.parse(output)
end
