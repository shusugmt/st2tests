*** Variables ***
${KEY}                  robot_key
${VALUE}                robot_value
${UPDATED VALUE}        new_robot_value
&{ELEMENTS}             robot2=key5  robot1=key4  1=2
${JSON FILE}            robotfm_tests/docs/variables/test_key_triggers.json

${TRIGGER KEY CREATE}   core.st2.key_value_pair.create
${TRIGGER KEY UPDATE}   core.st2.key_value_pair.update
${TRIGGER KEY CHANGE}   core.st2.key_value_pair.value_change
${TRIGGER KEY DELETE}   core.st2.key_value_pair.delete
${SUCCESS STATUS}       "status": "succeeded
${RUNNING STATUS}       "status": "running
${CANCELED STATUS}      "status": "canceled"
${FAILED STATUS}        "status": "failed"

*** Test Cases ***
TEST:Verify Key Value Triggers
    ${result}=       Run Process  st2  trigger  list  -p  core  -a ref  -j
    Log To Console   \nTRIGGER LIST:\n
    Process Log To Console   ${result}
    Should Contain   ${result.stdout}   ${TRIGGER KEY CREATE}
    Should Contain   ${result.stdout}   ${TRIGGER KEY UPDATE}
    Should Contain   ${result.stdout}   ${TRIGGER KEY CHANGE}
    Should Contain   ${result.stdout}   ${TRIGGER KEY DELETE}

TEST:Create, Update and Value Change key value pair
    [Template]                 KEYWORD:Set and update key
    ${KEY}  ${VALUE}           ${TRIGGER KEY CREATE}
    ${KEY}  ${VALUE}           ${TRIGGER KEY UPDATE}
    ${KEY}  ${UPDATED VALUE}   ${TRIGGER KEY CHANGE}

TEST:Delete a key
    Run Keyword      KEYWORD:Delete Key        ${KEY}
    Run Keyword      KEYWORD:Check key store actions with trigger instance  ${KEY}  ${UPDATED VALUE}  ${TRIGGER KEY DELETE}

TEST:Load and Delete Key Value pairs from json file
    ${result}=          Run Process        st2  key  load  ${JSON FILE}  -j
    Should Contain      ${result.stdout}   &{ELEMENTS}[robot2]
    Should Contain      ${result.stdout}   &{ELEMENTS}[robot1]
    Should Contain      ${result.stdout}   &{ELEMENTS}[1]
    ${result}=          Run Process        st2  key  list  -j
    Should Contain      ${result.stdout}   &{ELEMENTS}[robot2]
    Should Contain      ${result.stdout}   &{ELEMENTS}[robot1]
    Should Contain      ${result.stdout}   &{ELEMENTS}[1]
    Should Not Contain  ${result.stdout}   key1
    Should Not Contain  ${result.stdout}   key2
    Log To Console   \nFROM JSON:\n
    Process Log To Console   ${result}
    ${result}=          Run Process        st2  key  delete_by_prefix  -p  ro
    Should Contain      ${result.stdout}   Deleted 2 keys\nDeleted key ids: robot1, robot2
    Log To Console      \nDELETE BY PREFIX:\n
    Process Log To Console   ${result}
    ${result}=          Run Process        st2  key  delete  1  -j
    Log To Console      \nDELETE:\n
    Process Log To Console   ${result}
    Should Contain      ${result.stdout}   Resource with id "1" has been successfully deleted.

TEST:Key Value pair operations with expiry
    ${result}=           Run Process       st2  key  set  ${KEY}  ${VALUE}  -l  1  -j
    Should Contain       ${result.stdout}  expire_timestamp
    Should Contain       ${result.stdout}  "name": "${KEY}"
    Should Contain       ${result.stdout}  "value": "${VALUE}"
    ${result}=           Run Process       st2  key  get  ${KEY}  -j
    Should Contain       ${result.stdout}  expire_timestamp
    Should Contain       ${result.stdout}  "name": "${KEY}"
    Should Contain       ${result.stdout}  "value": "${VALUE}"
    Log To Console      \nKEY VALUE PAIR WITH EXPIRY:\n
    Process Log To Console   ${result}
    ${result}=           Wait Until Keyword Succeeds  1m  30s  KEYWORD:Get Key List
    Log To Console       \nKEY VALUE PAIR LIST(WITHOUT EXPIRY):\n
    Process Log To Console   ${result}


*** Keywords ***
KEYWORD:Get Key List
    ${result}=           Run Process       st2  key  list  -j
    Should Not Contain   ${result.stdout}  "name": "${KEY}"
    Should Not Contain   ${result.stdout}  "value": "${VALUE}"
    [return]             ${result}

KEYWORD:Set and update key
    [Arguments]      ${key}  ${value}   ${trigger value}
    ${result}=       Run Process        st2  key  set  ${key}  ${value}  -j
    ${message}=      Convert To Uppercase    ${trigger value}
    Log To Console   \n${message}\n
    Process Log To Console   ${result}
    Should Contain   ${result.stdout}   "name": "${key}"
    Should Contain   ${result.stdout}   "value": "${value}"
    Run Keyword      KEYWORD:Check key store actions with trigger instance  ${key}  ${value}  ${trigger value}

KEYWORD:Check key store actions with trigger instance
    [Arguments]      ${key}  ${value}  ${trigger value}
    ${result}=       Run Process       st2  trigger-instance  list   --trigger\=${trigger value}  -n  1  -j
    Should Contain   ${result.stdout}  "trigger": "${trigger value}"
    ${result}=       Run Process       st2  trigger-instance  list  --trigger\=${trigger value}  -n  1  -a  id  -j
    @{instance id}   Split String      ${result.stdout}    separator="
    Log To Console   \nINSTANCE ID: @{instance id}[3]
    ${result}=       Run Process       st2  trigger-instance  get  @{instance id}[3]  -j
    Log To Console   \nTRIGGER-INSTANCE:\n
    Process Log To Console   ${result}
    Should Contain   ${result.stdout}  "name": "${key}"
    Should Contain   ${result.stdout}  "value": "${value}"

KEYWORD:Delete Key
    [Arguments]      ${key}
    ${result}=       Run Process        st2  key  delete  ${key}
    Should Contain   ${result.stdout}    Resource with id "${key}" has been successfully deleted.

KEYWORD:Key Not Found
    [Arguments]      ${key}
    ${result}=       Run Process        st2  key  delete  ${key}
    Should Contain   ${result.stdout}    Key Value Pair "${key}" is not found.

SETUP/TEARDOWN:Check and Delete Key
   Log To Console    _______________________SUITE SETUP/TEARDOWN______________________
   Log To Console    _________________________________________________________________
   ${result}=       Run Process  st2  key  list  -j
   Run Keyword If   "${KEY}" in '''${result.stdout}'''  KEYWORD:Delete Key  ${KEY}
   ...       ELSE   KEYWORD:Key Not Found  ${KEY}
   Log To Console    _______________________SUITE SETUP/TEARDOWN______________________
   Log To Console    _________________________________________________________________

*** Settings ***
Library            Process
Library            String
Resource           ../common/keywords.robot
Suite Setup        SETUP/TEARDOWN:Check and Delete Key
Suite Teardown     SETUP/TEARDOWN:Check and Delete Key
