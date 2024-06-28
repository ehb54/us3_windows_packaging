# us3_windows_packaging
repo for info &amp; supplementary data to build us3 windows binary packages

- If you have any questions or problems, please create an issue.
- Pull requests happily considered.

## setting up a first time build environment
- [install createinstall](https://www.createinstall.com/download-free-trial.html)
  - get the `freeware version` - `cif-setup.exe`
- [install most recent msys2 64 bit package](https://repo.msys2.org/distrib/x86_64/)
  - at the time of this writing, it was `msys2-x86_64-20221216.exe`
  - accept all defaults when installing
- After installing, run the `msys2 msys` desktop app
  - the `msys2` desktop apps present a linux-like shell window
  - N.B. there are multiple msys2 desktop apps:
    - `msys2 msys`
    - `msys2 mingw64`
    - & others
  - under `msys2 msys` desktop app:
    - `pacman -Syuu`
      - repeat until there is nothing further updated
        - the window will likely close after the first update and you will have to restart the `msys2 msys` desktop app 
      - N.B. do not run this command again once the steps below have been run. This is due to qt5 requiring an older version of gcc. If you wish to update the msys2 system, it is recommended to completely uninstall msys2 and make sure no msys2 created directories remain and start again. For the adventurous, you could try using pacman to remove the gcc package and all its dependencies first, then update the system with pacman, but this has not been tested.
      - if pacman timeouts become an issue add `DisableDownloadTimeout` in `/etc/pacman.conf` [ref](https://github.com/msys2/MSYS2-packages/issues/1658#issuecomment-1852358396)
    - `pacman -S git`
    - `git clone https://github.com/ehb54/us3_windows_packaging`
    - `us3_windows_packaging/setup/setup_msys.pl --all`
      - you may need to press Enter/Return at the `/usr/bin/core_perl/cpan AppConfig Template` step to keep the setup progressing. 
    - exit the `msys2 msys` desktop app
  - under the `msys2 mingw64` desktop app
    - `~/us3_windows_packaging/setup/setup.pl --all`
      - optionally add `--procs n` to control the number of processors used for parallel makes
        - default is the number of availabe processors + 1
        - `--procs` is used for configuring & building qt, qwt and ultrascan
    - `~/us3_windows_packaging/setup/setup.pl --us branch`
      - where `branch` is an ultrascan3 repo branch
    - `cd ~/ultrascan-branch`
    - `. qt5env`
    - `./makeall.sh`
    - `./makesomo.sh`
    - `~/us3_windows_packaging/utils/fixdependencies.pl update`
      - this will have to be repeated until it gives packaging instructions
        - or fancy bash to repeat until it succeeds (watch out for non-fixable errors, it will repeat until manually interrupted!)
          - ```
            false; while [ $? -ne 0 ]; do ~/us3_windows_packaging/utils/fixdependencies.pl update; done
            ```
      - follow the packaging instructions
 
## after install - building ultrascan again
- always under the `msys2 mingw64` desktop app
- note that `branch` below is replaced by name of the branch used.
- option `--git repo` can be supplied to `setup.pl` to build from a fork
- all cases, make sure to have the latest packaging code
  - `cd ~/us3_windows_packaging`
  - `git pull` 
- existing branch
  - `cd ~/ultrascan-branch`
  - `git fetch origin`
  - `git reset --hard origin/branch`
  - `git pull`
  - `~/us3_windows_packaging/setup/setup.pl --us_update branch`
  - `. qt5env`
  - `./makeall.sh`
  - `./makesomo.sh`
  - `~/us3_windows_packaging/utils/fixdependencies.pl update`
    - this will have to be repeated until it gives packaging instructions
    - follow the packaging instructions
- new branch
  - `~/us3_windows_packaging/setup/setup.pl --us branch`
  - `cd ~/ultrascan-branch`
  - `. qt5env`
  - `./makeall.sh`
  - `./makesomo.sh`
  - `~/us3_windows_packaging/utils/fixdependencies.pl update`
    - this will have to be repeated until it gives packaging instructions
    - follow the packaging instructions

## notes
 - `createinstallfree` will put built packages in `/c/setups` (equivalently `c:/setups`)
 - depending on the speed of your machine & number of processers - it can take quite a while for the setups to finish
   - took about 6 hours on my (old) i7 with 4 cores given to the Window VM and a SATA SSD. 
 - qt versions can be changed [here](setup/setup.pl)
 - some ultrascan3 scripts are modified from the ultrascan3 repo branch, see [here](mods/win10-mingw64-templates)
   - this should eventually be migrated into the repos themselves
     - leaving it this way for now to allow correct building of prior releases
   - this is why the `git fetch orign && git reset --hard origin/branch && git pull && ~/us3_windows_packaging --us_update branch` when `building ultrascan again`
