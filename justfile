set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

image := "nix-docker-rb:latest"

build:
  docker build -f ./Dockerfile.amd -t {{image}} .

run: 
  just build
  just copy-ssh-keys-to-root
  docker run \
    --rm \
    -d \
    --init \
    -p 22:22 \
    {{image}} "$(ssh-add -L)"

stop:
  docker stop nix-docker-rb
  just rm-ssh-keys

up:
  just run

reup:
  just stop || true
  just run

copy-ssh-keys-to-root:
  sudo cp -r ~/.ssh /var/root

rm-ssh-keys:
  sudo rm -rf /var/root/.ssh

nix-build:
  sudo nix build --impure --builders 'ssh://root@127.0.0.1 x86_64-linux' .#iso