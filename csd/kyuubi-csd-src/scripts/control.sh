#!/bin/bash

set -ex

function log {
  timestamp=$(date)
  echo "$timestamp: $1"       #stdout
  echo "$timestamp: $1" 1>&2; #stderr
}


case $1 in
  (start)
    # Set java path
    if [ -n "$JAVA_HOME" ]; then
      log "JAVA_HOME added to path as $JAVA_HOME"
      export PATH=$JAVA_HOME/bin:$PATH
    else
      log "JAVA_HOME not set"
    fi
    export KYUUBI_HOME
    export KYUUBI_CONF_DIR=$CONF_DIR/conf
    while read -r line; do
        log "initialize environment : $line"
	export ${line}
    done <"${KYUUBI_CONF_DIR}/kyuubi-env.sh"
    export KYUUBI_LOG_DIR=$KYUUBI_LOG_DIR
    if [[ ! -e ${KYUUBI_LOG_DIR} ]]; then
  	mkdir -p ${KYUUBI_LOG_DIR}
    fi
    export KYUUBI_PID_DIR=$CONF_DIR/pid
    if [[ ! -e ${KYUUBI_PID_DIR} ]]; then
  	mkdir -p ${KYUUBI_PID_DIR}
    fi
    export KYUUBI_WORK_DIR_ROOT=$KYUUBI_WORK_DIR
    if [[ ! -e ${KYUUBI_WORK_DIR} ]]; then
  	mkdir -p ${KYUUBI_WORK_DIR}
    fi
    export KYUUBI_SCALA_VERSION="${KYUUBI_SCALA_VERSION:-"2.12"}"
    ## log4j write
    
    if [[ -f ${KYUUBI_HOME}/RELEASE ]]; then
  	FLINK_BUILTIN="$(find "$KYUUBI_HOME/externals" -name 'flink-*' -type d | head -n 1)"
	SPARK_BUILTIN="$(find "$KYUUBI_HOME/externals" -name 'spark-*' -type d | head -n 1)"
    else
  	FLINK_BUILTIN="$(find "$KYUUBI_HOME/externals/kyuubi-download/target" -name 'flink-*' -type d | head -n 1)"
  	SPARK_BUILTIN="$(find "$KYUUBI_HOME/externals/kyuubi-download/target" -name 'spark-*' -type d | head -n 1)"
    fi
    export FLINK_HOME="${FLINK_HOME:-"${FLINK_BUILTIN}"}"
    export FLINK_ENGINE_HOME="${KYUUBI_HOME}/externals/engines/flink"
    export SPARK_ENGINE_HOME="${KYUUBI_HOME}/externals/engines/spark"
    export TRINO_ENGINE_HOME="${KYUUBI_HOME}/externals/engines/trino"
    export HIVE_ENGINE_HOME="${KYUUBI_HOME}/externals/engines/hive"
    export SPARK_HOME="${SPARK_HOME:-"${SPARK_BUILTIN}"}"
    while read line; do
                logline=$(echo $line | grep "log.threshold=" || true)
                if [[ "$logline" != "" ]]
                then
                        logevel=${logline#*log.threshold=}
			continue
                fi
                logline=$(echo $line | grep "log.file=" || true)
                if [[ "$logline" != "" ]]
                then
                        logfile=${logline#*log.file=}
			continue
                fi
                logline=$(echo $line | grep "max.log.file.size=" || true)
                if [[ "$logline" != "" ]]
                then
                        maxsize=${logline#*max.log.file.size=}
			continue
                fi
                logline=$(echo $line | grep "max.log.file.backup.index=" || true)
                if [[ "$logline" != "" ]]
                then
                        maxindex=${logline#*max.log.file.backup.index=}
			continue
                fi
    done < log4j.properties
    echo status=${logevel}   >> conf/log4j2.properties
    echo name=KyuubiLog4j2                                                     >> conf/log4j2.properties
    echo property.log.level=${logevel}                                   >> conf/log4j2.properties
    echo rootLogger.level=\${log.level}                                         >> conf/log4j2.properties
    echo rootLogger.appenderRefs=console, DRFA                                 >> conf/log4j2.properties
    echo rootLogger.appenderRef.console.ref = console                          >> conf/log4j2.properties
    echo rootLogger.appenderRef.console.level = ERROR                          >> conf/log4j2.properties
    echo rootLogger.appenderRef.DRFA.ref = DRFA                                >> conf/log4j2.properties
    echo rootLogger.appenderRef.DRFA.level = ${logevel}                  >> conf/log4j2.properties
    echo property.log.dir = ${KYUUBI_LOG_DIR}                                         >> conf/log4j2.properties
    echo property.log.file = ${logfile}                                       >> conf/log4j2.properties
    echo appenders = console, DRFA                                             >> conf/log4j2.properties
    echo property.max.log.file.size = ${maxsize}                     >> conf/log4j2.properties
    echo property.max.log.file.backup.index = ${maxindex}     >> conf/log4j2.properties
    echo appender.DRFA.type = RollingRandomAccessFile                          >> conf/log4j2.properties
    echo appender.DRFA.name = DRFA                                             >> conf/log4j2.properties
    echo appender.DRFA.fileName = \${log.dir}/\${log.file}                       >> conf/log4j2.properties
    echo appender.DRFA.filePattern = \${log.dir}/\${log.file}.%d{yyyy-MM-dd}     >> conf/log4j2.properties
    echo appender.DRFA.layout.type = PatternLayout                             >> conf/log4j2.properties
    echo appender.DRFA.layout.pattern = %d{DEFAULT} %-5p %c: [%t]: %m%n        >> conf/log4j2.properties
    echo appender.DRFA.policies.type = Policies                                >> conf/log4j2.properties
    echo appender.DRFA.policies.size.type = SizeBasedTriggeringPolicy          >> conf/log4j2.properties
    echo appender.DRFA.policies.size.size = \${max.log.file.size}               >> conf/log4j2.properties
    echo appender.DRFA.strategy.type = DefaultRolloverStrategy                 >> conf/log4j2.properties
    echo appender.DRFA.strategy.max = \${max.log.file.backup.index}             >> conf/log4j2.properties
    echo appender.console.type = Console                                       >> conf/log4j2.properties
    echo appender.console.name = console                             >> conf/log4j2.properties
    echo appender.console.target = SYSTEM_ERR                        >> conf/log4j2.properties
    echo appender.console.layout.type = PatternLayout                >> conf/log4j2.properties
    echo appender.console.layout.pattern = %d{yy/MM/dd HH:mm:ss} %-5p %c{2}: [%t]: %m%n       >> conf/log4j2.properties
    CLASS="org.apache.kyuubi.server.KyuubiServer"
    RUNNER="${JAVA_HOME}/bin/java"
    if [[ -z "$KYUUBI_JAR_DIR" ]]; then
  	KYUUBI_JAR_DIR="$KYUUBI_HOME/jars"
    	if [[ ! -d ${KYUUBI_JAR_DIR} ]]; then
  		echo -e "\nCandidate Kyuubi lib $KYUUBI_JAR_DIR doesn't exist, searching development environment..."
    		KYUUBI_JAR_DIR="$KYUUBI_HOME/kyuubi-assembly/target/scala-${KYUUBI_SCALA_VERSION}/jars"
  	fi
    fi
    if [[ -z ${YARN_CONF_DIR} ]]; then
  	KYUUBI_CLASSPATH="${KYUUBI_JAR_DIR}/*:${KYUUBI_CONF_DIR}:${HADOOP_CONF_DIR}"
    else
  	KYUUBI_CLASSPATH="${KYUUBI_JAR_DIR}/*:${KYUUBI_CONF_DIR}:${HADOOP_CONF_DIR}:${YARN_CONF_DIR}"
    fi
    cmd="${RUNNER} ${KYUUBI_JAVA_OPTS} -cp ${KYUUBI_CLASSPATH} $CLASS"

    echo  "Starting $CLASS, logging to  kyuubi"
    exec ${cmd}
    ;;
  (*)
    echo "Don't understand [$1]"
    exit 1
    ;;
esac
