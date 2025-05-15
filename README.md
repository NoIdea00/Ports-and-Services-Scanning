# 🔍 Port Scanner Automation Script

A Python-based automation script that scans one or multiple IPs/domains using **Naabu** and **Nmap**. It performs quick port discovery with Naabu and detailed service detection using Nmap, saving structured results for later review.

---

## 🚀 Features

- 🔎 Validates input as IP or domain
- 📁 Creates organized scan directories per target and timestamp
- ⚡ Runs:
  - `naabu` for fast port detection
  - `nmap` for service/version detection
- 📝 Generates logs and summary reports
- 📊 Option to compile all Nmap results into a single file

---

## 🧰 Requirements

- Python 3.6+
- [Naabu](https://github.com/projectdiscovery/naabu)
- [Nmap](https://nmap.org)

---

## 📦 Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/NoIdea00/Ports-and-Services-Scanning-.git
   cd port-scanner-automation
   ```

2. **Install Python dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

3. **Ensure external tools are installed and in PATH:**

   - Naabu: `go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest`
   - Nmap: [Install from official site](https://nmap.org/download.html) or via package manager.

---

## 🛠 Usage

### Scan a single domain or IP

```bash
python3 scanner.py example.com
```

### Scan multiple targets from a file

```bash
python3 scanner.py -f targets.txt
```

---

## 📂 Output Structure

Scans are saved under the `scans/` directory:

```
scans/
├── example.com/
│   └── 20240515-1200/
│       ├── naabu.txt
│       ├── nmap.txt
│       └── scan.log
```

---

## 📊 Summary & Compilation

After scans are complete, a summary report is printed, and you’ll be prompted to compile all Nmap results into one file (`compiled_nmap_results.txt`).

---

## 🧪 Example

```bash
python3 scanner.py 192.168.1.1
```

```bash
python3 scanner.py -f list_of_targets.txt
```

---

## 🤝 Contributions

Pull requests and issues are welcome! Feel free to fork and improve.

---

## ⚠️ Disclaimer

This tool is intended for **authorized testing and educational purposes only**. Unauthorized scanning may be illegal.

---

## 📄 License

MIT License
