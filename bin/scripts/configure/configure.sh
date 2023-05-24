#!/bin/bash

echo "Configuring CLI"

LANGSTON_BIN="$HOME/langston-cli/bin"
CURRENT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CLI_ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && cd ../../.. && pwd )

echo
echo "Copying files to $HOME/langston-cli..."
# Copy files to the home directory, ignoring files in .cliignore
rsync -aq --exclude-from="$CLI_ROOT/.cliignore" --exclude "$CLI_ROOT/install.sh" "$CLI_ROOT" "$HOME"

path_to_executable=$(which langston)
if [ -x "$path_to_executable" ] ; then
  echo "langston-cli is installed here: $path_to_executable"
  exit
fi

if [[ ":$PATH:" == *":$LANGSTON_BIN:"* ]]; then
  echo "Your path correctly includes \"$LANGSTON_BIN\""
  exit
fi

if [[ $SHELL == '/bin/zsh' ]]; then
  if grep -q "LANGSTON-CLI" ~/.zshrc; then
    echo "Path already exported"
  else
    echo "Adding Langston CLI to .zshrc"
    touch -a ~/.zshrc
    echo -e '\n#FROM LANGSTON-CLI' >> ~/.zshrc
    echo -e "export PATH=${LANGSTON_BIN}:\$PATH" >> ~/.zshrc
#    source ~/.zshrc
  fi
elif [[ $SHELL == '/bin/bash' ]]; then
   if grep -q "LANGSTON-CLI" ~/.bash_profile; then
      echo "Path already exported"
  else
    echo "Adding Langston CLI to .bash_profile"
    touch -a ~/.bash_profile
    echo -e '\n#FROM LANGSTON-CLI' >> ~/.bash_profile
    echo -e "export PATH=${LANGSTON_BIN}:\$PATH" >> ~/.bash_profile
    #  source ~/.bash_profile
  fi
else
  echo "Using unknown shell"
fi

# Add new bin to current path
PATH="${LANGSTON_BIN}:\$PATH"


path_to_executable=$(which langston)
if [ -x "$path_to_executable" ] ; then
  echo "langston successfully is installed to: $path_to_executable"
  exit
else
  echo "langston-cli failed to install correctly. Please reach out for assistance."
  exit 1
fi
