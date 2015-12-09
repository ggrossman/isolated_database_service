# isolated_database_service

[![Build Status](https://travis-ci.org/ggrossman/isolated_database_service.png)](https://travis-ci.org/ggrossman/isolated_database_service)

Microservice wrapper for [isolated_server](https://github.com/gabetax/isolated_server)

[isolated_server](https://github.com/gabetax/isolated_server) lets you easily bring up and down clusters of
temporary MySQL and MongoDB servers on your local machine or CI environment for testing purposes.
However, it can only be used from Ruby.

This is a wrapper for [isolated_server](https://github.com/gabetax/isolated_server) which provides a
simple JSON REST API for it, making it language-agnostic and callable from Java, Scala, Python, etc.

## Running

The script `boot_isolated_database_service` can be used to start the service:

```bash
bin/boot_isolated_database_service
```

Pass the `-p` argument to configure the listen port, or Sinatra's default is used.

```bash
bin/boot_isolated_database_service -p 9000
```

## JSON API

### Create a Server
`POST /servers`

Boots up a new MySQL or MongoDB server.

#### Request JSON

```json
{
  "server": {
    "type": "mysql"
  }
}
```

`type` may be set to either `mysql` or `mongodb`. If not supplied, `mysql` is assumed.

#### Using curl

```bash
curl -H "Content-Type: application/json" -X POST \
     -d '{"server":{"type":"mysql"}}' http://localhost:9292/servers
```

#### Example Response

```http
201 Created

{
  "server": {
    "id": 1,
    "type": "mysql",
    "port": 41536,
    "up": true
  }
}
```

### List Servers
`GET /servers`

Lists the servers currently available.

#### Using curl

```bash
curl http://localhost:9292/servers
```

#### Example Response

```http
200 OK

{
  "servers": [
    {
      "id": 1,
      "port": 30979,
      "up": true,
      "type":"mysql"
    },
    {
      "id": 2,
      "port": 33212,
      "up": true,
      "type": "mysql"
    }
  ]
}
```

### Update Server
`PUT /servers/{id}`

Updates a server, bringing it up or down, setting read-only/read-write, etc.

#### Request JSON

```json
{
  "server": {
    "up": true,
    "rw": true,
    "master_id": 1
  }
}
```

All of the parameters `up`, `rw` and `master_id` are optional.

`up`: `true` will bring the server up, `false` will bring it down.

`rw`: `true` will set the server to read/write, `false` will set it to read-only.

`master_id`: The ID of another server can be given to make this server a slave of that master.

#### Using curl

```bash
curl -H "Content-Type: application/json" -X PUT \
     -d '{"server":{"up":false}}' http://localhost:9292/servers/2
```

#### Example Response

```http
200 OK

{
  "server": [
    {
      "id": 1,
      "type": "mysql",
      "up": true
    }
  ]
}
```

### Delete Server
`DELETE /servers/{id}`

Deletes a server, bringing it down and removing it from the server list.

#### Using curl

```bash
curl -X DELETE http://localhost:9292/servers/2
```

#### Example Response

```http
204 No Content
```

### Boot MySQL Cluster
`POST /mysql-clusters`

Creates a cluster of MySQL servers with a master, a slave and a chained slave server, with replication established.

The optional `initial_sql` property contains an array of SQL statements to execute on the master server before establishing replication.

#### Using curl

```bash
curl -H "Content-Type: application/json" \
     -d '{"cluster":{"initial_sql":[
            "CREATE TABLE test.foo (id INT, value INT)"
            "INSERT INTO test.foo VALUES (1, 2)"]}}' \
     -X POST http://localhost:9000/mysql-clusters
```

#### Example Response

```http
200 OK

{
  "cluster": {
    "master": { 
      "id": 1,
      "port": 57959,
      "up": true,
      "type": "mysql"
    },
    "slave": {
      "id": 2,
      "port": 27702,
      "up": true,
      "type": "mysql"
    },
    "slave_2": {
      "id": 3,
      "port": 51111,
      "up": true,
      "type": "mysql"
    }
  }
}
```
