#!/bin/bash -xe
exec > /var/log/user-data.log 2>&1

echo "INFO: Updating packages and installing dependencies..."
dnf update -y
dnf install -y python3 python3-pip git

sudo -u ec2-user bash -c '
set -xe

export AWS_DEFAULT_REGION="us-east-1"
export RDS_INSTANCE_IDENTIFIER="nyc-taxi-pipeline-dev-airflow-db"
export RDS_SECRET_NAME="nyc-taxi-pipeline-dev-rds-master-password"
export AIRFLOW_SECRET_NAME="nyc-taxi-pipeline-dev-airflow-admin-password"
export AIRFLOW_HOME=/home/ec2-user/airflow
export AIRFLOW_VERSION=2.8.4
PROJECT_DIR=/home/ec2-user/airflow_project

echo "INFO: Fetching secrets from AWS Secrets Manager..."
RDS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${RDS_SECRET_NAME} --query SecretString --output text)
AIRFLOW_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${AIRFLOW_SECRET_NAME} --query SecretString --output text)

echo "INFO: Waiting for RDS instance to become fully available..."
aws rds wait db-instance-available --db-instance-identifier ${RDS_INSTANCE_IDENTIFIER}
echo "INFO: RDS instance is available!"
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ${RDS_INSTANCE_IDENTIFIER} --query "DBInstances[0].Endpoint.Address" --output text)

echo "INFO: Creating Python virtual environment..."
mkdir -p ${PROJECT_DIR}
python3 -m venv ${PROJECT_DIR}/venv
source ${PROJECT_DIR}/venv/bin/activate

echo "INFO: Installing Python packages..."
pip install --upgrade pip
pip install \
  "apache-airflow[postgres,amazon]==${AIRFLOW_VERSION}" \
  "dbt-core==1.8.2" \
  "dbt-redshift==1.8.1"

echo "INFO: Initializing Airflow to generate config file..."
airflow db migrate

echo "INFO: Configuring airflow.cfg..."
ENCODED_RDS_PASSWORD=$(echo -n "${RDS_PASSWORD}" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.stdin.read()))")

sed -i "s#^sql_alchemy_conn = .*#sql_alchemy_conn = postgresql+psycopg2://airflow_user:${ENCODED_RDS_PASSWORD}@${RDS_ENDPOINT}:5432/airflow_metadata#" ~/airflow/airflow.cfg
sed -i "s#^executor = .*#executor = LocalExecutor#" ~/airflow/airflow.cfg
sed -i "s#^load_examples = .*#load_examples = False#" ~/airflow/airflow.cfg

echo "INFO: Migrating the database with the production connection string..."
airflow db migrate

echo "INFO: Creating Airflow admin user..."
echo -n "${AIRFLOW_ADMIN_PASSWORD}" | airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email kevin.ayers123@icloud.com \
    --password "${AIRFLOW_ADMIN_PASSWORD}"
'

echo "INFO: Setting up and starting systemd services for Airflow..."

cat <<EOT > /etc/systemd/system/airflow-webserver.service
[Unit]
Description=Airflow Webserver
After=network.target
[Service]
Environment="AIRFLOW_HOME=/home/ec2-user/airflow"
User=ec2-user
Group=ec2-user
Type=simple
ExecStart=/home/ec2-user/airflow_project/venv/bin/airflow webserver --port 8080
Restart=always
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOT

cat <<EOT > /etc/systemd/system/airflow-scheduler.service
[Unit]
Description=Airflow Scheduler
After=network.target
[Service]
Environment="AIRFLOW_HOME=/home/ec2-user/airflow"
User=ec2-user
Group=ec2-user
Type=simple
ExecStart=/home/ec2-user/airflow_project/venv/bin/airflow scheduler
Restart=always
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable --now airflow-webserver
systemctl enable --now airflow-scheduler

echo "INFO: User data script finished successfully!"
