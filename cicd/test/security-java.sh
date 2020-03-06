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

# Download ASoC CLI
ART_REPO_ZIP_FOLDER=asoc
ART_REPO_ZIP_FILE=SAClientUtil_7.0.1313_linux.zip
echo "No Proxy in ASoC: $NO_PROXY"
echo "SAClientUtil File: $ART_URL/$ART_REPO_ZIP_FOLDER/$ART_REPO_ZIP_FILE"
echo "Creds: $ART_REPO_USER:$ART_REPO_PASSWORD"
curl --noproxy "$NO_PROXY" --insecure -u $ART_REPO_USER:$ART_REPO_PASSWORD "$ART_URL/$ART_REPO_ZIP_FOLDER/$ART_REPO_ZIP_FILE" -o SAClientUtil.zip

# Unzip ASoC CLI
ls -al
unzip SAClientUtil.zip
rm -f SAClientUtil.zip
SAC_DIR=`ls -d SAClientUtil*`
mv $SAC_DIR SAClientUtil

# Check JAVA_HOME is set
echo "JAVA_HOME=$JAVA_HOME"

# Compile Source
if [ "$HTTP_PROXY" != "" ]; then
    # Swap , for |
    MAVEN_PROXY_IGNORE=`echo "$NO_PROXY" | sed -e 's/ //g' -e 's/\"\,\"/\|/g' -e 's/\,\"/\|/g' -e 's/\"$//' -e 's/\,/\|/g'`
    export MAVEN_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttp.nonProxyHosts='$MAVEN_PROXY_IGNORE' -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT -Dhttps.nonProxyHosts='$MAVEN_PROXY_IGNORE'"
fi
echo "MAVEN_OPTS=$MAVEN_OPTS"
mvn compile dependency:copy-dependencies $MAVEN_OPTS

# Create appscan-config.xml
cat >> appscan-config.xml <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
   <Targets>
    <Target path="target\classes">
      <CustomBuildInfo additional_classpath="target\dependency;target\classes" src_root="src\main\java;" jdk_path="$JAVA_HOME"  />
    </Target>
  </Targets>
</Configuration>
EOL

# Generate IRX file
SAClientUtil/bin/appscan.sh prepare -c appscan-config.xml -n $COMPONENT_NAME_$VERSION_NAME.irx

# Start Static Analyzer ASoC Scan
echo "ASoC App ID: $ASOC_APP_ID"
echo "ASoC Login Key ID: $ASOC_LOGIN_KEY_ID"
echo "ASoC Login Secret ID: $ASOC_LOGIN_SECRET"

SAClientUtil/bin/appscan.sh api_login -u $ASOC_LOGIN_KEY_ID  -P $ASOC_LOGIN_SECRET
ASOC_SCAN_ID=$(SAClientUtil/bin/appscan.sh queue_analysis -a $ASOC_APP_ID -f $COMPONENT_NAME_$VERSION_NAME.irx -n $COMPONENT_NAME_$VERSION_NAME |  tail -n 1)
echo $ASOC_SCAN_ID

START_SCAN=`date +%s`
RUN_SCAN=true
while [ "$(SAClientUtil/bin/appscan.sh status -i $ASOC_SCAN_ID)" != "Ready" ] && [ "$RUN_SCAN" == "true" ]; do
  NOW=`date +%s`
  DIFF=`expr $NOW - $START_SCAN`
  if [ $DIFF -gt 300 ]; then
    echo "Timed out waiting for ASoC job to complete [$DIFF/300]"
    RUN_SCAN=false
  else
    echo "ASoC job execution not completed ... waiting 10 seconds they retrying [$DIFF/300]"
    sleep 10
  fi
done

if [ "$RUN_SCAN" == "false" ]; then
  exit 1
fi

#Get ASoC execution summary
SAClientUtil/bin/appscan.sh info -i $ASOC_SCAN_ID -json >> ASOC_Summary.json

# Download ASoC report
SAClientUtil/bin/appscan.sh get_result -d ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html -i $ASOC_SCAN_ID

cat ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html

# Upload Scan Results
#ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html
