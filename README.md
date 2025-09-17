# blog rough draft 

## top of head notes 

think of way to NOT map host ports on docker (22:22) rather map to an arbitrary port (22:3083) and still get the build to recognize the remote builder 

# why would i use nix and docker ? 

this is probably the question on everyones mind right now and while many of the nix users i have conversed with started using nix purely to get away from docker i am here to bring peace between the communities and show how they can be used in tandem to solve nix multi-platform builds

# vain pov

the problem arose when i was working on building a nixos iso that would contain a pre configured configuration.nix file so I can install nixos on my old intel macbook pro and turn it into a homelab of sorts and have a reproducible iso that i can use to reproduce this setup on other intel macs (i have a lot). obviously downloading and flashing the nixos iso onto a flash drive from https://nixos.org and then putting my configuration.nix file onto the machine would be the easier solution here but out of curiosity the need for reproducibility i decided to try to build the iso myself using a flake. 

here is the current example flake.nix file I am trying to build: 
```nix
{
  description = "nix docker rb";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # https://zerforschen.plus/posts/why-i-do-not-use-flake-utils/
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in 
    {
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./iso.nix ];
      };

      packages = forAllSystems (system: {
        iso = self.nixosConfigurations.iso.config.system.build.isoImage;
      });
    };
}
```

iso.nix:
```nix
{ config, pkgs, ... }:

{
  # import iso module from nixpkgs
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix>
  ];

  # nixpkgs.localSystem.system = "x86_64-linux";

  # put our configuration.nix file in /etc/nixos/configuration.nix
  environment.etc."nixos/configuration.nix".source = ./configuration.nix;
}
```

example configuration.nix:
```nix
{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.loader.grub.enable = true;

  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "mbhv";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.your_username = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
  };

  # add support for macbook wifi adaptors
  boot.kernelModules = [ 
    "kvm-intel" 
    "wl"
  ];
  virtualisation.libvirtd.enable = true;

  # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
  nixpkgs.config.allowUnfree = true;

  # packages that will be available globally on the system
  environment.systemPackages = with pkgs; [
    vim
    git
    tailscale
    curl
    gh
  ];
}
```

INSERT SCREENSHOT OF FAILED BUILD WITHOUT REMOTE BUILDER 

## why is this a problem ? 

in short darwin platforms are the least supported by nix. we can see this from the [nixpkgs reference manual](https://nixos.org/manual/nixpkgs/stable/#chap-platform-support) so trying to build most packages on my m2 macbook air result in an error since the package doesnt have support for darwin systems or arm/silicon architecture.

### is this even a problem ? 

yes and no. multiplatform builds with nix are "solved" usually with 5 options. I'll dive into each one and why I decided against going that route.

1. A remote builder with the correct architecture and OS to support your build (this can be a physical/virtual machine with nix installed on it) 

physical/virutal machines come with their problems/limitations. physical machines obviously require you to have another machine that matches the OS and platform needed for the build and then furthur setup port forwarding or tailscale on the machine so it can be accessed from anywhere. virtual machines on macos come with limited options as well you can decide to pay for a parallels license or use virtual box/UTM to keep things free but all of these options require tedious setup and having to interact with a ui which is not my preferred method of building things since I would like for builds to be automated and easily reproducible.

2. CI builder i.e github actions runner building your flake

this option is definetly something you want to implement no matter what but unfortunatlely it doesn't make sense to use for local development due to it being so time consuming. I don't want to push to github for every test change just to verify if the change will actually build/run on top of an inevitably messy commit.

3. Cross compilation with dockerTools or hydra

this option is kind of split into three. while [cross compilation](https://nixos.org/manual/nixpkgs/stable/#chap-cross) exists for nix its documentation is incomplete and trying to figure out which dependencies are missing for every cross compilation build is VERY time consuming and results in a messy flake

cross compilation with [dockerTools](https://ryantm.github.io/nixpkgs/builders/images/dockertools/) is also in theory a solution. I haven't seen it successfully done myself and for my use case it didn't make sense to attempt since dockerTools requires the linux OS to build (which is part of the problem I am trying to solve) also images built with dockerTools tend to be larger in image size as well 

theory dockerTools cross compilation (requires a linux builder):
```nix
{
  outputs = { self, nixpkgs }: {
    # Regular build
    # packages.${localsystem}.${name} = drv { import pkgs = nixpkgs.legacypackages.${localsystem}; }
    packages.aarch64-darwin.containerImage = import ./docker.nix { pkgs = nixpkgs.legacyPackages.aarch64-darwin; };
    # Cross build
    # packages.${localSystem}."${name}-${crossSystem}" = drv { import nixpkgs { localSystem = localSystem; crossSystem = crossSystem;}
    packages.aarch64-darwin.containerImage-x86_64-linux = import ./docker.nix { pkgs = import nixpkgs { localSystem = "aarch64-darwin"; crossSystem = "x86_64-linux"; }; };
  };
}
```

from my research ive also heard mentions of using [hydra](https://hydra.nixos.org/) for cross compilation but i've never seen it working as intended


4. enable NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM 

you can enable the [NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unsupported-system) environment variable on your host system but this is more of a hammer and nail approach and won't fix most multiplatform builds.

5. nix-darwin linux-builder

[nix-darwin](https://github.com/nix-darwin/nix-darwin) also mentions in their docs they have a [linux builder](https://github.com/nix-darwin/nix-darwin/blob/830b3f0b50045cf0bcfd4dab65fad05bf882e196/modules/nix/linux-builder.nix) for builds on macos that require a linux OS. this was going to be my approach but this means installing nix-darwin onto your host system and you can't define the platform for the builder from what i've seen which doesnt solve the multiplatform issue but I could be wrong.

# da solution waow

we will use docker as a remote builder so I can specify the platform and operating system I would like to use for the build. in my use case I need an amd linux builder but i will also show how you can build arm packages as well. 

## dockerfile big waow

```Dockerfile
FROM nixos/nix:2.31.1-amd64

RUN set -eux; \
    { \
        echo "filter-syscalls = false"; \
        echo "max-jobs = auto"; \
        echo "cores = 0"; \
        echo "build-cores = 0"; \
    } >> /etc/nix/nix.conf

RUN nix-env -f '<nixpkgs>' -iA \
    gnused \
    openssh \
 && nix-store --gc

RUN set -eux; \
    mkdir -p /etc/ssh /var/empty /run /var/log /root/.ssh && \
    touch /var/log/lastlog && \
    echo "sshd:x:498:65534::/var/empty:/run/current-system/sw/bin/nologin" >> /etc/passwd; \
    cp /root/.nix-profile/etc/ssh/sshd_config /etc/ssh/sshd_config && \
    sed -i 's/root:!:/root:*:/' /etc/shadow; \
    sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config; \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N "" -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N "" -t ed25519 && \
    echo "source /root/.nix-profile/etc/profile.d/nix.sh" >> /etc/bashrc && \
    echo "source /etc/bashrc" >> /etc/profile

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

## entrypoint script small waow

```bash
#!/usr/bin/env bash
set -e

echo "$1" > /root/.ssh/authorized_keys

sshd=$(readlink -f $(which sshd))
exec $sshd -D -e
```




