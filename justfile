#!/usr/bin/env just --justfile

P4_ROOT := env_var('HOME') + "/code/p4"
BMV2_DIR := P4_ROOT + "/behavioral-model"
MN_DIR := P4_ROOT + "/mininet"
P4_TUTORIALS_DIR := P4_ROOT + "/tutorials"
OPEN_TOFINO_DIR := P4_ROOT + "/Open-Tofino"

COLOR_GREEN := '\033[0;32m'
COLOR_BLUE := '\033[0;34m'
COLOR_RED := '\033[0;31m'
COLOR_NONE := '\033[0m'

OUT_DIR := justfile_directory() + "/out"

#
# Init tasks: Installing build tools and etc
#
init: init-p4-apt init-p4c init-p4-bmv2 init-mininet init-p4-tutorials init-open-tofino

init-p4-apt:
    #!/usr/bin/env bash

    just _log-info "Running apt update ..."
    sudo apt update
    just _log-info ""

    just _log-info "Installing required tools ..."
    sudo apt install -y curl
    just _log-info ""

    . /etc/os-release

    just _log-info "Checking P4 apt repository source: /etc/apt/sources.list.d/home:p4lang.list"
    if [ -f "/etc/apt/sources.list.d/home:p4lang.list" ]; then
        just _log-info "P4 apt repository already added.";
    else
        just _log-info "Adding P4 apt repository ..."
        just _log-info "deb https://download.opensuse.org/repositories/home:/p4lang/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/home:p4lang.list
    fi
    just _log-info ""

    just _log-info "Adding P4 apt repository key ..."
    curl -L "https://download.opensuse.org/repositories/home:/p4lang/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -
    just _log-info ""

    just _log-info "Running apt update ..."
    sudo apt update
    just _log-info ""

init-p4c:
    @just _log-info "Installing p4c ..."
    sudo apt install -y p4lang-p4c
    @just _log-info ""

init-p4-bmv2:
    #!/usr/bin/env bash

    just _clone-repo "bmv2" "https://github.com/p4lang/behavioral-model.git" "{{BMV2_DIR}}"

    just _log-info "Installing bmv2 dependencies ..."
    sudo apt-get install -y automake cmake libgmp-dev \
        libpcap-dev libboost-dev libboost-test-dev libboost-program-options-dev \
        libboost-system-dev libboost-filesystem-dev libboost-thread-dev \
        libevent-dev libtool flex bison pkg-config g++ libssl-dev

    cd "{{BMV2_DIR}}/ci"
    bash ./install-thrift.sh
    bash ./install-nanomsg.sh
    cd "{{justfile_directory()}}"
    just _log-info ""

    just _log-info "Building bmv2 (this will take quite a while, best time to grab a cup of coffee) ..."
    cd "{{BMV2_DIR}}"
    ./autogen.sh
    ./configure 'CXXFLAGS=-O0 -g' --enable-debugger
    make
    cd "{{justfile_directory()}}"
    just _log-info ""

    just _log-info "Building and running bmv2 tests ..."
    cd "{{BMV2_DIR}}"
    make check
    cd "{{justfile_directory()}}"
    just _log-info ""

init-mininet:
    #!/usr/bin/env bash

    just _clone-repo-rev "mininet" "https://github.com/mininet/mininet.git" "{{MN_DIR}}" "2.3.1b1"

    just _log-info "Installing mininet ..."
    cd "{{P4_ROOT}}"
    mininet/util/install.sh -a
    cd "{{justfile_directory()}}"
    just _log-info ""

    just _log-info "Testing mininet ..."
    sudo mn --switch ovsbr --test pingall

init-p4-tutorials:
    just _clone-repo "p4-tutorials" "https://github.com/p4lang/tutorials.git" "{{P4_TUTORIALS_DIR}}"

init-open-tofino:
    just _clone-repo "OpenTofino" "https://github.com/barefootnetworks/Open-Tofino.git" "{{OPEN_TOFINO_DIR}}"

#
# P4 compile tasks
#
p4c-ss P4_FILE_PATH:
    @just p4c p4c-bm2-ss "{{P4_FILE_PATH}}"

