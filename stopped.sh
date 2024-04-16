# Get the start timestamp
start_time=$(date +%s)

# Get a list of all stopped or stopping instances
instance_names=$(aws lightsail get-instances | jq -r '.instances[] | select(.state.name == "stopped" or .state.name == "stopping") | .name')

# For each instance in the list, start it using xargs
echo "$instance_names" | xargs --no-run-if-empty -P 2 -I {} bash -c '
  instance="{}"
  echo "Starting instance: $instance"
  
  # Check instance state
  state=$(aws lightsail get-instance-state --instance-name $instance --query '"'state.name'"' --output text)
  
  # If instance is not stopped, wait for it to stop before starting it
  while [ "$state" != "stopped" ]
  do
    echo "Waiting for instance: $instance to stop"
    sleep 5
    state=$(aws lightsail get-instance-state --instance-name $instance --query '"'state.name'"' --output text)
  done
  
  # Start instance
  aws lightsail start-instance --instance-name $instance
'

# Wait for 5 seconds
sleep 5s

# Fetch names of all instances
instance_names=$(aws lightsail get-instances | jq -r '.instances[] | .name')

# Display instance names and public IP addresses sorted in order
aws lightsail get-instances --query "instances[*].[name, publicIpAddress]" --output json | jq -r '.[] | @tsv' | sort

# Get the end timestamp
end_time=$(date +%s)

# Calculate the time elapsed
elapsed_time=$(($end_time-$start_time))

echo "Total execution time: $elapsed_time seconds."
