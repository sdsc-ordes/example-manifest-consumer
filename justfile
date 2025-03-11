set positional-arguments
set dotenv-load
set shell := ["bash", "-cue"]
root_dir := `git rev-parse --show-toplevel`
build_dir := root_dir + "/build"

# Default recipe to list all recipes.
[private]
default:
  just --list --no-aliases

alias dev := nix-develop
# Enter a Nix development shell.
nix-develop *args:
  @echo "Starting nix developer shell in './tools/nix/flake.nix'."
  @cd "{{root_dir}}" && \
  cmd=("$@") && \
  { [ -n "${cmd:-}" ] || cmd=("zsh"); } && \
  nix develop ./tools/nix#default --accept-flake-config --command "${cmd[@]}"

# Clean up build directory
clean:
  cd {{root_dir}} && \
    rm -rf {{build_dir}}/* && \
    mkdir {{build_dir}}/pre

# Fetch manifest dependencies
fetch:
  vendir sync -f vendir.yaml --chdir external


[private]
render-ytt: clean fetch
    cp -r ./external/_ytt_lib ./src/ytt/* {{build_dir}}/pre && \
    ytt -f {{build_dir}}/pre > {{build_dir}}/manifests.yaml

# Render Helm templates
[private]
render-helm: render-ytt
  cd {{root_dir}} && \
    fd 'values.yaml' src/helm \
      -x sh -c 'helm template $(basename {//}) external/helm/$(basename {//})  -f {}' \
    >> {{build_dir}}/manifests.yaml

# Render manifests
render: render-helm

# Deploy rendered manifests
deploy: render
  just render && \
    kubectl apply -f build/manifests.yaml
