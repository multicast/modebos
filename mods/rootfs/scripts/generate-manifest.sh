#!/bin/bash
# Generate manifest of all files in the built image

env|sort > "/env.txt"
dpkg --get-selections >> /dpkg-selections.txt

# Save manifest outside the image in the artifacts directory
MANIFEST_FILE="/manifest.txt"
echo "Generating file manifest..."

# Create manifest with detailed file information
{
    echo "=== File System Manifest ==="
    echo "Generated on: $(date)"
    echo "Hostname: $(hostname)"
    echo ""

    # Comprehensive file listing with permissions, size, and checksums
    echo "=== Complete File Listing ==="
    find / -type f -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" \
        -not -path "/run/*" -not -path "/tmp/*" -not -path "/var/tmp/*" \
        -not -path "/var/cache/*" -not -path "/var/log/*" \
        -exec stat -c "%n|%s|%a|%Y|%U:%G" {} \; \
        | sort

    echo ""
    echo "=== Directory Structure ==="
    find / -type d -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" \
        -not -path "/run/*" -not -path "/tmp/*" -not -path "/var/tmp/*" \
        -not -path "/var/cache/*" -not -path "/var/log/*" \
        -exec stat -c "%n|%a|%Y|%U:%G" {} \; \
        | sort

    echo ""
    echo "=== Package Information ==="
    dpkg-query -W --showformat='${Package}\t${Version}\t${Architecture}\n' | sort

    echo ""
    echo "=== System Information ==="
    uname -a
    echo "Kernel version: $(uname -r)"
    echo "Distribution: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"

    echo ""
    echo "=== File Counts ==="
    echo "Total files: $(find / -type f -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" -not -path "/run/*" -not -path "/tmp/*" -not -path "/var/tmp/*" -not -path "/var/cache/*" -not -path "/var/log/*" | wc -l)"
    echo "Total directories: $(find / -type d -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" -not -path "/run/*" -not -path "/tmp/*" -not -path "/var/tmp/*" -not -path "/var/cache/*" -not -path "/var/log/*" | wc -l)"

    echo ""
    echo "=== Extended Attributes of /usr/bin/ping ==="
    if [ -f /usr/bin/ping ]; then
        echo "File: /usr/bin/ping"
        echo "Extended attributes:"
        getfattr -d /usr/bin/ping 2>/dev/null || echo "No extended attributes found or getfattr not available"
        echo ""
        echo "LSATTR information:"
        lsattr /usr/bin/ping 2>/dev/null || echo "No lsattr information available"
    else
        echo "File /usr/bin/ping not found"
    fi

    echo ""
    echo "=== Disk Usage Summary ==="
    du -sh / 2>/dev/null | head -1
} > "$MANIFEST_FILE"

echo "Manifest generated successfully on $(date)"
