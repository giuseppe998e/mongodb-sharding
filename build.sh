#!/bin/sh
# Copyright (c) 2021 Giuseppe Eletto
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

abort() {
    echo $1
    exit 1
}

check_reqs() {
    # Check if user is root
    if test "$1" != "--force-root" && test $(id -u) == 0; then
        abort "You should NOT run this script as root! (Use '--force-root' to bypass)"
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        abort "Docker is NOT installed!"
    fi

    # Check if Docker-Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        abort "Docker-Compose is NOT installed!"
    fi
}

dcompose() {
    echo "> Creating '$1' container(s)..."
    (docker-compose -f "$1/docker-compose.yaml" up -d 1> /dev/null) \
        && echo ">> Ok!" \
        || abort ">> Failed!"
}

mongocmd() {
    echo "> Executing command on '$1' container..."
    (docker exec -it $1 bash -c "sleep 5s && echo '$2' | mongosh" 1> /dev/null) \
        && echo ">> Ok!" \
        || abort ">> Failed!"
}

create_mongonet() {
    echo "> Creating docker network..."
    (docker network create "mongodb-net" 1> /dev/null) \
        && echo ">> Ok!" \
        || abort ">> Failed!"
}

create_cfgs() {
    dcompose "config-server"
    mongocmd "cfgsvr1" "rs.initiate({_id: \"cfgrs\", configsvr: true, members: [{ _id: 0, host: \"cfgsvr1\" }, { _id: 1, host: \"cfgsvr2\" }, { _id: 2, host: \"cfgsvr3\" }]})"
}

create_shard() {
    dcompose "shard$1"
    mongocmd "shard$1svr1" "rs.initiate({_id: \"shard$1rs\", members: [{ _id: 0, host: \"shard$1svr1\" }, { _id: 1, host: \"shard$1svr2\" }, { _id: 2, host: \"shard$1svr3\" }]})"
}

create_router() {
    dcompose "mongos"
    mongocmd "mongos" "sh.addShard(\"shard1rs/shard1svr1,shard1svr2,shard1svr3\"); sh.addShard(\"shard2rs/shard2svr1,shard2svr2,shard2svr3\")"
}

#-----------
# Main func

check_reqs $1

create_mongonet

create_cfgs

create_shard 1
create_shard 2

create_router

echo ""
echo "All done!"
echo "Connect to your sharded database using 'mongodb://127.0.0.1:27017'"
