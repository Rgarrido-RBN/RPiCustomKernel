#!/bin/bash
export DOCKER_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo ">>>>>>>>>>>>>>>> AVAILABLE COMMANDS "
echo
echo "    docker_permision -->  Add permission to docker after installation, use it only if docker throws permission errors"
echo "    docker_build -->  BUILD docker image"
echo "    docker_run -->  RUN docker image"
# Add permission to docker after installation, use it only if you need it
docker_permision ()
{
    sudo groupadd docker
    sudo usermod -aG docker ${USER}
    sudo chmod 666 /var/run/docker.sock
}

# Build docker image
docker_build ()
{
    docker rmi $CONTAINER_NAME || true
    docker build -t rpi_enviroment:1 -f $DOCKER_DIR/Dockerfile $DOCKER_DIR
}

# Run docker image
docker_run ()
{
    docker run --privileged -it -v $DOCKER_DIR/../:/root rpi_enviroment:1 /bin/bash
}
