FROM ubuntu:22.04

LABEL friedrichkurz.me/project=devspace-ssh

SHELL ["/bin/bash", "-c"]

ENV PYTHON_VERSION=3.10
ENV PIP_VERSION=24.0

RUN <<EOF
set -e
# -- Add non root user -- #
addgroup --gid 1000 dev 
adduser --uid 1000 --gid 1000 --disabled-password dev
EOF

USER dev

ENTRYPOINT ["/bin/bash", "-c"]
