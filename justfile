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

# Render Helm templates (pre-render)
[private]
helm-template: clean fetch
  for chart_dir in {{root_dir}}/external/helm_charts/*; do \
    service=$(basename ${chart_dir}); \
    helm template ${service}-consumer \
      ${chart_dir} \
      -f src/${service}/helm-values.yaml \
      > {{build_dir}}/pre/${service}.yaml; \
  done

# Render manifests
render: clean fetch helm-template
    cp -r ./external/_ytt_lib ./src/* {{build_dir}}/pre && \
    fd helm-values.yaml {{build_dir}}/pre -x rm {} && \
    ytt -f {{build_dir}}/pre > {{build_dir}}/manifests.yaml

# Deploy rendered manifests
deploy: render
  just render && \
    kubectl apply -f build/manifests.yaml
