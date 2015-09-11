# Common setup for Docker-based BLAST or other
# applications with data container

DOCKER_APP_IMAGE='araport/agave-ncbi-blast:2.2.30'
DOCKER_DATA_IMAGE='araport/agave-ncbi-blastdb:tair10'

HOST_SCRATCH='/home'
STAMP=$(date +%s)

## NO USER-SERVICABLE PARTS INSIDE
# Create unique but human comprehensible name for each container
DOCKER_APP_CONTAINER="app-$STAMP"
DOCKER_DATA_CONTAINER="db-$STAMP"
HOST_OPTS="--net=none -m=1g"

#DOCKER_DATA_RUN="docker run ${HOST_OPTS} --name ${DOCKER_DATA_CONTAINER} $DOCKER_DATA_IMAGE true"
DOCKER_DATA_RUN="docker create ${HOST_OPTS} --name ${DOCKER_DATA_CONTAINER} $DOCKER_DATA_IMAGE"
DOCKER_APP_RUN="docker run ${HOST_OPTS} --name ${DOCKER_APP_CONTAINER} -i -t --volumes-from ${DOCKER_DATA_CONTAINER} -v `pwd`:${HOST_SCRATCH}:rw -w ${HOST_SCRATCH} ${DOCKER_APP_IMAGE}"
## NO USER-SERVICABLE PARTS INSIDE

# Launch the data container
${DOCKER_DATA_RUN}
${DOCKER_APP_RUN} /bin/bash

exit 0

# docker create -v /opt/databases --name dbdata agaveapi/php-api-base /bin/true
