require 'sinatra'
require 'face'

class EasyFaceApi < Sinatra::Base
  set :skyb_api_key, "13eb99ff98224044bfcf5e57f2b8d4be"
  set :skyb_api_secret, "166e13b840274e56b9634efa4dea511a"
  set :skyb_namespace, "endsvchack"
  set :raise_errors, true
  set :show_exceptions, false

  post '/photos' do
    params["photos"].each do |photo|
      detect = client.faces_detect(:file => photo[:tempfile])
      tag_id = detect["photos"].first["tags"].first["tid"]
      user_id = "#{params["user_id"]}@#{settings.skyb_namespace}"
      tag = client.tags_save(:tids => tag_id, :uid => user_id)
    end
    201
  end

  protected
  def client
    @client ||= Face.get_client(:api_key => settings.skyb_api_key,
      :api_secret => settings.skyb_api_secret)
  end
end