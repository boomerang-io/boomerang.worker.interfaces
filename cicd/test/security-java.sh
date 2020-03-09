#!/bin/bash

#( printf '\n'; printf '%.0s-' {1..30}; printf ' Security Test - Java '; printf '%.0s-' {1..30}; printf '\n\n' )

COMPONENT_NAME=$1
VERSION_NAME=$2
ART_URL=$3
ART_REPO_USER=$4
ART_REPO_PASSWORD=$5
ASOC_APP_ID=$6
ASOC_LOGIN_KEY_ID=$7
ASOC_LOGIN_SECRET=$8
ASOC_CLIENT_CLI=$9

# Download ASoC CLI
echo "SAClientUtil File: $ART_URL/$ASOC_CLIENT_CLI"
echo "Creds: $ART_REPO_USER:$ART_REPO_PASSWORD"
curl --noproxy "$NO_PROXY" --insecure -u $ART_REPO_USER:$ART_REPO_PASSWORD "$ART_URL/$ASOC_CLIENT_CLI" -o SAClientUtil.zip

# Unzip ASoC CLI
ls -al SAClientUtil.zip
unzip SAClientUtil.zip
rm -f SAClientUtil.zip
SAC_DIR=`ls -d SAClientUtil*`
mv $SAC_DIR SAClientUtil
mv SAClientUtil ../SAClientUtil

# Compile Source
if [ "$HTTP_PROXY" != "" ]; then
    # Swap , for |
    MAVEN_PROXY_IGNORE=`echo "$NO_PROXY" | sed -e 's/ //g' -e 's/\"\,\"/\|/g' -e 's/\,\"/\|/g' -e 's/\"$//' -e 's/\,/\|/g'`
    export MAVEN_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttp.nonProxyHosts='$MAVEN_PROXY_IGNORE' -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT -Dhttps.nonProxyHosts='$MAVEN_PROXY_IGNORE'"
fi
echo "MAVEN_OPTS=$MAVEN_OPTS"
mvn clean package install -DskipTests=true -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true

# # Install jaxb for Java 11
# curl https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.0/jaxb-api-2.3.0.jar -o jaxb-api-2.3.0.jar
# curl https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.0/jaxb-api-2.3.0.pom -o jaxb-api-2.3.0.pom
# mvn install:install-file -Dfile=jaxb-api-2.3.0.jar -DpomFile=jaxb-api-2.3.0.pom
#
# curl https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-core/2.3.0/jaxb-core-2.3.0.jar -o jaxb-core-2.3.0.jar
# curl https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-core/2.3.0/jaxb-core-2.3.0.pom -o jaxb-core-2.3.0.pom
# mvn install:install-file -Dfile=jaxb-core-2.3.0.jar -DpomFile=jaxb-core-2.3.0.pom
#
# curl https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-impl/2.3.0/jaxb-impl-2.3.0.jar -o jaxb-impl-2.3.0.jar
# curl https://repo1.maven.org/maven2/com/sun/xml/bind/jaxb-impl/2.3.0/jaxb-impl-2.3.0.pom -o jaxb-impl-2.3.0.pom
# mvn install:install-file -Dfile=jaxb-impl-2.3.0.jar -DpomFile=jaxb-impl-2.3.0.pom



# export JDK_JAVA_OPTIONS="$JDK_JAVA_OPTIONS --add-modules=java.xml.bind"
# echo "JDK_JAVA_OPTIONS=$JDK_JAVA_OPTIONS"






# Create appscan-config.xml
# cat >> glen-appscan-config.xml <<EOL
# <?xml version="1.0" encoding="UTF-8"?>
# <Configuration>
#    <Targets>
#     <Target path="target/classes">
#       <CustomBuildInfo additional_classpath="target/dependency;target/classes" src_root="src/main/java;src/test/java;src/main/resources" jdk_path="$JAVA_HOME" />
#       <Exclude>SAClientUtil/</Exclude>
#     </Target>
#   </Targets>
# </Configuration>
# EOL

# Install Java 8 for ASoC
apk add openjdk8

