*** Test Cases ***
TEST:Stackstorm client's connection
    ${result}=       Run Process    st2  action  execute  core.local   cmd\=echo
    Process Log To Console    ${result}
    Should Contain   ${result.stdout}    st2 execution get
    # Run Keyword If   ${result.rc} != 0   Fatal Error    ST2 NOT RUNNING

TEST:Hubot npm
    ${result}=       Run Process    npm   list    \|  grep  hubot-stackstorm  cwd=/opt/stackstorm/chatops
    Process Log To Console    ${result}
    Should Contain   ${result.stdout}  hubot-stackstorm@
    # Run Keyword If   ${result.rc} != 0   Fatal Error  HUBOT-STACKSTORM IS NOT INSTALLED

TEST:Check for enabled StackStorm aliases
    ${result}=       Run Process      st2  action-alias   list  -a  enabled  -j
    Process Log To Console    ${result}
    Should Contain   ${result.stdout}  "enabled": true
    # Run Keyword If   ${result.rc} != 0   Fatal Error  StackStorm doesn't seem to have registered and enabled aliases.

TEST:Check chatops.notify rule
    ${result}=       Run Process   st2  rule  list  -p  chatops  -j
    Process Log To Console    ${result}
    Should Contain   ${result.stdout}  "ref": "chatops.notify"
    Should Contain   ${result.stdout}  "enabled": true
    # Run Keyword If   ${result.rc} != 0   Fatal Error   CHATOPS.NOTIFY RULE NOT PRESENT/ENABLED

TEST:Check Hubot help and load commands
    ${result}=       Run Keyword  KEYWORD:Hubot Help
    Process Log To Console    ${result}
    Should Contain   ${result.stdout}    !help - Displays all of the help commands
    Should Contain   ${result.stdout}    commands are loaded
    # Run Keyword If   ${result.rc} != 0   Fatal Error  HUBOT DOESN'T RESPOND TO THE "HELP" COMMAND OR DOESN'T TRY TO LOAD COMMANDS FROM STACKSTORM.


TEST:Check post_message execution and receive status
    ${channel}=       KEYWORD:Generate Token
    Log To Console   \nCHANNEL: ${channel}
    ${result}=        Wait Until Keyword Succeeds  3x  5s   KEYWORD:Hubot Post  ${channel}
    # Run Keyword If   ${result.rc} != 0    Fatal Error  CHATOPS.POST_MESSAGE HASN'T BEEN RECEIVED.

TEST:Check the complete request-response flow
    ${channel}=      KEYWORD:Generate Token
    Log To Console   \nCHANNEL: ${channel}
    ${result}=       Run Keyword  KEYWORD:Complete Flow  ${channel}
    Process Log To Console    ${result}
    Should Contain   ${result.stdout}   Give me just a moment to find the actions for you
    Should Contain   ${result.stdout}   st2.actions.list - Retrieve a list of available StackStorm actions.
    # Run Keyword If   ${result.rc} != 0    Fatal Error  END-TO-END TEST FAILED.


*** Keyword ***
KEYWORD:Hubot Help
    ${result}=     Run Process    {  echo  -n;  sleep  5;  echo  'hubot  help';  echo;  sleep  5;}  |  bin\/hubot  \-\-test
    ...                           cwd=/opt/stackstorm/chatops/  shell=True
    [return]      ${result}

KEYWORD:Hubot Post
    [Arguments]    ${channel}
    ${result}=     Run Process    {  echo  -n;  sleep  5;  st2  action  execute  chatops.post_message  channel\=${channel}
    ...                           message\='Debug. If you see this you are incredibly lucky but please ignore.'
    ...                           >\/dev\/null;  echo;  sleep  5;}  |  bin\/hubot  \-\-test
    ...                           cwd=/opt/stackstorm/chatops/    shell=True
    Should Contain     ${result.stdout}   Chatops message received
    Should Contain     ${result.stdout}   ${channel}

KEYWORD:Complete Flow
    [Arguments]    ${channel}
    ${result}=     Run Process  {  echo  -n;  sleep  10;  echo  'hubot  st2  list  5  actions  pack\=st2';  echo;  sleep  25;}
    ...                         |  bin\/hubot  \-\-test   cwd=/opt/stackstorm/chatops/    shell=True
    [return]       ${result}

KEYWORD:Generate Token
    ${token}=       Generate Random String  32
    [return]        ${token}

*** Settings ***
Documentation    Nine-Step Hubot Self-Check Script
Library          Process
Library          String
Resource         ../common/keywords.robot

