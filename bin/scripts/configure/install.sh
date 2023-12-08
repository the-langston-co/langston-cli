#!/bin/zsh
current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')
INSTALL_DIR="/Users/$current_user/langston-cli"
LANGSTON_BIN="$INSTALL_DIR/bin"
CURRENT_DIR=$(dirname $0)
CLI_ROOT="$CURRENT_DIR/../../.."

echo
echo "Installing Langston CLI"
echo
echo "Copying files..."
echo

# Copy files to the install directory, ignoring files listed in .cliignore
mkdir -p "$INSTALL_DIR"
rsync -a --exclude-from="$CLI_ROOT/.cliignore" --exclude "$CLI_ROOT/install.sh" "$CLI_ROOT/" "$INSTALL_DIR"

echo "✅  Files copied successfully to $INSTALL_DIR"

BREW_PATH=$(which brew)
if [ -x "$BREW_PATH" ] ; then
  echo "✅  Homebrew is already installed"
else
  echo "installing homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo "✅  Homebrew installed successfully"
fi

PATH_TO_JQ=$(which jq)
if [ -x "$PATH_TO_JQ" ] ; then
  echo "✅  jq installed"
else
  echo "installing JQ..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install jq
  echo "✅  jq installed"
fi


PATH_TO_EXECUTABLE=$(which langston)
if [ -x "$PATH_TO_EXECUTABLE" ] ; then
  echo "✅  langston-cli is installed here: $PATH_TO_EXECUTABLE"
  exit
fi

if [[ ":$PATH:" == *":$LANGSTON_BIN:"* ]]; then
  echo "✅  Your path correctly includes \"$LANGSTON_BIN\""
  exit
fi

if [[ $SHELL == '/bin/zsh' ]]; then
  touch -a ~/.zshrc
  if grep -q "LANGSTON-CLI" ~/.zshrc; then
    echo "Path already exported"
  else
    echo "Adding Langston CLI to .zshrc"
    echo -e '\n#FROM LANGSTON-CLI' >> ~/.zshrc
    echo -e "export PATH=${LANGSTON_BIN}:\$PATH" >> ~/.zshrc
  fi
elif [[ $SHELL == '/bin/bash' ]]; then
   touch -a ~/.bash_profile
   if grep -q "LANGSTON-CLI" ~/.bash_profile; then
      echo "Path already exported"
  else
    echo "Adding Langston CLI to .bash_profile"
    echo -e '\n#FROM LANGSTON-CLI' >> ~/.bash_profile
    echo -e "export PATH=${LANGSTON_BIN}:\$PATH" >> ~/.bash_profile
  fi
else
  echo "Using unknown shell"
fi

# Add new bin to current path
PATH="${LANGSTON_BIN}:\$PATH"

PATH_TO_EXECUTABLE=$(which langston)
if [ -x "$PATH_TO_EXECUTABLE" ] ; then
  echo "✅  langston successfully is installed to: $PATH_TO_EXECUTABLE"
  exit
else
  echo
  echo "******************************************************************************"
  echo " langston-cli failed to install correctly. Please reach out for assistance. "
  echo "******************************************************************************"
  echo
  exit 1
fi
