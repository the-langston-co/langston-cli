#!/bin/bash

echo "Configuring CLI"

INSTALL_DIR="$HOME/langston-cli"
LANGSTON_BIN="$INSTALL_DIR/bin"
CURRENT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CLI_ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../.. && pwd )

echo
echo "Copying files to $INSTALL_DIR from $CURRENT_DIR..."
# Copy files to the install directory, ignoring files in .cliignore
mkdir -p "$INSTALL_DIR"
rsync -a --exclude-from="$CLI_ROOT/.cliignore" --exclude "$CLI_ROOT/install.sh" "$CLI_ROOT/" "$INSTALL_DIR"

PATH_TO_EXECUTABLE=$(which langston)
if [ -x "$PATH_TO_EXECUTABLE" ] ; then
  echo "langston-cli is installed here: $PATH_TO_EXECUTABLE"
  exit
fi

if [[ ":$PATH:" == *":$LANGSTON_BIN:"* ]]; then
  echo "Your path correctly includes \"$LANGSTON_BIN\""
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
#    source ~/.zshrc
  fi
elif [[ $SHELL == '/bin/bash' ]]; then
   touch -a ~/.bash_profile
   if grep -q "LANGSTON-CLI" ~/.bash_profile; then
      echo "Path already exported"
  else
    echo "Adding Langston CLI to .bash_profile"
    echo -e '\n#FROM LANGSTON-CLI' >> ~/.bash_profile
    echo -e "export PATH=${LANGSTON_BIN}:\$PATH" >> ~/.bash_profile
    #  source ~/.bash_profile
  fi
else
  echo "Using unknown shell"
fi

# Add new bin to current path
PATH="${LANGSTON_BIN}:\$PATH"


PATH_TO_EXECUTABLE=$(which langston)
if [ -x "$PATH_TO_EXECUTABLE" ] ; then
  echo "langston successfully is installed to: $PATH_TO_EXECUTABLE"
  exit
else
  echo
  echo "******************************************************************************"
  echo " langston-cli failed to install correctly. Please reach out for assistance. "
  echo "******************************************************************************"
  echo
  exit 1
fi
