# DockTartar

- [Introduction](#introduction)
  - [Contributing](#contributing)
  - [Issues](#issues)
- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
  - [Configuration](#Configuration)
- [Maintenance](#maintenance)
  - [Upgrading](#upgrading)
  - [Shell Access](#shell-access)
- [Change history](#Change-history)

# Introduction

`Dockerfile` to create a [Docker](https://www.docker.com/) container image for periodically and recursively taring a directory.
It has been designed to tar docker-volumes on the host.
Docktartar will first stop all your running containers, tar them to a location and restart all containers.

## Contributing

If you find this image useful here's how you can help:

- Send a pull request with your awesome features and bug fixes
- Help users resolve their [issues](../../issues?q=is%3Aopen+is%3Aissue).

## Issues

Before reporting your issue please try updating Docker to the latest version and check if it resolves the issue. Refer to the Docker [installation guide](https://docs.docker.com/installation) for instructions.

SELinux users should try disabling SELinux using the command `setenforce 0` to see if it resolves the issue.

If the above recommendations do not help then [report your issue](../../issues/new) along with the following information:

- Output of the `docker version` and `docker info` commands
- The `docker run` command or `docker-compose.yml` used to start the image. Mask out the sensitive bits.
- Please state if you are using [Boot2Docker](http://www.boot2docker.io), [VirtualBox](https://www.virtualbox.org), etc.


# Getting started

## Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/gmentsik/tartar) and is the recommended method of installation.

```bash
docker pull gmentsik/docktartar:latest
```

Alternatively you can build the image yourself.

```bash
docker build -t gmentsik/docktartar github.com/gmentsik/docktartar
```

## Quickstart

Start Tartar using:

```bash
docker run --name docktartar -d --restart=always --volume /srv/docker:/backupSource --volume /var/backups/docker:/backupTarget gmentsik/docktartar:latest
```

*Alternatively, you can use the sample [docker-compose.yml](docker-compose.yml) file to start the container using [Docker Compose](https://docs.docker.com/compose/)*

## Configuration

There are environment variables you can set, the defaults are:

| Variable          | Default Value   | Description                                                        | Examples                                |
| ----------------- | --------------- | ------------------------------------------------------------------ | --------------------------------------- |
| BACKUP_PERIOD     | 24h             | If Loop is true, the procedure is repeated in this period of time. | 30s, 5m, 24h, 7d                        |
| BACKUP_DELAY      | 0s              | Delays the execution of the procedure.                             | 30s, 5m, 24h, 7d                        |
| TIMEZONE          | "Europe/Vienna" | Sets the timezone of the container.                                | 'Asia/Tokyo','America/Los_Angeles'      |
| LOOP              | True            | Executes the tar procedure periodically.                           | true or false                           |
| TAR_OWNER_USERID  | 1000            | Sets the Owner of the archive.                                     | enter `id` for all users on your system |
| TAR_OWNER_GROUPID | 1000            | Sets the Group-Owner of the archive.                               | enter `id` for all users on your system |



# Maintenance

## Upgrading

To upgrade to newer releases:

  1. Download the updated Docker image:

  ```bash
  docker pull gmentsik/docktartar
  ```

  2. Stop the currently running image:

  ```bash
  docker stop docktartar
  ```

  3. Remove the stopped container

  ```bash
  docker rm -v docktartar
  ```

  4. Start the updated image

  ```bash
  docker run -name tartar -d [OPTIONS] gmentsik/docktartar
  ```

## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using Docker version `1.3.0` or higher you can access a running containers shell by starting `bash` using `docker exec`:

```bash
docker exec -it docktartar bash
```

## Change history
### [v0.8] [06.01.2017]
#### added:  
* runs.sh with the full script for recursively taring a directory
* Dockerfile for building the container
* sample-docker compose
* this Readme