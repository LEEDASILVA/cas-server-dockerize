#!/bin/bash

### SERVER CONFIG ###
# Name of the server / container
cas_server_name='cas_server_demo'

# Server version (offical)
cas_server_version ='6.4.0'

# Server FQDN and service port
cas_server_url='cas.example.org'
cas_server_port='8443'

# Java KeyStore location for your server
cas_server_keystore='/root/demo_cas_server/certs/demo_server.jks'

### USER CONFIG ###
# Default user credentials
cas_user_name_default='casuser'
cas_user_password_default='Mellon'

# Misc user credentials
cas_user_name_misc='casadmin'
cas_user_password_misc='Mellon'

### ATTRIBUTE CONFIG ###
cas_attrib_cn= 'CAS'
cas_attrib_display_name='Apereo CAS'
cas_attrib_uid='casuser'
cas_attrib_first_name='Apereo'
cas_attrib_last_name='CAS'
cas_attrib_email='cas.user@0example.org'

### BEGIN: DO NOT EDIT ###
# General Configuration of the CAS server
cas_server_configs='{
      "management": {
        "endpoints": {
            "enabled-by-default": true,
            "web": {
                "exposure": {
                    "include": "*"
                }
            }
        }
    },
    "logging":{
        "config": "/etc/cas/config/log4j2.xml"
    },
    "cas": {
        "authn": {
            "accept": {
                "users": "'${cas_user_name_default}'::'${cas_user_password_default}','${cas_user_name_misc}'::'${cas_user_password_misc}'"
            },
            "attribute-repository": {
                "core": {
                        "default-attributes-to-release": [ "first-name", "last-name", "email" ]
                },
                "stub": {
                    "attributes": {
                        "cn": "'${cas_attrib_cn}'",
                        "display-name": "'${cas_attrib_display_name}'",
                        "uid": "'${cas_attrib_uid}'",
                        "first-name": "'${cas_attrib_first_name}'",
                        "last-name": "'${cas_attrib_last_name}'",
                        "email": "'${cas_attrib_email}'"
                    }
                }
            }
        },
        "events": {
            "core": {
                "track-configuration-modifications": false
            }
        },
        "monitor": {
            "endpoints": {
                "endpoint": {
                    "defaults": {
                        "access": "ANONYMOUS"
                    }
                }
            }
        },
        "server": {
            "name": "https://'${cas_server_url}':'${cas_server_port}'",
            "prefix": "https://'${cas_server_url}':'${cas_server_port}'/cas",
            "tomcat": {
                "http": {
                    "enabled": false
                }
            }
        },
        "service-registry": {
            "core": {
                "init-from-json": true
            }
        }
    }
}'
### END: DO NOT EDIT ###
cas_server_configs=$(echo "$cas_server_configs" | tr -d '[:space:]')
echo -e "***************************\nCAS Server Configurations\n***************************"
echo "${cas_server_configs}" | jq

docker stop ${cas_server_name} || true && docker rm ${cas_server_name} || true
echo -e "Mapping CAS keystore in Docker container to ${cas_server_keystore}\n"

docker run --rm -d \
  --mount type=bind,source="${cas_server_keystore}",target=/etc/cas/thekeystore \
  -e SPRING_APPLICATION_JSON="${cas_server_configs}" \
  -p ${cas_server_port}:8443 --name ${cas_server_name} apereo/cas:${cas_server_version}

docker logs ${cas_server_name} &
echo -e "Waiting for ${cas_server_name} to load..."
until curl -k -L --output /dev/null --silent --fail https://${cas_server_url}:${cas_server_port}/cas/login; do
  echo -n .
  sleep 1
done

echo -e "\nCAS Server (${cas_server_name}) is running on port ${cas_server_port}\n"
echo -e "\nPlease use the following URL to access the login page:\n"
echo -e "https://${cas_server_url}:${cas_server_port}/cas/login"
echo -e "\n\n Username: ${cas_user_name_default} and Password: ${cas_user_password_default}"
