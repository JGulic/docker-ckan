#!/bin/bash
#
# Initialize SOLR for CKAN by creating a ckan core
# Arguments are supplied via environment variables: CKAN_CORE_NAME CKAN_VERSION
# Example:
#   CKAN_CORE_NAME=ckan
#   CKAN_VERSION=2.9.5

set -e

CKAN_SOLR_SCHEMA_URL=https://raw.githubusercontent.com/JGulic/solr-schema/main/schema.solr8.xml
CKAN_SOLR_CONF=https://raw.githubusercontent.com/JGulic/solr-schema/main/solrconfig.xml
#CKAN_SOLR_CONF=https://raw.githubusercontent.com/ckan/ckan/ckan-2.9.7/contrib/docker/solr/solrconfig.xml

echo "Check whether managed schema exists for CKAN $CKAN_VERSION"
if ! curl --output /dev/null --silent --head --fail "$CKAN_SOLR_SCHEMA_URL"; then
  echo "Can't find CKAN SOLR schema at URL: $CKAN_SOLR_SCHEMA_URL. Exiting..."
  exit 1
fi

echo "Check whether SOLR is initialized for CKAN"
CORESDIR=/var/solr/data

COREDIR="$CORESDIR/$CKAN_CORE_NAME"
if [ -d "$COREDIR" ]; then
    echo "SOLR already initialized, skipping initialization"
else
    echo "Initializing SOLR core $CKAN_CORE_NAME for CKAN $CKAN_VERSION"

    # init script for handling an empty /var/solr
    /opt/docker-solr/scripts/init-var-solr
    
    # Precreate CKAN core
    /opt/docker-solr/scripts/precreate-core $CKAN_CORE_NAME
      
    # Replace the managed schema with CKANs schema
    echo "Adding CKAN managed schema"
    curl $CKAN_SOLR_SCHEMA_URL -o /var/solr/data/$CKAN_CORE_NAME/conf/managed-schema

    # Replace solrconf
    echo "Adding new solr conf"
    curl https://raw.githubusercontent.com/JGulic/solr-schema/main/solrconfig.xml > /var/solr/data/ckan/conf/solrconfig.xml
    curl https://raw.githubusercontent.com/apache/lucene-solr/releases/lucene-solr/8.11.1/solr/server/solr/configsets/sample_techproducts_configs/conf/elevate.xml > /var/solr/data/ckan/conf/elevate.xml

    echo "SOLR initialized"
fi
