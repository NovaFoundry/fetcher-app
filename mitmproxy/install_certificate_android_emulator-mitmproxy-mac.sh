#!/bin/bash -eu

#
# install_certificate_android_emulator-mitmproxy-mac.sh
#
# Version: v1: 
# - Install mitmproxy certificate to android emulator/device
# - Configure HTTP proxy for mitmproxy
# - Based on Proxyman's script
#
# For support, please refer to mitmproxy documentation
#

mode=""
ip=""
port=""
mitmCert=""
include_physical="false" # Default value

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -m|--mode)
        mode="$2"
        shift # past argument
        shift # past value
        ;;
        -i|--ip)
        ip="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--port)
        port="$2"
        shift # past argument
        shift # past value
        ;;
        -c|--cert)
        mitmCert="$2"
        shift # past argument
        shift # past value
        ;;
        --include-physical)
        include_physical="true"
        shift # past argument
        ;;
        *) # unknown option
        echo "❌ Error: Unknown option '$1'"
        echo "Use -h or --help for usage information."
        exit 1
        ;;
    esac
done

# --- Usage Function ---
print_usage() {
    echo "Usage: $0 -m <mode> [options]"
    echo ""
    echo "Modes:"
    echo "  all             Set proxy and install certificate"
    echo "  proxy           Set proxy only"
    echo "  revertProxy     Revert proxy settings only"
    echo "  certificate     Install certificate only"
    echo ""
    echo "Required Options based on Mode:"
    echo "  -m, --mode <mode>              : Operation mode (all, proxy, revertProxy, certificate)"
    echo "  -i, --ip <ip_address>          : IP address (required for all, proxy, certificate)"
    echo "  -p, --port <port_number>       : Port number (required for all, proxy, certificate)"
    echo "  -c, --cert <path_to_cert.pem>  : Path to mitmproxy certificate (required for all, certificate)"
    echo "                                   Default: ~/.mitmproxy/mitmproxy-ca-cert.pem"
    echo ""
    echo "Optional Options:"
    echo "  --include-physical            : Include physical devices (default: only emulators)"
    echo "  -h, --help                    : Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -m all -i 127.0.0.1 -p 8080 -c ~/.mitmproxy/mitmproxy-ca-cert.pem"
    echo "  $0 -m proxy -i 192.168.1.100 -p 8080 --include-physical"
    echo "  $0 -m revertProxy"
    echo "  $0 -m certificate -i 127.0.0.1 -p 8080 -c ~/.mitmproxy/mitmproxy-ca-cert.pem"

}

# --- Argument Validation ---
if [[ -z "$mode" ]]; then
    echo "❌ Error: Mode (-m or --mode) is required."
    print_usage
    exit 1
fi

# Validate mode value
valid_modes=("all" "proxy" "revertProxy" "certificate")
is_valid_mode=false
for valid_mode in "${valid_modes[@]}"; do
    if [[ "$mode" == "$valid_mode" ]]; then
        is_valid_mode=true
        break
    fi
done

if [[ "$is_valid_mode" == "false" ]]; then
    echo "❌ Error: Invalid mode '$mode'."
    print_usage
    exit 1
fi

# Validate required arguments based on mode
if [[ "$mode" == "all" ]] || [[ "$mode" == "proxy" ]] || [[ "$mode" == "certificate" ]]; then
    if [[ -z "$ip" ]]; then
        echo "❌ Error: IP Address (-i or --ip) is required for mode '$mode'."
        print_usage
        exit 1
    fi
    if [[ -z "$port" ]]; then
        echo "❌ Error: Port (-p or --port) is required for mode '$mode'."
        print_usage
        exit 1
    fi
fi

