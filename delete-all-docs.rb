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


def delete_doc_id(doc_id, rev_id)
  puts "[#{doc_id}](#{rev_id})"
  uri = URI.parse("http://127.0.0.1:5984/homepatrol/#{doc_id}?_#{rev_id}")
  request = Net::HTTP::Delete.new(uri)

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  # response.code
  # response.body

end

all_items_json = JSON.parse(response.body)

all_items_json.each do |rows|
  if rows[0] == "rows"
    homepatrol_ids = rows[1]
    homepatrol_ids.each do |homepatrol_id|
      doc_id = homepatrol_id["id"]
      doc_json = JSON.parse(get_doc_id(doc_id))
      doc_rev = doc_json["_rev"]
      response_code = delete_doc_id(doc_id, doc_rev)
      puts response_code
    end
  end
end
