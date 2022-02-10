#!/bin/bash

# Create log file for job execution
touch /root/job-execution.log
# Create env vars to access from crontab
printenv | sed 's/^\(.*\)$/export \1/g' > /root/project_env.sh
# Setup crontab from cron file
crontab /root/job-crontab
# Start cron daemon
service cron start
# Display job execution log file content
tail -f /root/job-execution.log
