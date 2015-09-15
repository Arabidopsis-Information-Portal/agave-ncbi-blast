# Init for Docker-based CLI
# applications that mount persistent
# data container

DOCKER_APP_IMAGE='araport/agave-ncbi-blast:2.2.30'
# Feel free to append a specific versioned tag to the data image, but be warned that will
# restrict the set of queriable public datasets to JUST that release
DOCKER_DATA_IMAGE='araport/agave-ncbi-blastdb:tair10'
# Only change if you need to and know what you're doing
HOST_SCRATCH='/home'
# In theory, these values can be set in the Agave application's metadata
# then set to invisible so they can't be re-set by end user

# YOU MUST INCLUDE THIS LINE AFTER DEFINING
# THE PREVIOUS VARIABLES ^^
source ./docker-common.sh

# Now, build up the arguments string for BLAST
# Variables expressed as ${var} are selectively
# replaced by the Agave runtime environment based
# on either platform-level variables or
# parameters defined and passed in the app metadata
# and associated job submission. If Agave can't recognize
# them, they will be left untouched in the script

# This is the FASTA query file
QUERYFILE="${query}"

# This is an optional custom FASTA file
# usable as database, in addition to any
# libraries selected from the databases volume
CUSTOMDB="${customDatabase}"

do_makeblastdb () {

   local dbfile=$1
   local dbtype=$2
   if [ -n "${dbfile}" ];
       then
       ${DOCKER_APP_RUN} makeblastdb -in "${dbfile}" -dbtype "${dbtype}" -out "custom_db" -logfile "makeblastdb-${dbfile}-${dbtype}.log"
       if [[ ! $? -eq 0 ]];
       then
            echo "Warning: Unable to format ${dbfile} as a custom ${dbtype} database." > "makeblastdb-${dbfile}-${dbtype}.log"
        fi
        DATABASES="${DATABASES} $HOST_SCRATCH/custom_db"
    fi

}

# Custom argument string and makeblastdb behavior for each type of BLAST
DATABASES="${database}"
ARGS="-num_threads 2"
case "${APPLICATION}" in
    blastn)
        do_makeblastdb ${CUSTOMDB} nucl
        # Not used by blastn: matrix gencode
        ARGS="${ARGS} ${evalue} ${penalty} ${reward} ${ungapped} ${max_target_seqs} ${filter} ${lowercase_masking} ${wordsize} ${gapopen} ${gapextend}"
        ;;
esac

# General case arguments
# Unify -html and -outfmt format modes
case ${format} in
	HTML)
		ARGS="$ARGS -html"
		;;
	TEXT)
		ARGS="$ARGS -outfmt 0"
		;;
	XML)
		ARGS="$ARGS -outfmt 5"
		;;
	TABULAR)
		ARGS="$ARGS -outfmt 6"
		;;
	TABULAR_COMMENTED)
		ARGS="$ARGS -outfmt 7"
		;;
	ASN1)
		ARGS="$ARGS -outfmt 11"
		;;
esac

# Run the command in Docker app container
${DOCKER_APP_RUN} ${APPLICATION} -db "${DATABASES}" ${ARGS} -query ${QUERYFILE} -out ${APPLICATION}_out

# Here is where we can insert additional commands to run either in local environment
# or the app container for additional post-processing

## -> NO USER-SERVICABLE PARTS INSIDE
docker rm -f ${DOCKER_DATA_CONTAINER}
docker rm -f ${DOCKER_APP_CONTAINER}
## <- NO USER-SERVICABLE PARTS INSIDE
