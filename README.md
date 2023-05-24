# Langston CLI Tools
Command Line Interface and scripts

# Installation

To install, download the `tar.gz` file and "extract" it on your computer. Typically, this is done simply by double clicking on the file you downloaded. Open the folder that was created (called `langston-cli-v1.x.x`) and `right-click` on the file named `install`. This should open up the Terminal. A warning may pop up asking you to confirm you want to run the file. Click Yes.

If everything goes well, you should see a message that says the installation was complete. 

To double-check, you can run this command

```shell
# Verify the installation
which langston
```

If you see a message that looks like `/Users/yourname/langston-cli/bin/langston`, then everything is set up correctly! 

# Use

```shell
# Install google auth proxy
langston auth-proxy install
```

# Developers

The following section is for developers

## Create a new release artifact

```shell
# Creates a tarball in the dist/ folder
rm -rf dist && mkdir -p dist && tar -zcvf dist/langston-cli.tar.gz --exclude-from=".archiveignore" .
```

## Extract the archive

```shell
# Unpack/extract the tarball into the langston-cli directory.
# Run this command from the location that the tarball was downloaded
mkdir -p langston-cli && tar -xzvf langston-cli.tar.gz -C langston-cli
```