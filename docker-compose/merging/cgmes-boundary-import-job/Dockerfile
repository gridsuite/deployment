FROM gridsuite/cgmes-boundary-import-job:latest
USER root
ENTRYPOINT []
RUN apt-get update && apt-get -y install cron
COPY init-job-container.sh /root
CMD chmod a+x /root/init-job-container.sh
CMD /root/init-job-container.sh
