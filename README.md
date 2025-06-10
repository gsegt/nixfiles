# Nixfiles

Nixfiles for all my systems.

- [Nixfiles](#nixfiles)
  - [1. Install](#1-install)
    - [1.1. Set a password for ssh access (optional)](#11-set-a-password-for-ssh-access-optional)
    - [1.2. Partitioning](#12-partitioning)
      - [1.2.1. Partition the drive](#121-partition-the-drive)
      - [1.2.2. Preparing the root partition](#122-preparing-the-root-partition)
      - [1.2.3. Encrypt root partition](#123-encrypt-root-partition)
        - [1.2.3.1. Create and mount btrfs partition](#1231-create-and-mount-btrfs-partition)
      - [1.2.4. Preparing the EFI System Partition](#124-preparing-the-efi-system-partition)
        - [1.2.4.1. Format EFI System Partition](#1241-format-efi-system-partition)
        - [1.2.4.2. Mount EFI System Partition](#1242-mount-efi-system-partition)
      - [1.2.5. Clone repo](#125-clone-repo)
    - [1.3. Generate hardware-config](#13-generate-hardware-config)
    - [1.4. Create initrd ssh key](#14-create-initrd-ssh-key)
    - [1.5. Install the system](#15-install-the-system)
    - [1.6. Post install](#16-post-install)

## 1. Install

1. Boot up the NIxOS minimal ISO on the target machine

### 1.1. Set a password for ssh access (optional)

1. Run `passwd` to give the default nixos user a password to ssh into it.

### 1.2. Partitioning

#### 1.2.1. Partition the drive

1. Run `sudo lsblk` to find your drive
2. Run `sudo sgdisk --zap-all /dev/${drive}` to completely erase your drive and create new GPT partition table with no partitions
3. Run the following command to partition the drive and give the partitions labels:

    ```shell
    sudo sgdisk --clear \
      --new=1:0:+1GiB --typecode=1:ef00 --change-name=1:ESP \
      --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsystem \
      /dev/${drive}
    ```

4. Run `lsblk -o +partlabel` to verify partitioning and labelling

> [!NOTE]
> `partlabel` (and `label` further down the guide) are optional are are simply based on convenience.

#### 1.2.2. Preparing the root partition

#### 1.2.3. Encrypt root partition

1. Run `sudo cryptsetup luksFormat /dev/disk/by-partlabel/cryptsystem` and then type `YES` and then type your encryption password twice to encrypt the root partition
2. Run `sudo cryptsetup open /dev/disk/by-partlabel/cryptsystem system` to open the encrypted partition with name `system` ; It can now be found under `/dev/mapper/system`

##### 1.2.3.1. Create and mount btrfs partition

1. Run `sudo mkfs.btrfs --label system /dev/mapper/system` to create the Btrfs root filesystem with the label `system`
2. Run `sudo mount -o defaults,noatime,compress-force=zstd:1,x-mount.mkdir LABEL=system /mnt` to mount the root Btrfs partition to `/mnt`
   - `noatime` prevents update time of a file on reads
   - `compress-force=zstd:1` will enable native compression with zstd algorithm at level 1 and use zstd algorithm to figure if compressing a file is worth it instead of Btrfs' algorithm
   - `x-mount.mkdir` creates a folder if necessary

#### 1.2.4. Preparing the EFI System Partition

##### 1.2.4.1. Format EFI System Partition

1. Run `sudo mkfs.vfat -F32 -n ESP /dev/disk/by-partlabel/ESP` to create the FAT32 boot filesystem with label `ESP`

##### 1.2.4.2. Mount EFI System Partition

1. Run `sudo mount -o defaults,umask=0077,x-mount.mkdir LABEL=ESP /mnt/boot` to mount the ESP in `/mnt`
    - `umask=0077` will mount the drive with 0700 default permissions

2. Run `lsblk -o +label` to verify mounting and labelling

#### 1.2.5. Clone repo

1. Run `mkdir -vp .ssh` to create the `.ssh` folder
2. Run `echo "<your_key>" > .ssh/github` to create you private github key, it should already be associated with your account
3. Run `chmod 600 .ssh/github` to set correct read/write permission for the private key
4. Run the following to create an ssh config that can clone from github

    ```shell
    echo "#: github.com - commit/pull/push to github.com
    Host github.com gist.github.com
        HostName github.com
        IdentityFile ~/.ssh/github
    " > .ssh/config
    ```

5. Run `sudo mkdir -vp /mnt/etc/nixos` to create the folder for our config
6. Run `sudo chown nixos:users /mnt/etc/nixos` to let the current user have full permissions over the folder
7. Run `git clone git@github.com:gsegt/nixfiles.git /mnt/etc/nixos` to clone the configuration is the appropriate repo

### 1.3. Generate hardware-config

1. Run `sudo nixos-generate-config --show-hardware-config --root /mnt > /mnt/etc/nixos/system/hardware-configuration.nix` to re-generate an up to date hardware config
2. Run `nix-shell -p nixfmt-rfc-style --run 'nixfmt /mnt/etc/nixos/system/hardware-configuration.nix'` to format the hardware configuration file
3. Run `nano /mnt/etc/nixos/system/hardware-configuration.nix` to add the following to the hardware-config:

    ```conf
    fileSystems."/" = {
        ...
        options = [
            "compress-force=zstd:1"
            "noatime"
        ];
    };
    ```

### 1.4. Create initrd ssh key

1. Run `sudo mkdir -vp /mnt/etc/secrets/initrd/` to create a directory for the initrd ssh key
2. Run `ssh-keygen -a 128 -t ed25519 (or -t rsa -b 4096) -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key` to create the ssh key
3. Run `sudo chmod 700 /mnt/etc/secrets/` to secure access to the directory, allowing only `root`

### 1.5. Install the system

1. Run `sed -i 's|./upgrade-diff.nix|# ./upgrade-diff.nix|g' /mnt/etc/nixos/system/default.nix /mnt/etc/nixos/home/default.nix` to avoid errors messages
2. Run `sudo nixos-install --flake /mnt/etc/nixos#aspire` to install the system
3. Run `reboot` to enjoy your your new system; Congratulations by the way \o/

> [!IMPORTANT]
> Additionally, if you have any keyfiles to transfer, now is a good time.

### 1.6. Post install

1. Run `passwd` to change the password from its default value
2. Run `sed -i 's|# ./upgrade-diff.nix|./upgrade-diff.nix|g' /etc/nixos/system/default.nix /etc/nixos/home/default.nix` to restore the upgrade-diff function
3. Run `sudo zfs import <vault>` to import your zfs pool, if any
