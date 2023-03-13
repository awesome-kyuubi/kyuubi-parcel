#!/bin/bash
set -x
case $1 in
  (start)
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
    echo status=${logevel} >> conf/log4j2.properties
    echo name=KyuubiLog4j2 >> conf/log4j2.properties
    echo property.log.level=${logevel} >> conf/log4j2.properties
    echo rootLogger.level=\${log.level} >> conf/log4j2.properties
    echo rootLogger.appenderRefs=console,DRFA >> conf/log4j2.properties
    echo rootLogger.appenderRef.console.ref=console >> conf/log4j2.properties
    echo rootLogger.appenderRef.console.level=ERROR >> conf/log4j2.properties
    echo rootLogger.appenderRef.DRFA.ref=DRFA >> conf/log4j2.properties
    echo rootLogger.appenderRef.DRFA.level=${logevel} >> conf/log4j2.properties
    echo property.log.dir=${KYUUBI_LOG_DIR} >> conf/log4j2.properties
    echo property.log.file=${logfile} >> conf/log4j2.properties
    echo appenders=console,DRFA >> conf/log4j2.properties
    echo property.max.log.file.size=${maxsize} >> conf/log4j2.properties
    echo property.max.log.file.backup.index=${maxindex} >> conf/log4j2.properties
    echo appender.DRFA.type=RollingRandomAccessFile >> conf/log4j2.properties
    echo appender.DRFA.name=DRFA >> conf/log4j2.properties
    echo appender.DRFA.fileName=\${log.dir}/\${log.file} >> conf/log4j2.properties
    echo appender.DRFA.filePattern=\${log.dir}/\${log.file}.%d{yyyy-MM-dd} >> conf/log4j2.properties
    echo appender.DRFA.layout.type=PatternLayout >> conf/log4j2.properties
    echo appender.DRFA.layout.pattern=%d{DEFAULT} %-5p %c: [%t]: %m%n >> conf/log4j2.properties
    echo appender.DRFA.policies.type=Policies >> conf/log4j2.properties
    echo appender.DRFA.policies.size.type=SizeBasedTriggeringPolicy >> conf/log4j2.properties
    echo appender.DRFA.policies.size.size=\${max.log.file.size} >> conf/log4j2.properties
    echo appender.DRFA.strategy.type=DefaultRolloverStrategy >> conf/log4j2.properties
    echo appender.DRFA.strategy.max=\${max.log.file.backup.index} >> conf/log4j2.properties
    echo appender.console.type=Console >> conf/log4j2.properties
    echo appender.console.name=console >> conf/log4j2.properties
    echo appender.console.target=SYSTEM_ERR >> conf/log4j2.properties
    echo appender.console.layout.type=PatternLayout >> conf/log4j2.properties
    echo appender.console.layout.pattern=%d{yy/MM/dd HH:mm:ss} %-5p %c{2}: [%t]: %m%n >> conf/log4j2.properties
    exec ${KYUUBI_HOME}/bin/kyuubi run
    ;;
  (*)
    echo "Don't understand [$1]"
    exit 1
    ;;
esac
