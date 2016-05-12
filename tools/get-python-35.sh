#!/usr/bin/env bash

set -xe

export DEBIAN_FRONTEND=noninteractive


function update_apt_cache() {
    apt-get update
}


function update_bash_rc() {
	cat >> ~/.bashrc <<'EOF'
    export PATH="~/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
EOF
    source ~/.bashrc
}


function install_python() {
    apt-get install --yes python3 python3-pip

    apt-get install --yes libpq-dev libsqlite3-dev libbz2-dev libreadline-dev libjpeg-dev

    if [[ ! -d "~/.pyenv" ]]; then
        curl --silent --fail -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

        update_bash_rc
    fi

    if [[ ! -d "~/.pyenv/versions/3.5.1" ]]; then
        pyenv install 3.5.1
        pyenv global 3.5.1
    fi

    pip3 install --upgrade pip
    pip3 install --upgrade tox
}


function main() {
	update_apt_cache
	install_python
}


main
