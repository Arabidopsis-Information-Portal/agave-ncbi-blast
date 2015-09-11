source ./common.sh

FILENAME="${query}"

# Build up the arguments string
#
# Accept a custom FASTA file as database
# in addition to any libraries selected
# from the databases volume
DATABASES="${database}"
# Nucleotide database
CUSTOM_NUC="${custom_nucl_db}"
if [ -n "$CUSTOM_NUC" ];
    makeblastdb -i ${CUSTOM_NT} -dbtype nucl -out custom_nuc -logfile makeblastdb_nucl.log
    if [[ $? -eq 0 ]];
        DATABASES="${DATABASES} custom_nuc"
    else
        echo "Warning: We were unable to format ${custom_nucl_db} as a custom database."
    fi
fi
# Protein database
CUSTOM_PRO="${custom_prot_db}"
if [ -n "$CUSTOM_PRO" ];
    makeblastdb -i ${CUSTOM_PRO} -dbtype prot -out custom_pro -logfile makeblastdb_prot.log
    if [[ $? -eq 0 ]];
        DATABASES="${DATABASES} custom_pro"
    else
        echo "Warning: We were unable to format ${custom_prot_db} as a custom database."
    fi
fi

# Trim leading and trailing comma
DATABASES=${DATABASES%,}
DATABASES=${DATABASES#,}


ARGS="${evalue} ${penalty} ${reward} ${ungapped} ${max_target_seqs} ${filter} ${lowercase_masking} ${wordsize} ${gapopen} ${gapextend} -num_threads 2"

# Not used by BLASTN so we don't insert them above
# matrix gencode

# Add arguments programmatically
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

# Run in Docker as follows
# Mount pwd as /scratch then use scratch as working directory
# Use bash as the parent shell rather than sh
# ${DOCKER_APP_RUN} blastn -db "${DATABASES}" ${ARGS} -query $FILENAME -out blastn_out

	#sudo docker rmi $DOCKER_IMAGE

