# Set up MongoDB Sharding using Docker containers
## Automatic set up
```
$ chmod +x build.sh
$ ./build.sh [--force-root]
```

---

## Docker local network
Create a new docker network
```
$ docker network create mongodb-net
```
(It allows servers to communicate with each other even in offline mode.)

## Initialize servers
### Config servers
Start config servers (3 member replica set)
```
$ docker-compose -f config-server/docker-compose.yaml up -d
```
Initiate replica set
```
$ docker exec -it cfgsvr1 mongo
```
```js
> rs.initiate(
    {
      _id: "cfgrs",
      configsvr: true,
      members: [
        { _id: 0, host: "cfgsvr1" },
        { _id: 1, host: "cfgsvr2" },
        { _id: 2, host: "cfgsvr3" }
      ]
    }
  )

> rs.status()
```

### Shard 1 servers
Start shard 1 servers (3 member replicas set)
```
$ docker-compose -f shard1/docker-compose.yaml up -d
```
Initiate replica set
```
$ docker exec -it shard1svr1 mongo
```
```js
> rs.initiate(
    {
      _id: "shard1rs",
      members: [
        { _id: 0, host: "shard1svr1" },
        { _id: 1, host: "shard1svr2" },
        { _id: 2, host: "shard1svr3" }
      ]
    }
  )

> rs.status()
```

### Mongos Router
Start mongos query router
```
$ docker-compose -f mongos/docker-compose.yaml up -d
```

## Add shard to the cluster
Connect to mongos
```
$ docker exec -it mongos mongo
```
Add shard
```js
> sh.addShard("shard1rs/shard1svr1,shard1svr2,shard1svr3")

> sh.status()
```

## Add another shard
Start shard 2 servers (3 member replicas set)
```
$ docker-compose -f shard2/docker-compose.yaml up -d
```
Initiate replica set
```
$ docker exec -it shard2svr1 mongo
```
```js
> rs.initiate(
    {
      _id: "shard2rs",
      members: [
        { _id: 0, host: "shard2svr1" },
        { _id: 1, host: "shard2svr2" },
        { _id: 2, host: "shard2svr3" }
      ]
    }
  )

> rs.status()
```
Repeat "*[Add shard to the cluster](#add-shard-to-the-cluster)* " replacing `shard1` with `shard2` for each occurrence.

# Notices
## License

* This guide is released under the [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/legalcode) license.
* The codes included with this guide are released under the [MIT](https://github.com/giuseppe998e/mongodb-sharding/blob/main/LICENSE) license.

## Attribution
This guide is based on [justmeandopensource/learn-mongodb](https://github.com/justmeandopensource/learn-mongodb) (unlicensed).
