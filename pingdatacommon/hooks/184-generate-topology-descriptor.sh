#!/usr/bin/env sh
${VERBOSE} && set -x

# shellcheck source=/dev/null
test -f "${STAGING_DIR}/env_vars" && . "${STAGING_DIR}/env_vars"

# shellcheck disable=SC2086
if test -z "${TOPOLOGY_PREFIX}" || test -z "${TOPOLOGY_SIZE}" || ! test ${TOPOLOGY_SIZE} -gt 0 ; then
    exit 0
fi

productString=""
case "${PING_PRODUCT}" in
    PingDirectory)
        productString="DIRECTORY"
        ;;
    PingDataSync)
        productString="SYNCHRONIZATION"
        ;;
    PingDirectoryProxy)
        productString="PROXY"
        ;;
    PingDataMetrics)
        productString="METRICS_ENGINE"
        ;;
    PingDataGovernance)
        productString="BROKER"
        ;;
    *)
        echo "UNSUPPORTED PRODUCT ${PING_PRODUCT}"
        exit 187
esac

if ! test "${productString}" = "DIRECTORY" ; then
    exit 0
fi

cat >> "${STAGING_DIR}/topology.json" <<END 
{
  "serverInstances" : [
END

if test -z "${TOPOLOGY_SUFFIX}" ; then
    # 1-based numbering in docker swarm and docker compose
    countFrom=1
    countTo=${TOPOLOGY_SIZE}
else
    # 0-based numbering in kubernetes
    countFrom=0
    countTo=$( TOPOLOGY_SIZE - 1 )
fi

# shellcheck disable=SC2086
for i in $( seq ${countFrom} ${countTo}  ) ; do
    instanceName=${TOPOLOGY_PREFIX}${i}
    containerHostName=${instanceName}
    if ! test -z "${TOPOLOGY_SUFFIX}" ; then
        containerHostName="${instanceName}.${TOPOLOGY_SUFFIX}"
    fi
    # Write the beginning of the "serverInstances" array
    SEPARATOR=","
    # shellcheck disable=SC2086
    if test $i -eq ${countTo} ; then
        SEPARATOR=""
    fi

    # Write the server instance's content
    cat >> "${STAGING_DIR}/topology.json" <<____END 
    {
        "instanceName" : "${instanceName}",
        "hostname" : "${containerHostName}",
        "location" : "${LOCATION}",
        "ldapPort" : ${LDAP_PORT},
        "ldapsPort" : ${LDAPS_PORT},
        "replicationPort" : ${REPLICATION_PORT},
        "startTLSEnabled" : true,
        "preferredSecurity" : "SSL",
        "product" : "${productString}"
    }${SEPARATOR}
____END

done
cat >> "${STAGING_DIR}/topology.json" <<END
  ]
}
END
