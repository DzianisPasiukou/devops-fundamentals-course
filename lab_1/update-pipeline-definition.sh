#!/bin/bash -
#===============================================================================
#
#          FILE: update-pipeline-definition.sh
#
#         USAGE: ./update-pipeline-definition.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/15/2023 10:12:08 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error

checkJQ() {
  # jq test
  type jq >/dev/null 2>&1
  exitCode=$?
	jqDependency=1
	
  if [ "$exitCode" -ne 0 ]; then
    printf "  ${red}'jq' not found! (json parser)\n${end}"
    printf "    Ubuntu Installation: sudo apt install jq\n"
    printf "    Redhat Installation: sudo yum install jq\n"
    jqDependency=0
  fi

  if [ "$jqDependency" -eq 0 ]; then
    printf "${red}Missing 'jq' dependency, exiting.\n${end}"
    exit 1
  fi
}

checkJQ

pipelineJson=$1
branch=''
owner=''
configuration=''
pollForSourceChanges=''

for (( i=2; i<=$#; i++  ))
do
	j=$((i+1))
	case ${!i} in
		--branch)
			branch=${!j}
			;;
		--owner)
			owner=${!j}
			;;
		--configuration)
			configuration=${!j}
			;;
		--poll-for-source-changes)
			pollForSourceChanges=${!j}
	esac
done

jq 'del(.metadata)' "$pipelineJson" > tmp.??.json && mv tmp.??.json "$pipelineJson"

if [[ $( jq '.pipeline.version' $pipelineJson )  == null ]]
then
	echo 'version is missing in json file'
	exit 1
else
nextVersion=$( jq '.pipeline.version+1' $pipelineJson )
jq --arg nextVersion $nextVersion ".* { pipeline: { version: $nextVersion } }" "$pipelineJson" > tmp.??.json && mv tmp.??.json "$pipelineJson"
fi

if [[ $branch != ""  ]]
then
	if [[ $( jq '.pipeline.stages[0].actions[0].configuration.Branch' $pipelineJson )  == null ]]
	then	
 	 	echo 'branch is missing in json file'
		exit 1
 	else
		jq --arg branchName "$branch" '.pipeline.stages[0].actions[0].configuration.Branch = $branchName' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	fi
else
	echo '--branch arg is missed'
fi

if [[ $owner != ""  ]]
then
	if [[ $( jq '.pipeline.stages[0].actions[0].configuration.Owner' $pipelineJson )  == null ]]
	then
		echo 'owner is missing in json file'
		exit 1
	else
		jq --arg owner "$owner" '.pipeline.stages[0].actions[0].configuration.Owner = $owner' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	fi
else
	echo '--owner arg is missed'
fi

if [[ $pollForSourceChanges != ""  ]]
then
	if [[ $( jq '.pipeline.stages[0].actions[0].configuration.PollForSourceChanges' $pipelineJson )  == null ]]
	then
		echo 'PollForSourceChanges is missing in json file'
		exit 1
	else
		jq --arg pollForSourceChanges "$pollForSourceChanges" '.pipeline.stages[0].actions[0].configuration.PollForSourceChanges = $pollForSourceChanges' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	fi
else
	echo '--poll-for-source-changes arg is missed'
fi

if [[ $configuration != ""  ]]
then
stages=$( jq '.pipeline.stages' $pipelineJson )
stagesLength=$( jq '.pipeline.stages | length' $pipelineJson )

for (( i=0; i<$stagesLength; i++ ))
do
	currentStage=$(echo $stages | jq --arg i $i '.[$i|tonumber]')
	actionsLength=$(echo $currentStage | jq '.actions | length' )
	for (( j=0; j < $actionsLength; j++ ))
	do
		jq --arg configuration "$configuration" --arg i "$i" --arg j "$j"  '.pipeline.stages[$i|tonumber].actions[$j|tonumber].configuration.EnvironmentVariables = $configuration' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	done
done
else
	echo '--configuration arg is missed'
fi


