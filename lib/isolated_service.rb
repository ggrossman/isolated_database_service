require 'sinatra'
require 'sinatra/json'
require 'isolated_server'
require 'isolated_server/mysql'
require 'isolated_server/mongodb'

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
end

class IsolatedService < Sinatra::Base
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

    unless params[:server][:up].nil?
      if params[:server][:up]
        server.up!
      else
        server.down!
      end
    end

    unless params[:server][:rw].nil?
      server.set_rw(params[:server][:rw])
    end

    master_id = params[:server][:master_id]
    unless master_id.nil?
      master_server = servers.servers[master_id] || halt(400)
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