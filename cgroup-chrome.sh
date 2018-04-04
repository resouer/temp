
# Create a new cgroup called `limitchrome` accessible by your user
sudo cgcreate -t $USER:$USER -a $USER:$USER  -g memory,cpuset:limitchrome
# Limit RAM to 1.5G roughly
echo 1600000000 | sudo tee /sys/fs/cgroup/memory/limitchrome/memory.limit_in_bytes
# Limit to CPUs 0 and 1 only
echo 0-1 | sudo tee /sys/fs/cgroup/cpuset/limitchrome/cpuset.cpus
# Manually set cpuset.mems
echo 0 | sudo tee /sys/fs/cgroup/cpuset/limitchrome/cpuset.mems
# Run chrome in this cgroup
cgexec -g memory,cpuset:limitchrome /opt/google/chrome/google-chrome --profile-directory=Default
# Delete the cgroup (not required)
sudo cgdelete -g memory,cpuset:limitchrome