p4c CC P4_FILE_PATH:
    #!/usr/bin/env bash

    P4_FILE_FULL_NAME="{{P4_FILE_PATH}}"
    P4_FILE_NAME="${P4_FILE_FULL_NAME##*/}"
    P4_FILE_NAME="${P4_FILE_NAME%.*}"
    BUILD_DIR="{{OUT_DIR}}/${P4_FILE_NAME}";

    just _log-head "Compiling P4 program:"
    just _log-info "- Input file: {{P4_FILE_PATH}}"
    just _log-info "- Build folder: ${BUILD_DIR}"
    just _log-info ""

    if [ ! -d "${BUILD_DIR}" ]; then
        just _log-info "Creating build folder: ${BUILD_DIR}"
        mkdir -p "${BUILD_DIR}";
    fi

    just _log-info "Invoking p4c ..."
    {{CC}} --std p4-16 "{{P4_FILE_PATH}}" -o "${BUILD_DIR}/${P4_FILE_NAME}.json" --p4runtime-files "${BUILD_DIR}/${P4_FILE_NAME}_runtime.json","${BUILD_DIR}/${P4_FILE_NAME}_runtime.txt","${BUILD_DIR}/${P4_FILE_NAME}_runtime.bin"

p4c-clean PROG_NAME:
    rm -rf "{{OUT_DIR}}/{{PROG_NAME}}"

#
# P4 mininet tasks
#
ss PROG_NAME *ARGS="":
    @just bm-1sw "{{BMV2_DIR}}/targets/simple_switch/simple_switch" "{{OUT_DIR}}/{{PROG_NAME}}/{{PROG_NAME}}.json" {{ARGS}}

psa PROG_NAME *ARGS="":
    @just bm-1sw "{{BMV2_DIR}}/targets/psa_switch/psa_switch" "{{OUT_DIR}}/{{PROG_NAME}}/{{PROG_NAME}}.json" {{ARGS}}

bm-1sw BM_EXE BM_JSON *ARGS="":
    sudo python "{{BMV2_DIR}}/mininet/1sw_demo.py" --behavioral-exe "{{BM_EXE}}" --json "{{BM_JSON}}" {{ARGS}}

bm-demo DEMO_NAME *ARGS="":
    @just bm-1sw "{{BMV2_DIR}}/targets/{{DEMO_NAME}}/{{DEMO_NAME}}" "{{BMV2_DIR}}/targets/{{DEMO_NAME}}/{{DEMO_NAME}}.json" {{ARGS}}

bm-cli THRIFT_PORT="9090" *ARGS="":
    "{{BMV2_DIR}}/tools/runtime_CLI.py" --thrift-port {{THRIFT_PORT}} {{ARGS}}

bm-log THRIFT_PORT="9090" *ARGS="":
    "{{BMV2_DIR}}/tools/nanomsg_client.py" --thrift-port {{THRIFT_PORT}} {{ARGS}}

bm-dbg THRIFT_PORT="9090" *ARGS="":
    sudo "{{BMV2_DIR}}/tools/p4dbg.py" --thrift-port {{THRIFT_PORT}} {{ARGS}}

#
# Utility tasks
#
_clone-repo REPO_NAME REPO_PATH REPO_DIR:
    @just _clone-repo-rev "{{REPO_NAME}}" "{{REPO_PATH}}" "{{REPO_DIR}}" ""

_clone-repo-rev REPO_NAME REPO_PATH REPO_DIR COMMIT_REV:
    #!/usr/bin/env bash

    just _log-info "Setting up {{REPO_NAME}} code repo to {{REPO_DIR}}"
    if [[ ! -d "{{REPO_DIR}}" ]]; then
        mkdir -p "{{REPO_DIR}}"
        git clone {{REPO_PATH}} "{{REPO_DIR}}"
    fi
    just _log-info ""

    if [[ "{{COMMIT_REV}}" != "" ]]; then
        just _log-info "Switching to commit {{COMMIT_REV}}"
        git checkout {{COMMIT_REV}}
        just _log-info ""
    else
        just _log-info "Pulling to latest commit"
        git pull
        just _log-info ""
    fi

_log-head LOG_LINE:
    @just _log-inner "{{COLOR_GREEN}}" "INFO!" "{{LOG_LINE}}"

_log-info LOG_LINE:
    @just _log-inner "{{COLOR_BLUE}}" "INFO " "{{LOG_LINE}}"

_log-error LOG_LINE:
    @just _log-inner "{{COLOR_RED}}" "ERROR" "{{LOG_LINE}}"

_log-inner COLOR LOG_LEVEL LOG_LINE:
    @if [ "{{LOG_LINE}}" = "" ]; then echo ""; else echo "{{COLOR}}[`date +'%Y-%m-%d %T'`][{{LOG_LEVEL}}] {{LOG_LINE}}{{COLOR_NONE}}"; fi