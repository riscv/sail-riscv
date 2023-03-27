# This Dockerfile creates a Docker image with the required \
# dependencies to build and run the Sail programming language \
# toolchain.

# Specifies the base image to be Ubuntu 22.04
FROM ubuntu:22.04

# Sets an environment variable ARCH with the value RV64. \
# This variable can be used within the Dockerfile or the \
# container to represent the architecture the Sail toolchain \
# will be working with.
ENV ARCH=RV64

# Sets the working directory for the Docker container to /build. \
# Any subsequent commands will be executed in this directory.
WORKDIR /build

# Copies the build.sh script from the local \
# filesystem to the /build directory.
COPY ./build.sh ./build.sh

# Install all dependencies, sail, make ./build.sh executable \
# and remove unecessary files.
RUN DEBIAN_FRONTEND=noninteractive; apt-get update; \
apt-get -y install zlib1g-dev pkg-config libgmp-dev z3 \
opam zlib1g-dev pkg-config libgmp-dev z3 device-tree-compiler build-essential; \
opam init --disable-sandboxing -y; opam install sail -y; \
chmod +x ./build.sh; rm -rf /var/lib/apt/lists/*

# Sets the default command to run when the Docker container is started. \
# In this case, it will run the build.sh script located in the /build \
# directory using the /bin/bash shell. 
ENTRYPOINT ["/bin/bash", "./container/build.sh"]
