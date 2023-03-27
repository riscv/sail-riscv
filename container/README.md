# Building the Sail Programming Language Toolchain Container Image

This guide provides instructions on how to build a container image for the Sail programming language toolchain using the provided Dockerfile.

## Prerequisites

Docker, Podman, or any OCI-compatible container runtime installed on your machine.

## Building the Container Image

Clone the Sail RISC-V repository:

```bash
git clone https://github.com/riscv/sail-riscv.git
```

Navigate to the container directory:

```bash
cd sail-riscv/container
```

Build the container image and tag it as riscv-sail-toolchain-base-image:

```bash
docker build -t riscv-sail-toolchain-base-image .
```

Wait for the build process to complete. Upon successful completion, you will see a message similar to the following:

```bash
Successfully built <image_id>
Successfully tagged riscv-sail-toolchain-base-image:latest
```

## Running the Container Image and RISC-V Sail Tests

Go back to the sail-riscv directory:

```bash
cd ..
```

Run the container image and execute the tests targeting RV64 (default):

```bash
docker run -it -v $(pwd):/build riscv-sail-toolchain-base-image:latest
```

(Optional) To target RV32, run the following command:

```bash
docker run -it -e ARCH=RV32 -v $(pwd):/build riscv-sail-toolchain-base-image:latest
```

At the end of the build, the binaries and test results will be available in the host filesystem.
