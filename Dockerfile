FROM apache/airflow:2.11.0-python3.11

USER root

# Install Java 17 and required system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jdk \
        curl \
        procps \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Download and install Spark 3.5.3
RUN curl -fsSL https://archive.apache.org/dist/spark/spark-3.5.8/spark-3.5.8-bin-hadoop3.tgz \
    | tar xz -C /opt/ && \
    ln -s /opt/spark-3.5.8-bin-hadoop3 /opt/spark

# Set Spark environment
ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${PATH}"

# Switch back to airflow user for pip installs
USER airflow

# Install the Spark provider
RUN pip install --no-cache-dir \
    apache-airflow-providers-apache-spark==5.6.0 \
    delta-spark==3.2.0 \
    dbt-core==1.11.0 \
    dbt-spark[PyHive]==1.10.1 \
    astronomer-cosmos[dbt-spark]==1.12.0

USER root
RUN curl -o /opt/spark/jars/hadoop-aws-3.3.4.jar \
  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar && \
  curl -o /opt/spark/jars/aws-java-sdk-bundle-1.12.262.jar \
  https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar && \
  curl -o /opt/spark/jars/delta-spark_2.12-3.2.0.jar \
  https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.2.0/delta-spark_2.12-3.2.0.jar && \
  curl -o /opt/spark/jars/delta-storage-3.2.0.jar \
  https://repo1.maven.org/maven2/io/delta/delta-storage/3.2.0/delta-storage-3.2.0.jar

# Switch back to airflow user for pip installs
USER airflow