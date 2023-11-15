# Langston CLI Tools
Command Line Interface for Langston employees

<!-- toc -->

- [Installation](#installation)
- [Quickstart](#quickstart)
- [Commands & Usage](#commands--usage)
  * [Update the CLI](#update-the-cli)
  * [Google Cloud SQL Auth Proxy](#google-cloud-sql-auth-proxy)
    + [Install cloud-sql-proxy](#install-cloud-sql-proxy)
    + [Start a connection to stage/prod](#start-a-connection-to-stageprod)
    + [Check DB connection status](#check-db-connection-status)
    + [Shut down a connection](#shut-down-a-connection)
- [Developers](#developers)
  * [Create a new release & upload files](#create-a-new-release--upload-files)
  * [Release internals tools](#release-internals-tools)
    + [Create a new release artifact](#create-a-new-release-artifact)
    + [Extract the archive](#extract-the-archive)
  * [Update the TOC in this README](#update-the-toc-in-this-readme)

<!-- tocstop -->

# Installation

To install, visit the [Releases](https://github.com/the-langston-co/langston-cli/releases) page and on the latest release, download the `tar.gz` file and "extract" it on your computer. 
Typically, this is done simply by double-clicking on the file you downloaded. Open the folder that was created (called `langston-cli-v1.x.x`) and `right-click` on the file named `install`. This should open up the Terminal. A warning may pop up asking you to confirm you want to run the file. Click Yes.

If everything goes well, you should see a message that says the installation was complete. 

To double-check, you can run this command

```shell
# Verify the installation
which langston
```

If you see a message that looks like `/Users/yourname/langston-cli/bin/langston`, then everything is set up correctly! 

_Note: a new directory will be created in the "Home" directory on your computer called `langston-cli`_. 

# Quickstart

Once the cli is installed, run the following commands to install additional tools & authenticate.

1. `langston auth <ENV>` - where ENV=stage|prod. For most users, you should only need to authenticate with Prod. This command will prompt you for a password which can be found in the Langston 1Password vault, or you can get it from a developer. Note: this password is the one that the Langston API requires in order to return the DB Service Account.
2. `langston db install` - installs the necessary dependencies to run `cloud-sql-proxy` to connect to our cloud database(s). 
3. `langston db start <ENV>` - Starts a new connections
4. `langston db status all` - Check the status of all of your DB connections
5. `langston db stop <ENV>` - Terminates a DB connection.


# Commands & Usage

## Update the CLI

To check for updates and upgrade the cli, run the following command (available on version v1.2.1 and later)

```shell
langston update
```

This will check the GitHub releases page and compare the latest version against the current CLI version. If the version is different, it will ask the user if they want to upgrade now. 

## Google Cloud SQL Auth Proxy

### Install cloud-sql-proxy

```shell
# Install google auth proxy
langston db install
```

### Start a connection to stage/prod

```shell
# ENV = stage|prod
langston db start <ENV>
```

### Check DB connection status

```shell
# ENV = all|stage|prod
langston db check <ENV>
```

### Shut down a connection

Terminates a `cloud-sql-proxy` connection to a given environment. 

```shell
# ENV = stage|prod 
langston db stop <ENV>
```

# Developers

The following section is for developers

## Create a new release & upload files

The

## Release internals tools

To create a new "Release" in GitHub with the bundled CLI code, simply run `./release.sh <NEW_VERSION>` from the root of this project where <NEW_VERSION> is in the format `vX.X.X`. 
This command does the following :
1. Authenticates the GitHub CLI using 1Password (note: this is configured to work on Neil's machine only at the moment using the ID of the vault entry that contains the GH Personal Access Token). Alternatively, this may be modified to take in a GH_TOKEN environment variable. 
2. Validates the proposed version is in the correct format.
3. Runs the `./bundle.sh` script that creates the langston cli archive in `dist/langston-cli-vX.X.X.tar.gz`. 
4. Creates a new GH release using the GitHub commandline: `gh release create ...`. This also uploads the created archive. 

### Create a new release artifact

Run the `bundle.sh` command. Optionally provide the version as the first argument. This will update the version in the `resources/VERSION.txt` file as well as tag the commit in git.

```shell
# Bundle the code and update the version. Version is optional.
./bundle.sh vX.X.X
```

The file will be created at `dist/langston-cli-${VERSION}.tar.gz`. Each time you run the above command, the contents of `dist/` will be emptied prior to the new archive being created.

### Extract the archive 

Here's an example of extracting the archive from the command line. 

```shell
# Unpack/extract the tarball into the langston-cli directory.
# Run this command from the location that the tarball was downloaded
mkdir -p langston-cli && tar -xzvf langston-cli.tar.gz -C langston-cli
```

## Update the TOC in this README

Run the following command to automatically update the table of contents (TOC) of this README.md. Enter `y` when prompted to proceed with writing to file.

```shell
npx markdown-toc -i README.md 
```