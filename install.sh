#!/bin/bash

# Paket yüklemelerini otomatik olarak gerçekleştiren dosya

# Renkli çıktılar
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

echo -e "${GREEN}--- Pandoc Dönüştürücü Hızlı Kurulum ---${NC}"

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Lütfen yönetici olarak çalıştırın: sudo ./install.sh${NC}"
  exit
fi

# Sistem güncelleme
echo "-> Sistem paket listesi güncelleniyor..."
apt-get update -y > /dev/null 2>&1

# Eksik paketleri tespit et ama kurulum yapma 
echo "-> Eksik paketler tespit ediliyor..."

PACKAGES="pandoc yad whiptail texlive-latex-base texlive-fonts-recommended texlive-extra-utils texlive-latex-extra git"
TO_INSTALL=""

# Paketler yüklü mü kontrolü
for pkg in $PACKAGES; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo -e "[OK] $pkg zaten yüklü."
    else
        echo -e "${RED}[EKSİK] $pkg listeye eklendi.${NC}"
        TO_INSTALL="$TO_INSTALL $pkg"
    fi
done

# Yüklü olmayan paketler toplu olarak tek seferde kurulur.
if [ -z "$TO_INSTALL" ]; then
    echo -e "${GREEN}-> Tüm paketler zaten yüklü! İşlem yapılmadı.${NC}"
else
    echo -e "-> Şu paketler tek seferde kuruluyor: $TO_INSTALL"
    # -y parametresi ile otomatik onay verilir. Sadece gerekli olan paketler kurulur.
    apt-get install -y --no-install-recommends $TO_INSTALL
fi

# Dosya izinleri değiştirilir.
echo "-> Dosya izinleri ayarlanıyor..."
chmod +x main.sh
[ -f lib/functions.sh ] && chmod +x lib/functions.sh

echo -e "${GREEN}--- Kurulum Tamamlandı! ./main.sh ile başlatabilirsiniz. ---${NC}"
