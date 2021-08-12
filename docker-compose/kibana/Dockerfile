FROM docker.elastic.co/kibana/kibana:6.8.6
ENTRYPOINT []
COPY run-with-logs-ilm-policy.sh /bin
COPY policy.json /usr/share/kibana/config
COPY index_policy.json /usr/share/kibana/config
COPY index_template_policy.json /usr/share/kibana/config
CMD /bin/run-with-logs-ilm-policy.sh
