#!/usr/bin/env sh
${VERBOSE} && set -x

# shellcheck source=/dev/null
if test -f "${STAGING_DIR}/env_vars" ; then
    set -o allexport
    . "${STAGING_DIR}/env_vars"
    set +o allexport
fi

# Allows the forcing a shell variable to be used in any template
# Example: ${_DOLLAR_}{username} ==> ${username} 
# shellcheck disable=SC2034
export _DOLLAR_="$"

# expand templates that are bundled together in zip files
# (useful for pingfederate for example with data.zip)
# shellcheck disable=SC2044
for bundle in $( find "${STAGING_DIR}/" -type f -iname \*.zip.subst ) ; do
    base="/tmp/zip"
    mkdir -p ${base} || exit 151
    unzip -d "${base}" "${bundle}" || exit 152
    # shellcheck disable=SC2044
    for template in $( find "${base}/" -type f -iname \*.subst ) ; do
        ${VERBOSE} && echo "envsubst < ${template} > ${template%.subst}"
        envsubst < "${template}" > "${template%.subst}"
        rm -f "${template}"
    done
    cd "${base}" || exit 153
    # shellcheck disable=2035
    zip -r "${bundle%.subst}" * || exit 154
    rm -rf "${base}"
    rm -f "${bundle}"
done


# we check if there are templates that we have to run through env subst
# shellcheck disable=SC2044
for template in $( find "${STAGING_DIR}/" -type f -iname \*.subst ) ; do 
    envsubst < "${template}" > "${template%.*}"
done
