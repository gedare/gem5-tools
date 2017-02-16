#!/bin/bash

## Script to simplify building gem5. Execute in current directory. The build
## will proceed in a subdirectory with the same name as the current git branch.
## By default, the target build/X86/gem5.fast will be compiled.

## globals
SCRIPT=build.sh
BASE=`pwd`/..
BUILD=${BASE}/builds
GEM5=${BASE}/gem5
buildsubdir=
architecture=
executable=

USAGE=\
"usage: ${SCRIPT} [ -bae ]
  -b    -- build subdirectory. [git branch]
  -a    -- architecture, one of ALPHA, ARM, MIPS, POWER, SPARC, X86 [X86]
  -e    -- executable, one of debug, opt, prof, perf, fast. [fast]
"

## functions
error_out() {
  echo "$*" >&2
}

fatal() {
  error_out "$USAGE"
  exit 1
}


validate_args() {
  if [[ -z ${buildsubdir} ]]; then
    buildsubdir=`git branch | grep "*" | awk '{ print $2 }'`
  fi

  if [[ ! -d ${BUILD}/${buildsubdir} ]]; then
    mkdir ${BUILD}/${buildsubdir}
  fi

  if [[ -z ${architecture} ]]; then
    architecture=X86
  fi

  if [[ -z ${executable} ]]; then
    executable=gem5.fast
  fi

  ## imperfect error checks
  if [[ ! -d ${BUILD} ]]; then
    echo "Error: ${SCRIPT} must be executed from ${BUILD}."
    fatal
  fi

  if [[ ! -d ${GEM5} ]]; then
    echo "Error: ${SCRIPT} must be executed from ${BUILD}."
    fatal
  fi

}

build_gem5() {
  scons -C ${GEM5} ${buildsubdir}/build/${architecture}/${executable}
}

main() {
  validate_args

  build_gem5
}

## Script entry point
while getopts "b:a:e:" OPT
do
  case "$OPT" in
    b) buildsubdir=$OPTARG;;
    a) architecture=$OPTARG;;
    e) executable=gem5.${OPTARG};;
    *) fatal;;
  esac
done

main
