#!/bin/bash

# Fonksiyon dosyasını içe aktar
 source ./lib/functions.sh

# --- TUI - Whiptail ---
run_tui() {
    # Kullanıcı geçerli bir dosya girene kadar döngüden çıkılmaz.
    while true; do
        INPUT_FILE=$(whiptail --title "Pandoc Dönüştürücü" --inputbox "Dönüştürülecek dosyanın yolunu girin:" 10 60 3>&1 1>&2 2>&3)
        
        # İptal edilirse çık.
        if [ $? -ne 0 ]; then
            echo "İşlem iptal edildi."
            exit 1
        fi

        # Hata: Boş giriş kontrolü - dosya yolu girilmezse tekrar sorulur.
        if [ -z "$INPUT_FILE" ]; then
            whiptail --title "Hata" --msgbox "Dosya yolu boş bırakılamaz! Lütfen tekrar deneyin." 10 60
            continue 
        fi

        # Hata: Dosya var mı kontrolü yoksa tekrar sorulur
        if [ ! -f "$INPUT_FILE" ]; then
            whiptail --title "Hata" --msgbox "Böyle bir dosya bulunamadı: $INPUT_FILE\nLütfen dosya adını kontrol edip tekrar yazın." 10 60
            continue 
        fi

        # Format doğru seçildiyse devam et
        break
    done

    # 2. Format Seçimi
    # Yanlışlıkla iptale basarsa programın çökmemesi için döngü kullanılır
    while true; do
        FORMAT=$(whiptail --title "Format Seçimi" --menu "Hedef formatı seçin:" 17 60 6 \
        "pdf" "PDF Belgesi" \
        "docx" "Word Belgesi" \
        "odt" "OpenDocument" \
        "html" "HTML Sayfası" \
        "md" "Markdown" \
        "txt" "Düz Metin" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
             echo "Format seçimi iptal edildi."
             exit 1
        fi
        
        break
    done

    # 3. Onay ve İşlem
    if (whiptail --title "Onay" --yesno "$INPUT_FILE dosyası $FORMAT formatına dönüştürülecek. Onaylıyor musunuz?" 10 60); then

        # İlerleme Çubuğu (yirmişer aralıklı)
        {
            for ((i = 0 ; i <= 100 ; i+=20)); do
                sleep 0.5
                echo $i
            done
        } | whiptail --gauge "Dönüştürülüyor..." 6 50 0

        # Dönüştürme işlemini çağır ve hataları yakala
        MSG=$(convert_document "$INPUT_FILE" "$FORMAT" 2>&1)
        EXIT_STATUS=$?
        
        if [ $EXIT_STATUS -eq 0 ]; then
             whiptail --title "Başarılı" --msgbox "$MSG" 10 60
        else
             # functions.sh'tan dönen hatayı göster
             whiptail --title "Dönüştürme Hatası" --msgbox "$MSG" 12 70
        fi
    else
        whiptail --title "İptal" --msgbox "İşlem kullanıcı tarafından iptal edildi." 8 40
    fi
}

# --- GUI - YAD ---
run_gui() {
    # Dosya Seçimi
    INPUT_FILE=$(yad --file --title="Dosya Seç" --width=600 --height=400)
    
    # İptal edilirse çık
    if [ -z "$INPUT_FILE" ]; then
        exit 1
    fi

    # Format Seçimi
    FORMAT=$(yad --list --title="Format" --column="Format" --column="Açıklama" \
    "pdf" "PDF Belgesi" \
    "docx" "Word Belgesi" \
    "odt" "OpenDocument" \
    "html" "HTML Sayfası" \
    "md" "Markdown" \
    "txt" "Düz Metin" \
    --height=300 --print-column=1)
    
    # Format seçilmezse çık
    if [ -z "$FORMAT" ]; then
        exit 1
    fi
    
    # Format çıktısını temizle (| karakterini sil)
    FORMAT=$(echo $FORMAT | tr -d '|')
          
    # İlerleme çubuğu ve işlem 
    (
        # İlerleme çubuğu
        for ((i = 20; i <= 80; i+=20)); do
            echo $i
            echo "# Dönüştürülüyor... %$i"
            sleep 0.5
        done

        # Dosya dönüştürme işlemi
        OUTPUT=$(convert_document "$INPUT_FILE" "$FORMAT" 2>&1)
        
        # Bitiş
        echo "100"
        echo "# İşlem Tamamlandı!"
        sleep 0.5
        
        # Sonucu geçici dosyaya yaz
        echo "$OUTPUT" > /tmp/yad_output
    ) | yad --progress --title="İşlem" --percentage=0 --auto-close --width=400

    # Sonucu ekrana bas
    if [ -f /tmp/yad_output ]; then
        MSG=$(cat /tmp/yad_output)
        yad --message --title="Sonuç" --text="$MSG" --width=400
        rm /tmp/yad_output
    fi
}

# --- ANA MENÜ (GİRİŞ NOKTASI) ---

# Eğer YAD yüklü değilse hata vermez direkt TUI açılır
if ! command -v yad &> /dev/null; then
    run_tui
    exit
fi

# Kullanıcıya arayüz sor
CHOICE=$(yad --list --title="Arayüz Seçimi" --text="Lütfen kullanmak istediğiniz arayüzü seçin:" \
--column="Mod" --column="Açıklama" \
"GUI" "Grafiksel Arayüz (Fare ile kullanım)" \
"TUI" "Terminal Arayüzü (Klavye ile kullanım)" \
--height=250 --width=500 --print-column=1 2> /dev/null)

# Seçim Temizliği (Hata vermemesi için '|' kaldırılır)
CHOICE=$(echo $CHOICE | tr -d '|')

# Seçime göre yönlendirme
if [[ "$CHOICE" == "GUI" ]]; then
    run_gui
elif [[ "$CHOICE" == "TUI" ]]; then
    run_tui
else
    echo "Çıkış yapıldı."
    exit 0
fi
