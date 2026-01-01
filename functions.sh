
#!/bin/bash

# Dosya uzantısını alma fonksiyonu
get_extension() {
    filename=$(basename -- "$1")
    extension="${filename##*.}"
    echo "$extension"
}

# Dönüştürme işlemini yapan fonksiyon
convert_document() {
    # 1. Değişkenler alınır
    local input_file="$1"
    local output_format="$2"
    local output_name="${input_file%.*}.$output_format"

    # 2. Dosya hatalı mı kontrolü yapılır
    if [ ! -f "$input_file" ]; then
        echo "HATA: '$input_file' bulunamadı veya bir dosya değil."
        return 1
    fi

    # Pandoc yüklü mü kontrolü
    if ! command -v pandoc &> /dev/null; then
        echo "HATA: Pandoc yüklü değil! Lütfen 'sudo apt install pandoc' ile yükleyin."
        return 1
    fi

    # Hata çıktısını (stderr) yakalayarak çalıştır 
    PANDOC_OUTPUT=$(pandoc "$input_file" -o "$output_name" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "BAŞARILI: $output_name oluşturuldu."
        return 0
    else
        # Pandoc'un verdiği gerçek hatayı ekrana bas
        echo "HATA: Dönüştürme başarısız!"
        echo "DETAY: $PANDOC_OUTPUT" 
        return 1
    fi
}
    
