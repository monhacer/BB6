# BB6 🚀

**BB6** is a simple Bash script to manage Linux network optimizations:

- ⚡ Enable/disable **BBR** TCP congestion control  
- 🌐 Enable/disable **IPv6**  
- 📶 Check and set **MTU** values on network interfaces  

---

## Features ✨

- 🐧 Auto detects Linux distribution (Debian, Ubuntu, CentOS, RHEL, Fedora, Arch)  
- 🔍 Checks kernel version (must be 4.9+) for BBR support  
- 🖧 Detects multiple network interfaces and lets you choose which one to configure  
- 📊 Displays current status of BBR, IPv6, and MTU  
- 🎛 Interactive menu for easy management  
- 💾 Saves settings persistently using sysctl  

---

## Usage 🛠️

Run the script as root:
```
wget https://raw.githubusercontent.com/monhacer/BB6/refs/heads/main/setup.sh
chmod +x setup.sh
./setup.sh
```
Follow the interactive menu to enable/disable BBR, IPv6, or set MTU.

---

## MTU Tips 💡

- 🚨 If you experience high packet loss or instability, try lowering the MTU value (e.g., from 1500 to 1400 or 1300)  
- 📦 MTU affects maximum packet size; setting it too high or too low may cause network issues  

---

## License 📄

This project is open source and free to use.
