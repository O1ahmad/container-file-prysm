<p><img src="https://avatars1.githubusercontent.com/u/12563465?s=200&v=4" alt="OCI logo" title="oci" align="left" height="70" /></p>
<p><img src="https://prysmaticlabs.com/assets/PrysmStripe.png" alt="Prysm logo" title="prysm" align="right" height="60" /></p>

Container File :stars: :link: Prysm
=========
![GitHub release (latest by date)](https://img.shields.io/github/v/release/0x0I/container-file-template?color=yellow)
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
$ docker run --mount type=bind,source="$(pwd)"/custom-config.yml,target=/tmp/config.yml 0labs/prysm:latest --config-file /tmp/config.yml
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
  0labs/prysm:latest --config /tmp/prysm/config.yml
```

_Moreover, see [here](https://docs.prylabs.network/docs/prysm-usage/parameters/) for a list of supported flags to set as runtime command-line flags._

```bash
# connect to Prater Eth2 testnet and automatically accept the terms of use agreement 
docker run 0labs/prysm:latest --prater --accept-terms-of-use
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

:flashlight: To assist with managing a `prysm` client and interfacing with the *Ethereum 2.0* network, the following utility functions have been included within the image.

##### Check account balances

Display account balances of all accounts currently managed by a designated `geth` RPC server.

```
$ geth-helper status check-balances --help
Usage: geth-helper status check-balances [OPTIONS]

  Check all client managed account balances

Options:
  --rpc-addr TEXT  server address to query for RPC calls  [default:
                   (http://localhost:8545)]
  --help           Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `geth` RPC server address for querying network state

The balances output consists of a JSON list of entries with the following properties:
  * __account__ - account owner's address
  * __balance__ - total balance of account in decimal

###### example

```bash
docker exec --env RPC_ADDRESS=geth-rpc.live.01labs.net 0labs/geth:latest geth-helper status check-balances

[
  {
   "account": 0x652eD9d222eeA1Ad843efab01E60C29bF2CF6E4c,
   "balance": 1000000
  },
  {
   "account": 0x256eDb444eeA1Ad876efaa160E60C29bF8CH3D9a,
   "balance": 2000000
  }
]
```

##### View client sync progress

View current progress of an RPC server's sync with the network if not already caughtup.

```
$ geth-helper status sync-progress --help
Usage: geth-helper status sync-progress [OPTIONS]

  Check client blockchain sync status and process

Options:
  --rpc-addr TEXT  server address to query for RPC calls  [default:
                   (http://localhost:8545)]
  --help           Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `geth` RPC server address for querying network state

The progress output consists of a JSON block with the following properties:
  * __progress__ - percent (%) of total blocks processed and synced by the server
  * __blocksToGo__ - number of blocks left to process/sync
  * __bps__: rate of blocks processed/synced per second
  * __percentageIncrease__ - progress percentage increase since last view
  * __etaHours__ - estimated time (hours) to complete sync

###### example

```bash
$ docker exec 0labs/geth:latest geth-helper status sync-progress

  {
   "progress":66.8226399830796,
   "blocksToGo":4298054,
   "bps":5.943412173361741,
   "percentageIncrease":0.0018371597201962686,
   "etaHours":200.87852803477827
  }
```

##### Backup and encrypt keystore

Encrypt and backup client keystore to designated container/host location.

```
$ geth-helper account backup-keystore --help
Usage: geth-helper account backup-keystore [OPTIONS] PASSWORD

  Encrypt and backup wallet keystores.

  PASSWORD password used to encrypt and secure keystore backups

Options:
  --keystore-dir TEXT  path to import a backed-up geth wallet key store
                       [default: (/root/.ethereum/keystore)]
  --backup-path TEXT   path containing backup of a geth wallet key store
                       [default: (/tmp/backups)]
  --help               Show this message and exit.
```

`$password=<string>` (**required**)
- password used to encrypt and secure keystore backups. Keystore backup is encrypted using the `zip` utility's password protection feature.

`$KEYSTORE_DIR=<string>` (**default**: `/root/.ethereum/keystore`)
- container location to retrieve keys from

`$BACKUP_PATH=<string>` (**default**: `/tmp/backups`)
- container location to store encrypted keystore backups. **Note:** Using container `volume/mounts`, keystores can be backed-up to all kinds of storage solutions (e.g. USB drives or auto-synced Google Drive folders)

`$AUTO_BACKUP_KEYSTORE=<boolean>` (**default**: `false`)
- automatically backup keystore to $BACKUP_PATH location every $BACKUP_INTERVAL seconds

`$BACKUP_INTERVAL=<cron-schedule>` (**default**: `* * * * * (hourly)`)
- keystore backup frequency based on cron schedules

`$BACKUP_PASSWORD=<string>` (**required**)
- encryption password for automatic backup operations - see *$password*

##### Import backup

Decrypt and import backed-up keystore to designated container/host keystore location.

```
$ geth-helper account import-backup --help
Usage: geth-helper account import-backup [OPTIONS] PASSWORD

  Decrypt and import wallet keystores backups.

  PASSWORD password used to decrypt and import keystore backups

Options:
  --keystore-dir TEXT  directory to import a backed-up geth wallet key store
                       [default: (/root/.ethereum/keystore)]
  --backup-path TEXT   path containing backup of a geth wallet key store
                       [default: (/tmp/backups/wallet-backup.zip)]
  --help               Show this message and exit.
```

`$password=<string>` (**required**)
- password used to decrypt keystore backups. Keystore backup is decrypted using the `zip/unzip` utility's password protection feature.

`$KEYSTORE_DIR=<string>` (**default**: `/root/.ethereum/keystore`)
- container location to import keys

`$BACKUP_PATH=<string>` (**default**: `/tmp/backups`)
- container location to retrieve keystore backup. **Note:** Using container `volume/mounts`, keystores can be imported from all kinds of storage solutions (e.g. USB drives or auto-synced Google Drive folders)

##### Query RPC

Execute query against designated `geth` RPC server.

```
$ geth-helper status query-rpc --help
Usage: geth-helper status query-rpc [OPTIONS]

  Execute RPC query

Options:
  --rpc-addr TEXT  server address to query for RPC calls  [default:
                   (http://localhost:8545)]
  --method TEXT    RPC method to execute a part of query  [default:
                   (eth_syncing)]
  --params TEXT    comma separated list of RPC query parameters  [default: ()]
  --help           Show this message and exit.
```

`$RPC_ADDRESS=<web-address>` (**default**: `localhost:8545`)
- `geth` RPC server address for querying network state

`$RPC_METHOD=<geth-rpc-method>` (**default**: `eth_syncing`)
- `geth` RPC method to execute

`$RPC_PARAMS=<rpc-method-params>` (**default**: `''`)
- `geth` RPC method parameters to include within call

The output consists of a JSON blob corresponding to the expected return object for a given RPC method. Reference [Ethereum's RPC API wiki](https://eth.wiki/json-rpc/API) for more details.

###### example

```bash
docker exec --env RPC_ADDRESS=geth-rpc.live.01labs.net --env RPC_METHOD=eth_gasPrice \
    0labs/geth:latest geth-helper status query-rpc

"0xe0d7b70f7" # 60,355,735,799 wei
```

Examples
----------------

* Create account and bind data/keystore directory to host path:
```
docker run -it -v /mnt/geth/data:/root/.ethereum/ 0labs/geth:latest geth account new --password <secret>
```

* Launch an Ethereum light client and connect it to the Ropsten, best current like-for-like representation of Ethereum, PoW (Proof of Work) test network:
```
docker run --env CONFIG-Eth-SyncMode=light 0labs/geth:latest geth --ropsten
```

* View sync progress of active local full-node:
```
docker run --name 01-geth --detach --env CONFIG-Eth-SyncMode=full 0labs/geth:latest geth --mainnet

docker exec 01-geth geth-helper status sync-progress
```

* Run *fast* sync node with automatic daily backups of custom keystore directory:
```
docker run --env CONFIG-Eth-SyncMode=fast --env KEYSTORE_DIR=/tmp/keystore \
           --env AUTO_BACKUP_KEYSTORE=true --env BACKUP_INTERVAL="0 * * * *" \
           --env BACKUP_PASSWORD=<secret> \
  --volume ~/.ethereum/keystore:/tmp/keystore 0labs/geth:latest
```

* Import account from keystore backup stored on an attached USB drive:
```
docker run --name 01-geth --detach --env CONFIG-Eth-SyncMode=full \
           --volume /path/to/usb/mount/keys:/tmp/keys \
           --volume ~/.ethereum:/root/.ethereum \0labs/geth:latest geth --mainnet

docker exec --env BACKUP_PASSWORD=<secret>
            --env BACKUP_PATH=/tmp/keys/my-wallets.zip
            01-geth geth-helper account import-backup

docker exec 01-geth account import /root/.ethereum/keystore/a-wallet
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
