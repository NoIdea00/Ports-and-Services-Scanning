# 🔍 Port Scanner with Naabu & Nmap

A lightweight Bash script to automate port scanning using [Naabu](https://github.com/projectdiscovery/naabu) and [Nmap](https://nmap.org/). It supports scanning individual IPs or domains as well as multiple targets from a file. All results are timestamped and saved in organized directories for easy review.

## 🚀 Features

- ✅ Validates IPv4 and domain inputs
- 📁 Saves organized scan results per target and timestamp
- 🛠️ Uses:
  - [Naabu](https://github.com/projectdiscovery/naabu) for fast port discovery
  - [Nmap](https://nmap.org/) for service and version detection
- 📜 Logs all output into detailed logs for each scan
- 📦 Batch scan support via input file

## 🧪 Requirements

- `bash`
- `naabu`
- `nmap`

Ensure both `naabu` and `nmap` are installed and available in your system `$PATH`.

## 📦 Installation

```bash
git clone https://github.com/your-username/port-scan-tool.git
cd port-scan-tool
chmod +x port-scan.sh
```

## 🛠 Usage

### Scan a single target:
```bash
./port-scan.sh example.com
```

### Scan multiple targets from file:
```bash
./port-scan.sh -f targets.txt
```

File format:
```
example.com
192.168.0.1
```

### Display help:
```bash
./port-scan.sh -h
```

## 📂 Output Structure

Each scan creates a structured directory:
```
scans/
└── example.com/
    └── 20250515-1430/
        ├── naabu.txt
        ├── nmap.txt
        └── scan.log
```

## 📃 License

This project is licensed under the MIT License.

---

### 📬 Contribution

No Thanks!