# Check for default mitmproxy certificate location if not specified
if [[ "$mode" == "all" ]] || [[ "$mode" == "certificate" ]]; then
    if [[ -z "$mitmCert" ]]; then
        # Try to use default mitmproxy certificate location
        DEFAULT_CERT="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"
        if [[ -f "$DEFAULT_CERT" ]]; then
            mitmCert="$DEFAULT_CERT"
            echo "ℹ️ Using default mitmproxy certificate: $mitmCert"
        else
            echo "❌ Error: Certificate Path (-c or --cert) is required for mode '$mode'."
            echo "Default certificate not found at: $DEFAULT_CERT"
            print_usage
            exit 1
        fi
    elif [[ ! -f "$mitmCert" ]]; then
         echo "❌ Error: Certificate file not found at '$mitmCert'."
         exit 1
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Install mitmproxy Certificate to Android Emulator/Device Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  Important Notes:"
echo "   • Only supports Android Emulators with Google APIs"
echo "   • DO NOT support Google Play Store version"
echo ""
echo "📚 Documentation:"
echo "   https://docs.mitmproxy.org/stable/concepts-certificates/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚙️  Settings:"
echo "   Mode                : $mode"
if [[ -n "$ip" ]]; then echo "   IP Address          : $ip"; fi
if [[ -n "$port" ]]; then echo "   Port                : $port"; fi
if [[ -n "$mitmCert" ]]; then echo "   Certificate Path    : $mitmCert"; fi
echo "   Include Physical Dev: $include_physical"
echo ""

checkADBCommand() {
    echo "Checking adb command..."
    if ! command -v adb &> /dev/null
    then
        echo ""
        echo "❌ [ERROR] ADB Command Not Found"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Please install Android Debug Bridge (adb) from android-platform-tools"
        echo ""
        echo "📥 Installation Steps:"
        echo "━━━━━━━━━━━━━━━━━━━━━━"
        echo "1. Install Homebrew (Skip if already installed):"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)\""
        echo ""
        echo "2. Install ADB:"
        echo "   brew install android-platform-tools"
        echo ""
        echo "3. Run this script again"
        echo ""
        exit 1
    fi
    echo "✅ ADB found at: $(which adb)"
}

checkDeviceStatusFunc() {
    echo "1. Checking Android Emulators Status..."

    # Get error output
    # Use || true to prevent the script is exited
    states=$(adb get-state 2>&1 1>/dev/null) || true

    if [[ $states == "error: no devices/emulators found" ]]; then
        echo ""
        echo "❌ [ERROR] No Active Android Emulators Found"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Please start an Android Emulator from Android Studio and try again"
        echo ""
        exit 1
    elif [[ $states == "error: more than one device/emulator" ]]; then
        echo "ℹ️  Found multiple Android Emulators"
        # continue running, do not exit
    elif [[ $states == "error: device offline" ]]; then
        echo ""
        echo "❌ [ERROR] Device is Offline"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Please restart your Android Emulator and try again"
        echo ""
        exit 1
    elif [[ -z "$states" ]]; then
        echo "✅ Status: Device Ready"
    else
        echo ""
        echo "❌ [ERROR] Unexpected Error"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Error details: $states"
        echo "Please try running the script again"
        echo ""
        exit 1
    fi
}

# --- Helper function to determine if a device should be processed ---
should_process_device() {
    local device_id="$1"
    local include_physical_flag="$2"
    local is_emulator="false"

    if [[ "$device_id" == *"emulator"* ]]; then
        is_emulator="true"
    fi

    if [[ "$include_physical_flag" == "true" ]]; then
        return 0 # Process all devices (physical and emulators)
    elif [[ "$is_emulator" == "true" ]]; then
        return 0 # Process only emulators
    else
        return 1 # Skip physical devices when include_physical is false
    fi
}

# --- Helper function to get device type string ---
get_device_type_string() {
    local device_id="$1"
    if [[ "$device_id" == *"emulator"* ]]; then
        echo "Emulator Device"
    else
        echo "Physical Device"
    fi
}

overrideProxyAndInstallCertificateFunc() {
    # Override proxy
    overrideProxy

    # Install certificate to root
    __inject_root_certificate

    print_success_message
}

print_success_message() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Installation Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Restart your app from Android Studio"
    echo "   2. Start mitmproxy with: mitmproxy -p $port"
    echo "   3. Or start mitmweb with: mitmweb -p $port"
    echo ""
}

installCertificateFunc() {
    ## Install certificate to root
    __inject_root_certificate
    print_success_message
}

