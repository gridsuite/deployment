FROM gridsuite/case-import-job:latest
USER root
ENTRYPOINT []
RUN apt-get update && apt-get -y install cron
COPY init-job-container.sh /root
CMD /root/init-job-container.sh
