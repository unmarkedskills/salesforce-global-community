#!/bin/bash

SCRIPT_PATH="./config/scripts/bash/" # set script path
echo -e "script path : $SCRIPT_PATH"
source "$SCRIPT_PATH""utility.sh"
source "$SCRIPT_PATH""decorator.sh"

SCRATCH_ORG_PATH="./config/scratch-org-config/" # set scratch org path
SCRATCH_PRE_PATH="./config/scratch-pre-deploy/" # set scratch org pre deployment components path
# TODO: analyze to automate it with deriving the dependencies and read the permission set name from config
#PERMISSION_SETS=("Sage_Global_Core_Admin" "Sage_Global_Core_Data_Model_Admin" "Sage_ODS_Views" "Sage_Global_Sales_Admin") # required permission sets
source "$SCRIPT_PATH""createDevEnv.sh" --package salesforce-global-community