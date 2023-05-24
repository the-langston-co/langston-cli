# langston-cli
Command Line Interface and scripts

```shell
# Install google auth proxy
./langston.sh install auth-proxy
```

## Create a new release artifact

```shell
# Creates a tarball in the dist/ folder
mkdir -p dist && tar -zcvf dist/langston-cli.tar.gz --exclude-from=".archiveignore" .
```

## Extract the archive

```shell
# Unpack/extract the tarball into the langston-cli directory.
# Run this command from the location that the tarball was downloaded
mkdir -p langston-cli && tar -xzvf langston-cli.tar.gz -C langston-cli
```