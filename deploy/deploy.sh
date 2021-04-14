#! /bin/bash

## create pwcli wrapper to run the pwcli container interactively

rm -f /usr/local/bin/pwcli

cat > /usr/local/bin/pwcli << EOF
#!/usr/bin/env bash
#
#  A script wrapper for running the docker image pwcli interactively
#

docker_img="brtlvrs/pwcli:latest"

docker run --rm -it \\
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \\
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \\
  -v $(pwd):/pwsh \\
  \$docker_img pwsh "$@"
EOF

chmod +x /usr/local/bin/pwcli
