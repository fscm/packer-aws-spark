SPARK_LOG_DIR="/var/log/spark"
SPARK_PID_DIR="/var/run/spark"
SPARK_TMP_DIR="/srv/spark/tmp"
SPARK_HOME=/srv/spark

SPARK_EXECUTOR_MEMORY="$(/usr/bin/awk '/MemTotal/{m=$2*.80;print m"k"}' /proc/meminfo)"
SPARK_EXECUTOR_INSTANCES="1"
SPARK_EXECUTOR_CORES="$(/usr/bin/nproc)"
SPARK_EXECUTOR_DIR="/srv/spark/work"

SPARK_WORKER_DIR="/srv/spark/work"

SPARK_LOCAL_IP="0.0.0.0"
SPARK_MASTER_HOST="0.0.0.0"
SPARK_PUBLIC_DNS="localhost"

PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/:$SPARK_HOME/python/lib/py4j.zip:$PYTHONPATH
