# Init for Docker-based CLI
# applications that mount persistent
# data container

DOCKER_APP_IMAGE='araport/agave-ncbi-blast:2.2.30'
# You may append a specific versioned tag to the data image, but be warned that will
# restrict the set of queriable public datasets to JUST that release unless
# the tag is 'latest'
DOCKER_DATA_IMAGE='araport/agave-ncbi-blastdb:latest'
# Only change if you need to and know what you're doing
HOST_SCRATCH='/home'
# In theory, these values can be set in the Agave application's metadata
# then set to invisible so they can't be re-set by end user
# How many concurrent threads to run BLAST*
#
# Discover this from the host and run at max
_THREADS=$(cat /proc/cpuinfo | grep processor | wc -l)

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

    # Build a local BLAST database if values were passed
    # Log an error if the user sent in the wrong format
   local dbfile=$1
   local dbtype=$2
   if [ -n "${dbfile}" ] && [ -n "${dbtype}" ];
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
ARGS="-num_threads ${_THREADS}"
filter_flag=""
# This is new. Set up the ARG and custom database creation up based on the preferred application
case "${blast_application}" in
    blastn)
        do_makeblastdb ${CUSTOMDB} nucl
        # Not used by blastn: matrix gencode
        if [ "${filter}" -eq 0 ];then filter_flag="-dust no";fi
        ARGS="${evalue} ${penalty} ${reward} ${ungapped} ${max_target_seqs} ${filter_flag} ${lowercase_masking} ${wordsize} ${gapopen} ${gapextend}"
        ;;
    blastp)
        do_makeblastdb ${CUSTOMDB} prot
        # Not used by blastp: penalty reward gencode
        if [ "${filter}" -eq 0 ];then filter_flag="-seg no";fi
        ARGS="${ARGS} ${evalue} ${ungapped} ${max_target_seqs} ${filter_flag} ${lowercase_masking} ${wordsize} ${gapopen} ${gapextend} ${matrix}"
        ;;
    blastx)
        do_makeblastdb ${CUSTOMDB} prot
        # Not used by blastx: penalty reward
        if [ "${filter}" -eq 0 ];then filter_flag="-seg no";fi
        ARGS="${ARGS} ${evalue} ${ungapped} ${max_target_seqs} ${filter_flag} ${lowercase_masking} ${wordsize} ${gapopen} ${gapextend} ${matrix}"
        ;;
    tblastn)
        do_makeblastdb ${CUSTOMDB} nucl
        # Not used by tblastn: gencode reward penalty
        if [ "${filter}" -eq 0 ];then filter_flag="-seg no";fi
        ARGS="${ARGS} ${evalue} ${ungapped} ${max_target_seqs} ${filter_flag} ${lowercase_masking} ${wordsize} ${gapopen} ${gapextend} ${matrix}"
        ;;
    tblastx)
        do_makeblastdb ${CUSTOMDB} nucl
        # Not used by tblastx: gencode penalty reward gapopen gapextend
        if [ "${filter}" -eq 0 ];then filter_flag="-seg no";fi
        ARGS="${ARGS} ${evalue} ${ungapped} ${max_target_seqs} ${filter_flag} ${lowercase_masking} ${wordsize} ${matrix}"
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

# Remove duplicate spaces in ARGS in order to pass a clean command to the Docker container
ARGS=$(echo $ARGS | sed -e's/  */ /g')

# Run the command in Docker app container
OUTFILE="${blast_application}_out"
${DOCKER_APP_RUN} ${blast_application} ${ARGS} -query ${QUERYFILE} -db "${DATABASES}" -out ${OUTFILE}

# Here is where we can insert additional commands to run either in local environment
# or the app container for additional post-processing

## -> NO USER-SERVICABLE PARTS INSIDE
docker rm -f ${DOCKER_DATA_CONTAINER} &
docker rm -f ${DOCKER_APP_CONTAINER} &
## <- NO USER-SERVICABLE PARTS INSIDE
