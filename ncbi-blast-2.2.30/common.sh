# Common setup for Docker-based BLAST or other
# applications with data container

DOCKER_APP_IMAGE='araport/ncbi-blast:2.2.30'
#DOCKER_DATA_IMAGE='araport/blastdb:tair10'
DOCKER_DATA_IMAGE='agaveapi/java-api-base'

HOST_SCRATCH='/scratch'
STAMP=$(date +%s | md5)

## NO USER-SERVICABLE PARTS INSIDE
# Create unique but human comprehensible name for each container
DOCKER_APP_CONTAINER="app-$STAMP"
DOCKER_DATA_CONTAINER="db-$STAMP"
HOST_OPTS="--net=none -m=1g --rm=true"

#DOCKER_DATA_RUN="docker run ${HOST_OPTS} --name ${DOCKER_DATA_CONTAINER} $DOCKER_DATA_IMAGE true"
DOCKER_DATA_RUN="docker run ${HOST_OPTS} --name ${DOCKER_DATA_CONTAINER} $DOCKER_DATA_IMAGE true"
DOCKER_APP_RUN="docker run ${HOST_OPTS} --name ${DOCKER_APP_CONTAINER} -i -t --volumes-from ${DOCKER_DATA_CONTAINER} -v `pwd`:${HOST_SCRATCH}:rw -w ${HOST_SCRATCH} ${DOCKER_APP_IMAGE}"
## NO USER-SERVICABLE PARTS INSIDE

# Launch the data container
${DOCKER_DATA_RUN}

exit 0

# docker create -v /opt/databases --name dbdata agaveapi/php-api-base /bin/true
