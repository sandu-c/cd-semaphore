#!/usr/bin/env bash

GREEN=('success' 'canceled' 'skipped' 'manual' 'scheduled')
YELLOW=('created' 'waiting_for_resource' 'preparing' 'pending' 'running')
RED=('failed')

GREEN_LIGHT="GREEN_LIGHT"
YELLOW_LIGHT="YELLOW_LIGHT"
RED_LIGHT="RED_LIGHT"

containsElement () {
    local e match="$1"
    shift
    e=$@

    for VAR in ${e[@]} ; do
       [[ $VAR ==  $match ]] && return 0
    done

    return 1
}

semaphoreStatus(){
     if [[ $1 == "" ]]
        then
        echo "Status is not available ?"
        exit 1
     fi

     local status=$1

     if containsElement ${status} "${GREEN[@]}";
           then echo ${GREEN_LIGHT}
     elif containsElement ${status} "${YELLOW[@]}";
           then echo ${YELLOW_LIGHT}
     elif containsElement ${status} "${RED[@]}";
           then echo ${RED_LIGHT}
      else echo "something went wrong "
     fi
}

getProjectStatus(){
    curl -s --header "PRIVATE-TOKEN: $3" "http://$2/api/v4/projects/$1/pipelines?ref=$4&order_by=updated_at&sort=desc"  > pipeline_list.txt
    ID=$(cat pipeline_list.txt | jq .[0].id)
    PIPELINE=$(curl -s --header "PRIVATE-TOKEN: $3" "http://$2/api/v4/projects/$1/pipelines/$ID" | jq)
    STATUS=$(echo $PIPELINE | jq -r .status)
    echo $PIPELINE > pipeline.txt
    echo $STATUS

}

evaluateBranch(){
    local STATUS=$(getProjectStatus $1 $3 $4 $5)

    echo -n "$5 branch semaphore is: "
    local SEMAPHORE=$(semaphoreStatus $STATUS)
    echo $SEMAPHORE "(status: $STATUS)"

    if [[ ${SEMAPHORE} == ${GREEN_LIGHT} ]]
        then
            GREEN_COLOR='\033[1;32m'
            NC='\033[0m' # No Color
            echo -e "\n${GREEN_COLOR}Semaphore is GREEN !!!"
            echo -e "You can go ahead and merge your branch now.\n"
            exit 0
    elif [[ ${SEMAPHORE} == ${YELLOW_LIGHT} ]]
        then
            YELLOW_COLOR='\033[1;33m'
            NC='\033[0m' # No Color

            PIPE=$(cat pipeline.txt)
            NAME=$(echo $PIPE | jq -r .user.name)
            USER_NAME=$(echo $PIPE | jq -r .user.username)
            STARTED_AT=$(echo $PIPE | jq -r .started_at)
            LINK=$(echo $PIPE | jq -r .web_url)

            echo -e "\n${YELLOW_COLOR}Semaphore is YELLOW !!!"
            echo -e "${YELLOW_COLOR}There is a running pipeline triggered by $NAME ($USER_NAME) on the $5 branch started at $STARTED_AT. Waiting for it to finish ...  ${NC}"
            if (( $2 < 1 )); then
                echo -e "${YELLOW_COLOR}\n>>> I'm tired of waiting."
                echo -e "${YELLOW_COLOR}>>> Check the $5 branch pipeline status at:"
                echo -e "${YELLOW_COLOR}>>> $LINK "
                echo -e "${YELLOW_COLOR}>>> and try again later when it is in a valid state ..."
                echo -e "${YELLOW_COLOR}>>> Valid $5 branch pipeline states for this project are: ${GREEN[@]}\n"
                exit 1
            else
                echo -e "${YELLOW_COLOR}Retrying $2 more times ...${NC}\n"
                sleep 60
                evaluateBranch $1 $(( $2 - 1 )) $3 $4 $5

            fi
    elif [[ ${SEMAPHORE} == ${RED_LIGHT} ]]
        then
            RED_COLOR='\033[0;31m'
            NC='\033[0m' # No Color
            echo -e "\n${RED_COLOR}Semaphore is RED !!!${NC}\n"

            PIPE=$(cat pipeline.txt)
            NAME=$(echo $PIPE | jq -r .user.name)
            USER_NAME=$(echo $PIPE | jq -r .user.username)
            LINK=$(echo $PIPE | jq -r .web_url)
            echo -e "${RED_COLOR}>>> More details at $LINK"
            echo -e "${RED_COLOR}>>> The pipeline of the $5 branch was broken at $NAME ($USER_NAME) commit"
            echo -e "${RED_COLOR}>>> You could ask this user to fix the $5 branch pipeline or fix it yourself (see instructions below)"
            echo -e "${RED_COLOR}>>> You cannot merge your branch until the $5 branch pipeline is fixed "
            echo -e "${RED_COLOR}>>> Valid $5 branch pipeline states for this project are: ${GREEN[@]} \n"
            
            echo -e "-----------------"
            echo -e "-----------------"
            echo -e "${RED_COLOR}\n>>> Alternatively if you're up for the challenge you can try to fix it yourself:"
            echo -e "${RED_COLOR}>>>>>> 1) investigate what is the reason that made the $5 branch pipeline to fail"
            echo -e "${RED_COLOR}>>>>>> 2) if the problem is infrastructure related then contact with DevOps"
            echo -e "${RED_COLOR}>>>>>> 3) if the problem is code related then identify the repository where you need to provide the fix"
            echo -e "${RED_COLOR}>>>>>> 4) create a branch named \"cdfix/<your-descriptive-fix-name-here>\" on the identified repository"
            echo -e "${RED_COLOR}>>>>>> 5) create a merge request from \"cdfix/<your-descriptive-fix-name-here>\" to $5"
            echo -e "${RED_COLOR}>>>>>> 6) ask your colleagues (and ping $NAME) to review and approve your fix. Merge it ASAP in order to unblock others that are in the same situation as you\n"
            echo -e "${RED_COLOR}>>>>>> 7) let $NAME know that now he owes you a beer for fixing his broken build :) "

            exit 1
    fi
}
