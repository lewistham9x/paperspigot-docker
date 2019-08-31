#!/bin/bash
set -e
run_paper() {
  # Start server
  screen -dmSU paper java -jar $JAVA_ARGS \
    -Xmx$RAM -Xms$RAM \
    $SERVER_PATH/paper.jar \
    $SPIGOT_ARGS \
    --bukkit-settings $CONFIG_PATH/bukkit.yml --plugins $PLUGINS_PATH --world-dir $WORLDS_PATH --spigot-settings $CONFIG_PATH/spigot.yml --commands-settings $CONFIG_PATH/commands.yml --config $PROPERTIES_LOCATION \
    --paper-settings $CONFIG_PATH/paper.yml \
    $PAPER_ARGS
}

console_command() {
    COMMAND=$@
    echo "Executing console command: ${COMMAND[@]}"
    sh -c "exec >/dev/tty 2>/dev/tty </dev/tty && /usr/bin/screen -s /bin/bash -S paper -X ${COMMAND[@]}`echo -ne '\015'`"
}

safe_shutdown() {
    echo "Performing safe shutdown..."
    console_command stop
}

case "$1" in
    serve)
        shift 1
        trap safe_shutdown EXIT
        run_paper
        ;;
    console)
        shift 1
        console_command $@
        ;;
    *)
        exec "$@"
esac

