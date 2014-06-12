require 'sinatra'
require 'face'
require 'pry'

class EasyFaceApi < Sinatra::Base
  set :skyb_api_key, "13eb99ff98224044bfcf5e57f2b8d4be"
  set :skyb_api_secret, "166e13b840274e56b9634efa4dea511a"
  set :skyb_namespace, "endsvchack"
  set :raise_errors, true
  set :show_exceptions, false

  post '/photos' do
    params["photos"].each do |photo|
      # Detect faces
      detect = client.faces_detect(:file => uploaded_file(photo))
      # Save (tag) the photo as the given user_id
      tag_id = detect["photos"].first["tags"].first["tid"]
      tag = client.tags_save(:tids => tag_id, :uid => user_id)
    end

    # Train the face software with the new photos
    client.faces_train(:uids => user_id)

    201
  end

  post '/photos/:user_id/detect' do
    urls = params["urls"]
    users = {}

    faces = client.faces_recognize(:uids => user_id, :urls => urls.join(","))
    faces["photos"].each do |photo|
      tag = photo["tags"].first
      if tag && tag["uids"]
        matches = tag["uids"]
        if matches && matches.length > 0
          best_guess = matches.map do |m|
            {
              :user_id => m["uid"].split("@").first,
              :confidence => m["confidence"]
            }
          end.sort {|a,b| b[:confidence] <=> a[:confidence]}.first

          current_confidence = users[best_guess[:user_id]]
          if current_confidence.nil? || current_confidence[:confidence] < best_guess[:confidence]
            users[best_guess[:user_id]] = {
              :confidence => best_guess[:confidence],
              :url => photo["url"]
            }
          end
        end
      end
    end

    # # Don't include the original user that we are testing...
    # users.delete params[:user_id]

    content_type :json
    users.to_json
  end

  protected
  def client
    @client ||= Face.get_client(:api_key => settings.skyb_api_key,
      :api_secret => settings.skyb_api_secret)
  end

  def user_id
    @user_id ||= "#{params["user_id"]}@#{settings.skyb_namespace}"
  end

  # TODO - Upload only supports JPG right now :/
  def uploaded_file(photo)
    picture_file = "#{photo[:tempfile].path}.jpg"
    FileUtils.cp photo[:tempfile].path, picture_file
    File.new(picture_file, 'rb')
  end
end