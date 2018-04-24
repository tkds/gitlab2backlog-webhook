require 'backlog_kit'
require 'webrick'
require 'json'

json_file_path = './config.json'
json_data = open(json_file_path) do |io|
  JSON.load(io)
end

client = BacklogKit::Client.new(
  space_id: json_data['space_id'],
  api_key: json_data['api_key']
)

def comments(result)
  comment = ''
  comment << "''ID:'' #{result['commits'][0]['id']}\n"
  comment << "''Date:'' #{result['commits'][0]['timestamp']}\n"
  comment << "''URL:'' #{result['commits'][0]['url']}\n"
  comment << "''Author:'' #{result['commits'][0]['author']['name']}\n"
  comment << "{code}\n"
  comment << "#{result['commits'][0]['message']}\n"
  comment << "{/code}\n"
end

def ticket_number(result, projects)
  projects.each do |project|
    if /((\#)(#{project.project_key}-[0-9]{1,}))/ =~ result['commits'][0]['message'] then
      return $3
    end
  end
  nil
end

server = WEBrick::HTTPServer.new(:Port => 8000)
server.mount_proc '/' do |req, res|
  result = JSON.parse(req.body)
  projects = client.get_projects.body
  ticket = ticket_number(result, projects)
  client.add_comment(ticket, comments(result)) unless ticket.nil?
end

trap 'INT' do
  server.shutdown
end
server.start