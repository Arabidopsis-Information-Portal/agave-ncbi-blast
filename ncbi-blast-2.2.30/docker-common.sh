## -> NO USER-SERVICABLE PARTS INSIDE
# Create unique but human comprehensible name for each container

if [ -z "${DOCKER_DATA_IMAGE}" ];
then
    echo "Error: DOCKER_DATA_IMAGE was not defined"
fi
if [ -z "${DOCKER_APP_IMAGE}" ];
then
    echo "Error: DOCKER_APP_IMAGE was not defined"
fi
if [ -z "$HOST_SCRATCH" ];
then
    echo "Warning: HOST_SCRATCH was not defined"
fi

#TTY="-t"
TTY=""
MYUID=$(id -u $USER)
STAMP=$(date +%s)
DOCKER_APP_CONTAINER="app-$STAMP"
DOCKER_DATA_CONTAINER="db-$STAMP"
HOST_OPTS="--net=none -m=1g -u=$MYUID"
# Data container (paused)
DOCKER_DATA_CREATE="docker create ${HOST_OPTS} --name ${DOCKER_DATA_CONTAINER} $DOCKER_DATA_IMAGE"
DOCKER_DATA_CONTAINER=$( ${DOCKER_DATA_CREATE} | cut -c1-12 )
# App container (running)
DOCKER_APP_CREATE="docker run ${HOST_OPTS} -d --volumes-from ${DOCKER_DATA_CONTAINER} -v `pwd`:${HOST_SCRATCH}:rw -w ${HOST_SCRATCH} --name ${DOCKER_APP_CONTAINER} ${DOCKER_APP_IMAGE} sleep 2419200"
DOCKER_APP_CONTAINER=$( ${DOCKER_APP_CREATE} | cut -c1-12)
DOCKER_APP_RUN="docker exec -i ${TTY} $DOCKER_APP_CONTAINER"
## <- NO USER-SERVICABLE PARTS INSIDE
