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

      stub_request(:post, "http://api.skybiometry.com/fc/faces/train.json").
        with(:body => {"api_key"=>"13eb99ff98224044bfcf5e57f2b8d4be", "api_secret"=>"166e13b840274e56b9634efa4dea511a", "uids"=>"dan@endsvchack"},
          :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'106', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.read('spec/fixtures/train.json'))

      post '/photos', params
    end

    it "should detect faces and assign to a particular user" do
      last_response.status.should eq(201)
    end
  end

  context "with a previously saved (tagged) user" do
    describe "POST to /photos/:user_id/detect" do
      before do
        stub_request(:post, "http://api.skybiometry.com/fc/faces/recognize.json").
         with(:body => {"api_key"=>"13eb99ff98224044bfcf5e57f2b8d4be", "api_secret"=>"166e13b840274e56b9634efa4dea511a", "uids"=>"dan@endsvchack", "urls"=>"http://someurl.com/image.jpg,http://someurl.com/some_other_image.jpg"},
              :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'198', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => File.read('spec/fixtures/recognise.json'))

        post '/photos/dan/detect', "urls" => %w(http://someurl.com/image.jpg
          http://someurl.com/some_other_image.jpg)
      end

      it "should return a list of similar" do
        JSON(last_response.body).should eq({"dan" => { "confidence" => 100, "url" => 'http://www.dangarland.co.uk/images/endsvchack/madrid.jpg'}})
      end
    end
  end
end
