#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run this script as root.${NC}"
    exit 1
fi

check_kernel_version() {
    version=$(uname -r | cut -d '-' -f1)
    major=$(echo "$version" | cut -d '.' -f1)
    minor=$(echo "$version" | cut -d '.' -f2)

    if (( major < 4 )) || { (( major == 4 )) && (( minor < 9 )); }; then
        echo -e "${RED}Kernel version is $version which is older than 4.9.${NC}"
        echo -e "${YELLOW}You need to upgrade your kernel to at least 4.9 to use BBR.${NC}"
        echo -e "${YELLOW}Please upgrade kernel manually and rerun this script.${NC}"
        echo -ne "${YELLOW}Press Enter to exit...${NC}"
        read
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

check_bbr_status() {
    algo=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    echo -n "Current BBR status: "
    if [[ "$algo" == "bbr" ]]; then
        echo -e "${GREEN}Enabled${NC}"
    else
        echo -e "${RED}Disabled${NC}"
    fi
}

check_ipv6_status() {
    status_all=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)
    status_default=$(sysctl -n net.ipv6.conf.default.disable_ipv6 2>/dev/null)
    echo -n "IPv6 status: "
    if [[ "$status_all" == "1" && "$status_default" == "1" ]]; then
        echo -e "${RED}Disabled${NC}"
    else
        echo -e "${GREEN}Enabled${NC}"
    fi
}

enable_bbr() {
    echo "Detected distribution: $DISTRO"
    case "$DISTRO" in
        ubuntu|debian)
            grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p
            ;;
        centos|rhel|fedora)
            grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p
            ;;
        arch)
            echo "net.core.default_qdisc=fq" > /etc/sysctl.d/99-bbr.conf
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-bbr.conf
            sysctl --system
            ;;
        *)
            echo -e "${RED}Unsupported distribution. Manual setup may be required.${NC}"
            return
            ;;
    esac
    echo -e "${GREEN}BBR enabled.${NC}"
}

disable_bbr() {
    case "$DISTRO" in
        ubuntu|debian|centos|rhel|fedora)
            sed -i '/net.core.default_qdisc=fq/d' /etc/sysctl.conf
            sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
            sysctl -w net.ipv4.tcp_congestion_control=cubic
            sysctl -p
            ;;
        arch)
            rm -f /etc/sysctl.d/99-bbr.conf
            sysctl -w net.ipv4.tcp_congestion_control=cubic
            sysctl --system
            ;;
        *)
            echo -e "${RED}Unsupported distribution. Manual cleanup may be required.${NC}"
            return
            ;;
    esac
    echo -e "${RED}BBR disabled.${NC}"
}

enable_ipv6() {
    echo "Enabling IPv6..."
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
    sysctl -w net.ipv6.conf.default.disable_ipv6=0

    if ! grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.disable_ipv6=0" >> /etc/sysctl.conf
    else
        sed -i 's/^net.ipv6.conf.all.disable_ipv6=.*/net.ipv6.conf.all.disable_ipv6=0/' /etc/sysctl.conf
    fi

    if ! grep -q "net.ipv6.conf.default.disable_ipv6" /etc/sysctl.conf; then
        echo "net.ipv6.conf.default.disable_ipv6=0" >> /etc/sysctl.conf
    else
        sed -i 's/^net.ipv6.conf.default.disable_ipv6=.*/net.ipv6.conf.default.disable_ipv6=0/' /etc/sysctl.conf
    fi

    echo -e "${GREEN}IPv6 enabled.${NC}"
}

disable_ipv6() {
    echo "Disabling IPv6..."
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1

    if ! grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
    else
        sed -i 's/^net.ipv6.conf.all.disable_ipv6=.*/net.ipv6.conf.all.disable_ipv6=1/' /etc/sysctl.conf
    fi

    if ! grep -q "net.ipv6.conf.default.disable_ipv6" /etc/sysctl.conf; then
        echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
    else
        sed -i 's/^net.ipv6.conf.default.disable_ipv6=.*/net.ipv6.conf.default.disable_ipv6=1/' /etc/sysctl.conf
    fi

    echo -e "${RED}IPv6 disabled.${NC}"
}

check_kernel_version

while true; do
    clear
    echo "==================================="
    echo -e "GitHub: ${GREEN}https://github.com/monhacer${NC}"
    echo "==================================="
    echo ""
    check_bbr_status
    check_ipv6_status
    echo ""
    echo "========= BBR & IPv6 Menu ========="
    echo ""
    echo -e "1.${GREEN} Enable BBR${NC}"
    echo -e "2.${GREEN} Disable BBR${NC}"
    echo -e "3.${GREEN} Enable IPv6${NC}"
    echo -e "4.${GREEN} Disable IPv6${NC}"
    echo -e "0.${GREEN} Exit${NC}"
    echo ""
    echo -ne "${YELLOW}Select an option: ${NC}"
    read choice

    case $choice in
        1)
            enable_bbr
            echo -ne "${YELLOW}Press Enter to continue...${NC}"
            read
            ;;
        2)
            disable_bbr
            echo -ne "${YELLOW}Press Enter to continue...${NC}"
            read
            ;;
        3)
            enable_ipv6
            echo -ne "${YELLOW}Press Enter to continue...${NC}"
            read
            ;;
        4)
            disable_ipv6
            echo -ne "${YELLOW}Press Enter to continue...${NC}"
            read
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            echo -ne "${YELLOW}Press Enter to continue...${NC}"
            read
            ;;
    esac
done
