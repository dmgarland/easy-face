require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "EasyFace" do
  include Rack::Test::Methods

  describe "POST to /photos" do
    before do
      params = {
        "photos" => [Rack::Test::UploadedFile.new("spec/fixtures/image.jpg", "image/jpeg")],
        "user_id" => 'dan'
      }

      stub_request(:post, "http://api.skybiometry.com/fc/faces/detect.json").
      to_return(:body => File.read('spec/fixtures/detect.json'))

      stub_request(:post, "http://api.skybiometry.com/fc/tags/save.json").
         to_return(:status => 200, :body => File.read('spec/fixtures/save.json'))

      post '/photos', params
    end

    it "should detect faces and assign to a particular user" do
      last_response.status.should eq(201)
    end
  end
end
