
SHELL := /bin/bash
PYTHON := python
CONAN := conan
SED := sed
CONAN_HOME := $(shell pwd)/.conan2
CONAN_OPTS := -vtrace
# execute all lines of a target in one shell
.ONESHELL:

.PHONY: all
all: build

.PHONY: build
build:
	@if [ "$$VIRTUAL_ENV" == "" ] ; then
	    echo "creating python virtual environment in ./venv"
	    ${PYTHON} -m venv venv
	    source venv/bin/activate
	    pip install -r requirements.txt
	fi
	export CONAN_HOME="${CONAN_HOME}"  # copy from make env to bash env
	${CONAN} config install conan-config
	 #${CONAN} remote enable conancenter
	[ ! -e ".conan2/profiles/default" ] && ${CONAN} profile detect
	(cd conan_lbstanza_generator && ${CONAN} create .)

	 # get the current project name from the slm.toml file
	SLMPROJNAME=$$(${SED} -n -e '/^ *name *= *"*\([^"]*\).*/{s//\1/;p;q}' slm.toml)
	SLMPROJVER=$$(${SED} -n -e '/^ *version *= *"*\([^"]*\).*/{s//\1/;p;q}' slm.toml)

	 # build slm and link to dependency libs using stanza.proj fragments
	 # build only the current project, not any dependencies
	echo "building \"$${SLMPROJNAME}/$${SLMPROJVER}\""
	${CONAN} create \
	    ${CONAN_OPTS} \
	    --build "$${SLMPROJNAME}/$${SLMPROJVER}" .

.PHONY: upload
upload:
	@if [ "$$VIRTUAL_ENV" == "" ] ; then
	    echo "using python virtual environment in ./venv"
	    source venv/bin/activate
	fi
	export CONAN_HOME="${CONAN_HOME}"  # copy from make env to bash env
	${CONAN} remote enable artifactory
	 # expects user in CONAN_LOGIN_USERNAME_ARTIFACTORY and password in CONAN_PASSWORD_ARTIFACTORY
	${CONAN} remote login artifactory

	 # get the current project name from the slm.toml file
	SLMPROJNAME=$$(${SED} -n -e '/^ *name *= *"*\([^"]*\).*/{s//\1/;p;q}' slm.toml)
	SLMPROJVER=$$(${SED} -n -e '/^ *version *= *"*\([^"]*\).*/{s//\1/;p;q}' slm.toml)

	${CONAN} upload -r artifactory $${SLMPROJNAME}/$${SLMPROJVER}

.PHONY: clean
clean:
	@CLEANCMD="rm -rf .conan2 .slm build venv"
	echo $$CLEANCMD && eval $$CLEANCMD
	[ "x$$VIRTUAL_ENV" != "x" ] && [ ! -e "$$VIRTUAL_ENV" ] && printf "Virtual environment directory has been cleaned.\nRun 'deactivate' to exit from the virtual environment.\n" || true
