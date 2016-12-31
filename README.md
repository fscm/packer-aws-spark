# Apache Spark AMI

AMI that should be used to create virtual machines with Apache Spark installed.

## Synopsis

This script will create an AMI with Apache Spark installed and with all of the
required initialization scripts.

The AMI resulting from this script should be the one used to instantiate a
Spark server (master or worker).

## Getting Started

There are a couple of things needed for the script to work.

### Prerequisites

Packer and AWS Command Line Interface tools need to be installed on your local
computer.
To build a base image you have to know the id of the latest Debian AMI files
for the region where you wish to build the AMI.

#### Packer

Packer installation instructions can be found
[here](https://www.packer.io/docs/installation.html).

#### AWS Command Line Interface

AWS Command Line Interface installation instructions can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)

#### Debian AMI's

A list of all the Debian AMI id's can be found at the debian official page:
[Debian oficial Amazon EC2 Images](https://wiki.debian.org/Cloud/AmazonEC2Image/)

### Usage

In order to create the AMI using this packer template you need to provide a
few options.

```
Usage:
  packer build \
    -var 'aws_access_key=AWS_ACCESS_KEY' \
    -var 'aws_secret_key=<AWS_SECRET_KEY>' \
    -var 'aws_region=<AWS_REGION>' \
    -var 'aws_base_ami=<BASE_IMAGE>' \
    -var 'spark_version=<SPARK_VERSION>' \
    -var 'spark_hadoop_version=<HADOOP_VERSION>' \
    [-var 'option=value'] \
    spark.json
```

#### Script Options

- `aws_access_key` - *[required]* The AWS access key.
- `aws_ami_name` - The AMI name (default value: "spark").
- `aws_ami_name_prefix` - Prefix for the AMI name (default value: "").
- `aws_base_ami` - *[required]* The AWS base AMI id to use. See [here](https://wiki.debian.org/Cloud/AmazonEC2Image/) for a list of available options.
- `aws_instance_type` - The instance type to use for the build (default value: "t2.micro").
- `aws_region` - *[required]* The regions were the build will be performed.
- `aws_secret_key` - *[required]* The AWS secret key.
- `java_build_number` - Java build number (default value: "15").
- `java_major_version` - Java major version (default value: "8").
- `java_update_version` - Java update version (default value: "112").
- `scala_short_version` - Scala short version (default value: "2.11"). Setting this option also requires setting the `scala_version` option.
- `scala_version` - Scala version (default value: "2.11.8"). Seting this option may also require setting the `scala_short_version` option.
- `spark_hadoop_version` - *[required]* Hadoop version of the Spark package.
- `spark_version` - *[required]* Spark version.

### Instantiate a Cluster

In order to end up with a functional Spark Cluster some configurations have to
be performed after instantiating the servers.

To help perform those configurations a small script is included on the AWS
image. The script is called **spark_config**.

#### Configuration Script

The script can and should be used to set some of the Spark options as well as
setting the Spark service to start at boot.

```
Usage: spark_config [options] <instance_type>
```

##### Instance Type

The script can only configure one instance at a time. Setting a instance type
is **required** by the script.

- `master` - Treats the configuration options as if it was a Spark Master instance.
- `worker` - Treats the configuration options as if it was a Spark Worker instance.
- `history` - Treats the configuration options as if it was a Spark History instance.

##### Options

* `-c <CORES>` - *[worker]* Sets the number of Executor cores that Spark Executor will use (default value is the number of cpu cores/threads).
* `-D` - *[master,worker,history]* Disables the respective Spark service from start at boot time.
* `-E` - *[master,worker,history]* Enables the respective Spark service to start at boot time.
* `-h <AGE>` - *[master,worker,history]* Sets how old the job history files will have to be before being deleted on the server (default value is '15d').
* `-i <NUMBER>` - *[worker]* Sets the number of Spark Executor instances that will de started (default value is '1').
* `-k <SIZE>` - *[master,worker,history]* Sets the size of the Kryo Serializer buffer (default value is '16m'). Values should be provided following the same Java heap nomenclature.
* `-m <MEMORY>` - *[worker]* Sets the Spark Executor maximum heap size (default value is 80% of the server memory). Values should be provided following the same Java heap nomenclature.
* `-p <ADDRESS>` - *[master,worker,history]* Sets the public DNS name of the Spark instance (default value is the server FQDN). This is the value that the instance will report as the server address on all the url's (including the ones on the Spark UI).
* `-r <NUMBER>` - *[worker]* Sets the maximum number of log files kept by the Executer log rotator (default value is '15').
* `-s <ADDRESS>` - *[worker]* Sets the Spark Master address to which the Spark Worker will connect to (default value is 'localhost').
* `-S` - *[master,worker,history]* Starts the respective Spark service after performing the required configurations (if any given).
* `-W <SECONDS>` - *[master,worker,history]* Waits the specified amount of seconds before starting the respective Spark service (default value is '0').

#### Configuring the Spark Master Instance

To prepare an instance to act as a Spark Master the following steps need to
be performed.

Run the configuration tool (*spark_config*) to configure the instance as a
Spark Master server.

```
spark_config -E -S master
```

After this steps a Spark Master service should be running and configured to
start on server boot.

More options can be used on the instance configuration, see the
[Configuration Script](#configuration-script) section for more details

#### Configuring a Spark Worker Instance

To prepare an instance to act as a Spark Worker the following steps need to
be performed.

Run the configuration tool (*spark_config*) to configure the instance as a
Spark Worker server.

```
spark_config -E -S -s spark-master.my-domain.tld worker
```

After this steps a Spark Worker instance should be running, connected to the
specified Spark Master address and configured to start on server boot.

More options can be used on the instance configuration, see the
[Configuration Script](#configuration-script) section for more details

#### Configuring the Spark History Instance

To prepare an instance to act as a Spark History the following steps need to
be performed.

Run the configuration tool (*spark_config*) to configure the instance as a
Spark History server.

```
spark_config -E -S history
```

To be able to use the Spark History service properly every Spark instance needs
to write the job logs to a shared folder. The shared folder should be mounted
on the following location on every instance/server (including the History
instance) and *write* permission needs to be given to the *spark* user
(uid=2000).

```
/var/log/spark
```

After this steps the Spark History service should be running and configured to
start on server boot.

More options can be used on the instance configuration, see the
[Configuration Script](#configuration-script) section for more details

## Services

This AMI will have the SSH service running as well as the Spark (Master and/or
Worker) services. The following ports will have to be configured on Security
Groups.

| Service           | Port   | Protocol |
|:------------------|:------:|:--------:|
| SSH               | 22     |    TCP   |
| Spark Application | 4040   |    TCP   |
| Spark REST Server | 6066   |    TCP   |
| Spark Master      | 7077   |    TCP   |
| Spark Master UI   | 8080   |    TCP   |
| Spark Worker UI   | 8081   |    TCP   |
| Spark History     | 18080  |    TCP   |

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/packer-templates/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/packer-templates/contributors)
who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/fscm/packer-templates/LICENSE)
file for details
