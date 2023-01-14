# Alioth app repo

Alioth applications.

## Repo structure

All applications are organized in following structure:

```
- <app-name>: the root folder of each application
  - src: source folder
  - script: scripts, e.g. scripts for testing
  - data: extra data if any, e.g. test inputs and etc
```

The application could have PoCs, which will resides within each application folder and follows the same folder structure as below:

```
- <app-name>: the root folder of each application
  - poc: folder for all PoCs
    - <poc-name>:
      - src: source folder
        - <poc-name>.<arch>.p4: The arch can be bmv2, tna, ebpf and etc.
      - script: scripts, e.g. scripts for testing
      - data: extra data if any, e.g. test inputs and etc
```

## Gettting started

### OS

We recommand using `Ubuntu` (>=20.04) as the OS, since it is by far the OS with the best support on P4 related things. All of our utility scripts are based on Ubuntu as well, so you will get the best experience.

If you are using WSL on Windows, we highly recommend to switch to using a Ubuntu Hyper-V VM instead. This is because the Linux kernel that WSL uses doesn't have certain features, so it cannot get openvswitch installed, which will cause mininet fail to run.

### Installing `just`

Instead of using `make`, we are using `just` instead in order to make writing makefile easier.

Installing `just` is easy. On Ubuntu, we can use snap:

```bash
sudo snap install --edge --classic just
```

If you are using ARM-based system, we can install `just` with prebuild release using the command below:

```bash
curl --proto '=https' --tlsv1.3 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
```

For more information, feel free to check the following links:

- `just` packages: <https://github.com/casey/just#packages>
- Installing `rust`: <https://www.rust-lang.org/tools/install>
- Installing `snap`: <https://snapcraft.io/docs/installing-snap-on-ubuntu>

### Installing dev environment

All dev environment initialization steps are included in our `just` makefile. So we can simply run the following command to get the dev environment initlaized. 

```bash
just init
```

It will run the following sub tasks and install the following things on the system. Every sub task is self-contained, so if any tasks fails, we can rerun the specific task to get things fixed.

| Task | Dependency |
| - | - |
| init-p4c | [p4c](https://github.com/p4lang/p4c) |
| init-p4-bmv2 | [bmv2](https://github.com/p4lang/behavioral-model) |
| init-mininet | [mininet](https://github.com/mininet/mininet) |
| init-p4-tutorials | [p4-tutorials](https://github.com/p4lang/tutorials) |
| init-open-tofino | [Open-Tofino](https://github.com/barefootnetworks/Open-Tofino) |

Once everything is done, we can find all code under `~/code/p4` folder. And we are ready to go!

## Running a P4 program

To run a P4 program, we need to compile the specific program, load it in mininet as well as launching a CLI for running runtime commands. These can be achieved with the following steps:

1. Use `p4c-ss` task to compile the program:

   ```bash
   just p4c-ss <P4_FILE_PATH>
   ```

   e.g.
   ```bash
   just p4c-ss ~/code/p4/tutorials/exercises/basic/basic.p4
   ```

   This will compile the P4 program and generate the output into `./out/basic` folder.

2. Use `ss` task to launch the program.

   ```bash
   just ss <PROG_NAME>
   ```

   e.g.
   ```bash
   just ss basic
   ```

   This will use the generated P4 bmv2 program `./out/basic/basic.json` to launch the mininet. And we can start to play with it.

3. In the end, use `bm-cli` task to launch the CLI for running the runtime commands:

   ```bash
   just bm-cli
   ```

## Debug BMv2

In order to enable BMv2 debugger, please manually change the `behavioral-model/tools/p4_mininet.py` file to update the `enable_debugger` parameter default value to `True`.

Then while the mininet is running, run:

```bash
just bm-dbg
```

It requires root access to run the debugger, so it will ask for sudo password. And after running it, this will launch the debugger as below:

```bash
$ just bm-dbg
sudo "/home/r12f/code/p4/behavioral-model/tools/p4dbg.py" --thrift-port 9090
'--socket' not provided, using ipc:///tmp/bmv2-0-debug.ipc (obtained from switch)
Obtaining JSON from switch...
Done
Connecting to the switch...
Connection established
Prototype for Debugger UI
P4DBG:
```

## Cheat Sheet

- `just --list`: List all build tasks.
- `just init`: Initialize dev enrivonment. Please read the guidance above for more details.
- `just bm-1sw <bm-exe> <bm-json>`: Run 1 switch demo with specific P4 programs.
  - e.g. `just bm-1sw ~/code/p4/behavioral-model/targets/simple_router/simple_router ~/code/p4/behavioral-model/targets/simple_router/simple_router.json`
- `just p4c-ss <P4_FILE_PATH>`: Compile the P4 program into `./out/<P4_PROGRAM_NAME>` folder.
- `just ss <P4_PROGRAM_NAME>`: Launch mininet with the `<P4_PROGRAM_NAME>` from the out folder loaded.
- `just bm-cli`: Launch CLI for running P4 runtime commands.
- `just bm-log`: Launch nanomsg log listener for listenling to logs.
- `just bm-dbg`: Launch bmv2 debugger.

## LICENSE

MIT.