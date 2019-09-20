require 'base64'
require 'digest'
require 'json'
require 'net/http'
require 'taglib'
require 'uri'

mp3_file = ARGV[0]
raw_data = File.open(mp3_file).read
mp3_size = File.size?(mp3_file)

base64_encoded_data = Base64.encode64(raw_data)
TagLib::MPEG::File.open(mp3_file) do |file|
  # timestamp is embedded in filename
  dot, date, filename = mp3_file.split("/")
  timestamp, wav, mp3 = filename.split(".")
  date, time = timestamp.split("_")
  tag = file.id3v2_tag
  puts "title: #{tag.title}"
  puts "length: #{mp3_size}"
  puts "artist: #{tag.artist}"
  puts "genre: #{tag.genre}"
  puts "year: #{tag.year}"
  puts "date: #{date}"
  puts "time: #{time}"
  puts "album: #{tag.album}"
  # curl -X PUT http://localhost:5984/test/docid 
  #      -d '{"_attachments": {"message.txt":
  #                                {"data": "aGVsbG8sIENvdWNoIQ==",
  #                                "content_type": "application/base64"}}}'
  #      -H "Content-Type:application/json"
  doc_id = Digest::SHA1.hexdigest base64_encoded_data
  uri = URI.parse("http://127.0.0.1:5984/homepatrol/#{doc_id}")
  request = Net::HTTP::Put.new(uri)
  request.content_type = "application/json"
  request.body = JSON.dump({"title": "#{tag.title}",
                            "artist": "#{tag.artist}",
                            "genre": "#{tag.genre}",
                            "year": "#{tag.year}",
                            "date": "#{date}",
                            "time": "#{time}",
                            "album": "#{tag.album}",
                            "length": "#{mp3_size}",
                            "_attachments" => {
                              mp3_file => {
                                "data" => base64_encoded_data,
                                "content_type" => "application/base64"
                              }
                             }
                           })
  
  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  puts response.code
  puts response.body
end
