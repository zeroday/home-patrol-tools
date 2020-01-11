require 'base64'
require 'digest'
require 'json'
require 'net/http'
require 'taglib2'
require 'uri'

mp3_file = ARGV[0]
puts "mp3 #{mp3_file}"
raw_data = File.open(mp3_file).read
mp3_size = File.size?(mp3_file)
puts "size #{mp3_size}"
HOST = '192.168.1.241'
base64_encoded_data = Base64.encode64(raw_data)
f = TagLib::File.new(mp3_file) 
# timestamp is embedded in filename
dot, date, filename = mp3_file.split("/")
timestamp, wav, mp3 = filename.split(".")
date, time = timestamp.split("_")
puts "title: #{f.title}"
puts "artist: #{f.artist}"
puts "genre: #{f.genre}"
puts "date: #{date}"
puts "time: #{time}"
  # curl -X PUT http://localhost:5984/test/docid 
  #      -d '{"_attachments": {"message.txt":
  #                                {"data": "aGVsbG8sIENvdWNoIQ==",
  #                                "content_type": "application/base64"}}}'
  #      -H "Content-Type:application/json"
doc_id = Digest::SHA1.hexdigest base64_encoded_data
uri = URI.parse("http://192.168.1.241/homepatrol/#{doc_id}")
request = Net::HTTP::Put.new(uri)
request.content_type = "application/json"
request.body = JSON.dump({"status": "new",
                          "title": "#{f.title}",
                          "artist": "#{f.artist}",
                          "genre": "#{f.genre}",
                          "year": "#{f.year}",
                          "date": "#{date}",
                          "time": "#{time}",
                          "album": "#{f.album}",
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

puts response.body

