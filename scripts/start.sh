#!/bin/bash
set -e

java -jar $JAVA_ARGS \
  -Xmx$RAM -Xms$RAM \
  $SERVER_PATH/paper.jar \
  $SPIGOT_ARGS \
  --bukkit-settings $CONFIG_PATH/bukkit.yml --plugins $PLUGINS_PATH --world-dir $WORLDS_PATH --spigot-settings $CONFIG_PATH/spigot.yml --commands-settings $CONFIG_PATH/commands.yml --config $PROPERTIES_LOCATION \
  --paper-settings $CONFIG_PATH/paper.yml \
  $PAPER_ARGS