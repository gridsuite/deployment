FROM gridsuite/cgmes-assembling-job:latest
ENTRYPOINT []
RUN apt-get update && apt-get -y install cron
COPY init-job-container.sh /root
CMD /root/init-job-container.sh
