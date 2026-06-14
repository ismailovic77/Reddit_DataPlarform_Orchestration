from datetime import datetime, timedelta
from pathlib import Path
from airflow.hooks.base import BaseHook
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import SparkThriftProfileMapping


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

profile_config = ProfileConfig(
    profile_name='reddit_dataplatform',
    target_name='dev',
    profile_mapping=SparkThriftProfileMapping(
        conn_id='spark_thrift_default',
        profile_args={
            'schema':'default'
        }
    ),
)

conn = BaseHook.get_connection('spark_default')
extra = conn.extra_dejson

with DAG(
    dag_id='spark_dbt_pipeline',
    default_args=default_args,
    description='Triggers a PySpark job on the local standalone cluster followed by dbt job ',
    schedule_interval=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['spark', 'pyspark', 'dbt'],
) as dag:

    submit_spark_job = SparkSubmitOperator(
        task_id='submit_spark_job',
        application='/opt/pyspark/jobs/reddit_dataplatform_pyspark/gold/gold_sample.py',
        conn_id='spark_default',
        name='airflow_spark_job',
        verbose=True,
        py_files='/opt/pyspark/wheel/reddit_dataplatform_processing-0.1.0-py3-none-any.whl',
        conf={
            # driver networking
            'spark.driver.host':extra.get('spark.driver.host'),
            'spark.driver.bindAddress':extra.get('spark.driver.bindAddress'),
            'spark.driver.port':extra.get('spark.driver.port'),
            'spark.driver.blockManager.port':extra.get('spark.driver.blockManager.port'),
            # python
            'spark.pyspark.python':extra.get('spark.pyspark.python'),
            'spark.pyspark.driver.python':extra.get('spark.pyspark.driver.python'),
            # s3
            'spark.hadoop.fs.s3a.endpoint':extra.get('spark.hadoop.fs.s3a.endpoint'),
            'spark.hadoop.fs.s3a.access.key':extra.get('spark.hadoop.fs.s3a.access.key'),
            'spark.hadoop.fs.s3a.secret.key':extra.get('spark.hadoop.fs.s3a.secret.key'),
            'spark.hadoop.fs.s3a.path.style.access':extra.get('spark.hadoop.fs.s3a.path.style.access'),
            'spark.hadoop.fs.s3a.impl':extra.get('spark.hadoop.fs.s3a.impl'),
            # resources (job-specific)
            'spark.driver.memory':'1g',
            'spark.executor.memory':'1g',
            'spark.executor.cores':'1',
        },
    )

    dbt_task_group = DbtTaskGroup(
        group_id='dbt_transformations',
        project_config=ProjectConfig(
            dbt_project_path=Path('/opt/dbt_project'),
        ),
        profile_config=profile_config,
        execution_config=ExecutionConfig(
            dbt_executable_path='/home/airflow/.local/bin/dbt',
        ),
    )
    
    

    submit_spark_job >> dbt_task_group