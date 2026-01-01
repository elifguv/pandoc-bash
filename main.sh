#!/bin/bash

# Fonksiyon dosyasını içe aktar
source ./functions.sh

# --- TUI Whiptail ---
run_tui() {
    # Uyumlu bir çıktı almak için temporary dosya oluştur
    TEMP_RESULT=$(mktemp)

    # 1. Dosya Seçimi
    whiptail --title "Pandoc Dönüştürücü" --inputbox "Dönüştürülecek dosyanın tam yolunu girin:" 10 60 2> "$TEMP_RESULT"
    
    # Kullanıcı iptal'e basarsa çıkış
    if [ $? -ne 0 ]; then
        echo "İşlem iptal edildi."
        rm "$TEMP_RESULT" # Geçici dosyayı sil
        exit 1
    fi
    
    # Dosyadaki veriyi değişkene al
    INPUT_FILE=$(cat "$TEMP_RESULT")

    # Dosya yolu boş mu kontrolü
    if [ -z "$INPUT_FILE" ]; then
        echo "Dosya yolu girilmedi."
        rm "$TEMP_RESULT"
        exit 1
    fi

    # 2. Format Seçimi
    whiptail --title "Format Seçimi" --menu "Hedef formatı seçin:" 17 60 6 \
    "pdf" "PDF Belgesi" \
    "docx" "Word Belgesi" \
    "odt" "OpenDocument (LibreOffice)" \
    "html" "HTML Sayfası" \
    "md" "Markdown" \
    "txt" "Düz Metin" 2> "$TEMP_RESULT"

    if [ $? -ne 0 ]; then
        echo "Format seçilmedi veya iptal edildi."
        rm "$TEMP_RESULT"
        exit 1
    fi

    FORMAT=$(cat "$TEMP_RESULT")

    # 3. Onay ve İşlem
    if (whiptail --title "Onay" --yesno "$INPUT_FILE dosyası $FORMAT formatına dönüştürülecek. Onaylıyor musunuz?" 10 60); then
        # Görsel ilerleme çubuğu
        {
            for ((i = 0 ; i <= 100 ; i+=20)); do
                sleep 0.5
                echo $i
            done
        } | whiptail --gauge "Dönüştürülüyor..." 6 50 0

        # Dönüştürme işlemini (functions.sh) çağır
        MSG=$(convert_document "$INPUT_FILE" "$FORMAT")
        
        whiptail --title "Sonuç" --msgbox "$MSG" 10 60
    else
        echo "Kullanıcı onayı vermedi."
    fi

    # Geçici dosyayı sil
    rm "$TEMP_RESULT"
}

# --- GUI YAD ---
run_gui() {
    # Dosya Seçimi
    INPUT_FILE=$(yad --file --title="Dönüştürülecek Dosyayı Seçin" --width=600 --height=400)
    
    if [ -z "$INPUT_FILE" ]; then
        exit 1
    fi

    # Format Seçimi
    FORMAT=$(yad --list --title="Format Seçimi" --column="Format" --column="Açıklama" \
    "pdf" "PDF Belgesi" \
    "docx" "Word Belgesi" \
    "odt" "OpenDocument (LibreOffice)" \
    "html" "HTML Sayfası" \
    "md" "Markdown" \
    "txt" "Düz Metin" \
    --height=350 --width=450 --print-column=1)

    if [ -z "$FORMAT" ]; then
        exit 1
    fi
    
    # Format çıktısını temizle
    FORMAT=$(echo $FORMAT | tr -d '|')

    # İlerleme Çubuğu ve İşlem
    (
        echo "10"; sleep 0.5
        echo "# Dönüştürülüyor: $INPUT_FILE -> $FORMAT"; sleep 0.5
        echo "50"
        OUTPUT=$(convert_document "$INPUT_FILE" "$FORMAT")
        echo "100"
        echo "# İşlem Tamamlandı!"
    ) | yad --progress --title="İşlem Sürüyor" --percentage=0 --auto-close

    # Sonuç Mesajı
    yad --message --title="Sonuç" --text="Dönüştürme işlemi tamamlandı!\nDosya konumu: ${INPUT_FILE%.*}.$FORMAT" --button="Tamam:0"
}

# --- ANA MENÜ ---
# Mac testi için direkt TUI çalıştır, ana menüdeki seçim için güncelle
run_tui