# Check JAVA_HOME is set
if [ -z "$JAVA_HOME" ]; then
  ls -al /usr/lib/jvm/default-jvm/jre/bin/java
  export JAVA_HOME=/usr/lib/jvm/default-jvm
fi
echo "JAVA_HOME=$JAVA_HOME"

java --version

# Generate IRX file
export APPSCAN_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"
echo "APPSCAN_OPTS=$APPSCAN_OPTS"
#../SAClientUtil/bin/appscan.sh prepare -c appscan-config.xml -n ${COMPONENT_NAME}_${VERSION_NAME}.irx
../SAClientUtil/bin/appscan.sh prepare -v -X -n ${COMPONENT_NAME}_${VERSION_NAME}.irx
# mvn package com.hcl.security:appscan-maven-plugin:prepare -Doutput=${COMPONENT_NAME}_${VERSION_NAME}.irx

# curl -T glen.test.java_0.0.30-5.failed "https://tools.boomerangplatform.net/artifactory/boomerang/software/asoc/glen.test.java_0.0.30-5.failed" --insecure -u $ART_REPO_USER:$ART_REPO_PASSWORD
# curl -T glen.test.java_0.0.30-5_logs.zip "https://tools.boomerangplatform.net/artifactory/boomerang/software/asoc/glen.test.java_0.0.30-5_logs.zip" --insecure -u $ART_REPO_USER:$ART_REPO_PASSWORD

# if [ ! -f "${COMPONENT_NAME}_${VERSION_NAME}.irx" ]; then
#   file=`ls *.failed 2> /dev/null`
#   if [ -f "$file" ]; then
#     cp $file ${COMPONENT_NAME}_${VERSION_NAME}.irx
#   fi
# fi

ls -al

# echo "========================================================================================="
# cat appscan-config.xml
# echo "========================================================================================="

cat ../SAClientUtil/logs/client.log

if [ ! -f "${COMPONENT_NAME}_${VERSION_NAME}.irx" ]; then
  exit 128
fi

# Start Static Analyzer ASoC Scan
echo "ASoC App ID: $ASOC_APP_ID"
echo "ASoC Login Key ID: $ASOC_LOGIN_KEY_ID"
echo "ASoC Login Secret ID: $ASOC_LOGIN_SECRET"

../SAClientUtil/bin/appscan.sh api_login -u $ASOC_LOGIN_KEY_ID -P $ASOC_LOGIN_SECRET
ASOC_SCAN_ID=$(../SAClientUtil/bin/appscan.sh queue_analysis -a $ASOC_APP_ID -f ${COMPONENT_NAME}_${VERSION_NAME}.irx -n ${COMPONENT_NAME}_${VERSION_NAME} | tail -n 1)
echo "ASoC Scan ID: $ASOC_SCAN_ID"

if [ -z "$ASOC_SCAN_ID" ]; then
  exit 129
fi

START_SCAN=`date +%s`
RUN_SCAN=true
while [ "$(../SAClientUtil/bin/appscan.sh status -i $ASOC_SCAN_ID)" != "Ready" ] && [ "$RUN_SCAN" == "true" ]; do
  NOW=`date +%s`
  DIFF=`expr $NOW - $START_SCAN`
  if [ $DIFF -gt 600 ]; then
    echo "Timed out waiting for ASoC job to complete [$DIFF/600]"
    RUN_SCAN=false
  else
    echo "ASoC job execution not completed ... waiting 15 seconds they retrying [$DIFF/600]"
    sleep 15
  fi
done

if [ "$RUN_SCAN" == "false" ]; then
  exit 130
fi

#Get ASoC execution summary
../SAClientUtil/bin/appscan.sh info -i $ASOC_SCAN_ID -json >> ASOC_Summary.json

# Download ASoC report
../SAClientUtil/bin/appscan.sh get_result -d ASOC_SCAN_RESULTS_${COMPONENT_NAME}_${VERSION_NAME}.html -i $ASOC_SCAN_ID

cat ASOC_SCAN_RESULTS_${COMPONENT_NAME}_${VERSION_NAME}.html

# Upload Scan Results
#ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html
