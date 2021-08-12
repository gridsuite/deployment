#!/bin/bash

# Check if elasticsearch is ready
ready=`curl --silent -X GET 'http://elasticsearch:9200/_cat/health' | egrep 'yellow|green'`
until [ ! -z "${ready}" ]
do
  sleep 5
  ready=`curl --silent -X GET 'http://elasticsearch:9200/_cat/health' | egrep 'yellow|green'`
done

# Elasticsearch is ready : we can add the ilm policy and apply it to existing and further indexes
curl -X PUT -H 'Content-Type: application/json' -d@/usr/share/kibana/config/policy.json 'http://elasticsearch:9200/_ilm/policy/logs_policy'
curl -X PUT -H 'Content-Type: application/json' -d@/usr/share/kibana/config/index_policy.json 'http://elasticsearch:9200/filebeat-*/_settings'
curl -X PUT -H 'Content-Type: application/json' -d@/usr/share/kibana/config/index_template_policy.json 'http://elasticsearch:9200/_template/logs_template'

# Start kibana
/usr/share/kibana/bin/kibana
