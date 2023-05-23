#!/bin/bash
echo
echo "Starting Mac install script..."

if command -v cloud-sql-proxy &> /dev/null; then
    echo 'cloud-sql-proxy is already installed'
    exit
fi

if [[ $(uname -m) == 'arm64' ]]; then
  echo "Installing Google Auth Proxy for Apple Silicon"
else
  echo "Installing Google Auth Proxy for Intel chip"
fi