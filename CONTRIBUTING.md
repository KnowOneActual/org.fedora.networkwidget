# Contributing to Network Info Widget

Thank you for considering contributing to the Network Info Widget! We welcome community contributions, bug fixes, and feature enhancements.

---

## 🛠️ Getting Started

Before contributing code, please review the [Development Guide](file:///home/user/github/org.fedora.networkwidget/DEVELOPMENT.md) to understand the project architecture, how to set up your local development environment, and how to test your changes.

---

## 📋 Code of Conduct

Please treat all maintainers and contributors with respect. We aim to foster a welcoming, helpful, and friendly community environment.

---

## 💡 How Can I Contribute?

### 1. Reporting Bugs
* Check the existing issues or commit logs to see if the bug has already been addressed.
* If not, open a new issue describing:
  * What version of KDE Plasma you are running.
  * Your operating system and version (e.g., Fedora 40 KDE).
  * The steps to reproduce the issue.
  * The expected vs. actual behavior.
  * Any error logs from `journalctl --user -u plasma-plasmashell`.

### 2. Suggesting Enhancements
* We follow a strict **opt-in** architecture for advanced features to keep the default layout minimal. Check [roadmap.md](file:///home/user/github/org.fedora.networkwidget/roadmap.md) to see planned features.
* Open an issue or start a discussion explaining:
  * The feature you want to add.
  * Why it is useful.
  * How you propose designing the configuration UI for it.

### 3. Submitting Pull Requests
* Fork the repository and create your branch from `main`.
* Write clean, readable code and ensure it follows the guidelines below.
* Verify your changes locally using:
  * standalone QML validation: `plasmoidviewer -a org.fedora.networkwidget`
  * python test script: `python3 contents/ui/get_info.py`
* Open a pull request with a detailed description of the changes.

---

## ✍️ Coding Guidelines

### QML (Frontend)
* **Match Active Theme**: Never hardcode colors. Use semantic palette variables from KDE's theme system:
  * Text: `Kirigami.Theme.textColor`
  * Muted Label: `Kirigami.Theme.disabledTextColor`
  * Accent: `Kirigami.Theme.highlightColor`
* **Avoid Hardcoded Sizing**: Use `Kirigami.Units` (e.g., `Kirigami.Units.gridUnit`, `Kirigami.Units.smallSpacing`) to ensure high-DPI scaling works correctly.
* **Reactive Sizing**: Ensure your layouts dynamically update their heights to prevent clipping issues.

### Python (Backend)
* **Standard Library First**: Keep dependencies minimal. Use standard library modules (`subprocess`, `json`, `sys`, `argparse`, `socket`) rather than introducing third-party packages.
* **Graceful Fallbacks**: If a CLI utility (e.g., `resolvectl`) is missing or fails, log the error to stderr and return `"None"` or empty values in JSON rather than crashing.
* **Compatibility**: Write Python code that works on Python 3.6+ and doesn't rely on OS-specific paths that may differ between Fedora and other Linux distributions.