__inject_root_certificate() {
    echo "3. Installing mitmproxy Certificate to System-Level CA..."

    # Get the certificate hash
    CERT_HASH=$(openssl x509 -inform PEM -subject_hash_old -in "$mitmCert" | head -1)
    if [ -z "$CERT_HASH" ]; then
        echo "❌ Error: Could not calculate certificate hash"
        exit 1
    fi

    # Process each device
    for device in $(adb devices | grep -v "List" | grep "device$" | cut -f1); do
        # Determine if this device should be processed
        if should_process_device "$device" "$include_physical"; then
            local device_type=$(get_device_type_string "$device")
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🤖 Processing $device_type: $device"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

            # Push the certificate to the device
            adb -s "$device" push "$mitmCert" "/data/local/tmp/$CERT_HASH.0"

            # Create and push the injection script with multi-path support
            INJECTION_SCRIPT="/data/local/tmp/inject_cert.sh"
            cat << 'EOF' | adb -s "$device" shell "cat > $INJECTION_SCRIPT"
#!/system/bin/sh

# Create a separate temp directory for current certificates
mkdir -p -m 700 /data/local/tmp/tmp-ca-copy

# Determine the source certificate path based on Android version
if [ -d "/apex/com.android.conscrypt/cacerts" ]; then
    CERT_SOURCE="/apex/com.android.conscrypt/cacerts"
elif [ -d "/system/etc/security/cacerts" ]; then
    CERT_SOURCE="/system/etc/security/cacerts"
elif [ -d "/system/etc/certificates" ]; then
    CERT_SOURCE="/system/etc/certificates"
elif [ -d "/etc/security/cacerts" ]; then
    CERT_SOURCE="/etc/security/cacerts"
# Some older Android versions or custom ROMs
elif [ -d "/data/misc/keychain/cacerts-added" ]; then
    CERT_SOURCE="/data/misc/keychain/cacerts-added"
elif [ -d "/system/ca-certificates/files" ]; then
    CERT_SOURCE="/system/ca-certificates/files"
else
    echo "❌ Error: Could not find certificate directory"
    echo "Searched in:"
    echo "- /apex/com.android.conscrypt/cacerts"
    echo "- /system/etc/security/cacerts"
    echo "- /system/etc/certificates"
    echo "- /etc/security/cacerts"
    echo "- /data/misc/keychain/cacerts-added"
    echo "- /system/ca-certificates/files"
    exit 1
fi

echo "📂 Using certificate source: $CERT_SOURCE"

# Copy out the existing certificates
cp $CERT_SOURCE/* /data/local/tmp/tmp-ca-copy/ 2>/dev/null || true

# Create the in-memory mount on top of the system certs folder
mkdir -p /system/etc/security/cacerts
mount -t tmpfs tmpfs /system/etc/security/cacerts

# Copy the existing certs back into the tmpfs
mv /data/local/tmp/tmp-ca-copy/* /system/etc/security/cacerts/ 2>/dev/null || true

# Copy our new cert in
mv /data/local/tmp/*.0 /system/etc/security/cacerts/

# Update the permissions and selinux context labels
chown root:root /system/etc/security/cacerts/*
chmod 644 /system/etc/security/cacerts/*
chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*

# Handle Zygote processes
ZYGOTE_PID=$(pidof zygote || true)
ZYGOTE64_PID=$(pidof zygote64 || true)

# Inject into Zygote mount namespaces
for Z_PID in "$ZYGOTE_PID" "$ZYGOTE64_PID"; do
    if [ -n "$Z_PID" ]; then
        nsenter --mount=/proc/$Z_PID/ns/mnt -- \
            /bin/mount --bind /system/etc/security/cacerts $CERT_SOURCE
    fi
done

# Get PIDs of all Zygote child processes
APP_PIDS=$(
    echo "$ZYGOTE_PID $ZYGOTE64_PID" | \
    xargs -n1 ps -o 'PID' -P | \
    grep -v PID
)

# Inject into app mount namespaces
for PID in $APP_PIDS; do
    nsenter --mount=/proc/$PID/ns/mnt -- \
        /bin/mount --bind /system/etc/security/cacerts $CERT_SOURCE &
done
wait

EOF

            # Make the injection script executable
            adb -s "$device" shell "chmod +x $INJECTION_SCRIPT"

            # Execute the injection script as root
            adb -s "$device" shell "su 0 $INJECTION_SCRIPT"

            # Configure Chrome flags
            SPKI_FINGERPRINT=$(openssl x509 -in "$mitmCert" -pubkey -noout | \
                openssl pkey -pubin -outform der | \
                openssl dgst -sha256 -binary | \
                base64)

            CHROME_FLAGS_SCRIPT="/data/local/tmp/chrome_flags.sh"
            cat << EOF | adb -s "$device" shell "cat > $CHROME_FLAGS_SCRIPT"
#!/system/bin/sh
FLAGS="chrome --ignore-certificate-errors-spki-list=$SPKI_FINGERPRINT"

for variant in chrome android-webview webview content-shell; do
    for base_path in /data/local /data/local/tmp; do
        FLAGS_PATH=\$base_path/\$variant-command-line
        echo "\$FLAGS" > "\$FLAGS_PATH"
        chmod 744 "\$FLAGS_PATH"
        chcon "u:object_r:shell_data_file:s0" "\$FLAGS_PATH"
    done
done
EOF

            # Execute Chrome flags script
            adb -s "$device" shell "chmod +x $CHROME_FLAGS_SCRIPT"
            adb -s "$device" shell "su 0 sh $CHROME_FLAGS_SCRIPT"
            adb -s "$device" shell "su 0 am force-stop com.android.chrome"

            # Force stop all apps to apply changes
            APPS=$(adb -s $device shell dumpsys window a | grep "/" | cut -d "{" -f2 | cut -d "/" -f1 | cut -d " " -f2)
            for APP in $APPS; do
                adb -s $device shell am force-stop $APP
            done

            echo "✅ Certificate injection completed for $device_type $device"
        else
            local device_type=$(get_device_type_string "$device")
             echo ""
             echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
             echo "📱 Skipping $device_type (not included): $device"
             echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
    done
}

revertProxy() {
    echo "2. Reverting HTTP Proxy Settings..."
    for device in $(adb devices | grep -v "List" | grep "device$" | cut -f1); do
        # Determine if this device should be processed
        if should_process_device "$device" "$include_physical"; then
            local device_type=$(get_device_type_string "$device")
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🤖 Processing $device_type: $device"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            adb -s $device shell settings put global http_proxy :0
            if [ $? -eq 0 ]; then
                echo "✅ Proxy settings removed successfully for $device_type $device"
            else
                echo "❌ Failed to revert proxy settings for $device_type $device"
            fi
        else
            local device_type=$(get_device_type_string "$device")
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📱 Skipping $device_type (not included): $device"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
    done
    echo ""
}

overrideProxy() {
    echo "2. Configuring HTTP Proxy..."
    echo "   Target: mitmproxy ($ip:$port)"
    for device in $(adb devices | grep -v "List" | grep "device$" | cut -f1); do
        # Determine if this device should be processed
        if should_process_device "$device" "$include_physical"; then
            local device_type=$(get_device_type_string "$device")
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "🤖 Processing $device_type: $device"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            adb -s $device shell svc wifi enable
            adb -s $device shell settings put global http_proxy $ip:$port
            if [ $? -eq 0 ]; then
                echo "✅ Proxy configured successfully for $device_type $device"
            else
                echo "❌ Failed to configure proxy for $device_type $device"
            fi
        else
            local device_type=$(get_device_type_string "$device")
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📱 Skipping $device_type (not included): $device"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
    done
    echo ""
}

# Main

## Check adb
checkADBCommand

## Check Status first
checkDeviceStatusFunc

if [[ $mode == "all" ]]; then
    overrideProxyAndInstallCertificateFunc
elif [[ $mode == "proxy" ]]; then
    overrideProxy
elif [[ $mode == "revertProxy" ]]; then
    revertProxy
elif [[ $mode == "certificate" ]]; then
    installCertificateFunc
fi