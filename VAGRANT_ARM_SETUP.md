# Vagrant Setup Guide for ARM Macs (Apple Silicon)

## The Problem

VirtualBox does not support running x86 VMs on ARM-based Macs (M1, M2, M3, M4 chips). When you try to run `vagrant up` with a VirtualBox provider and an x86 box, you'll get:

```
VBoxManage: error: Cannot run the machine because its platform architecture x86 is not supported on ARM
```

## Solutions

### Option 1: Use VMware Fusion (Recommended) ✅

VMware Fusion supports ARM architecture on Apple Silicon Macs.

#### Step 1: Install VMware Fusion
```bash
# Download VMware Fusion for Mac with Apple silicon
# Get it from: https://www.vmware.com/products/fusion/fusion-evaluation.html
# Personal Use License is FREE
```

#### Step 2: Install Vagrant VMware Provider
```bash
# Install the VMware Utility
# Download from: https://developer.hashicorp.com/vagrant/downloads/vmware

# Install the Vagrant VMware plugin
vagrant plugin install vagrant-vmware-desktop
```

#### Step 3: Update Vagrantfile
The Vagrantfile has been updated to use `bento/ubuntu-22.04-arm64` box and support VMware provider.

#### Step 4: Run Vagrant
```bash
# Specify VMware provider
vagrant up --provider=vmware_desktop

# Or set as default
export VAGRANT_DEFAULT_PROVIDER=vmware_desktop
vagrant up
```

---

### Option 2: Use Parallels Desktop 💰

Parallels Desktop has excellent ARM support but requires a paid license.

#### Installation
```bash
# Install Parallels Desktop from: https://www.parallels.com/

# Install Vagrant Parallels provider
vagrant plugin install vagrant-parallels
```

#### Update Vagrantfile
Add this to your Vagrantfile:
```ruby
config.vm.provider "parallels" do |prl|
  prl.name = "rohan-rest-app"
  prl.memory = 2048
  prl.cpus = 2
end
```

#### Run
```bash
vagrant up --provider=parallels
```

---

### Option 3: Use QEMU (Free Alternative) 🆓

QEMU with libvirt is a free alternative that works on ARM Macs.

#### Installation
```bash
# Install QEMU
brew install qemu

# Install libvirt
brew install libvirt

# Install Vagrant libvirt plugin
vagrant plugin install vagrant-libvirt
```

#### Update Vagrantfile
```ruby
config.vm.provider "libvirt" do |libvirt|
  libvirt.memory = 2048
  libvirt.cpus = 2
end
```

#### Run
```bash
vagrant up --provider=libvirt
```

---

### Option 4: Use Docker Instead (Simplest) 🐳 ⭐

Since you already have Docker working, you might not need Vagrant at all!

#### Your existing Docker setup:
```bash
# Start everything with Docker Compose
make start-api

# Access API at http://localhost:8080
curl http://localhost:8080/health
```

#### Advantages:
- ✅ Already configured and working
- ✅ Lighter than VMs
- ✅ Faster startup
- ✅ Same environment as production
- ✅ No hypervisor needed

---

### Option 5: Use Multipass (Ubuntu's Solution) 🎯

Multipass is Ubuntu's official VM solution, free and ARM-compatible.

#### Installation
```bash
# Install Multipass
brew install multipass
```

#### Create VM
```bash
# Create an Ubuntu VM
multipass launch --name rohan-rest-app --memory 2G --cpus 2 --disk 10G

# Mount project directory
multipass mount . rohan-rest-app:/home/ubuntu/rohan-rest-app

# Get a shell
multipass shell rohan-rest-app

# Inside the VM
cd /home/ubuntu/rohan-rest-app
./scripts/script.sh  # Run your installation script
```

---

## Comparison Table

| Solution | Cost | ARM Support | Ease of Use | Performance |
|----------|------|-------------|-------------|-------------|
| **Docker** | Free | ✅ Native | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **VMware Fusion** | Free (Personal) | ✅ Yes | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Multipass** | Free | ✅ Yes | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **QEMU/libvirt** | Free | ✅ Yes | ⭐⭐⭐ | ⭐⭐⭐ |
| **Parallels** | Paid ($99/yr) | ✅ Yes | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **VirtualBox** | Free | ❌ No | N/A | N/A |

---

## Recommended Approach

### For Your Use Case:

1. **Primary: Use Docker** (you already have it working!)
   ```bash
   make start-api
   make logs-all
   make test
   ```

2. **Secondary: Use VMware Fusion** (if you need a full VM)
   - Free for personal use
   - Best ARM support
   - Works with Vagrant
   - Your Vagrantfile is already updated!

3. **Alternative: Use Multipass** (lightweight Ubuntu VMs)
   - Perfect for development
   - Easy to use
   - Official Ubuntu solution

---

## Quick Start with VMware Fusion

Since I've updated your Vagrantfile, here's how to get started:

```bash
# 1. Install VMware Fusion
# Download from: https://www.vmware.com/products/fusion.html

# 2. Install VMware Utility
# Download from: https://developer.hashicorp.com/vagrant/downloads/vmware

# 3. Install Vagrant plugin
vagrant plugin install vagrant-vmware-desktop

# 4. Destroy existing VM (if any)
vagrant destroy -f

# 5. Start with VMware
vagrant up --provider=vmware_desktop

# 6. SSH into VM
vagrant ssh

# 7. Check the app
curl http://localhost:8080/health
```

---

## Why Not VirtualBox on ARM?

VirtualBox 7.x added limited ARM support, but:
- ❌ Can only run ARM guests on ARM hosts (no x86 emulation)
- ❌ Most Vagrant boxes are x86
- ❌ Limited box availability
- ❌ Performance issues
- ✅ Better alternatives exist

---

## Updated Vagrantfile Features

Your Vagrantfile now includes:

✅ ARM64 Ubuntu box (`bento/ubuntu-22.04-arm64`)
✅ VMware Fusion support (primary)
✅ VirtualBox fallback (for Intel Macs)
✅ rsync synced folders (better compatibility)
✅ Proper networking configuration
✅ Automatic provisioning script

---

## Troubleshooting

### If VMware Fusion installation fails:
```bash
# Check plugin status
vagrant plugin list

# Reinstall plugin
vagrant plugin uninstall vagrant-vmware-desktop
vagrant plugin install vagrant-vmware-desktop
```

### If box download is slow:
```bash
# Download box manually
vagrant box add bento/ubuntu-22.04-arm64
```

### If provisioning fails:
```bash
# SSH into VM and run manually
vagrant ssh
cd /vagrant
./scripts/script.sh
```

---

## My Recommendation

**Just use Docker!** 🐳

Your project is already set up with Docker Compose and working perfectly. Unless you specifically need a full Ubuntu VM for some reason, stick with Docker:

```bash
# Start everything
make start-api

# View logs
make logs-all

# Run tests
make test

# Stop everything
make stop-all
```

It's faster, lighter, and already working on your ARM Mac!

---

## Next Steps

Choose your path:

**A. Continue with Docker (Recommended)**
```bash
make start-api
# Done! ✅
```

**B. Set up VMware Fusion**
```bash
# Follow the Quick Start guide above
```

**C. Try Multipass**
```bash
brew install multipass
multipass launch --name rohan-rest-app
```

---

**Last Updated**: October 22, 2025
**Your Mac**: ARM-based (Apple Silicon)
**Current Status**: Vagrantfile updated for ARM support
