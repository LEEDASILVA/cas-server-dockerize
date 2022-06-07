#!/bin/bash
properties='{
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
    "cas": {
        "authn": {
            "accept": {
                "users": "casuser::Mellon,casadmin::Mellon"
            },
            "attribute-repository": {
                "stub": {
                    "attributes": {
                        "cn": "CAS",
                        "display-name": "Apereo CAS",
                        "uid": "casuser",
                        "first-name": "Apereo",
                        "last-name": "CAS",
                        "email": "lee@01talent.com"
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
            "name": "https://localhost:8444",
            "prefix": "https://localhost:8444/cas",
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
properties=$(echo "$properties" | tr -d '[:space:]')
echo -e "***************************\nCAS properties\n***************************"
echo "${properties}" | jq

if [[ -z "${CAS_KEYSTORE}" ]] ; then
  keystore="$PWD"/thekeystore
  echo -e "Generating keystore for CAS Server at ${keystore}"
  dname="${dname:-CN=localhost,OU=Example,OU=Org,C=US}"
  subjectAltName="${subjectAltName:-dns:example.org,dns:localhost,ip:127.0.0.1}"
  [ -f "${keystore}" ] && rm "${keystore}"
  keytool -genkey -noprompt -alias cas -keyalg RSA \
    -keypass changeit -storepass changeit \
    -keystore "${keystore}" -dname "${dname}"
  [ -f "${keystore}" ] && echo "Created ${keystore}"
  export CAS_KEYSTORE="${keystore}"
else
  echo -e "Found existing CAS keystore at ${CAS_KEYSTORE}"
fi

docker stop casserver || true && docker rm casserver || true
echo -e "Mapping CAS keystore in Docker container to ${CAS_KEYSTORE}"

docker run --rm -d \
  --mount type=bind,source="${CAS_KEYSTORE}",target=/etc/cas/thekeystore \
  -e SPRING_APPLICATION_JSON="${properties}" \
  -p 8444:8443 --name casserver apereo/cas:6.5.0

docker logs -f casserver &
echo -e "Waiting for CAS..."
until curl -k -L --output /dev/null --silent --fail https://localhost:8444/cas/login; do
  echo -n .
  sleep 1
done
echo -e "\nCAS Server is running on port 8444"
echo -e "\n\nReady!"
