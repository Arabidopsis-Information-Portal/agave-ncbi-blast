# Agave and Docker build files for the back end of Araport BLAST app

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

## Building and updating the BLAST web service @ Araport

Agave-based applications are comprised of two essential parts:

_Deployment bundle_
This is a folder, stored on a remote internet accessible server that is registered with the Agave platform as a 'storageSystem'. The folder contains essential data and scripts to successfuly perform a computing task on a Agave 'executionSystem' given a set of parameter values and inputs. There are many types of valid executionSystems for Agave, but the Araport platform only directly allows the use case that is demonstrated in ths NCBI BLAST application.

_Application metadata_
This is JSON-compatible a data structure which provides information about how to make utilize the assets stored in a particular deployment bundle on a specific executionSystem.

### Building a deployment bundle

Araport provides a small Docker cluster for running computation tasks. Each Agave application registered for use at Araport has in its deployment bundle a *script template* that pulls a Docker image, then runs a task in it assuming that is has access to input files and environment variables that can be used to craft a runnable Bash script.

```
agave-ncbi-blast/
├── Dockerfile
├── README.md
├── scripts/
    ├── app-register.sh
    ├── app-upload.sh
    ├── docker-build.sh
└── ncbi-blast/
    ├── blast.json
    ├── blast.sh
    ├── common.sh
    └── tests
```

File {{ncbi-blast/blast.sh}} is the wrapper script template. It refers to two Docker images as variables: DOCKER_APP_IMAGE and DOCKER_DATA_IMAGE. These must exist in Docker Hub before the application can be invoked. You can see from browsing {{ncbi-blast/blast.sh}}  that it simply sets up a couple a Docker containers from public images. One contains the reference databases in a data volume and the other contains the binaries. Then, assuming Agave Bash variable substitution processes the wrapper script, it becomes a syntactially valid Bash script at job time. That Bash script is executed on the Docker host, where it sends a command into the container based on DOCKER_APP_IMAGE to do data processing. Because the app container mounts the local work directory as a volume, the ouputs from that command are saved to the host filesystem immediately and survive the demise of the container.

Start any work on the Araport BLAST app by checking out this repository. Make sure you have the following installed and configured locally:

1. Docker 1.7 or better
2. The Araport CLI (or, you can use the Docker container. We'll give parallel instructions)
3. Python 2.7.x, preferable with virtualenv and pip
4. The jq JSON parser

### Updating to a new BLAST release

Only do this if you need to need to update the actual version of the BLAST application Docker image. Otherwise, you may simply use *araport/agave-ncbi-blast:2.2.30* as your preferred image.

First, create a new branch of this repository with the new BLAST version number. For instance, to update from 2.2.30 to 2.2.31

```
git checkout -b 2.2.31
```

Next, update the Docker file to install the latest version of BLAST+ in a container, then build the image, making sure to tag the image with the new version number. Here's an example:

```
export TAG=$(git rev-parse --abbrev-ref HEAD)
docker build --rm=true -t araport/agave-ncbi-blast:${TAG} .
docker tag -f araport/agave-ncbi-blast:${TAG} araport/agave-ncbi-blast:latest
```

Then, push the image to the public Docker Hub as follows. This assumes you are on the Araport team and have privledges to take this action.

```
docker push --disable-content-trust=true araport/agave-ncbi-blast
```

Your BLAST web service will not yet take advantage of this new image, but now it's easily accesible.

### Updating the wrapper script template

After updating the Docker Hub image, you must update the wrapper script template ({{ncbi-blast=V.v.v/blast.sh}}) to make it aware of the new asset.


1. Change the version numer of the *ncbi-blast-V.v.v* directory if the version was updated (as above)
2. Update the DOCKER_APP_IMAGE value to point to the new image:tag
3. If there are any changes to the way BLAST is invoked (new parameters, etc.) edit those into the wrapper script as well.
4. Upload the *ncbi-blast-V.v.v* directory to an Agave storageSystem

In the case where we've updated the BLAST software version:

```
files-upload -F *ncbi-blast-2.2.31* $ARAPORT_USERNAME/apps
```

You may also wish to *only* revise the wrapper template to fix issues or add additional functionality. In this case, you will stay in the same git branch, not rename the *ncbi-blast-V.v.v folder*, and will simply re-upload the directory to the storageSystem, where its contents will over-write the previous contents.

*Note* If you are deploying this application for the first time (or to a new storageSystem) you will must make sure to have uploaded the physcial assets (*ncbi-blast-V.v.v*) at least once.

### Creating or updating application metadata in the Agave apps service

1. If you've updated the version number for the binary application, you will need to update the *version* field in the application JSON file (*ncbi-blast-2.2.31/blast.json*). You will also need to update the *deploymentPath* to point to the directory containing the new assets. In the case of our hypothetical update to blast+ 2.2.31, *version* is *2.2.31* and *deploymentPath* needs to end with *ncbi-blast-2.2.31*
2. If you've made any changes to the inputs or parameter names in the wrapper script, these will need to be changed in the application JSON description.
3. Update these application JSON file in the Agave storage system (for consistency if they are downloaded by other people). You can either re-upload the entire asset directory or specifically update the file as follows:

```
files-upload -F *ncbi-blast-2.2.31/blast.json* $ARAPORT_USERNAME/apps/ncbi-blast-2.2.31
```

4. Now, update the application service with the new JSON file as follows:

```
apps-addupdate -F *ncbi-blast-2.2.31/blast.json*
```

