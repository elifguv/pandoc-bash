#!/bin/bash

# Dosya uzantısını alma fonksiyonu
get_extension() {
    filename=$(basename -- "$1")
    extension="${filename##*.}"
    echo "$extension"
}

# Dönüştürme işlemini yapan fonksiyon
convert_document() {

    # Verilen dosya hatalı mı kontrolü
    if [ ! -f "$input_file" ]; then
    	echo "HATA: '$input_file' bulunamadı veya bir dosya değil."
   	 return 1
    fi

    local input_file="$1"
    local output_format="$2"
    local output_name="${input_file%.*}.$output_format"

    # Pandoc yüklü mü kontrolü
    if ! command -v pandoc &> /dev/null; then
        echo "HATA: Pandoc yüklü değil! Lütfen 'sudo apt install pandoc' ile yükleyin."
        return 1
    fi

    # Dönüştürme komutu
    pandoc "$input_file" -o "$output_name"
    
    if [ $? -eq 0 ]; then
        echo "BAŞARILI: $output_name oluşturuldu."
        return 0
    else
        echo "HATA: Dönüştürme başarısız oldu."
        return 1
    fi
}
