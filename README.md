# Langston CLI Tools
Command Line Interface for Langston employees

<!-- toc -->

- [Installation](#installation)
- [Commands & Usage](#commands--usage)
- [Developers](#developers)
  * [Create a new release artifact](#create-a-new-release-artifact)
  * [Extract the archive](#extract-the-archive)

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

# Commands & Usage

```shell
# Install google auth proxy
langston auth-proxy install
```

# Developers

The following section is for developers

## Create a new release artifact

Run the `bundle.sh` command. Optionally provide the version as the first argument. This will update the version in the `resources/VERSION.txt` file as well as tag the commit in git.

```shell
# Bundle the code and update the version. Version is optional.
./bundle.sh vX.X.X
```

The file will be created at `dist/langston-cli-${VERSION}.tar.gz`. Each time you run the above command, the contents of `dist/` will be emptied prior to the new archive being created.

## Extract the archive

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