set -o nounset                                  # Treat unset variables as an error

checkJQ() {
  # jq test
  type jq >/dev/null 2>&1
  exitCode=$?
	
  if [ "$exitCode" -ne 0 ]; then
    printf "  ${red}'jq' not found! (json parser)\n${end}"
    printf "    Ubuntu Installation: sudo apt install jq\n"
    printf "    Redhat Installation: sudo yum install jq\n"
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

if [[ $( jq '.metadata' $pipelineJson ) == null  ]]
then
	echo 'metadata is missing in json file'
	exit 1
else
jq 'del(.metadata)' "$pipelineJson" > tmp.??.json && mv tmp.??.json "$pipelineJson"
fi

if [[ $( jq '.pipeline.version' $pipelineJson )  == null ]]
then
	echo 'version is missing in json file'
	exit 1
else
jq ".pipeline.version += 1" "$pipelineJson" > tmp.??.json && mv tmp.??.json "$pipelineJson"
fi

if [[ $branch != "" ]]
then
	foundBranch=$( jq '.pipeline.stages[] | select(.name=="Source") | .actions[] | select(.name=="Source") | .configuration.Branch' $pipelineJson  )
	if [[ $foundBranch  == null ]]
	then	
 	 	echo 'branch is missing in json file'
		exit 1
 	else
		jq --arg branch "$branch" '.pipeline.stages[] |= if .name == "Source" then .actions[] |= if .name == "Source" then .configuration.Branch = $branch else . end else . end' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	fi
fi

if [[ $owner != ""  ]]
then
	foundOwner=$( jq '.pipeline.stages[] | select(.name=="Source") | .actions[] | select(.name=="Source") | .configuration.Owner' $pipelineJson  )
	if [[ $foundOwner == null ]]
	then
		echo 'owner is missing in json file'
		exit 1
	else
		jq --arg owner "$owner" '.pipeline.stages[] |= if .name == "Source" then .actions[] |= if .name == "Source" then .configuration.Owner = $owner else . end else . end' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	fi
fi

if [[ $pollForSourceChanges != ""  ]]
then
	foundPollForSourceChanges=$( jq '.pipeline.stages[] | select(.name=="Source") | .actions[] | select(.name=="Source") | .configuration.PollForSourceChanges' $pipelineJson  )
	if [[ $foundPollForSourceChanges == null ]]
	then
		echo 'PollForSourceChanges is missing in json file'
		exit 1
	else
		jq --arg pollForSourceChanges "$pollForSourceChanges" '.pipeline.stages[] |= if .name == "Source" then .actions[] |= if .name == "Source" then .configuration.PollForSourceChanges = $pollForSourceChanges else . end else . end' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
	fi
fi

if [[ $configuration != ""  ]]
then
	jq --arg configuration  "$configuration" '.pipeline.stages[] |= if . then .actions[] |= if . then .configuration.EnvironmentVariables = $configuration else . end else .  end' "$pipelineJson" >tmp.$$.json && mv tmp.$$.json "$pipelineJson"
fi
