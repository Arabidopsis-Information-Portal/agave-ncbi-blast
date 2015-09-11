# Agave and Docker build files for the back end of our BLAST app

More details later...

## Objectives

1. Refactor so that the BLAST databases live on a data volume 
    rather than being mounted on the Docker host
2. Create a workflow that allows the data volume to be updated via updates to its Dockerfile and
    that ties the version of BLAST used to create the databases to them in an accountable way
3. Publish the human name, filename, and source URL for each sequence database to the Agave 
    metadata service associated with the release tag for the container.
4. Consolidate app-specific wrappers into a single script and move the blast program up to be a parameter
5. Abstract out the Docker-specific housekeeping to a common.sh file
6. Add in some Docker version checking to enable automatic removal of images if running > 1.7
7. Enable users to specify a custom database in the form of a FASTA file submitted at job time
8. Potentially add post-processing of BLAST results on the server side to make them more attractive
    (We haven't decided/discussed what we want to do yet)
9. Add in resource constraints to app container to allow oversubscription
10. Move from using a custom pass-thru directory on the Docker host to using /home/$USERNAME,
    thus increasing portability on different clouds, new hosts, etc.
11. Integrate with Docker Hub so that we can get automatic builds, tagged by release
