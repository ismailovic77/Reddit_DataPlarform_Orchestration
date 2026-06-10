from datetime import datetime, timedelta
from pathlib import Path

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
    profile_name='dbt_analysis',
    target_name='dev',
    profile_mapping=SparkThriftProfileMapping(
        conn_id='spark_thrift_default',
        profile_args={
            'schema': 'default',
            'host': 'host.docker.internal',
            'port': 10000,
            'threads': 2,
        },
    ),
)

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
        application='/opt/pyspark_jobs/reddit_dataplateform_processing/gold/gold_sample.py',
        conn_id='spark_default',
        name='airflow_spark_job',
        verbose=True,
        py_files='/opt/pyspark_jobs/reddit_dataplatform_processing-0.1.0-py3-none-any.whl',
        conf={
            'spark.master': 'spark://host.docker.internal:7077',
            'spark.driver.host': '192.168.1.125',
            'spark.driver.bindAddress': '0.0.0.0',
            'spark.driver.port': '4041',
            'spark.driver.blockManager.port': '19041',
            'spark.pyspark.python': '/Users/user/Desktop/learning/Reddit_DataPlatform_Processing/.venv/bin/python',
            'spark.pyspark.driver.python': 'python3',
            'spark.driver.memory': '1g',
            'spark.executor.memory': '1g',
            'spark.executor.cores': '1',
            'spark.hadoop.fs.s3a.endpoint': 'http://host.docker.internal:9000',
            'spark.hadoop.fs.s3a.access.key': 'minioadmin',
            'spark.hadoop.fs.s3a.secret.key': 'minioadmin',
            'spark.hadoop.fs.s3a.path.style.access': 'true',
            'spark.hadoop.fs.s3a.impl': 'org.apache.hadoop.fs.s3a.S3AFileSystem',
        },
    )

    
    #dbt_run = BashOperator(
    #    task_id='run_dbt',
    #    bash_command='dbt run --project-dir /opt/dbt_project --profiles-dir /opt/airflow/.dbt',
    #)

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
