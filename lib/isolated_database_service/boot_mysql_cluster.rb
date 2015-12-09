#!/usr/bin/env ruby

require 'isolated_server'
require 'isolated_server/mysql'

# This is based on https://github.com/osheroff/ar_mysql_flexmaster/blob/master/test/boot_mysql_env.rb
module BootMysqlCluster
  def self.boot!(initial_sql = [])
    mysql_master = nil
    mysql_slave = nil
    mysql_slave_2 = nil

    threads = []
    threads << Thread.new do
      mysql_master = IsolatedServer::Mysql.new(allow_output: false)
      mysql_master.boot!
    end

    threads << Thread.new do
      mysql_slave = IsolatedServer::Mysql.new
      mysql_slave.boot!
    end

    threads << Thread.new do
      mysql_slave_2 = IsolatedServer::Mysql.new
      mysql_slave_2.boot!
    end

    threads.each(&:join)

    mysql_master.connection.query("CHANGE MASTER TO master_host='127.0.0.1', master_user='root', master_password=''")
    mysql_slave.make_slave_of(mysql_master)
    mysql_slave_2.make_slave_of(mysql_slave)

    initial_sql.each do |sql|
      mysql_master.connection.query(sql)
    end
    mysql_slave.set_rw(false)
    mysql_slave_2.set_rw(false)

    # let replication for the grants and such flow down.  bleh.
    repl_sync = false
    while !repl_sync
      repl_sync = [[mysql_master, mysql_slave], [mysql_slave, mysql_slave_2]].all? do |master, slave|
        master_pos = master.connection.query("show master status").to_a.first["Position"]
        slave.connection.query("show slave status").to_a.first["Exec_Master_Log_Pos"] == master_pos
      end
      sleep 1
    end

    [mysql_master, mysql_slave, mysql_slave_2]
  end
end
