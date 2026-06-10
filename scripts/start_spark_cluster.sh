

# global variables 
MASTER_COMMAND="org.apache.spark.deploy.master.Master"
MASTER_INSTANCE=1
WORKER_COMMAND="org.apache.spark.deploy.worker.Worker"
WORKER_INSTANCE=1
THRIFT_SERVER_COMMAND="org.apache.spark.sql.hive.thriftserver.HiveThriftServer2"
THRIFT_SERVER_INSTANCE=1

export $SPARK_HOME=/opt/spark
export PYSPARK_PYTHON=/Users/user/Desktop/learning/reddit_etl/.venv/bin/python

start_master(){
  echo "starting master ..."
  $SPARK_HOME/sbin/start-master.sh \
    --port $SPARK_MASTER_PORT \
    --host $SPARK_MASTER_HOST \
    --webui-port $SPARK_MASTER_WEBUI_PORT
}

start_worker(){
  $SPARK_HOME/sbin/start-worker.sh spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT \
    --host $SPARK_WORKER_HOST \
    --port $SPARK_WORKER_PORT \
    --webui-port $SPARK_WORKER_WEBUI_PORT \
    --cores 8 \
    --memory 8G 
}

start_thrift_server(){
  $SPARK_HOME/sbin/start-thriftserver.sh \
    --master spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT\
    --hiveconf hive.server2.thrift.port=$HIVE_SERVER2_THRIFT_PORT \
    --hiveconf hive.server2.thrift.bind.host=$HIVE_SERVER2_THRIFT_BIND_HOST \
    --executor-memory 2G \
    --total-executor-cores 2 \
    --conf spark.sql.warehouse.dir=s3a://warehouse \
    --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
    --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
    --conf spark.hadoop.fs.s3a.endpoint=http://localhost:$MINIO_S3_API_PORT \
    --conf spark.hadoop.fs.s3a.access.key=minioadmin \
    --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
    --conf spark.hadoop.fs.s3a.path.style.access=true \
    --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem 
    
}

# start the script
echo "[STARTUP] Checking the master status"
$SPARK_HOME/sbin/spark-daemon.sh status "${MASTER_COMMAND}" "${MASTER_INSTANCE}" 2>&1 
STATUS_CODE=$? 

if [[ $STATUS_CODE -eq 0 ]]; then 
  echo "[STARTUP] master is running checking the worker"
  $SPARK_HOME/sbin/spark-daemon.sh status "${WORKER_COMMAND}" "${WORKER_INSTANCE}" 2>&1 
  STATUS_CODE=$? 
  if [[ $STATUS_CODE -eq 0 ]]; then
    echo "[STARTUP] worker is running checking the thrift server"
    $SPARK_HOME/sbin/spark-daemon.sh status "${THRIFT_SERVER_COMMAND}" "${THRIFT_SERVER_INSTANCE}" 2>&1 
    STATUS_CODE=$?
    if [[ $STATUS_CODE -eq 0 ]]; then
      echo "[STARTUP] thrift server is running"
    else 
      echo "[STARTUP] thrift server is not running , running it now ...."
      start_thrift_server
    fi
  else
    echo "[STARTUP] worker is not running , running it now ...."
    start_worker
    start_thrift_server
  fi
else
  echo "[STARTUP] master is not running , running it now ...."
  start_master
  start_worker
  start_thrift_server
fi