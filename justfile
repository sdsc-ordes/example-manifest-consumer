root_dir := `git rev-parse --show-toplevel`
build_dir := root_dir + "/build"

fetch:
  vendir sync -f vendir.yaml --chdir external

render: fetch
  cd {{root_dir}} && \
    rm -rf {{build_dir}}/* && \
    mkdir {{build_dir}}/pre && \
    cp -r ./src/* {{build_dir}}/pre && \
    cp -r ./external/_ytt_lib {{build_dir}}/pre && \
    ytt -f {{build_dir}}/pre > {{build_dir}}/manifests.yaml


deploy: render
  just render && \
    kubectl apply -f build/manifests.yaml
