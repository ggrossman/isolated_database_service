require File.expand_path '../spec_helper.rb', __FILE__

describe IsolatedDatabaseService do
  before do
    allow_any_instance_of(IsolatedServer::Mysql).to receive(:boot!).and_return(true)
  end

  describe "GET /servers" do
    before do
      3.times do
        post "/servers", {server: {type: 'mysql'}}
      end
    end

    it "should list out the servers" do
      get "/servers"
      expect(last_response).to be_ok
      parsed_body = JSON.parse(last_response.body)
      expect(parsed_body['servers'].length).to eq(3)
    end
  end

  describe "POST /servers" do
    it "should reject bad arguments" do
      post "/servers"
      expect(last_response).to be_bad_request
    end

    it "should create a server" do      
      post "/servers", {server: {type: 'mysql'}}
      expect(last_response).to be_created
      expect(app().servers.count).to eq(1)
    end
  end

  describe "PUT /servers/:id" do
    before do
      @server = double()
      allow(@server).to receive(:port).and_return(5000)
      allow(@server).to receive(:up?).and_return(true)
      @id = app().servers.add_server(@server)
    end

    it "should bring up a server" do
      expect(@server).to receive(:up!).and_return(true)
      put "/servers/#{@id}", {server: {up: true}}
    end

    it "should bring down a server" do
      expect(@server).to receive(:down!).and_return(true)
      put "/servers/#{@id}", {server: {up: false}}
    end

    it "should set a server to read/write" do
      expect(@server).to receive(:set_rw).with(true).and_return(true)
      put "/servers/#{@id}", {server: {rw: true}}
    end

    it "should set a server to read-only" do
      expect(@server).to receive(:set_rw).with(false).and_return(true)
      put "/servers/#{@id}", {server: {rw: false}}
    end

    it "should set a server's master" do
      @master_server = double()
      @master_id = app().servers.add_server(@master_server)
      expect(@server).to receive(:make_slave_of).with(@master_server).and_return(true)
      put "/servers/#{@id}", {server: {master_id: @master_id}}
    end      
  end

  describe "DELETE /servers/:id" do
    before do
      3.times do
        post "/servers", {server: {type: 'mysql'}}
      end
    end

    it "should delete a server" do
      expect(app().servers.count).to eq(3)
      expect(app().servers.servers[1]).to receive(:down!)
      delete "/servers/1"
      expect(last_response.status).to eq(204)
      expect(app().servers.count).to eq(2)
    end
  end
end
