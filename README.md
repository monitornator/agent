# Monitornator Agent

Monitoring agent for Monitornator ([monitornator.io](https://monitornator.io)).

## Installation

```
bash <(curl -sSL https://agent.monitornator.io/install.sh) --server-id=${SERVER_ID} --token=${SECRET_TOKEN}
```

## Currently supported

- Ubuntu 14.04, 16.04, 18.04, 18.10
- Debian 9

More supported systems coming soon.

## Dependencies

These dependencies are being installed if not yet present:

- build-essential
- python3
- python3-dev
- python3-setuptools
- python3-pip
- supervisor