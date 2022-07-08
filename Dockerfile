ARG build_version="golang:1.16-buster"
ARG build_type="package"
ARG prysm_version=v2.0.6

# TODO: readd build/install from source conditional

# ----- Stage: package install -----
FROM debian:buster as builder-package

ARG prysm_version

RUN apt update && apt install --yes --no-install-recommends curl ca-certificates apt-transport-https gnupg2 curl

WORKDIR /tmp/bin
RUN curl --fail -L https://github.com/prysmaticlabs/prysm/releases/download/${prysm_version}/beacon-chain-${prysm_version}-linux-amd64 > /tmp/bin/beacon-chain
RUN curl --fail -L https://github.com/prysmaticlabs/prysm/releases/download/${prysm_version}/validator-${prysm_version}-linux-amd64 > /tmp/bin/validator
RUN chmod +x /tmp/bin/beacon-chain /tmp/bin/validator

FROM builder-${build_type} as build-condition

# ******* Stage: base ******* #
FROM debian:buster as base

RUN apt update && apt install --yes --no-install-recommends \
    ca-certificates \
    curl \
	cron \
    python3-pip \
    tini \
	apt-transport-https gnupg2 \
    # apt cleanup
	&& apt-get autoremove -y; \
	apt-get clean; \
	update-ca-certificates; \
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

WORKDIR /docker-entrypoint.d
COPY entrypoints /docker-entrypoint.d
COPY scripts/entrypoint.sh /usr/local/bin/prysm-entrypoint

COPY scripts/prysm-helper.py /usr/local/bin/prysm-helper
RUN chmod 775 /usr/local/bin/prysm-helper

RUN pip3 install click requests pyaml

COPY --from=build-condition /tmp/bin/beacon-chain /usr/local/bin/
COPY --from=build-condition /tmp/bin/validator /usr/local/bin/

RUN  chmod +x /usr/local/bin/beacon-chain /usr/local/bin/validator

ENTRYPOINT ["prysm-entrypoint"]

# ******* Stage: testing ******* #
FROM base as test

ARG goss_version=v0.3.16

RUN curl -fsSL https://goss.rocks/install | GOSS_VER=${goss_version} GOSS_DST=/usr/local/bin sh

WORKDIR /test

COPY test /test

ENV NOLOAD_CONFIG=1

CMD ["goss", "--gossfile", "/test/goss.yaml", "validate"]

# ******* Stage: release ******* #
FROM base as release

ARG version=0.1.1

LABEL 01labs.image.authors="zer0ne.io.x@gmail.com" \
	01labs.image.vendor="O1 Labs" \
	01labs.image.title="0labs/prysm" \
	01labs.image.description="Official Golang implementation of the Ethereum 2.0 protocol." \
	01labs.image.source="https://github.com/0x0I/container-file-prysm/blob/${version}/Dockerfile" \
	01labs.image.documentation="https://github.com/0x0I/container-file-prysm/blob/${version}/README.md" \
	01labs.image.version="${version}"

# ORDER: 1. beacon-chain, 2. validator
#      p2p/tcp  p2p/udp  rpc  http-api  json-rpc   metrics
#        ↓         ↓      ↓       ↓         ↓         ↓
EXPOSE 13000    12000   4000    3501       3500      8080
EXPOSE                  7000               7500      8081

CMD ["beacon-chain", "--accept-terms-of-use"]

# ******* Stage: tools ******* #

FROM base as build-tools

ARG prysm_version

WORKDIR /tmp/bin
RUN curl --fail -L "https://github.com/prysmaticlabs/prysm/releases/download/${prysm_version}/client-stats-${prysm_version}-linux-amd64" > /tmp/bin/client-stats

RUN cp /tmp/bin/client-stats /usr/local/bin && chmod +x /usr/local/bin/client-stats

CMD ["/bin/bash"]
