require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'open3'

# Ensure the public directory is used for static files
set :public_folder, 'public'

def main_colours_palette(image_path)
  result, status = Open3.capture2e('java', '-jar', File.join(File.expand_path(File.dirname(__FILE__)), 'lib', 'palette.jar'), image_path)
  raise result if status != 0

  result.lines.map(&:chomp)
end

def music_file_metadata(file_path)
  result, status = Open3.capture2e('ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_format', '-show_streams', file_path)
  raise result if status != 0

  JSON.parse(result)
end

get '/:filename' do
  filename = params[:filename]
  file_path = File.join(settings.public_folder, 'static', "#{filename}.ogg")

  if File.exist?(file_path)
    metadata = music_file_metadata(file_path)
    image_path = File.join('public/static', filename)
    has_image = File.exist?(image_path)
    stream = metadata['streams'].select { |e| e['codec_type'] == 'audio' }.first
    tags = Hash[stream['tags'].map { |k, v| [k.downcase.to_sym, v] }]
    tags[:duration] = metadata['format']['duration'].to_f
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
