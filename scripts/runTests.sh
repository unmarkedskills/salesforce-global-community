#!/bin/bash

RED_BOLD="\x1B[1;31m"
GREEN_BOLD="\x1B[1;32m"
NO_COLOUR="\x1B[0m"

RUN_ROOT=`pwd`
DEFAULT_DIR="testrun"

whichOrg(){
    while [ ! -n "$ORG_NAME"  ] 
    do
        echo -e "${GREEN_BOLD}Loading active scratch Orgs...${NO_COLOUR}"
        ORGS=$(sfdx force:org:list --json | jq '.result.scratchOrgs[] .alias' | tr -d \")
        
        echo $ORGS
        echo -e "${GREEN_BOLD}🐱  Please enter a name for your scratch org:${NO_COLOUR}"
        read ORG_NAME
    done    

}

init(){
    export SFDX_IMPROVED_CODE_COVERAGE="true"
    if [[ -d "$DEFAULT_DIR" ]]
    then
        rm -rf $DEFAULT_DIR
    else
        mkdir $DEFAULT_DIR
    fi
    whichOrg
}

searchAllTestClasses(){
    echo -e "${GREEN_BOLD} Finding all Test classes in package....${NO_COLOUR}"
    TEST_CLASS_NAMES=($(grep --include=*.cls -Ril "testMethod" ./ | xargs basename | sed -e 's/\.cls//'))
    TEST_CLASS_NAMES+=($(grep --include=*.cls -Ril "@isTest" ./ | xargs basename | sed -e 's/\.cls//'))
    echo "${TEST_CLASS_NAMES[*]}"
    PKG_TESTS=$( IFS=$','; echo "${TEST_CLASS_NAMES[*]}" )
    
}

failedTests(){
    echo -e "${RED_BOLD} Failed Tests $1${NO_COLOUR}"
    runid=$( cat $DEFAULT_DIR/test-run-id.txt )
    cat $DEFAULT_DIR/test-result-$runid.json | jq '.tests[] | select(.Outcome == "Fail") | .ApexClass.Name' | uniq
}

coverage(){
    echo -e "${RED_BOLD} coverage under 80 % $1${NO_COLOUR}"
    runid=$( cat $DEFAULT_DIR/test-run-id.txt )    
    #cat ./$DEFAULT_DIR/test-result-codecoverage.json | jq '.[] | .name + ", "+ (.coveredPercent|tostring)'
    cat ./$DEFAULT_DIR/test-result-codecoverage.json | jq '.[] | select(.coveredPercent < 80) | .name + ", "+ (.coveredPercent|tostring)' 
}

runAllTests(){
    echo "Runing Tests..."
    sfdx force:apex:test:run -l RunLocalTests -d ./testrun -r json -u ${ORG_NAME} -c --json
    #cat ./testrun/test-result-codecoverage.json | jq '.[] | .name + ", "+ (.totalLines|tostring)'
}

runPkgTests(){
    searchAllTestClasses
     echo -e "${GREEN_BOLD}Running Package Tests....${NO_COLOUR}"
    sfdx force:apex:test:run -n $PKG_TESTS -d ./testrun -r json -u ${ORG_NAME} -c -w 25
    
    if [ "$?" = "1" ]
    then 
         echo -e "${RED_BOLD}🐱  Test run took too long.${NO_COLOUR}"
        exit 
    else
        runid=$( cat $DEFAULT_DIR/test-run-id.txt )
        echo -e "${RED_BOLD} Failed Tests..${NO_COLOUR}"
        failedTests $runid
        echo -e "${RED_BOLD} Coverage Results (Under 80%)..${NO_COLOUR}"
        coverage
    fi 
}

init
echo "SFDX_IMPROVED_CODE_COVERAGE is $SFDX_IMPROVED_CODE_COVERAGE"
start=`date +%s`
echo $ORG_NAME
runAllTests
failedTests
coverage
end=`date +%s`
runtime=$((end-start))
echo "Tests took $runtime seconds to exectute and validate"