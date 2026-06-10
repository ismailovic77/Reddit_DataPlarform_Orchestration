#stoping the spark services first 
$SPARK_HOME/sbin/stop-thriftserver.sh
$SPARK_HOME/sbin/stop-worker.sh
$SPARK_HOME/sbin/stop-master.sh