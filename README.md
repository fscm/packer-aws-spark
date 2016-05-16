# Apache Spark AMI

AMI that should be used to create virtual machines with Apache Spark installed.

## Synopsis

This script will create an AMI with Apache Spark installed and with all of
the required initialization scripts.

The AMI resulting from this script should be the one used to instantiate a
Spark server (master or worker).

## Getting Started

There are a couple of things needed for the script to work.

### Prerequisities

Packer and AWS Command Line Interface tools need to be installed on your
local computer.
To build a base image you have to know the id of the latest Debian AMI files
for the region where you wish to build the AMI.

#### Packer

Packer installation instructions can be found [here](https://www.packer.io/docs/installation.html).

#### AWS Command Line Interface

AWS Command Line Interface installation instructions can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

#### Debian AMI's

A list of all the Debian AMI id's can be found at the debian official page:
[Debian oficial Amazon EC2 Images"](https://wiki.debian.org/Cloud/AmazonEC2Image/)

### Usage

In order to create the AMI using this packer template you need to provide a
few options.

```
Usage:
  packer build -var 'aws_access_key=AWS_ACCESS_KEY' -var 'aws_secret_key=<AWS_SECRET_KEY>' -var 'aws_region=<AWS_REGION>' -var 'aws_base_ami=<BASE_IMAGE>' -var 'spark_version=<SPARK_VERSION>' -var 'hadoop_version=<HADOOP_VERSION>' -var 'java_version=<JAVA_VERSION>' spark.json
Options:
  aws_access_key     the aws access key for your user.
  aws_secret_key     the aws secret key for your user.
  aws_region         the region where the ami will be created.
  aws_base_ami       the debian base image id to use for the build.
  spark_version      the spark version to install.
  hadoop_version     the hadoop version used by spark.
  java_version       the java version used by cassandra (will be installed).
```

### Instantiate a Server

In order to end up with a functional Spark server some configurations have to
be performed after instantiating a new server.

#### Configuring the Master

To prepare an instance to act as a Spark Master the following steps need to
be performed.

Create a configuration file, located at /opt/service/spark-master/override.env
with the required information:

* SPARK_DAEMON_MEMORY is the memory that should be alocated for the Java heap (will default to 512m)

Here is an example of how the configuration file can be created:

```
echo "SPARK_DAEMON_MEMORY=1g" > /opt/service/spark-master/override.env
```

To initialize the Spark Master, and ensure that the same will start on every
reboot, the following symbolic link will have to be created:

```
ln -s /opt/service/spark-master /etc/service/spark-master
```

After this steps a Spark Master should be configured and running on the server.

#### Configuring a Worker

To prepare an instance to act as a Spark Worker the following steps need to
be performed.

Create a configuration file, located at /opt/service/spark-master/override.env
with the required information:

* SPARK_DAEMON_MEMORY is the memory that should be alocated for the Java heap (will default to 512m)
* SPARK_EXECUTOR_INSTANCES is the number of Spark instances (will default to 1)
* SPARK_EXECUTOR_CORES is the number of cores per instance that will be available to process jobs (will default to 1)
* __SPARK_WORKER_PORT__ is the port that will be used by the Spark worker (will default to 42002)
* __SPARK_MASTER_ADDR__ is the address of the Spark Master to connect to (will default to 127.0.0.1)
* __SPARK_MASTER_PORT__ is the port of the Spark Master to connect to (will default to 7077)

Here is an example of how the configuration file can be created:

```
cat <<EOF > /opt/service/spark-worker/override.env
SPARK_DAEMON_MEMORY=1g
SPARK_EXECUTOR_INSTANCES=1
SPARK_EXECUTOR_CORES=2
__SPARK_WORKER_PORT__=42002
__SPARK_MASTER_ADDR__=spark-master.yourdomain.com
__SPARK_MASTER_PORT__=7077
EOF
```

To initialize the Spark Worker, and ensure that the same will start on every
reboot, the following symbolic link will have to be created:

```
ln -s /opt/service/spark-worker /etc/service/spark-worker
```

After this steps a Spark Worker should be configured and running on the server.

## Services

This AMI will have the SSH service running as well as the Spark (Master and/or
Worker) services. The following ports will have to be configured on Security
Groups.

| Service        | Port   | Protocol |
|----------------|:------:|:--------:|
| ssh            |   22   |    TCP   |
| spark (master) |  6066  |    TCP   |
| spark (master) |  7077  |    TCP   |
| spark (master) |  8080  |    TCP   |
| spark (worker) |  4040  |    TCP   |
| spark (worker) |  8081  |    TCP   |
| spark (worker) | 42002  |    TCP   |
| spark          |  ALL   |    TCP   |

## Contributing

1. Create your feature branch: `git checkout -b my-new-feature`
2. Commit your changes: `git commit -am 'Add some feature'`
3. Push to the branch: `git push origin my-new-feature`
4. Submit a pull request

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/packer-templates/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/packer-templates/contributors)
who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/fscm/packer-templates/blob/master/LICENSE)
file for details
