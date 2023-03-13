#!/bin/bash
set -x

# Read a value from a properties file.
function read_property {
  local key="$1"
  local file="$2"
  echo $(grep "^$key=" "$file" | tail -n 1 | sed "s/^$key=\(.*\)/\\1/")
}

# replace $1 with $2 in file $3
function replace {
  perl -pi -e "s#${1}#${2}#g" $3
}

function prepare_log_conf {
  local KYUUBI_LOG_LEVEL=$(                read_property "log.threshold"             "$CONF_DIR/log4j.properties")
  local KYUUBI_LOG_DIR=$(                  read_property "log.dir"                   "$CONF_DIR/log4j.properties")
  local KYUUBI_LOG_FILE=$(                 read_property "log.file"                  "$CONF_DIR/log4j.properties")
  local KYUUBI_MAX_LOG_FILE_SIZE=$(        read_property "max.log.file.size"         "$CONF_DIR/log4j.properties")
  local KYUUBI_MAX_LOG_FILE_BACKUP_INDEX=$(read_property "max.log.file.backup.index" "$CONF_DIR/log4j.properties")
  
  cat $CONF_DIR/aux/log4j2.properties.template > $CONF_DIR/conf/log4j2.properties
  
  replace "{{KYUUBI_LOG_LEVEL}}"                 "$KYUUBI_LOG_LEVEL"                 "$CONF_DIR/conf/log4j2.properties"
  replace "{{KYUUBI_LOG_DIR}}"                   "$KYUUBI_LOG_DIR"                   "$CONF_DIR/conf/log4j2.properties"
  replace "{{KYUUBI_LOG_FILE}}"                  "$KYUUBI_LOG_FILE"                  "$CONF_DIR/conf/log4j2.properties"
  replace "{{KYUUBI_MAX_LOG_FILE_SIZE}}"         "$KYUUBI_MAX_LOG_FILE_SIZE"         "$CONF_DIR/conf/log4j2.properties"
  replace "{{KYUUBI_MAX_LOG_FILE_BACKUP_INDEX}}" "$KYUUBI_MAX_LOG_FILE_BACKUP_INDEX" "$CONF_DIR/conf/log4j2.properties"
}

case $1 in
  (start)
    export KYUUBI_HOME=${KYUUBI_HOME:-$CDH_KYUUBI_HOME}
    export KYUUBI_CONF_DIR=${KYUUBI_CONF_DIR:-$CONF_DIR/conf}
    prepare_log_conf
    exec ${KYUUBI_HOME}/bin/kyuubi run
    ;;
  (*)
    echo "Don't understand [$1]"
    exit 1
    ;;
esac
