FROM ubuntu:latest

# Install required packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli

RUN apt-get update && apt-get install -y \
    jq \
    wget

# Install MinIO client (mc)
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc /usr/local/bin/

# Copy the backup script to the container
COPY docker-volume-backup.sh /data/docker-volume-backup.sh
RUN chmod +x /data/docker-volume-backup.sh

WORKDIR /data

# Set the entrypoint to execute the backup script
ENTRYPOINT ["/data/docker-volume-backup.sh"]
