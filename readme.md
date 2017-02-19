[![Docker Stars](https://img.shields.io/docker/stars/gmentsik/docktartar.svg?style=flat-square)](https://hub.docker.com/r/gmentsik/docktartar)
[![Docker Pulls](https://img.shields.io/docker/pulls/gmentsik/docktartar.svg?style=flat-square)](https://hub.docker.com/r/gmentsik/docktartar)
[![Docker Automated buil](https://img.shields.io/docker/automated/gmentsik/docktartar.svg?style=flat-square)](https://hub.docker.com/r/gmentsik/docktartar)
[![Docker Repository on Quay](https://quay.io/repository/gmentsik/docktartar/status "Docker Repository on Quay")](https://quay.io/repository/gmentsik/docktartar)
[![](https://images.microbadger.com/badges/image/gmentsik/docktartar.svg)](https://microbadger.com/images/gmentsik/docktartar "Get your own image badge on microbadger.com")

# DockTartar

- [Introduction](#introduction)
- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
  - [Environment Variables](#environment-variables)
- [Maintenance](#maintenance)
  - [Upgrading](#upgrading)
  - [Shell Access](#shell-access)
- [Change history](CHANGELOG)
- [Contributing](#contributing)
- [Issues](#issues)

# Introduction

Docktartar will recursively tar a directory to another location. It has been designed to stop running docker containers before doing the backup and restart them after the archival process.

Some Features:

* Multi-Core Compression with pigz
* CRON daemon to schedule the backup job
* SMB Client to backup to a network share
* Temp-Directory to build the archive locally (eg SSD), restart the containers and move the archive afterwards
* Mail notifications with ssmtp
* Full configuration with environment variables
* Chose which containers to stop and restart


You can provide a temp-directory for faster archival, afterwards the script will move the archive wherever you want.
This is useful in cases where you want to store your backup on a remote server (you should really do this!).
The workflow in this case is:

1. Stop Containers
2. Build the archive in the /backupTmp directory
3. Start containers
4. move the archive from /backupTmp to /targetTmp
5. Chown the archive

# Getting started

## Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/gmentsik/docktartar) and is the recommended method of installation.

```bash
docker pull gmentsik/docktartar
```

_Alternatively you can build the image yourself._

```bash
docker build -t gmentsik/docktartar github.com/gmentsik/docktartar
```

## Quickstart
You can use the sample [docker-compose.yml](docker-compose.yml) file to start the container using [Docker Compose](https://docs.docker.com/compose/)*

Or start Docktartar using:

```bash
docker run -d --name docktartar \
              --restart=always \
              --volume /srv/docker:/backupSource \
              --volume /var/backups/docker:/backupTarget  \
              --volume /var/run/docker.sock:/var/run/docker.sock \
              --volume /var/lib/docker:/var/lib/docker \
      gmentsik/docktartar
```


## Environment Variables


| Variable          | Default Value   | Description                                                                                                              | Examples                                |
| ----------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------- |
| CRON              | "0 0 * * *"     | (=Midnight) When the script should start in cron format. Check [cron-generator](http://www.crontab-generator.org)        | `"0 30 * * *"  `, `"0 0 */3 * *"`       |
| TIMEZONE          | "Europe/Vienna" | Sets the timezone of the container.                                                                                      | `'Asia/Tokyo'`,`'America/Los_Angeles'`  |
| TAR_OWNER_USERID  | 0               | Sets the Owner of the archive. 0 = root                                                                                  | enter `id` for all users on your system |
| TAR_OWNER_GROUPID | 0               | Sets the Group-Owner of the archive. 0 = root                                                                            | enter `id` for all users on your system |
| TAG               | "docker"        | Sets filename tag.[timestamp].tar.gz                                                                                     | `docker-backup`                         |
| STOP_CONTAINERS   | "all"           | The containers to stop. Either Name, Id or all. nginx mysql all will stop nginx then mysql and then all others.          | `mysql all`, `nginx mysql`, `all`       |
| START_CONTAINERS  | "all"           | The containers to start. Either Name, Id or all. nginx mysql all will start nginx then mysql and then all others.        | `mysql all`, `nginx mysql`, `all`       |
| INCREMENTAL       | "true"          | Generates incremental backups                                                                                            | `true` or `false`                       |
| SMB               | "false"         | Enables Samba integration                                                                                                | `true` or `false`                       |
| SMB_USER          | ""              | Username of the samba user                                                                                               | `username`                              |
| SMB_PASSWORD      | ""              | Password of the samba user                                                                                               | `pass`                                  |
| SMB_SMB_PATH      | ""              | IP+Path of the Samba Network Share                                                                                       | `192.162.4.10/shares/backups`           |
| EMAIL_HOST_PORT   | ""              | Host and port of your e-mail server/smarthost The format is host.tld:port                                                | `mail.company.com:587`                  |
| EMAIL_USER        | ""              | Username for authentication on your mail server                                                                          | `web58p4`                               |
| EMAIL_PASS        | ""              | Password for authentication on your mail server                                                                          | `secretpassword`                        |
| EMAIL_USE_STARTTLS| "NO"            | use starttls, YES or NO                                                                                                  | `YES` or `NO`                           |
| EMAIL_FROM        | "Docktartar"    | The name that is displayed in the from field                                                                             | `Docktartar`                            |
| EMAIL_FROM_ADRESS | ""              | The e-mail adress that is displayed in the from field                                                                    | `admin@company.com`                     |
| EMAIL_SUBJECT     | "Docktartar"    | The subject of the message                                                                                               | `Backupjob`                             |
| EMAIL_TO          | ""              | The E-Mail adress where the emails should be send                                                                        | `yourmail@company.com`                  |
| TEMP_DIR          | "NO"            | If set to YES, the archive is built in /backupTmp and then moved to /backupTarget, after the all containers restarted    | `YES` or `NO`                           |

## Samba Share and Permissions

In order to run this with samba share as the backup target, you have to either run the container with `privileged: true` or add `cap_add: SYS_ADMIN`

## Volumes

| Container Volume      | Description                                                                                   |
| -----------------     | ----------------------------------------------------------------------------------------------|
| /backupSource         | The contents of this folder will be archived in a tar-archive.                                |
| /backupTarget         | The tar-archive will be put in this directory. If you use a Network share, do not mount this! |
| /var/run/docker.sock  | Has to be mapped in ordner to be able to stop and start containers.                           |
| /var/lib/docker       | Has to be mapped in ordner to be able to stop and start containers.                           |
    
# Maintenance

## Test Mail settings
There is a test script in the root folder called `test-mail.sh` which can be used to test the email settings.
  ```bash
  docker exec -it docktartar /root/test-mail.sh
  ```


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
  docker run -name docktartar -d [OPTIONS] gmentsik/docktartar
  ```

## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using Docker version `1.3.0` or higher you can access a running containers shell by starting `bash` using `docker exec`:

```bash
docker exec -it docktartar bash
```

# Contributing

If you find this image useful here's how you can help:

- Send a pull request with your awesome features and bug fixes
- Help users resolve their [issues](../../issues?q=is%3Aopen+is%3Aissue).

# Issues

Before reporting your issue please try updating Docker to the latest version and check if it resolves the issue. Refer to the Docker [installation guide](https://docs.docker.com/installation) for instructions.

SELinux users should try disabling SELinux using the command `setenforce 0` to see if it resolves the issue.

If the above recommendations do not help then [report your issue](../../issues/new) along with the following information:

- Output of the `docker version` and `docker info` commands
- The `docker run` command or `docker-compose.yml` used to start the image. Mask out the sensitive bits.
- Please state if you are using [Boot2Docker](http://www.boot2docker.io), [VirtualBox](https://www.virtualbox.org), etc.

