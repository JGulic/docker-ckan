###################
### Extensions ####
###################
FROM keitaro/ckan:2.9.0 as extbuild

MAINTAINER Keitaro Inc <info@keitaro.com>

# Locations and tags, please use specific tags or revisions
ENV HARVEST_GIT_URL=https://github.com/ckan/ckanext-harvest
ENV HARVEST_GIT_BRANCH=v1.3.1

# Switch to the root user
USER root

# Install necessary packages to build extensions
RUN apk add --no-cache \
        gcc \
        g++ \
        libffi-dev \
        openssl-dev \
        python3-dev 

# Fetch and build the custom CKAN extensions
RUN pip wheel --wheel-dir=/wheels git+${HARVEST_GIT_URL}@${HARVEST_GIT_BRANCH}#egg=ckanext-harvest
RUN pip wheel --wheel-dir=/wheels -r https://raw.githubusercontent.com/ckan/ckanext-harvest/${HARVEST_GIT_BRANCH}/pip-requirements.txt
RUN curl -o /wheels/harvest.txt https://raw.githubusercontent.com/ckan/ckanext-harvest/${HARVEST_GIT_BRANCH}/pip-requirements.txt

############
### MAIN ###
############
FROM keitaro/ckan:2.9.0

ENV CKAN__PLUGINS envvars image_view text_view recline_view datastore datapusher harvest ckan_harvester

# Switch to the root user
USER root

COPY --from=extbuild /wheels /srv/app/ext_wheels

# Install and enable the custom extensions
RUN pip install --no-index --find-links=/srv/app/ext_wheels ckanext-harvest && \
    pip install --no-index --find-links=/srv/app/ext_wheels -r /srv/app/ext_wheels/harvest.txt && \
    # Not working atm since ckan config tool tries to load config before executing config-tool, workaround
    # ckan -c ${APP_DIR}/production.ini config-tool "ckan.plugins = ${CKAN__PLUGINS}" && \
    sed -i "/ckan.plugins = envvars/c ckan.plugins = ${CKAN__PLUGINS}" ${APP_DIR}/production.ini && \
    chown -R ckan:ckan /srv/app

# Remove wheels
RUN rm -rf /srv/app/ext_wheels

# Add harvest entrypoint script
COPY ./scripts/00_harvest.sh ${APP_DIR}/docker-entrypoint.d/00_harvest.sh

# Switch to the ckan user
USER ckan