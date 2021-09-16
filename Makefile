# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh
PROJECT_CONFIG_FILE_NAME = .conf

# targets
HELP = help
ALTARIA = altaria
BRAVE = brave
CONFIGS = configs
CLEAN = clean

# executables
ENVSUBST = envsubst

# should list all the vars in the multiline var below
_SUDOER_PASSWORD_CRYPT = $${SUDOER_PASSWORD_CRYPT}
project_config_file_vars = \
	${_SUDOER_PASSWORD_CRYPT}

define PROJECT_CONFIG_FILE =
cat << _EOF_
#
#
# Config file to centralize vars, and to aggregate common vars.

# needed to construct altaria's comprtconfig and brave's comprtconfig
export SUDOER_PASSWORD_CRYPT=
_EOF_
endef
# Use the $(value ...) function if there are other variables in the multi-line
# variable that should be evaluated by the shell and not make! e.g. 
# export PROJECT_CONFIG_FILE = $(value _PROJECT_CONFIG_FILE)
export PROJECT_CONFIG_FILE

# simply expanded variables
SHELL_TEMPLATE_EXT := .shtpl
shell_template_wildcard := %${SHELL_TEMPLATE_EXT}
script_shell_templates := $(shell find ${CURDIR} -name *${SHELL_TEMPLATE_EXT})

# to be passed in at make runtime
PREPROCESS_ALIASES =

# Determines the config name(s) to be generated from the template(s).
# Short hand notation for string substitution: $(text:pattern=replacement).
scripts := $(script_shell_templates:${SHELL_TEMPLATE_EXT}=)

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  ${PROJECT_CONFIG_FILE_NAME}            - generates the configuration file to be used by other'
>	@echo '                     make targets. Particularly targets that utilize shell'
>	@echo '                     templates.'
>	@echo '  ${ALTARIA}          - the build node environment for the jenkins-torkel container'
>	@echo '  ${BRAVE}            - the environment for deploying docker containers'
>	@echo '  ${CLEAN}            - removes files generated from other targets'

${PROJECT_CONFIG_FILE_NAME}:
>	eval "$${PROJECT_CONFIG_FILE}" > "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}"

.PHONY: ${ALTARIA}
${ALTARIA}:
# assumes that configs will be exported into the env
ifdef PREPROCESS_ALIASES
>	cd "$@" && ${ENVSUBST} '${project_config_file_vars}' < "comprtconfig.shtpl" > "comprtconfig"
else
>	@[ -f "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}" ] || { echo "${PROJECT_CONFIG_FILE_NAME} must be generated, run 'make ${PROJECT_CONFIG_FILE_NAME}'"; exit 1; }
>	. "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}" && cd "$@" && ${ENVSUBST} '${project_config_file_vars}' < "comprtconfig.shtpl" > "comprtconfig"
endif

.PHONY: ${BRAVE}
${BRAVE}:
ifdef PREPROCESS_ALIASES
>	cd "$@" && ${ENVSUBST} '${project_config_file_vars}' < "comprtconfig.shtpl" > "comprtconfig"
else
>	@[ -f "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}" ] || { echo "${PROJECT_CONFIG_FILE_NAME} must be generated, run 'make ${PROJECT_CONFIG_FILE_NAME}'"; exit 1; }
>	. "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}" && cd "$@" && ${ENVSUBST} '${project_config_file_vars}' < "comprtconfig.shtpl" > "comprtconfig"
endif

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ${scripts}
