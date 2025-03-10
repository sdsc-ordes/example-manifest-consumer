# Example manifest consumer repo

This repository showcases the use of ytt + vendir to reuse manifests from other repositories.

## Structure

This repository is structured as follows:

- `./build`: rendered manifests (not checked out in git).
- `./external`: vendored manifests from third-party repositories.
- `./justfile`: commands to work with the manifests.
- `./src`: manifests and values specific to this repository.
- `./tools`: tooling to work with the manifests.

## Usage

### Setup

This repository contains a [justfile](./justfile), and we use [`just`](https://github.com/casey/just) as a command runner.

We provide all the tools you need to work on this project in a nix development shell.
See here to install nix: https://determinate.systems/nix-installer/

To enter the dev-shell, run:

```shell
just dev
```

> [!NOTE]
> Alternatively, you may enter the devshell directly with :
> `nix develop ./tools/nix#default --accept-flake-config --command "zsh"`


### Deploying the manifests

First, the manifests are fetched from the source repository using [`vendir`](https://carvel.dev/vendir).
See the [vendir.yaml](./external/vendir.yaml) file for the configuration. You can fetch the manifests with:

```shell
just fetch
```

The third-party manifests are made available in the `./external` directory.

Next, you can render the manifests using [`ytt`](https://carvel.dev/ytt).
You can render the manifests with:

```shell
just render
```

The rendered manifests are all concatenated written to `./build/manifests.yaml`.

Finally, you can apply the rendered manifests to your cluster using `kubectl`:

```shell
just deploy
```

> [!TIP]
> `just deploy` automatically fetches and renders the manifests before applying them.
