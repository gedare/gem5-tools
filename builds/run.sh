#!/bin/bash

## Script to simplify running gem5. Execute in current directory. The build
## will proceed in a subdirectory with the same name as the current git branch.
## By default, the target build/X86/gem5.fast will be executed with the
## kernel located at /dist/m5/system/binaries/x86_64-vmlinux-2.6.22.9.smp
## and disk-image at /dist/m5/system/disks/linux-x86.img

## globals
SCRIPT=run.sh
BASE=`pwd`/..
BUILD=${BASE}/builds
GEM5=${BASE}/gem5
buildsubdir=
architecture=
executable=
config=
checkpoints=
kernel=
disk=
cores=
script=
fastfoward=
restore=
outdir=

USAGE=\
"usage: ${SCRIPT} [ -baecCkdnsfo ]
  -b    -- build subdirectory. [git branch]
  -a    -- architecture, one of ALPHA, ARM, MIPS, POWER, SPARC, X86 [X86]
  -e    -- executable, one of debug, opt, prof, perf, fast. [fast]
  -c    -- config file [${GEM5}/configs/example/fs.py]
  -C    -- checkpoints directory (absolute path) [${BUILD}/\$\{buildsubdir\}/m5out]
  -k    -- kernel [/dist/m5/system/binaries/x86_64-vmlinux-2.6.22.9.smp]
  -d    -- disk image [/dist/m5/system/disks/linux-x86.img]
  -n    -- number of cores [1]
  -s    -- script to run after reading with m5 readfile
  -f    -- number of instructions to fastforward in atomic mode
  -r    -- restore from checkpoint number
  -o    -- output directory for gem5 [${BUILD}/\$\{buildsubdir\}/m5out]
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

  if [[ -z ${architecture} ]]; then
    architecture=X86
  fi

  if [[ -z ${executable} ]]; then
    executable=gem5.fast
  fi

  if [[ -z ${config} ]]; then
    config=${GEM5}/configs/example/fs.py
  fi

  if [[ -z ${checkpoints} ]]; then
    checkpoints=${BUILD}/${buildsubdir}/m5out
  fi

  if [[ -z ${outdir} ]]; then
    outdir=${BUILD}/${buildsubdir}/m5out
  fi

  if [[ -z ${kernel} ]]; then
    kernel=/dist/m5/system/binaries/x86_64-vmlinux-2.6.22.9.smp
  fi

  if [[ -z ${disk} ]]; then
    disk=/dist/m5/system/disks/linux-x86.img
  fi

  if [[ -z ${cores} ]]; then
    cores=1
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

  if [[ ! -d ${BUILD}/${buildsubdir} ]]; then
    echo "Error: no build found at ${BUILD}/${buildsubdir}"
    fatal
  fi
  if [[ ! -d ${BUILD}/${buildsubdir}/build/${architecture} ]]; then
    echo "Error: no build found at ${BUILD}/${buildsubdir}/build/${architecture}"
    fatal
  fi
  
  if [[ ! -f ${BUILD}/${buildsubdir}/build/${architecture}/${executable} ]]; then
    echo "Error: executable not found: ${BUILD}/${buildsubdir}/build/${architecture}/${executable}"
    fatal
  fi

  if [[ ! -z ${script} ]]; then
    if [[ ! -f ${script} ]]; then
      echo "Error: script  not found: ${script}"
      fatal
    fi
  fi
}

run_gem5() {
  cd ${buildsubdir}
  configcmd="${config} --checkpoint-dir=${checkpoints} --kernel=${kernel} --disk-image=${disk} -n ${cores}"
  if [[ ! -z ${script} ]]; then
    configcmd="${configcmd} --script=${script}"
  fi
  if [[ ! -z ${fastforward} ]]; then
    configcmd="${configcmd} --fast-forward=1000000000"
    configcmd="${configcmd} --standard-switch 1000000000 --caches"
  fi
  if [[ ! -z ${restore} ]]; then
    configcmd="${configcmd} -r ${restore}"
  fi

  build/${architecture}/${executable} -d ${outdir} ${configcmd}
  cd ${BUILD}
}

main() {
  validate_args

  run_gem5
}

## Script entry point
while getopts "b:a:e:c:C:k:d:n:s:f:r:o:" OPT
do
  case "$OPT" in
    b) buildsubdir=$OPTARG;;
    a) architecture=$OPTARG;;
    e) executable=gem5.${OPTARG};; #FIXME
    c) config=$OPTARG;;
    C) checkpoints=$OPTARG;;
    k) kernel=$OPTARG;;
    d) disk=$OPTARG;;
    n) cores=$OPTARG;;
    s) script=$OPTARG;;
    f) fastforward=$OPTARG;;
    r) restore=${OPTARG};;
    o) outdir=${OPTARG};;
    *) fatal;;
  esac
done
main
