#!/bin/bash

VERSION=41
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RCONPW=YOUR_REMOTE_CONN_ADMIN_PASSWORD
RCONPATH=rcon-0.10.3-amd64_linux/rcon

function zstart {
    docker run -itd --rm --name zomboid -v $SCRIPT_DIR/Zomboid:/home/steam/Zomboid -p 16261:16261/udp -p 16262:16262/udp zomboid:41
}

function zstop {
    isPlayersOnline || shutdownCountDown
    docker stop zomboid
}

function shutdownCountDown {
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"server is shutting down in 5min\""
    sleep 60
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"server is shutting down in 4min\""
    sleep 60
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"server is shutting down in 3min\""
    sleep 60
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"server is shutting down in 2min\""
    sleep 60
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"server is shutting down in 1min\""
    sleep 60
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"server is shutting down NOW!!!\""
    sleep 2
}

function backup {
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "save"
    sleep 5
    docker logs -n 10 zomboid | grep "Saving finish" && return 0
    sleep 60
    docker logs -n 10 zomboid | grep "Saving finish" && return 0
    return 1
}

function debugmsg {
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "servermsg \"DEBUG: This is a test message.\""
}

function zhelp {
    echo "Usage:"
    echo "$0 start|stop|restart|test|updateMods|backup"
}

function checkModsUpdate {
    echo "Checking if mods need updating..."
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "checkModsNeedUpdate"
    sleep 6  # allow for checking mod versions online
    docker logs -n 10 zomboid | grep "Mods need update" && echo "Yes. needs update" && return 0
    echo "Does not need update"
    return 1
}

function isPlayersOnline {
    docker container exec zomboid $RCONPATH -a localhost:27015 -p $RCONPW "players" | grep "(0)" && echo "No players in World." && return 0
}

case $1 in
        start)
                zstart
                exit;;
        stop)
                zstop
                exit;;
        restart)
                backup
                zstop
                sleep 5
                zstart
                exit;;
        test)
                #debugmsg
                isPlayersOnline
                exit;;
        backup)
                backup
                exit;;
        updateMods)
                checkModsUpdate && backup && zstop && sleep 5 && zstart
                exit;;
        *)
                zhelp
                exit;;
esac
