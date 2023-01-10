#!/usr/bin/env just --justfile

P4_ROOT := "~/code/p4"
BMV2_DIR := P4_ROOT + "/behavioral-model"
MN_DIR := P4_ROOT + "/mininet"
P4_TUTORIALS_DIR := P4_ROOT + "/tutorials"
OPEN_TOFINO_DIR := P4_ROOT + "/Open-Tofino"

#
# Init tasks: Installing build tools and etc
#
init: init-p4-apt init-p4c init-p4-bmv2 init-mininet init-p4-tutorials init-open-tofino

init-p4-apt:
    #!/usr/bin/env bash

    . /etc/os-release

    @echo "Checking P4 apt repository source: /etc/apt/sources.list.d/home:p4lang.list"
    if [[ ! -f "/etc/apt/sources.list.d/home:p4lang.list" ]]; then
        @echo "P4 apt repository already added.";
    else
        @echo "Adding P4 apt repository ..."
        echo "deb https://download.opensuse.org/repositories/home:/p4lang/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/home:p4lang.list
    fi
    @echo ""

    @echo "Adding P4 apt repository key ..."
    curl -L "https://download.opensuse.org/repositories/home:/p4lang/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -
    @echo ""

    @echo "Running apt update ..."
    sudo apt update
    @echo ""

init-p4c:
    @echo "Installing p4c ..."
    sudo apt install p4lang-p4c
    @echo ""

init-p4-bmv2:
    #!/usr/bin/env bash

    just clone-repo "bmv2" "https://github.com/p4lang/behavioral-model.git" "{{BMV2_DIR}}"

    @echo "Installing bmv2 dependencies ..."
    sudo apt-get install -y automake cmake libgmp-dev \
        libpcap-dev libboost-dev libboost-test-dev libboost-program-options-dev \
        libboost-system-dev libboost-filesystem-dev libboost-thread-dev \
        libevent-dev libtool flex bison pkg-config g++ libssl-dev

    cd "{{BMV2_DIR}}\ci"
    bash ./install-thrift.sh
    bash ./install-nanomsg.sh
    @echo ""

    @echo "Building bmv2 (this will take quite a while, best time to grab a cup of coffee) ..."
    cd "{{BMV2_DIR}}"
    ./autogen.sh
    ./configure 'CXXFLAGS=-O0 -g' --enable-debugger
    make
    sudo make install
    @echo ""

    @echo "Building and running bmv2 tests ..."
    make check
    @echo ""

init-mininet:
    #!/usr/bin/env bash

    just clone-repo-rev "mininet" "https://github.com/mininet/mininet.git" "{{MN_DIR}}" "2.3.1b1"

    @echo "Installing mininet ..."
    cd "{{P4_ROOT}}"
    mininet/util/install.sh -a
    @echo ""

    @echo "Testing mininet ..."
    sudo mn --switch ovsbr --test pingall

init-p4-tutorials:
    just clone-repo "p4-tutorials" "https://github.com/p4lang/tutorials.git" "{{P4_TUTORIALS_DIR}}"

init-open-tofino:
    just clone-repo "OpenTofino" "https://github.com/barefootnetworks/Open-Tofino.git" "{{OPEN_TOFINO_DIR}}"

#
# Utility tasks
#
clone-repo REPO_NAME REPO_PATH REPO_DIR:
    @just clone-repo "{{REPO_NAME}}" "{{REPO_PATH}}" "{{REPO_DIR}}" ""

clone-repo-rev REPO_NAME REPO_PATH REPO_DIR COMMIT_REV:
    #!/usr/bin/env bash

    @echo "Setting up {{REPO_NAME}} code repo to {{REPO_DIR}}"
    if [[ ! -d "{{REPO_DIR}}" ]]; then
        mkdir -p "{{REPO_DIR}}"
        cd "{{REPO_DIR}}"
        git clone {{REPO_PATH}} .
    fi
    @echo ""

    if [[ "{{COMMIT_REV}}" != "" ]]; then
        @echo "Switching to commit {{COMMIT_REV}}"
        git checkout {{COMMIT_REV}}
        @echo ""
    else
        @echo "Pulling to latest commit"
        git pull
        @echo ""
    fi