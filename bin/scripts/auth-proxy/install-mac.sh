#!/bin/zsh
echo
echo "Starting Mac install script..."

# CHECK IF ALREADY ON PATH
#if command -v cloud-sql-proxy &> /dev/null; then
#    echo 'cloud-sql-proxy is already installed'
#    exit
#fi

# Set the working directory to be the user's home directory
cd ~/
mkdir -p langston-cli
cd langston-cli
mkdir -p bin
cd bin

# Download the program based on the operating system
if [[ -f "cloud-sql-proxy" ]]; then
  echo "cloud-sql-proxy already downloaded to correct directory"
else
  if [[ $(uname -m) == 'arm64' ]]; then
    echo "Installing Google Auth Proxy for Apple Silicon"
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.3.0/cloud-sql-proxy.darwin.arm64
  else
    echo "Installing Google Auth Proxy for Intel chip"
    curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.3.0/cloud-sql-proxy.darwin.amd64
  fi
fi

 # Make the downloaded file executable
chmod +x cloud-sql-proxy
