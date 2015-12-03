require 'sinatra'
require 'sinatra/json'
require 'isolated_server'
require 'isolated_server/mysql'
require 'isolated_server/mongodb'

module IsolatedDatabaseService
  class ServerList
    attr_accessor :next_id, :servers

    def initialize
      @next_id = 1
      @servers = {}
    end

    def add_server(server)
      id = @next_id
      @servers[id] = server
      @next_id += 1
      id
    end

    def delete_server(id)
      @servers.delete(id)
    end

    def count
      @servers.length
    end

    def clear
      @servers = {}
      @next_id = 1
    end
  end

  class Application < Sinatra::Base
    set :servers, ServerList.new

    post '/servers' do
      halt(400) unless params[:server]
      server_type = params[:server][:type] || 'mysql'

      new_server = case server_type
      when 'mysql'
        IsolatedServer::Mysql.new
      when 'mongodb'
        IsolatedServer::Mongodb.new
      else
        halt(40)
      end

      id = servers.add_server(new_server)
      new_server.boot!
      status 201
      json :server => present_server(id, new_server)
    end

    get '/servers' do
      json :servers => servers.servers.map { |id, server| present_server(id, server) } 
    end

    put '/servers/:id' do
      halt(400) unless params[:server]

      up = parse_boolean(params[:server][:up])
      unless up.nil?
        if up
          server.up!
        else
          server.down!
        end
      end

      rw = parse_boolean(params[:server][:rw])
      server.set_rw(rw) unless rw.nil?

      master_id = params[:server][:master_id]
      unless master_id.nil?
        master_server = servers.servers[master_id.to_i] || halt(400)
        server.make_slave_of(master_server)
      end

      json :server => present_server(params[:id].to_i, server)
    end

    delete '/servers/:id' do
      server.down!
      servers.delete_server(params[:id].to_i)
      status 204
    end

    private

    def servers
      settings.servers
    end

    def server
      @server ||= servers.servers[params[:id].to_i] || halt(404)
    end

    def parse_boolean(value)
      if truthy?(value)
        true
      elsif falsy?(value)
        false
      else
        nil
      end
    end

    def truthy?(value)
      ['true', 't', '1', 'yes', true].include?(value)
    end

    def falsy?(value)
      ['false', 'f', '0', 'no', false].include?(value)
    end

    def present_server(id, server)
      server_type = if server.is_a?(IsolatedServer::Mysql)       
        'mysql'
      elsif server.is_a?(IsolatedServer::Mongodb)
        'mongodb'
      else
        'unknown'
      end
      {id: id, port: server.port, up: server.up?, type: server_type}
    end
  end
end
