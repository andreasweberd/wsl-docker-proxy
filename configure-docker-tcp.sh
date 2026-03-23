#!/bin/bash
cat > /tmp/daemon.json << 'EOF'
{
  "hosts": [
    "unix:///var/run/docker.sock",
    "tcp://127.0.0.1:2375"
  ]
}
EOF
sudo cp /tmp/daemon.json /etc/docker/daemon.json
sudo service docker restart
echo "Docker configured"

