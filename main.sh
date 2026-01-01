#!/bin/bash

# Fonksiyon dosyasını içe aktar
source ./functions.sh

# --- TUI Whiptail ---
run_tui() {
    # 1. Dosya Seçimi
    INPUT_FILE=$(whiptail --title "Pandoc Dönüştürücü" --inputbox "Dönüştürülecek dosyanın yolunu girin:" 10 60 3>&1 1>&2 2>&3)

    # İptal edilirse çık
    if [ $? -ne 0 ]; then
        echo "İşlem iptal edildi."
        exit 1
    fi

    # Boş giriş kontrolü
    if [ -z "$INPUT_FILE" ]; then
        echo "HATA: Dosya adı girmediniz."
        exit 1
    fi

    # 2. Format Seçimi
    FORMAT=$(whiptail --title "Format Seçimi" --menu "Hedef formatı seçin:" 17 60 6 \
    "pdf" "PDF Belgesi" \
    "docx" "Word Belgesi" \
    "odt" "OpenDocument" \
    "html" "HTML Sayfası" \
    "md" "Markdown" \
    "txt" "Düz Metin" 3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        echo "Format seçilmedi."
        exit 1
    fi

    # 3. Onay ve İşlem
    if (whiptail --title "Onay" --yesno "$INPUT_FILE dosyası $FORMAT formatına dönüştürülecek. Onaylıyor musunuz?" 10 60); then

        # İlerleme Çubuğu
        {
            for ((i = 0 ; i <= 100 ; i+=20)); do
                sleep 0.5
                echo $i
            done
        } | whiptail --gauge "Dönüştürülüyor..." 6 50 0

        # Dönüştürme işlemini çağır ve hataları yakala
        MSG=$(convert_document "$INPUT_FILE" "$FORMAT" 2>&1)
       
        # Sonucu göster
        whiptail --title "Sonuç" --msgbox "$MSG" 12 70
    else
        echo "Kullanıcı onayı vermedi."
    fi
}

# --- GUI YAD ---
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
   
    if [ -z "$FORMAT" ]; then
        exit 1
    fi
   
    # Format çıktısını temizle (| karakterini sil)
    FORMAT=$(echo $FORMAT | tr -d '|')
         
   # İlerleme çubuğu ve işlem
    (
        # %20'den %80'e kadar ilerleyen çubuk
        for ((i = 20; i <= 80; i+=20)); do
            echo $i                        
            echo "# Dönüştürülüyor... %$i" 
            sleep 0.5                
        done

        # İşlemi yap ve çıktıyı değişkene al
        OUTPUT=$(convert_document "$INPUT_FILE" "$FORMAT" 2>&1)
        
        echo "100"
        echo "# İşlem Tamamlandı!"
        sleep 0.5
        
        # YAD için sonucu geçici dosyaya yaz 
        echo "$OUTPUT" > /tmp/yad_output
    ) | yad --progress --title="İşlem" --percentage=0 --auto-close --width=400

    # Sonucu ekrana bas
    if [ -f /tmp/yad_output ]; then
        MSG=$(cat /tmp/yad_output)
        yad --message --title="Sonuç" --text="$MSG" --width=400
        rm /tmp/yad_output
    fi
}

# --- ANA MENÜ ---

# Eğer YAD yüklü değilse hata vermeden direkt TUI açılır
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

# YAD çıktısının sonundaki '|' işareti temizlenerek else'e girmesi engellenir
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
