#!/bin/bash
#
# Docker Volume Backup Script
#
# This script allows you to backup Docker volumes to a MinIO backup server.
# It provides options to exclude volumes, add prefixes to backup file names,
# enable date prefixes, and directly upload volumes without confirmation.
#
# Author: Roland Körtvely (roland.kortvely@gmail.com)
# License: MIT License
#
# Usage: ./docker-volume-backup.sh [options...] (--minio-url=URL --access-key=KEY --secret-key=KEY --bucket=BUCKET | --config=CONFIG --bucket=BUCKET)
#

# Function to display help
display_help() {
    echo "Usage: $0 [options...] (--minio-url=URL --access-key=KEY --secret-key=KEY --bucket=BUCKET | --config=CONFIG --bucket=BUCKET)"
    echo
    echo "   --exclude=vol1,vol2,vol3      Exclude specified volumes from backup"
    echo "   --config=CONFIG               Path to JSON configuration file (default: credentials.json)"
    echo "   --prefix=PREFIX               Additional prefix for backup file names"
    echo "   --date                        Enable date prefix in backup file names"
    echo "   --auto-upload                 Directly upload volumes without confirmation"
    echo "   -h, --help                    Display this help and usage information"
    echo
    echo "Example: $0 --exclude=volume1,volume2 --minio-url=http://minio-server --access-key=access-key --secret-key=secret-key --bucket=bucket-name --prefix=my_prefix --date --auto-upload"
    echo "or"
    echo "Example: $0 --exclude=volume1,volume2 --config=config.json --bucket=bucket-name --prefix=my_prefix --date --auto-upload"

    exit 0
}

# Function to validate root user
validate_root_user() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
    fi
}

# Function to validate if mc is installed
validate_mc_installation() {
    if ! command -v mc &> /dev/null; then
        echo "mc (MinIO Client) could not be found. Please install it."
        echo
        echo "Install Minio Client:"
        echo "wget https://dl.min.io/client/mc/release/linux-amd64/mc"
        echo "chmod +x mc"
        echo "sudo mv mc /usr/local/bin/mc"
        exit
    fi
}

# Function to validate if jq is installed
validate_jq_installation() {
    if ! command -v jq &> /dev/null; then
        echo "jq could not be found."
        echo "Please install jq with the following command:"
        echo "sudo apt-get install jq"
        exit
    fi
}

# Function to validate Minio connection
validate_minio_connection() {
    echo "Validating connection to MinIO server..."
    if ! mc ls myminio &>/dev/null; then
        echo "Failed to connect to MinIO server. Please check your MinIO parameters."
        exit 1
    fi
}

# Function to setup minio client alias
setup_mc_alias() {
    echo "Setting up MinIO Client alias..."
    mc alias set myminio $MINIO_URL $ACCESS_KEY $SECRET_KEY --api S3v4
}

# Function to backup volumes
backup_volumes() {
    echo "Starting backup process..."
    for volume in $(docker volume ls -q); do
        if [[ " ${EXCLUDES[@]} " =~ " ${volume} " ]]; then
            continue
        fi

        # Create a temporary variable to hold the filename prefix
        FILENAME_PREFIX=""
        if [ -n "$PREFIX" ]; then
            FILENAME_PREFIX="${PREFIX}_"
        fi
        if [ -n "$DATE_PREFIX" ]; then
            FILENAME_PREFIX="${FILENAME_PREFIX}${DATE_PREFIX}_"
        fi

        BACKUP_FILE="${FILENAME_PREFIX}$volume.tar.gz"

        docker run --rm -v $volume:/volume -v /tmp:/backup alpine tar -czf /backup/$BACKUP_FILE -C /volume ./
        echo "Backing up volume $volume..."
        mc cp /tmp/$BACKUP_FILE myminio/$BUCKET/$BACKUP_FILE

        echo "Backup of volume $volume completed. Backup file name: $BACKUP_FILE"
    done
}

# Function to list volumes and sizes, and ask to proceed
list_volumes_and_confirm() {
    echo "Listing volumes and their sizes..."
    for volume in $(docker volume ls -q); do
        if [[ " ${EXCLUDES[@]} " =~ " ${volume} " ]]; then
            continue
        fi

        echo "Volume: $volume"
        docker run --rm -t -v $volume:/volume alpine du -sh /volume
    done

    read -p "Continue with backup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
}

# Function to start backup
start_backup() {
    if [ "$AUTO_UPLOAD" != true ]; then
        list_volumes_and_confirm
    fi

    echo "Proceeding with the backup..."
    backup_volumes
}

# Parse arguments
for i in "$@"
do
case $i in
    --exclude=*)
    EXCLUDES_ARG="${i#*=}"
    shift # past argument=value
    ;;
    --minio-url=*)
    MINIO_URL="${i#*=}"
    shift # past argument=value
    ;;
    --access-key=*)
    ACCESS_KEY="${i#*=}"
    shift # past argument=value
    ;;
    --secret-key=*)
    SECRET_KEY="${i#*=}"
    shift # past argument=value
    ;;
    --bucket=*)
    BUCKET="${i#*=}"
    shift # past argument=value
    ;;
    --config=*)
    CONFIG="${i#*=}"
    shift # past argument=value
    ;;
    --prefix=*)
    PREFIX="${i#*=}"
    shift # past argument=value
    ;;
    --date)
    DATE=true
    shift # past argument=value
    ;;
    -h|--help)
    display_help
    shift # past argument with no value
    ;;
    --auto-upload)
    AUTO_UPLOAD=true
    shift # past argument=value
    ;;
    *)
    # unknown option
    display_help
    ;;
esac
done

# If a configuration file is not specified, set it to the default
if [ -z "$MINIO_URL" ] || [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
    if [ -z "$CONFIG" ]; then
        CONFIG="credentials.json"
    fi
fi

if [ -n "$CONFIG" ]; then
    validate_jq_installation
    if [ ! -f "$CONFIG" ]; then
        echo "Configuration file $CONFIG not found."
        exit 1
    fi

    MINIO_URL=$(jq -r '.url' $CONFIG)
    ACCESS_KEY=$(jq -r '.accessKey' $CONFIG)
    SECRET_KEY=$(jq -r '.secretKey' $CONFIG)
fi

if [ -z "$MINIO_URL" ] || [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ] || [ -z "$BUCKET" ]; then
    echo "MinIO parameters and bucket name are required."
    display_help
    exit 1
fi

#validate_root_user
validate_mc_installation

# Default excluded volumes
DEFAULT_EXCLUDES=("minio")

# Merge both excluded arrays
EXCLUDES=(${EXCLUDES_ARG//,/ } ${DEFAULT_EXCLUDES[@]})

# If DATE is not set, do not generate a date prefix
if [ "$DATE" != true ]; then
    DATE_PREFIX=""
else
    DATE_PREFIX=$(date +%Y_%m_%d_%H_%M)
fi

setup_mc_alias
validate_minio_connection
start_backup
