#!/bin/bash
#
# Apache Spark install script.
#
# version: 0.0.1
# Date: 13/04/2016 - Frederico Martins (https://github.com/fscm)

set -e

BASEDIR=$(dirname $0)
BASENAME=$(basename $0)

show_usage() {
  echo >&2 "Usage: ${BASENAME} <SPARK_VERSION> <HADOOP_VERSION>"
  echo >&2 "Arguments:"
  echo >&2 "  SPARK_VERSION   - the spark version to install."
  echo >&2 "  HADOP_VERSION   - the hadoop version that will be used by spark."
}

if [ $# -lt 2 ]; then
  show_usage
  exit 1
fi

SPARK_VERSION=$1
HADOOP_VERSION=$2

echo "Creating Spark user..."
sudo groupadd -g 2000 spark
sudo useradd -m -u 2000 -g 2000 -s /bin/bash -d /opt/spark spark

echo "Fetching Spark..."
sudo wget -q http://www.gtlib.gatech.edu/pub/apache/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -O /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

echo "Installing Spark..."
sudo tar xzf /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /opt/spark/
sudo ln -s /opt/spark/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark/default
sudo mkdir -p /var/log/spark
sudo mkdir -p /opt/spark/buffer
cat <<EOF | sudo tee -a /opt/spark/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/conf/spark-defaults.conf > /dev/null
spark.eventLog.enabled            true
spark.eventLog.dir                /var/log/spark/
spark.history.fs.logDirectory     /var/log/spark/
spark.history.fs.cleaner.enabled  true
spark.history.fs.cleaner.interval 1d
spark.history.fs.cleaner.maxAge   7d
EOF
sudo chown -R spark:spark /opt/spark /var/log/spark
echo '5 2 * * *    spark    /usr/bin/find /opt/spark/buffer/* -type d -mtime +2 -exec rm -rf {} + &> /dev/null' | sudo tee /etc/cron.d/spark > /dev/null

echo "Creating Spark startup scripts..."
sudo mkdir -p /opt/service/{spark-master,spark-worker,spark-history}/log/main
echo -e '#!/bin/sh\nexec setuidgid nobody multilog t s16777215 n10 "!/bin/gzip" ./main' | sudo tee /opt/service/{spark-master,spark-worker,spark-history}/log/run > /dev/null
cat <<EOF | sudo tee -a /opt/service/spark-master/run > /dev/null
#!/bin/bash
LOCAL_IP_ADDR=\`ip addr show | grep -v "lo$"| awk '/inet /{print \$2}' | awk -F '/' '{print \$1}'\`
if [[ -f ./override.env ]]; then . ./override.env; fi
if [[ "x\${SPARK_DAEMON_MEMORY}" = "x" ]]; then SPARK_DAEMON_MEMORY=512m; fi
export SPARK_DAEMON_MEMORY=\${SPARK_DAEMON_MEMORY}
export SPARK_LOCAL_IP=\${LOCAL_IP_ADDR}
export SPARK_CONF_DIR=/opt/spark/default/conf
cd /opt/spark/default
exec 2>&1
exec setuidgid spark ./bin/spark-class org.apache.spark.deploy.master.Master
EOF
cat <<EOF | sudo tee -a /opt/service/spark-worker/run > /dev/null
#!/bin/bash
__LOCAL_IP_ADDR__=\`ip addr show | grep -v "lo$"| awk '/inet /{print \$2}' | awk -F '/' '{print \$1}'\`
if [[ -f ./override.env ]]; then . ./override.env; fi
if [[ "x\${SPARK_DAEMON_MEMORY}" = "x" ]]; then SPARK_DAEMON_MEMORY=512m; fi
if [[ "x\${SPARK_EXECUTOR_INSTANCES}" = "x" ]]; then SPARK_EXECUTOR_INSTANCES=1; fi
if [[ "x\${SPARK_EXECUTOR_CORES}" = "x" ]]; then SPARK_EXECUTOR_CORES=1; fi
if [[ "x\${__SPARK_MASTER_ADDR__}" = "x" ]]; then __SPARK_MASTER_ADDR__=\${__LOCAL_IP_ADDR__}; fi
if [[ "x\${__SPARK_MASTER_PORT__}" = "x" ]]; then __SPARK_MASTER_PORT__=7077; fi
if [[ "x\${__SPARK_WORKER_PORT__}" = "x" ]]; then __SPARK_WORKER_PORT__=42002; fi
export SPARK_DAEMON_MEMORY=\${SPARK_DAEMON_MEMORY}
export SPARK_LOCAL_IP=\${__LOCAL_IP_ADDR__}
export SPARK_EXECUTOR_INSTANCES=\${SPARK_EXECUTOR_INSTANCES}
export SPARK_EXECUTOR_CORES=\${SPARK_EXECUTOR_CORES}
export SPARK_CONF_DIR=/opt/spark/default/conf
cd /opt/spark/default
exec 2>&1
exec setuidgid spark ./bin/spark-class org.apache.spark.deploy.worker.Worker -p \${__SPARK_WORKER_PORT__} spark://\${__SPARK_MASTER_ADDR__}:\${__SPARK_MASTER_PORT__}
EOF
cat <<EOF | sudo tee -a /opt/service/spark-history/run > /dev/null
#!/bin/bash
LOCAL_IP_ADDR=\`ip addr show | grep -v "lo$"| awk '/inet /{print \$2}' | awk -F '/' '{print \$1}'\`
if [[ -f ./override.env ]]; then . ./override.env; fi
export SPARK_LOCAL_IP=\${LOCAL_IP_ADDR}
export SPARK_CONF_DIR=/opt/spark/default/conf
cd /opt/spark/default
exec 2>&1
exec setuidgid spark ./bin/spark-class org.apache.spark.deploy.history.HistoryServer
EOF
sudo chmod +x /opt/service/{spark-master,spark-worker,spark-history}/log/run
sudo chmod +x /opt/service/{spark-master,spark-worker,spark-history}/run
sudo chown nobody:nogroup /opt/service/{spark-master,spark-worker,spark-history}/log/main

echo "All done."
exit 0
