# Alioth app repo

Alioth applications.

## Gettting started

### OS

We recommand using `Ubuntu` as the OS, since it so far has the best support on P4 related things. All of our utility scripts are based on Ubuntu as well, so you will get the best support.

If you are using WSL on Windows, we highly recommend to switch to using a Ubuntu Hyper-V VM instead. This is because the Linux kernel that WSL uses doesn't have certain features, so it cannot get openvswitch installed, which will cause mininet fail to run.

### Installing `just`

Instead of using `make`, we are using `just` instead in order to make writing makefile easier.

Installing `just` is easy. On Ubuntu, we can use snap:

```bash
sudo snap install --edge --classic just
```

If you are using ARM-based system, we need to [install rust](https://www.rust-lang.org/tools/install) and run following command to get it installed:

```bash
cargo install just
```

For more information, feel free to check the following links:

- `just` packages: <https://github.com/casey/just#packages>
- Installing `rust`: <https://www.rust-lang.org/tools/install>
- Installing snap: <https://snapcraft.io/docs/installing-snap-on-ubuntu>

### Installing dev environment

All dev initialization steps are included in our `just` makefile. So we can simply run the following command to get the dev environment initlaized. 

```bash
just init
```

It will run the following sub tasks and install the following things on the system. Every sub task is self-contained, so if any tasks fails, we can rerun the specific task to get things fixed.

| Project | Task |
| - | - |
| init-p4c | [p4c](https://github.com/p4lang/p4c) |
| init-p4-bmv2 | [bmv2](https://github.com/p4lang/behavioral-model) |
| init-mininet | [mininet](https://github.com/mininet/mininet) |
| init-p4-tutorials | [p4-tutorials](https://github.com/p4lang/tutorials) |
| init-open-tofino | [Open-Tofino](https://github.com/barefootnetworks/Open-Tofino) |

Once everything is done, we can find all code under `~/code/p4` folder. And we are ready to go!

### Cheat Sheet

- `just --list`: List all build tasks.
- `just init`: Initialize dev enrivonment. Please read the guidance above for more details.
- `just run-1sw <bm-exe> <bm-json>`: Run 1 switch demo with specific P4 programs.
  - e.g. `just run-1sw ~/code/p4/behavioral-model/targets/simple_router/simple_router ~/code/p4/behavioral-model/targets/simple_router/simple_router.json`

## LICENSE

MIT.