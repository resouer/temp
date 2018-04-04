# Create a new cgroup called `limitsublime` accessible by your user
sudo cgcreate -t $USER:$USER -a $USER:$USER  -g memory,cpuset:limitsublime
# Limit RAM to 1.5G roughly
echo 4000000000 | sudo tee /sys/fs/cgroup/memory/limitsublime/memory.limit_in_bytes
# Limit to CPUs 0 and 1 only
echo 2-3 | sudo tee /sys/fs/cgroup/cpuset/limitsublime/cpuset.cpus
# Manually set cpuset.mems
echo 0 | sudo tee /sys/fs/cgroup/cpuset/limitsublime/cpuset.mems
# Run sublime in this cgroup
cgexec -g memory,cpuset:limitsublime /opt/sublime_text/sublime_text --profile-directory=Default
# Delete the cgroup (not required)
sudo cgdelete -g memory,cpuset:limitsublime
