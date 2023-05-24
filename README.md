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