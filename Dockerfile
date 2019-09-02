# Java Version
ARG JAVA_VERSION=11

################################
### We use a java base image ###
################################
FROM openjdk:${JAVA_VERSION} AS build

###########################
### Maintained by lekt8 ###
###########################
LABEL maintainer="lekt8"

#################
### Arguments ###
#################

ARG PAPER_VERSION=1.14.4 
ARG PAPER_DOWNLOAD_URL=https://papermc.io/api/v1/paper/${PAPER_VERSION}/latest/download
ARG MINECRAFT_BUILD_USER=minecraft-build
ENV MINECRAFT_BUILD_PATH=/opt/minecraft

#################################################################################################
### https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line ###
### Requires repo and admin:public key permissions
#################################################################################################

ENV GITHUB_REPO_NAME=papermc-server
ENV GITHUB_TOKEN=6969696969696969fc36c533ea3d5c711426bf9a93
ARG KEY_NAME=paper-git@docker

#########################
### Working directory ###
#########################
WORKDIR ${MINECRAFT_BUILD_PATH}

##########################
### Download paperclip ###
##########################
ADD ${PAPER_DOWNLOAD_URL} paper.jar
ADD https://github.com/github/hub/releases/download/v2.12.3/hub-linux-amd64-2.12.3.tgz hub.tgz

####################
### Setup GitHub ###
####################
RUN tar -C ${MINECRAFT_BUILD_PATH} -xzf hub.tgz && rm hub.tgz && mv ${MINECRAFT_BUILD_PATH}/hub* ${MINECRAFT_BUILD_PATH}/hub

############
### User ###
############
RUN useradd -ms /bin/bash ${MINECRAFT_BUILD_USER} && \
    chown ${MINECRAFT_BUILD_USER} ${MINECRAFT_BUILD_PATH} -R

USER ${MINECRAFT_BUILD_USER}

############################################
### Run paperclip and obtain patched jar ###
############################################
RUN java -jar ${MINECRAFT_BUILD_PATH}/paper.jar; exit 0

# Copy built jar
RUN mv ${MINECRAFT_BUILD_PATH}/cache/patched*.jar ${MINECRAFT_BUILD_PATH}/paper.jar

###########################
### Running environment ###
###########################
FROM openjdk:${JAVA_VERSION} AS runtime

##########################
### Environment & ARGS ###
##########################
ARG MINECRAFT_PATH=/opt/minecraft
ENV SERVER_PATH=${MINECRAFT_PATH}/server
ENV DATA_PATH=${MINECRAFT_PATH}/data
ENV LOGS_PATH=${MINECRAFT_PATH}/logs
ENV CONFIG_PATH=${MINECRAFT_PATH}/config
ENV WORLDS_PATH=${MINECRAFT_PATH}/worlds
ENV PLUGINS_PATH=${MINECRAFT_PATH}/plugins
ENV PROPERTIES_LOCATION=${CONFIG_PATH}/server.properties
ENV RAM=1G
ENV JAVA_ARGS="-XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=50 -XX:G1MaxNewSizePercent=80 -XX:G1MixedGCLiveThresholdPercent=35 -XX:+AlwaysPreTouch -XX:+ParallelRefProcEnabled -Dusing.aikars.flags=mcflags.emc.gs"
ENV SPIGOT_ARGS="--nojline"
ENV PAPER_ARGS=""

#################
### Libraries ###
#################
ADD https://bootstrap.pypa.io/get-pip.py .
RUN python get-pip.py

RUN pip install mcstatus

###################
### Healthcheck ###
###################
HEALTHCHECK --interval=10s --timeout=5s \
    CMD mcstatus localhost:$( cat $PROPERTIES_LOCATION | grep "server-port" | cut -d'=' -f2 ) ping

#########################
### Working directory ###
#########################
WORKDIR ${SERVER_PATH}

###########################################
### Obtain runable jar from build stage ###
###########################################
COPY --from=build ${MINECRAFT_PATH}/paper.jar ${SERVER_PATH}/
COPY --from=build ${MINECRAFT_PATH}/hub ${SERVER_PATH}/hub

######################
### Obtain scripts ###
######################
ADD scripts/docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

ADD scripts/start.sh start.sh
RUN chmod +x start.sh

############
### User ###
############
RUN addgroup minecraft && \
    useradd -ms /bin/bash minecraft -g minecraft -d ${MINECRAFT_PATH} && \
    mkdir ${LOGS_PATH} ${DATA_PATH} ${WORLDS_PATH} ${PLUGINS_PATH} ${CONFIG_PATH} && \
    chown -R minecraft:minecraft ${MINECRAFT_PATH}

USER minecraft

#########################
### Setup environment ###
#########################
# !!!Removed Create symlink for plugin volume as hotfix for some plugins who hard code their directories
# Create symlink for persistent data
RUN ln -s $DATA_PATH/banned-ips.json $SERVER_PATH/banned-ips.json && \
    ln -s $DATA_PATH/banned-players.json $SERVER_PATH/banned-players.json && \
    ln -s $DATA_PATH/help.yml $SERVER_PATH/help.yml && \
    ln -s $DATA_PATH/ops.json $SERVER_PATH/ops.json && \
    ln -s $DATA_PATH/permissions.yml $SERVER_PATH/permissions.yml && \
    ln -s $DATA_PATH/whitelist.json $SERVER_PATH/whitelist.json && \
    ln -s $DATA_PATH/mstore $SERVER_PATH/mstore && \
    echo "eula=true" > $SERVER_PATH/eula.txt && \
    # Create symlink for logs
    ln -s $LOGS_PATH $SERVER_PATH/logs

# Setup $HUB Command
ENV HUB=${SERVER_PATH}/hub/bin/hub

###############
### Volumes ###
###############
VOLUME "${CONFIG_PATH}"
VOLUME "${WORLDS_PATH}"
VOLUME "${PLUGINS_PATH}"
VOLUME "${DATA_PATH}"
VOLUME "${LOGS_PATH}"

#############################
### Expose minecraft port ###
#############################
EXPOSE 25565

######################################
### Entrypoint is the start script ###
######################################
ENTRYPOINT [ "./docker-entrypoint.sh" ]

# Run Command
CMD [ "serve" ]
