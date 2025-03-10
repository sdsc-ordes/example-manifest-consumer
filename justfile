root_dir := `git rev-parse --show-toplevel`

fetch:
  vendir sync -f vendir.yaml --chdir external

render: fetch
  cd {{root_dir}} && \
    rm -rf ./build/* && \
    cp -r ./src/* ./build/&& \
    cp -r ./external/_ytt_lib ./build/ && \
    cd ./build && \
    ytt -f .

deploy: render
  kubectl apply -f build/*
