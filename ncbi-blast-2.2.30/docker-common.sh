## -> NO USER-SERVICABLE PARTS INSIDE
# Create unique but human comprehensible name for each container

if [ -z "${DOCKER_DATA_IMAGE}" ];
then
    echo "Error: DOCKER_DATA_IMAGE was not defined"
fi
if [ -z "${DOCKER_DATA_VOLUME}" ];
then
  echo "Error: DOCKER_DATA_VOLUME was not defined"
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

# Pull containers to ensure freshness!
echo "Updating application and database images..."
#time docker pull ${DOCKER_APP_IMAGE}
#time docker pull ${DOCKER_DATA_IMAGE}
echo "Done"

# Build data image
# Has to be done this way because if VOLUME is declared in the Dockerfile
# then subsequent layered additions to your volumes will not persist
DOCKER_DATA_IMAGE_BUILT="data_image_built_$STAMP"
mkdir -p "$DOCKER_DATA_IMAGE_BUILT"

cat > $DOCKER_DATA_IMAGE_BUILT/Dockerfile <<EOD
FROM ${DOCKER_DATA_IMAGE}
ENV BUILD_DATE "$(date)"
ENV DOCKER_DATA_SOURCE ${DOCKER_DATA_IMAGE}
VOLUME ${DOCKER_DATA_VOLUME}
EOD

docker build --rm=true -t "$DOCKER_DATA_IMAGE_BUILT" "$DOCKER_DATA_IMAGE_BUILT" && rm -rf $DOCKER_DATA_IMAGE_BUILT

# Data container (paused)
DOCKER_DATA_CREATE="docker create ${HOST_OPTS} --name ${DOCKER_DATA_CONTAINER} $DOCKER_DATA_IMAGE_BUILT"
DOCKER_DATA_CONTAINER=$( ${DOCKER_DATA_CREATE} | cut -c1-12 )
# App container (running)
DOCKER_APP_CREATE="docker run ${HOST_OPTS} -d --volumes-from ${DOCKER_DATA_CONTAINER} -v `pwd`:${HOST_SCRATCH}:rw -w ${HOST_SCRATCH} --name ${DOCKER_APP_CONTAINER} ${DOCKER_APP_IMAGE} sleep 2419200"
DOCKER_APP_CONTAINER=$( ${DOCKER_APP_CREATE} | cut -c1-12)
DOCKER_APP_RUN="docker exec -i ${TTY} $DOCKER_APP_CONTAINER"
## <- NO USER-SERVICABLE PARTS INSIDE
