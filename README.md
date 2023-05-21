# Docker Volume Backup Script to MinIO

The Docker Volume Backup Script is a shell script for Linux that allows you to backup Docker volumes to a MinIO backup server. It provides flexibility to exclude specific volumes, add prefixes to backup file names, enable date prefixes, and directly upload volumes without confirmation.

## Prerequisites

- Linux-based operating system
- Docker installed and running
- MinIO server running or access to a MinIO server

## Usage

```bash
./docker-volume-backup.sh [options...] (--minio-url=URL --access-key=KEY --secret-key=KEY --bucket=BUCKET | --config=CONFIG --bucket=BUCKET)
```

### Options

- `--exclude=vol1,vol2,vol3`: Exclude specified volumes from backup.
- `--config=CONFIG`: Path to JSON configuration file (default: credentials.json).
- `--prefix=PREFIX`: Additional prefix for backup file names.
- `--date`: Enable date prefix in backup file names.
- `--auto-upload`: Directly upload volumes without confirmation.
- `-h, --help`: Display help and usage information.

### Examples

Backup volumes with MinIO access parameters specified directly:
```
./docker-volume-backup.sh --exclude=volume1,volume2 --minio-url=http://minio-server --access-key=access-key --secret-key=secret-key --bucket=bucket-name --prefix=my_prefix --date
```

Backup volumes using a JSON configuration file:

```
./docker-volume-backup.sh --exclude=volume1,volume2 --config=config.json --bucket=bucket-name --prefix=my_prefix --date
```

## License

This project is licensed under the [MIT License](LICENSE).
