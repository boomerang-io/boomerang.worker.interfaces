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
curl -Lk --noproxy $NO_PROXY --insecure -u $ART_REPO_USER:$ART_REPO_PASSWORD "$ART_URL/$ART_REPO_ZIP_FOLDER/$ART_REPO_ZIP_FILE" -o SAClientUtil.zip

# Unzip ASoC CLI
unzip SAClientUtil.zip
rm -f SAClientUtil.zip
SAC_DIR=`ls -d SAClientUtil*`
mv $SAC_DIR SAClientUtil

# Compile Source
mvn compile dependency:copy-dependencies

# Check JAVA_HOME is set
echo "JAVA_HOME=$JAVA_HOME"

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
echo $ASOC_APP_ID
echo $ASOC_LOGIN_KEY_ID
echo $ASOC_LOGIN_SECRET

SAClientUtil/bin/appscan.sh api_login -u $ASOC_LOGIN_KEY_ID  -P $ASOC_LOGIN_SECRET
ASOC_SCAN_ID=$(SAClientUtil/bin/appscan.sh queue_analysis -a $ASOC_APP_ID -f $COMPONENT_NAME_$VERSION_NAME.irx -n $COMPONENT_NAME_$VERSION_NAME |  tail -n 1)
echo $ASOC_SCAN_ID
while [ "$(SAClientUtil/bin/appscan.sh status -i $ASOC_SCAN_ID)" != "Ready" ]
    do
        echo "asoc job execution not ready"
        sleep 10
    done
echo "done"

#Get ASoC execution summary
SAClientUtil/bin/appscan.sh info -i $ASOC_SCAN_ID -json >> ASOC_Summary.json

# Download ASoC report
SAClientUtil/bin/appscan.sh get_result -d ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html -i $ASOC_SCAN_ID

cat ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html

# Upload Scan Results
#ASOC_SCAN_RESULTS_$COMPONENT_NAME_$VERSION_NAME.html
