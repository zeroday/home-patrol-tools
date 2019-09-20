require 'base64'
require 'digest'
require 'json'
require 'net/http'
require 'taglib'
require 'uri'
require 'net/http'
require 'uri'
require 'json'

uri = URI.parse("http://127.0.0.1:5984/homepatrol/_all_docs")
request = Net::HTTP::Get.new(uri)
request.content_type = "application/json"
req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

def get_doc_id(doc_id)
  doc_uri = URI.parse("http://127.0.0.1:5984/homepatrol/#{doc_id}")
  doc_request = Net::HTTP::Get.new(doc_uri)
  doc_request.content_type = "application/json"
  req_options = {
    use_ssl: doc_uri.scheme == "https",
  }
  doc_response = Net::HTTP.start(doc_uri.hostname, doc_uri.port, req_options) do |http|
    http.request(doc_request)
  end
  return doc_response.body
end


def put_doc_id(doc_id, doc_json)
  uri = URI.parse("http://localhost:5984/homepatrol/#{doc_id}")
  request = Net::HTTP::Put.new(uri)
  request.content_type = "application/json"
  request.body = JSON.dump(doc_json)

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  return "[#{doc_id}] #{response.code} #{response.body}"
end

def create_new_revision(doc_id, doc_rev, date, time, length, doc_json)
  puts "(#{doc_id}) [#{date}] #{time} #{length}"
  doc_json["date"] = date
  doc_json["time"] = time
  doc_json["length"] = length
  revision_hash = Digest::SHA1.hexdigest "#{date}#{time}#{length}"
  doc_json["_rev"] = doc_rev
  return doc_json
end


all_items_json = JSON.parse(response.body)

all_items_json.each do |rows|
  if rows[0] == "rows"
    homepatrol_ids = rows[1]
    homepatrol_ids.each do |homepatrol_id|
      doc_id = homepatrol_id["id"]
      doc_json = JSON.parse(get_doc_id(doc_id))
      doc_rev = doc_json["_rev"]
      attachments = doc_json["_attachments"]
      next if attachments.nil?
      # assumes only one attachment
      attachments.each do |path_to_file, metadata|
        #puts "k: #{key} v: #{value}"
        # k: ./2019-08-17_13-06-00/2019-08-17_13-30-38.wav.mp3
        # v: {"content_type"=>"application/base64", "revpos"=>1,
        #     "digest"=>"md5-UPNvx5HPxLDUBZ/kR4VN1A==",
        #     "length"=>31093, "stub"=>true}
        length = metadata["length"]
        dot, date, filename = path_to_file.split("/")
        timestamp, wav, mp3 = filename.split(".")
        date, time = timestamp.split("_")
        new_doc = create_new_revision(doc_id, doc_rev, date, time, length, doc_json)
        response_code = put_doc_id(doc_id, new_doc)
        puts response_code
      end
    end
  end
end
