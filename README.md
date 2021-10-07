<p><img src="https://avatars1.githubusercontent.com/u/12563465?s=200&v=4" alt="OCI logo" title="oci" align="left" height="70" /></p>
<p><img src="https://prysmaticlabs.com/assets/PrysmStripe.png" alt="Prysm logo" title="prysm" align="right" height="60" /></p>

Container File :stars: :link: Prysm
=========
![GitHub release (latest by date)](https://img.shields.io/github/v/release/0x0I/container-file-prysm?color=yellow)
[![0x0I](https://circleci.com/gh/0x0I/container-file-demo.svg?style=svg)](https://circleci.com/gh/0x0I/container-file-demo)
[![Docker Pulls](https://img.shields.io/docker/pulls/0labs/demo?style=flat)](https://hub.docker.com/repository/docker/0labs/demo)
[![License: MIT](https://img.shields.io/badge/License-MIT-blueviolet.svg)](https://opensource.org/licenses/MIT)

Configure and operate Prysm: A full-featured client for the Ethereum 2.0 protocol, written in Go

**Overview**
  - [Setup](#setup)
    - [Build](#build)
    - [Config](#config)
  - [Operations](#operations)
  - [Examples](#examples)
  - [License](#license)
  - [Author Information](#author-information)

#### Setup
--------------
Guidelines on running service containers are available and organized according to the following software & machine provisioning stages:
* _build_
* _config_
* _operations_

#### Build

##### targets

| Name  | description |
| ------------- | ------------- |
| `builder` | image state following build of prysm binary/artifacts |
| `test` | image containing test tools, functional test cases for validation and `release` target contents |
| `release` | minimal resultant image containing service binaries, entrypoints and helper scripts |
| `tool` | setup consisting of all prysm utilities, helper tooling and `release` target contents |

```bash
docker build --target <target> -t <tag> .
```

#### Config

:page_with_curl: Configuration of the `prysm` client can be expressed in a config file written in [YAML](https://yaml.org/), a minimal markup format, used as an alternative to passing command-line flags at runtime. Guidance on and a list of configurable settings can be found [here](https://docs.prylabs.network/docs/prysm-usage/parameters/#loading-parameters-via-a-yaml-file).

_The following variables can be customized to manage the location and content of this YAML configuration:_

`$PRYSM_CONFIG_DIR=</path/to/configuration/dir>` (**default**: `/etc/prysm`)
- container path where the `prysm` YAML configuration should be maintained

  ```bash
  PRYSM_CONFIG_DIR=/mnt/etc/geth
  ```

`$CONFIG_<setting> = <value (string)>` **default**: *None*

- Any configuration setting/value key-pair supported by `prysm` should be expressible and properly rendered within the associated YAML config.

    `<setting>` -- represents a YAML config setting:
    ```bash
    # [YAML Setting 'pyrmont']
    CONFIG_pyrmont=<value>
    ```

    `<value>` -- represents setting value to configure:
    ```bash
    # [YAML Setting 'pyrmont']
    # Setting: pyrmont
    # Value: true
    CONFIG_pyrmont=true
    ```

_Additionally, the content of the YAML configuration file can either be pregenerated and mounted into a container instance:_

```bash
$ cat custom-config.yml
mainnet: true
datadir: "/mnt/data"
http-web3provider: "https://mainnet.infura.io/v3/YOUR-PROJECT-ID"

# mount custom config into container
$ docker run --mount type=bind,source="$(pwd)"/custom-config.yml,target=/tmp/config.yml 0labs/prysm:latest beacon-chain --config-file /tmp/config.yml
```

_...or developed from both a mounted config and injected environment variables (with envvars taking precedence and overriding mounted config settings):_

```bash
$ cat custom-config.yml
mainnet: true
datadir: "/mnt/data"
http-web3provider: "https://mainnet.infura.io/v3/YOUR-PROJECT-ID"

# mount custom config into container
$ docker run -it --env PRYSM_CONFIG_DIR=/tmp/prysm --env CONFIG_datadir=/new/data/dir --env CONFIG_accept-terms-of-use=true \
  --mount type=bind,source="$(pwd)"/custom-config.yml,target=/tmp/prysm/config.yml \
  0labs/prysm:latest beacon-chain --config /tmp/prysm/config.yml
```

_Moreover, see [here](https://docs.prylabs.network/docs/prysm-usage/parameters/) for a list of supported flags to set as runtime command-line flags._

```bash
# connect to Prater Eth2 testnet and automatically accept the terms of use agreement 
docker run 0labs/prysm:latest beacon-chain --prater --accept-terms-of-use
```

**Also, note:** as indicated in the linked documentation, CLI flags generally translate into configuration settings by removing the preceding `--` flag marker.

_...and reference below for network/chain identification and communication configs:_ 

###### port mappings

| Port  | mapping description | type | config setting | command-line flag |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| `13000`    | The port used by libp2p | *TCP*  | `p2p-tcp-port` | `--p2p-tcp-port` |
| `12000`    | The port used by discv5 | *UDP*  | `p2p-udp-port` | `--p2p-udp-port` |
| `4000`    | RPC port exposed by a beacon node | *TCP*  | `rpc-port` | `--rpc-port` |
| `3500`    | The port on which the gateway server runs on | *TCP*  | `grpc-gateway-port` | `--grpc-gateway-port` |
| `8080`    | Port used to listen and respond to beacon node metrics request for Prometheus | *TCP*  | `monitoring-port` | `--monitoring-port` |
| `7500`    | Enable gRPC gateway for validator JSON requests | *TCP*  | `grpc-gateway-port` | `--grpc-gateway-port ` |
| `7000`    | RPC port exposed by a validator client | *TCP*  | `rpc-port` | `--rpc-port` |
| `8081`    | Port used to listen and respond to validator metrics request for Prometheus | *TCP*  | `monitoring-port` | `--monitoring-port` |

###### chain id mappings

| name | config setting (Eth : NetworkId) | command-line flag |
| :---: | :---: | :---: |
| Mainnet | 1 | `--mainnet` |
| Goerli | 5 | `--goerli` |

**note:** only Eth1 web3 providers connected to either Mainnet or the Goerli testnet are supported currently.

see [chainlist.org](https://chainlist.org/) for a complete list


#### Operations

:flashlight: To assist with managing a `prysm` client and interfacing with the *Ethereum 2.0* network, the following utility functions have been included within the image. *Note:* all tool command-line flags can alternatively be expressed as container runtime environment variables, as described below.

##### Setup deposit accounts and tooling

Download Eth2 deposit CLI tool and setup validator deposit accounts.

`$SETUP_DEPOSIT_CLI=<boolean>` (**default**: `false`)
- whether to download the Eth 2.0 deposit CLI maintained at https://github.com/ethereum/eth2.0-deposit-cli

`$DEPOSIT_CLI_VERSION=<string>` (**default**: `v1.2.0`)
- version of the Eth 2.0 deposit CLI to download

`$ETH2_CHAIN=<string>` (**default**: `mainnet`)
- Ethereum 2.0 chain to register deposit validator accounts and keystores for

`$SETUP_DEPOSIT_ACCOUNTS=<boolean>` (**default**: `false`)
- whether to automatically setup Eth 2.0 validator depositor accounts ([see](https://github.com/ethereum/eth2.0-deposit-cli#step-2-create-keys-and-deposit_data-json) for more details)

`$DEPOSIT_DIR=<path>` (**default**: `/var/tmp/deposit`)
- container directory to generate Eth 2.0 validator deposit keystores

`$DEPOSIT_MNEMONIC_LANG=<string>` (**default**: `english`)
- language to generate deposit mnemonic in 

`$DEPOSIT_NUM_VALIDATORS=<int>` (**default**: `1`)
- count of Eth 2.0 validator deposit keystores to generate

`$DEPOSIT_KEY_PASSWORD=<string>` (**default**: `passw0rd`)
- validator deposit keystore password associated with generated mnemonic

A *validator_keys* directory containing deposit data and the generated validator deposit keystore(s) will be created at the `DEPOSIT_DIR` path.

```bash
ls /var/tmp/deposit/validator_keys
  deposit_data-1632777614.json  keystore-m_12381_3600_0_0_0-1632777613.json
```


##### Backup beacon-chain node or validator databases

Backup node chain and validator databases using the `/db/backup` API.

```
$ prysm-helper status backup-db --help
Usage: prysm-helper status backup-db [OPTIONS]

  Backup Prysm beacon-chain node or validator databases (see for details:
  https://docs.prylabs.network/docs/prysm-usage/database-backups/)

Options:
  --host-addr TEXT  Prysm Eth2 metrics host address in format
                    <protocol(http/https)>://<IP>:<port>  [default:
                    (http://localhost:8080)]
  --help            Show this message and exit.
```

`$BACKUP_HOST_ADDR=<url>` (**default**: `http://localhost:8080`)
- Prysm Eth2 metrics host address in format <protocol(http/https)>://<IP>:<port>

`$AUTO_BACKUP_DB=<boolean>` (**default**: `false`)
- whether to automatically execute database backups based on `$BACKUP_INTERVAL`

`$BACKUP_INTERVAL=<cron-schedule>` (**default**: `0 */6 * * * (every 6 hours)`)
- database backup frequency based on a cron schedule


##### Import beacon-chain or validator node database backup

Import backed-up database to designated container/host data location.

```
$ prysm-helper status import-db-backup --help
Usage: prysm-helper status import-db-backup [OPTIONS]

  Import Prysm beacon-chain or validator Backup Prysm beacon-chain node or
  validator databases (see for details:
  https://docs.prylabs.network/docs/prysm-usage/database-backups/)

Options:
  --backup-path TEXT         path of backup prysm service database  [default:
                             (/root/.eth2/backups/)]
  --restore-target-dir TEXT  Directory to restore imported database backup to
                             [default: (/root/.eth2)]
  --service TEXT             prysm service database to backup  [default:
                             (beacon-chain)]
  --help                     Show this message and exit.
```

`$IMPORT_BACKUP_DB=<string>` (**default**: `false`)
- whether to automatically import a beacon-chain or validator node database on launch

`$BACKUP_SERVICE=<string>` (**default**: `beacon-chain`)
- service (beacon-chain or validator) database to backup

`$BACKUP_PATH=<string>` (**default**: `/tmp/backups`)
- path of backup Prysm service database to import

`$RESTORE_DIR=<string>` (**default**: `/root/.ethereum/keystore`)
- directory to restore imported database backup to


##### Query Ethereum standard Beacon API

Execute a RESTful Ethereum Beacon HTTP API request.

```
$ prysm-helper status api-request --help
Usage: prysm-helper status api-request [OPTIONS]

  Execute RESTful API HTTP request

Options:
  --host-addr TEXT   Prysm Eth2 API host address in format
                     <protocol(http/https)>://<IP>:<port>  [default:
                     (http://localhost:3501)]
  --api-method TEXT  HTTP method to execute a part of request  [default:
                     (GET)]
  --api-path TEXT    Restful API path to target resource  [default:
                     (eth/v1/node/health)]
  --api-data TEXT    Restful API request body data included within POST
                     requests  [default: ({})]
  --help             Show this message and exit.
```

`$API_HOST_ADDR=<url>` (**default**: `localhost:3501`)
- Prysm Eth2 API host address in format <protocol(http/https)>://<IP>:<port>

`$API_METHOD=<http-method>` (**default**: `GET`)
- HTTP method to execute

`$API_PATH=<url-path>` (**default**: `/eth/v1/node/health`)
- RESTful API path to target resource

`$API_DATA=<json-string>` (**default**: `'{}'`)
- RESTful API request body data included within POST requests

The output consists of a JSON blob corresponding to the expected return object for a given API query. Reference [Prysm's Ethereum Beacon API docs](https://docs.prylabs.network/docs/how-prysm-works/ethereum-public-api) for more details.

###### example

```bash
docker exec [--env API_PATH=eth/v1/node/syncing] prysm-beacon prysm-helper status api-request [--api-path eth/v1/node/syncing]
{
  "data": {
        "head_slot": "2315233",
        "is_syncing": false,
        "sync_distance": "1"
  }
}
```

##### Import validator keystores

Automatically import designated validator keystores and associated wallets on startup.

`$SETUP_VALIDATOR=<boolean>` (**default**: `false`)
- whether to attempt to import validator keystores and associated wallets

`$VALIDATOR_WALLET_PASSWORD=<string>` (**required**)
- password to secure validator wallet associated with imported keystore

`$VALIDATOR_ACCOUNT_PASSWORD=<string>` (**required**)
- password to secure validator account

`$VALIDATOR_KEYS_DIR=<directory>` (**default**: `/keys`)
- Path to a directory where keystores to be imported are stored

`$VALIDATOR_WALLET_DIR=<directory>` (**default**: `/wallets`)
- Path to a wallet directory within container for Prysm validator accounts

`$ETH2_CHAIN=<string>` (**default**: `pyrmont`)
- Ethereum 2.0 chain imported keystore and wallets are associated with


All account wallets keystore/wallet details will be created at the `$VALIDATOR_WALLET_DIR`.

```bash
ls /wallets/direct/accounts/
  all-accounts.keystore.json
```

Examples
----------------

* Enable automatic acceptance of the terms of use when launching either a beacon-chain or validator node:
```
docker run --env CONFIG_accept-terms-of-use=true 0labs/prysm:latest
```

* Launch a Prysm beacon-chain node connected to the Pyrmont Ethereum 2.0 testnet using a Goerli web3 Ethereum provider:
```
# cat .env
CONFIG_http-web3provider=http://ethereum-rpc.goerli.01labs.net:8545
CONFIG_pyrmont=true

docker run --env-file 0labs/prysm:latest
```

* Import Prater validator keystore and associated wallets on startup:
```
# cat .env
ETH2_CHAIN=prater
SETUP_VALIDATOR=true
VALIDATOR_WALLET_PASSWORD=N7p3D1?!m+bA
VALIDATOR_ACCOUNT_PASSWORD=passw0rd
VALIDATOR_KEYS_DIR=/validator/keys
VALIDATOR_WALLET_DIR=/validator/wallets


docker run --env-file .env -v /host/validator/keys:/validator/keys 0labs/prysm:latest validator
```

* Install Eth2 deposit CLI tool and automatically setup multiple validator accounts/keys to register on the Pyrmont testnet:
```
# cat .env
SETUP_DEPOSIT_CLI=true
DEPOSIT_CLI_VERSION=v1.2.0
SETUP_DEPOSIT_ACCOUNTS=true
DEPOSIT_NUM_VALIDATORS=3
ETH2_CHAIN=pyrmont
DEPOSIT_KEY_PASSWORD=ABCabc123!@#$

docker run --env-file .env 0labs/prysm:latest
```

* Setup automatic cron backups of a localhost beacon-chain node DB every 12 hours (or twice a day):
```
# cat .env
AUTO_BACKUP_DB=true
BACKUP_HOST_ADDR=http://localhost:8080
BACKUP_INTERVAL=0 */12 * * *

docker run --env-file .env 0labs/prysm:latest
```

License
-------

MIT

Author Information
------------------

This Containerfile was created in 2021 by O1.IO.

🏆 **always happy to help & donations are always welcome** 💸

* **ETH (Ethereum):** 0x652eD9d222eeA1Ad843efec01E60C29bF2CF6E4c

* **BTC (Bitcoin):** 3E8gMxwEnfAAWbvjoPVqSz6DvPfwQ1q8Jn

* **ATOM (Cosmos):** cosmos19vmcf5t68w6ug45mrwjyauh4ey99u9htrgqv09
