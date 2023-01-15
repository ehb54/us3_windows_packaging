# us3_windows_packaging
repo for info &amp; supplementary data to build us3 windows binary packages

- If you have any questions or problems, please create an issue.
- Pull requests happily considered.

## setting up a first time build environment
- [install createinstall](https://www.createinstall.com/download-free-trial.html)
  - get the `freeware version`
- [install most recent msys2 64 bit package](https://repo.msys2.org/distrib/x86_64/)
  - at the time of this writing, it was `msys2-x86_64-20221216.exe`
  - accept all defaults when installing
- After installing, run the `msys2 msys` desktop app
  - the `msys2` desktop apps present a linux-like shell window
  - N.B. there are multiple msys2 desktop apps:
    - `msys2 msys`
    - `msys2 mingw64`
    - & others
  - under `msys2 msys` shell run:
    - `pacman -Syuu`
      - repeat until there is nothing further updated
        - the window will likely close after the first update and you will have to restart the `msys2 msys` desktop app 
    - `pacman -S git`
    - `git clone https://github.com/ehb54/us3_windows_packaging`
    - `us3_windows_packaging/setup/setup_msys.pl --all`
    - exit the `msys2 msys` desktop app
  - under the `msys2 mingw64` desktop app
    - `~/us3_windows_packaging/setup/setup.pl --all`
    - `~/us3_windows_packaging/setup/setup.pl --us branch`
      - where `branch` is an ultrascan3 repo branch
    - `cd ultrascan-branch`
    - `. qt5env`
    - `./makeall.sh`
    - `./makesomo.sh`
    - `~/us3_windows_packaging/utils/fixdependencies.pl update`
      - this will have to be repeated until it gives packaging instructions
      - follow the packaging instructions
 
## after install - building ultrascan again
- always under the `msys2 mingw64` desktop app
- existing branch
  - `cd ultrascan-branch`
  - `git stash`
  - `git pull`
  - `git stash pop`
  - `. qt5env`
  - `./makeall.sh`
  - `./makesomo.sh`
  - `~/us3_windows_packaging/utils/fixdependencies.pl update`
    - this will have to be repeated until it gives packaging instructions
    - follow the packaging instructions
- new branch
  - `~/us3_windows_packaging/setup/setup.pl --us branch`
  - `cd ultrascan-branch`
  - `. qt5env`
  - `./makeall.sh`
  - `./makesomo.sh`
  - `~/us3_windows_packaging/utils/fixdependencies.pl update`
    - this will have to be repeated until it gives packaging instructions
    - follow the packaging instructions
