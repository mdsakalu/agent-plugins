# Installing Atlassian CLI (ACLI)

## Check if Installed

```bash
acli --version
```

If this returns a version number, ACLI is already installed. Skip to authentication.

## macOS

### Homebrew (Recommended)

```bash
brew tap atlassian/homebrew-acli
brew install acli
```

Verify installation:
```bash
acli --version
```

### Binary with curl

**Apple Silicon (M1/M2/M3):**
```bash
curl -LO "https://acli.atlassian.com/darwin/latest/acli_darwin_arm64/acli"
chmod +x ./acli
sudo mv ./acli /usr/local/bin/acli
```

**Intel:**
```bash
curl -LO "https://acli.atlassian.com/darwin/latest/acli_darwin_amd64/acli"
chmod +x ./acli
sudo mv ./acli /usr/local/bin/acli
```

## Linux

### Binary with curl

**x86_64:**
```bash
curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_amd64/acli"
chmod +x ./acli
sudo mv ./acli /usr/local/bin/acli
```

**ARM64:**
```bash
curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_arm64/acli"
chmod +x ./acli
sudo mv ./acli /usr/local/bin/acli
```

## Windows

Download from: https://developer.atlassian.com/cloud/acli/guides/install-windows/

Or use PowerShell:
```powershell
Invoke-WebRequest -Uri "https://acli.atlassian.com/windows/latest/acli_windows_amd64/acli.exe" -OutFile "acli.exe"
```

Add to PATH or move to a directory in your PATH.

## Updating ACLI

### Homebrew
```bash
brew upgrade acli
```

### Binary
Re-run the curl command for your platform to download the latest version.

## Troubleshooting

If `acli` command not found after installation:
1. Check your PATH includes `/usr/local/bin`
2. Open a new terminal window
3. Run `which acli` to verify location

## More Information

- Official docs: https://developer.atlassian.com/cloud/acli/guides/install-acli/
- All commands: https://developer.atlassian.com/cloud/acli/reference/commands/
