set positional-arguments
set dotenv-load
set shell := ["bash", "-cue"]
root_dir := `git rev-parse --show-toplevel`
build_dir := root_dir + "/build"
pre_dir := build_dir + "/pre"
out_dir := build_dir + "/manifests"

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
    mkdir -p {{pre_dir}} {{out_dir}}

# Fetch manifest dependencies
fetch:
  vendir sync -f vendir.yaml --chdir external


# Render Helm charts [intermediate step before rendering ytt manifests]
[private]
render-helm: clean fetch
  # render external helm charts with our values into pre-build directory
  cd {{root_dir}} && \
    fd '^helm$' src/ \
      -x sh -c 'helm template $(basename {//}) external/helm/$(basename {//}) -f {}/values.yaml --output-dir {{pre_dir}}'

# Render ytt manifests
[private]
render-ytt: render-helm
  # copy all non-helm files to the pre-build directory and render them
  cd {{root_dir}} && \
    rsync -av --exclude='*/helm/' \
      ./external/_ytt_lib \
      ./src/ \
      {{pre_dir}} && \
    ytt -f {{pre_dir}} --output-files {{out_dir}}

# Render manifests
render: render-ytt

# Deploy rendered manifests
deploy: render
  just render && \
    kubectl apply -f {{out_dir}}
