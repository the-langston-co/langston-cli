#!/usr/bin/env zsh

# This is the local version
# This script downloads & installs the cli. If the cli is already installed, it will update it to the latest version.
# This is also the source of the script in Kandji to install langston-cli automatically

current_user=$(/usr/sbin/scutil <<<"show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ && ! /root/ && ! /_mbsetupuser/ { print $3 }' | /usr/bin/awk -F '@' '{print $1}')
CLI_DIR="/Users/$current_user/langston-cli"
DOWNLOAD_DIR="$CLI_DIR/downloads"

LOG_NAME="cli_download.log"
LOG_DIR="/Users/$current_user/langston-cli-tmp/logs"
LOG_PATH="$LOG_DIR/$LOG_NAME"
mkdir -p "${DOWNLOAD_DIR}"
mkdir -p "$LOG_DIR"
touch -a $LOG_PATH
cd "${DOWNLOAD_DIR}" || exit

echo "*********************************************************************"
echo " [$(date +"%Y-%m-%d_%H-%M-%S")] LANGSTON DOWNLOAD SCRIPT STARTING          "
echo " Running as user $(whoami)"
echo "*********************************************************************"
echo

logging() {
    # Logging function
    #
    # Takes in a log level and log string and logs to /Library/Logs/$script_name if a
    # LOG_PATH constant variable is not found. Will set the log level to INFO if the
    # first built-in $1 is passed as an empty string.
    #
    # Args:
    #   $1: Log level. Examples "info", "warning", "debug", "error"
    #   $2: Log statement in string format
    #
    # Examples:
    #   logging "" "Your info log statement here ..."
    #   logging "warning" "Your warning log statement here ..."
    log_level=$(printf "%s" "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    script_name="$(/usr/bin/basename "$0")"
    prefix=$(/bin/date +"[%b %d, %Y %Z %T $log_level]:")

    # see if a LOG_PATH has been set
    if [[ -z "${LOG_PATH}" ]]; then
        LOG_PATH="/Library/Logs/${script_name}"
    fi

    if [[ -z $log_level ]]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [[ -z $log_statement ]]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    # echo the same log statement to stdout
    /bin/echo "$prefix $log_statement"

    # send log statement to log file
    printf "%s %s\n" "$prefix" "$log_statement" >>"$LOG_PATH"

}

set_brew_prefix() {
    # Set the homebrew prefix.
    # Set the brew prefix to either the Apple Silicon location or the Intel location based on the
    # processor_brand information
    #
    # $1: proccessor brand information
    local brew_prefix

    if [[ $1 == *"Apple"* ]]; then
        # set brew prefix for apple silicon
        brew_prefix="/opt/homebrew"
    else
        # set brew prefix for Intel
        brew_prefix="/usr/local"
    fi

    # return the brew_prefix
    /bin/echo "$brew_prefix"
}


check_brew_install_status() {
    # Check brew install status.
    brew_path="$(/usr/bin/find /usr/local/bin /opt -maxdepth 3 -name brew 2>/dev/null)"

    if [[ -n $brew_path ]]; then
        # If the brew binary is found, just run brew update and exit
        logging "info" "Homebrew already installed at $brew_path..."
    else
        logging "info" "Homebrew is not installed..."
    fi
}


update_path() {
    # Add brew to current user PATH
    # Check for missing PATH
    get_path_cmd="$brew_prefix/bin/brew doctor 2>&1 | /usr/bin/grep 'export PATH=' | /usr/bin/tail -1"


    # get the shell dot rc file returned from the get_path_cmd command so that we know
    # which shell the current user is using.
    shell_rc_file=$(echo "$get_path_cmd" | awk '{print $5}' | awk -F '/' '{print $2}')
    logging "info" "user Shell RC file: ${shell_rc_file}"

    #update_pa Checking to see if the output returned from get_path_cmd contains the word homebrew and
    # also checking to see if brew is actually in the current user's path by runing the which
    # command.
    if echo "$get_path_cmd" | grep "homebrew" >/dev/null 2>&1 && ! /usr/bin/which brew >/dev/null 2>&1; then


        # Check the user's shell rc file to see if homebrew has already been added to the
        # user's PATH. If we find it in there already then there is no reason to write to that
        # file again.
        if ! /usr/bin/grep "$brew_prefix/bin" "/Users/$current_user/$shell_rc_file" >/dev/null 2>&1; then
            echo "Adding brew to user's PATH..."
            echo "Using command: $get_path_cmd"
            "${get_path_cmd}"

        else
            echo "brew path $brew_prefix/bin already in user's $shell_rc_file..."
        fi

    else
        logging "info" "brew already in user's PATH..."
    fi
}


#First, ensure homebrew is installed
echo "PATH=$PATH"
echo
echo
BREW_PATH="$(/usr/bin/find /usr/local/bin /opt -maxdepth 3 -name brew 2>/dev/null)"
processor_brand="$(/usr/sbin/sysctl -n machdep.cpu.brand_string)"
check_brew_install_status
brew_prefix=$(set_brew_prefix "$processor_brand")


echo "Current brew path is ${BREW_PATH}"
echo "Brew prefix is $brew_prefix"

update_path

if [ -x "$BREW_PATH" ] ; then
  echo "✅  Homebrew is already installed"
else
  echo "'brew' was not found... installing homebrew"
  NONINTERACTIVE=1 /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW_PATH=$(command -v brew)
  if [ -x "$BREW_PATH" ] ; then
    echo "✅  $(brew -v) installed successfully"
  else
    echo "❌  Failed to install homebrew"
    exit 1
  fi
fi

PATH_TO_JQ=$(command -v jq)
if [ -x "$PATH_TO_JQ" ] ; then
  echo "✅  jq already installed ($(jq --version))"
else
  echo "installing JQ..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install jq
  PATH_TO_JQ=$(command -v jq)
  if [ -x "$PATH_TO_JQ" ] ; then
    echo "✅  jq installed successfully ($(jq --version))"
  fi
fi

PATH_TO_JQ=$(command -v jq)
if ! [ -x "$PATH_TO_JQ" ] ; then
  echo "❌  jq is not installed, can not continue."
  exit 1
fi

PATH_TO_WGET=$(command -v wget)
if [ -x "$PATH_TO_WGET" ] ; then
  echo "✅  wget installed"
else
  echo "installing wget..."
#  echo "Please enter the password to your computer to perform the installation"
  brew install wget
  PATH_TO_WGET=$(command -v wget)
  echo
  echo "✅  wget installed"
fi

PATH_TO_WGET=$(command -v wget)
if ! [ -x "$PATH_TO_WGET" ] ; then
  echo "❌  wget is not installed, can not continue."
  exit 1
fi

RELEASES=$(curl -s --location 'https://api.github.com/repos/the-langston-co/langston-cli/releases')
DOWNLOAD_URL=$(jq -r ".[0].assets[0].browser_download_url" <<< "$RELEASES")
LATEST_VERSION=$(jq -r ".[0].tag_name" <<< "$RELEASES")
DOWNLOAD_FILENAME="langston-cli-${LATEST_VERSION}.tar.gz"
echo
echo "⏳  Downloading langston-cli from ${DOWNLOAD_URL}..."
echo
wget -O "$DOWNLOAD_FILENAME" "$DOWNLOAD_URL"

echo "Langston CLI downloaded from "

if [ -f "${DOWNLOAD_FILENAME}" ] ; then
  echo "✅  Downloaded langston-cli to ${DOWNLOAD_DIR}/${DOWNLOAD_FILENAME}"
  echo
else
  echo "❌  Failed to save file. Exiting."
  exit 1
fi
echo "Extracting files to ${CLI_DIR}..."
tar -xzvf "${DOWNLOAD_FILENAME}" -C ..

echo "🎉  Langston CLI setup finished."