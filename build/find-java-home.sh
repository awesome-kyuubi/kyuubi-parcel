#!/usr/bin/env bash

if [ -z "${JAVA_HOME}" -a "$(uname -s)" = "Darwin" ]; then
  # For some versions of macOS, "/usr/bin/javac" is a real file instead of a symbolic link,
  # so the JAVA_HOME may be set to path "/usr" improperly.
  # The following command is an appropriate way of setting JAVA_HOME on macOS.
  export JAVA_HOME="$(/usr/libexec/java_home)"
fi

if [ -z "${JAVA_HOME}" -a "$(command -v rpm)" ]; then
  local RPM_JAVA_HOME="$(rpm -E %java_home 2>/dev/null)"
  if [ "$RPM_JAVA_HOME" != "%java_home" ]; then
    JAVA_HOME="$RPM_JAVA_HOME"
  fi
fi

if [ -z "${JAVA_HOME}" -a "$(command -v javac)" ]; then
  JAVA_HOME="$(dirname $(dirname $(realpath $(command -v javac))))"
fi

if [ -z "${JAVA_HOME}" -a "$(command -v java)" ]; then
  JAVA_HOME="$(dirname $(dirname $(realpath $(command -v java))))"
fi

if [ -z "$JAVA_HOME" ]; then
  echo "Error: JAVA_HOME is not set, cannot proceed."
  exit -1
fi

export JAVA_HOME="${JAVA_HOME}"
