#!/bin/bash

# CSV Dosyalarını Kontrol ve Oluşturma
csv_dosya_kontrol() {
    # depo.csv oluştur
    if [ ! -f "depo.csv" ]; then
        touch depo.csv
        echo "Ürün No,Ürün Adı,Stok Miktarı,Birim Fiyatı,Kategori" > depo.csv
        chmod 600 depo.csv # Sadece oluşturucu kullanıcı okuyup yazabilir
    fi

    # kullanici.csv oluştur ve admin kullanıcısını ekle
    if [ ! -f "kullanici.csv" ]; then
        touch kullanici.csv
        echo "Kullanıcı Adı,Şifre,Rol,Durum" > kullanici.csv
        echo "1:$(echo -n "1" | md5sum | awk '{print $1}'):1" >> kullanici.csv
        chmod 600 depo.csv # Sadece oluşturucu kullanıcı okuyup yazabilir
    fi

    # log.csv oluştur
    if [ ! -f "log.csv" ]; then
        touch log.csv
        echo "Hata Kodu,Zaman Bilgisi,Kullanıcı,Mesaj" > log.csv
        chmod 600 depo.csv # Sadece oluşturucu kullanıcı okuyup yazabilir
    fi
}

# Log dosyasındaki en yüksek hata numarasını bul ve bir artır
hata_no_belirleme() {
    if [ -f "log.csv" ]; then
        max_error_no=$(awk -F',' 'NR>1 {if($1 > max) max=$1} END {print max}' log.csv)
        echo $((max_error_no + 1))
    else
        echo 1
    fi
}

# Log Kayıt Fonksiyonu
log_kayit_kullanici_girisi() {
    hata_mesaji="$1"
    zaman=$(date "+%Y-%m-%d %H:%M:%S")
    hata_no=$(awk -F',' 'END {print $1+1}' log.csv)
    echo "$hata_no,$zaman,$username,$hata_mesaji" >> log.csv
}


hizli_yedek() {
    # Yedekleme dizini oluştur
    yedek_dizini="yedekler"
    mkdir -p "$yedek_dizini"

    # Yedekleme işlemleri
    cp -f depo.csv "$yedek_dizini/" 2>/dev/null
    cp -f kullanici.csv "$yedek_dizini/" 2>/dev/null
    cp -f log.csv "$yedek_dizini/" 2>/dev/null
}

# Kullanıcı adı girme ekranı
kullanici_adi_ekrani() {
    while true; do
        # Kullanıcı adı girme ekranı
        username=$(zenity --entry --title="Giriş Ekranı" --text="Kullanıcı Adınızı Girin:" \
                          --cancel-label="Çıkış" --ok-label="Giriş")

        # Kullanıcı 'Çıkış' butonuna basarsa programı kapat
        if [ $? -ne 0 ]; then
            cikis_giris_ekrani
            return
        fi

        # Kullanıcı adı kontrolü
        if grep -q "^$username:" kullanici.csv; then
            # Kullanıcının durumunu kontrol et (aktif veya kilitli)
            durum=$(awk -F':' -v user="$username" '$1==user {print $4}' kullanici.csv)

            if [ "$durum" == "kilitli" ]; then
                # Hesap kilitliyse uyarı mesajı göster
                zenity --error --title="Hesap Kilitli" --text="Hesabınız kilitlenmiştir! Lütfen yöneticiyle iletişime geçin."
            else
                # Kullanıcı aktifse şifre ekranına geç
                sifre_ekrani
                return
            fi
        else
            # Kullanıcı adı bulunamadıysa hata mesajı göster
            zenity --error --title="Kullanıcı Bulunamadı" --text="Girilen kullanıcı adı mevcut değil! Lütfen tekrar deneyin."
        fi
    done
}


# Şifre Değiştirme Fonksiyonu
sifre_degistir() {
    while true; do
        # Kullanıcıdan yeni şifre ve onay alın
        yeni_sifre_form=$(zenity --forms --title="Şifre Değiştir" --text="Yeni şifrenizi girin ve onaylayın:" \
            --add-password="Yeni Şifre" \
            --add-password="Şifre Onayı")
        
        if [ $? -ne 0 ]; then
            # İptal edilirse işlemi sonlandır
            zenity --warning --title="İptal Edildi" --text="Şifre değiştirme işlemi iptal edildi."
            return
        fi

        # Şifreleri ayır
        yeni_sifre=$(echo "$yeni_sifre_form" | awk -F'|' '{print $1}')
        sifre_onay=$(echo "$yeni_sifre_form" | awk -F'|' '{print $2}')

        # Şifre eşitliğini kontrol et
        if [ "$yeni_sifre" != "$sifre_onay" ]; then
            zenity --error --title="Hata" --text="Girdiğiniz şifreler eşleşmiyor! Lütfen tekrar deneyin."
        else
            # Şifreler eşit ise işlem tamamlanır
            hashed_pass=$(echo -n "$yeni_sifre" | md5sum | awk '{print $1}')
            sed -i "s/^$username:.*/$username:$hashed_pass:1:aktif/" kullanici.csv
            zenity --info --title="Başarılı" --text="Şifreniz başarıyla değiştirildi!"
            return
        fi
    done
}

# Şifre Ekranı
sifre_ekrani() {
    deneme_sayisi=0
    while true; do
        # Kullanıcı rolünü kontrol et
        rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)

        if [ "$rol" == "1" ]; then
            # Yönetici için şifre ekranı
            secim=$(zenity --list --title="Yönetici Şifre Ekranı" --text="Bir işlem seçin:" \
                --column="Seçenekler" \
                "1. Giriş Yap" \
                "2. Şifre Değiştir" \
                "3. Geri Dön")
            
            case "$secim" in
                "1. Giriş Yap")
                    password=$(zenity --password --title="Şifre Girişi" --text="Şifrenizi girin:")
                    if [ $? -ne 0 ]; then
                        zenity --warning --title="İptal Edildi" --text="Giriş işlemi iptal edildi."
                        continue
                    fi
                    hashed_pass=$(echo -n "$password" | md5sum | awk '{print $1}')
                    if grep -q "^$username:$hashed_pass" kullanici.csv; then
                        zenity --info --title="Giriş Başarılı" --text="Hoş geldiniz, $username!"
                        ana_menu
                        return
                    else
                        zenity --error --title="Hatalı Giriş" --text="Şifre hatalı! Lütfen tekrar deneyin."
                    fi
                    ;;
                "2. Şifre Değiştir")
                    sifre_degistir  # Şifre değiştirme fonksiyonu çağrılır
                    ;;
                "3. Geri Dön")
                    kullanici_adi_ekrani
                    return
                    ;;
                *)
                    zenity --error --title="Hata" --text="Geçersiz seçim!"
                    ;;
            esac
        else
            # Yönetici değilse standart şifre ekranı
            password=$(zenity --password --title="Şifre Ekranı" --text="Şifrenizi girin:")
            if [ $? -ne 0 ]; then
                zenity --warning --title="İptal Edildi" --text="Giriş işlemi iptal edildi."
                kullanici_adi_ekrani
                return
            fi
            hashed_pass=$(echo -n "$password" | md5sum | awk '{print $1}')
            if grep -q "^$username:$hashed_pass" kullanici.csv; then
                zenity --info --title="Giriş Başarılı" --text="Hoş geldiniz, $username!"
                ana_menu
                return
            else
                ((deneme_sayisi++))
                zenity --error --title="Hatalı Giriş" --text="Şifre hatalı! En fazla 3 yanlış giriş hakkınız vardır. Deneme sayısı: $deneme_sayisi"

                # 3 hatalı giriş sonrası hesap kilitleme
                if [ $deneme_sayisi -ge 3 ]; then
                    sed -i "s/^$username:.*/$username:$(awk -F':' -v user="$username" '$1==user {print $2}' kullanici.csv):$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv):kilitli/" kullanici.csv
                    zenity --error --title="Hesap Kilitlendi" --text="Üç hatalı giriş nedeniyle hesabınız kilitlendi!"
                    kullanici_adi_ekrani
                    return
                fi
            fi
        fi
    done
}

# Yönetici Kilitli Hesapları Görüntüleme ve Kilit Açma
hesap_kilidi_ac() {

	    rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)
	    
	    if [ "$rol" != "1" ]; then
	    	#rol 1 değilse yetki hatası verir
	    	zenity --error --title="Yetki Hatası" --text="Yetkiniz yetersiz! Bu sayfayı yanlız yöneticiler erişebilir." --ok-label="Menüye Dön"
	    	ana_menu #ana menüye geri döner
	    	return
	    fi
    while true; do	    
	    # Kilitli hesapları listele
	    kilitli_hesaplar=$(awk -F':' '$4=="kilitli" {print $1}' kullanici.csv)

	    if [ -z "$kilitli_hesaplar" ]; then
		zenity --info --title="Hesap Kilidi Aç" --text="Kilitli hesap bulunmamaktadır."
		return
	    fi

	    # Zenity list ile kilitli hesapları göster
	    secilen_kullanici=$(zenity --list --title="Kilitli Hesaplar" --width=400 --height=300 \
	    	--column="Kullanıcı Adı" --ok-label="Kilidi Aç" --cancel-label="Geri Dön" $kilitli_hesaplar)
	    	
	    if [ $? -ne 0 ]; then
	    	ana_menu 
	    	return
	    fi

	    # Eğer hiçbir hesap seçilmezse uyarı ver
	    if [ -z "$secilen_kullanici" ]; then
		zenity --warning --title="Hesap Seçilmedi" --text="Herhangi bir hesap seçmediniz."
		return
	    fi

	    # Seçilen kullanıcının kilidini aç
	    sed -i "s/^$secilen_kullanici:.*/$secilen_kullanici:$(awk -F':' -v user="$secilen_kullanici" '$1==user {print $2}' kullanici.csv):$(awk -F':' -v user="$secilen_kullanici" '$1==user {print $3}' kullanici.csv):aktif/" kullanici.csv
	    log_kayit_kullanici_girisi "Hesap kilidi açıldı ($secilen_kullanici)"
	    zenity --info --title="Başarılı" --text="$secilen_kullanici hesabının kilidi açıldı."
	    
	    hizli_yedek
    done
}


kullanici_yonetimi() {
    while true; do  
    	    # bu fonksiyonu sadece yöneticiler kullanabilmesi için kontrol kısmı ekleriz 
    	    rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)
	    
	    if [ "$rol" != "1" ]; then
	    	#rol 1 değilse yetki hatası verir
	    	zenity --error --title="Yetki Hatası" --text="Yetkiniz yetersiz! Bu sayfayı yanlız yöneticiler erişebilir." --ok-label="Menüye Dön"
	    	ana_menu #ana menüye geri döner
	    	return
	    fi 
	    
	    # yönetim menüsü
	    secim=$(zenity --list --title="Kullanıcı Yönetimi" --text="Bir işlem seçin" --width=400 --height=700 --column="İşlemler"  --cancel-label="Menüye Dön"\
		"1. Yeni Kullanıcı Ekle" \
		"2. Kullanıcıları Listele" \
		"3. Kullanıcı Güncelle" \
		"4. Kullanıcı Silme" \
		"5. Kilitli Hesapları Yönet")
		
		#kullanıcı bir seçim yapmaz ise (cancel durumunu seçerse)
		if [ $? -ne 0 ]; then
	 		ana_menu
	 		return
	 	fi

	    case $secim in
		"1. Yeni Kullanıcı Ekle") yeni_kullanici_ekle ;;
		"2. Kullanıcıları Listele") kullanicilari_listele ;;
		"3. Kullanıcı Güncelle") kullanici_guncelle ;;
		"4. Kullanıcı Silme") kullanici_sil ;;
		"5. Kilitli Hesapları Yönet") hesap_kilidi_ac ;;
		
		
	    esac
    done
}

# Yeni Kullanıcı Ekle
yeni_kullanici_ekle() {
    # Kullanıcı adı girin
    kullanici_adi=$(zenity --entry --title="Yeni Kullanıcı" --text="Kullanıcı Adı:")
    if [ $? -ne 0 ]; then return; fi

    # Benzersiz kullanıcı adı kontrolü
    if grep -q "^$kullanici_adi:" kullanici.csv; then
        zenity --error --title="Hata" --text="Bu kullanıcı adı zaten kayıtlı!"
        return
    fi

    # Şifre girin
    sifre=$(zenity --password --title="Yeni Kullanıcı" --text="Şifre:")
    if [ $? -ne 0 ]; then return; fi

    # Rol seçimi
    rol=$(zenity --list --title="Rol Seçimi" --text="Kullanıcı rolünü seçin:" --column="Rol" "Yönetici" "Kullanıcı")
    if [ $? -ne 0 ]; then return; fi

    # Rol değerini 1 veya 2 olarak ayarla
    case "$rol" in
        "Yönetici") rol_num=1 ;;
        "Kullanıcı") rol_num=2 ;;
        *) zenity --error --title="Hata" --text="Geçersiz rol seçimi!"; return ;;
    esac

    # Şifreyi hashle
    hashed_pass=$(echo -n "$sifre" | md5sum | awk '{print $1}')

    # Kullanıcıyı dosyaya kaydet
    echo "$kullanici_adi:$hashed_pass:$rol_num:aktif" >> kullanici.csv
    zenity --info --title="Başarılı" --text="Yeni kullanıcı başarıyla eklendi."
    
    hizli_yedek
}




# Kullanıcı Güncelle
kullanici_guncelle() {
    # Kullanıcı adı girişi
    kullanici_adi=$(zenity --entry --title="Kullanıcı Güncelle" --text="Güncellenecek Kullanıcı Adını Girin:")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Güncelleme işlemi iptal edildi."
        return
    fi

    # Kullanıcı adı kontrolü
    mevcut_kullanici=$(grep "^$kullanici_adi:" kullanici.csv)
    if [ -z "$mevcut_kullanici" ]; then
        zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
        return
    fi

    # Kullanıcı bilgilerini ayır
    eski_sifre=$(echo "$mevcut_kullanici" | awk -F':' '{print $2}')
    eski_rol=$(echo "$mevcut_kullanici" | awk -F':' '{print $3}')
    eski_durum=$(echo "$mevcut_kullanici" | awk -F':' '{print $4}')

  while true; do
    # Yeni bilgiler için kullanıcıdan giriş al
    yeni_kullanici_adi=$(zenity --entry --title="Kullanıcı Güncelle" --text="Yeni Kullanıcı Adı:" --entry-text="$kullanici_adi")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Güncelleme işlemi iptal edildi."
        return
    fi
    
    # Yeni kullanıcı adının başka bir kullanıcı ile aynı olup olmadığını kontrol et
        if grep -q "^$yeni_kullanici_adi:" kullanici.csv && [ "$yeni_kullanici_adi" != "$kullanici_adi" ]; then
            zenity --error --title="Hata" --text="Bu kullanıcı adı zaten mevcut! Lütfen başka bir ad deneyin."
        else
            break
        fi
    done
    
    zenity --info --title="Bilgilendirme" --text="Yeni Şifre (Boş bırakırsanız mevcut şifre korunur)"
    yeni_sifre=$(zenity --password --title="Kullanıcı Güncelle" --text="Yeni Şifre (Boş bırakırsanız eski şifre korunur):")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Güncelleme işlemi iptal edildi."
        return
    fi

    yeni_rol=$(zenity --list --title="Rol Seçimi" --text="Yeni Rol Seçin:" --column="Rol" "1 (Yönetici)" "2 (Kullanıcı)")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Güncelleme işlemi iptal edildi."
        return
    fi

    # Sadece "1" veya "2" olarak kaydedilecek
    yeni_rol=$(echo "$yeni_rol" | awk '{print $1}')
    
    # Durumu otomatik güncelle
    if [ "$eski_rol" == "1" ] && [ "$yeni_rol" == "2" ]; then
        yeni_durum="aktif"
    elif [ "$eski_rol" == "2" ] && [ "$yeni_rol" == "1" ]; then
        yeni_durum=""
    else
        # Durum değişmeyecekse eski durumu koru
        yeni_durum="$eski_durum"
    fi

    # Şifreyi kontrol et ve hashle (boş bırakılırsa eski şifre korunur)
    if [ -z "$yeni_sifre" ]; then
        yeni_hashed_sifre="$eski_sifre"
    else
        yeni_hashed_sifre=$(echo -n "$yeni_sifre" | md5sum | awk '{print $1}')
    fi

    # Kullanıcı bilgilerini güncelle
    sed -i "s/^$kullanici_adi:.*/$yeni_kullanici_adi:$yeni_hashed_sifre:$yeni_rol:$yeni_durum/" kullanici.csv

    # Güncelleme başarılı mesajı
    zenity --info --title="Başarılı" --text="Kullanıcı bilgileri başarıyla güncellendi!"
    
    hizli_yedek
}




# Kullanıcıları Listele
kullanicilari_listele() {
# Rol değerine göre düzenleme: 1 -> Yönetici, 2 -> Kullanıcı
    liste=$(awk -F':' 'NR>1 {
        rol=($3=="1") ? "Yönetici" : ($3=="2") ? "Kullanıcı" : "Bilinmeyen";
	if ($3=="1") {
            print "Kullanıcı Adı: " $1 " | Rol: " rol 
        } else {
            print "Kullanıcı Adı: " $1 " | Rol: " rol " | Durum: " $4 
        }
      }' kullanici.csv)
    
    if [ -z "$liste" ]; then
        zenity --info --title="Kullanıcı Listesi" --text="Listelenecek kullanıcı bulunmamaktadır."
    else
        zenity --text-info --title="Kullanıcı Listesi" --width=500 --height=700 --filename=<(echo "$liste")
    fi
}

# Kullanıcı Silme
kullanici_sil() {
    # Silinecek kullanıcıyı seç
    kullanici_adi=$(zenity --entry --cancel-label="Geri Dön" --title="Kullanıcı Silme" --text="Silinecek Kullanıcı Adını Girin:" )
    if [ $? -ne 0 ]; then return; fi  # İptal edilirse geri dön

    if ! grep -q "^$kullanici_adi:" kullanici.csv; then
        zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
        return
    fi

# Silme işlemi için onay iste
    zenity --question --title="Kullanıcı Silme Onayı" \
           --text="Bu kullanıcıyı silmek istediğinizden emin misiniz?\n\nKullanıcı: $kullanici_adi"

    # Kullanıcının yanıtını kontrol et
    if [ $? -eq 0 ]; then
        # Kullanıcı "Evet" dedi, silme işlemini yap
        sed -i "/^$kullanici_adi:/d" kullanici.csv
        zenity --info --title="Başarılı" --text="Kullanıcı başarıyla silindi!"
    else
        # Kullanıcı "Hayır" dedi
        zenity --info --title="İptal Edildi" --text="Silme işlemi iptal edildi."
    fi
    
    hizli_yedek
}


# Program Yönetimi Fonksiyonu
program_yonetimi() {
    while true; do
     	    # bu fonksiyonu sadece yöneticiler kullanabilmesi için kontrol kısmı ekleriz 
    	    rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)
	    
	    if [ "$rol" != "1" ]; then
	    	#rol 1 değilse yetki hatası verir
	    	zenity --error --title="Yetki Hatası" --text="Yetkiniz yetersiz! Bu sayfayı yanlız yöneticiler erişebilir." --ok-label="Menüye Dön"
	    	ana_menu #ana menüye geri döner
	    	return
	    fi 
	    
        # Program Yönetimi Seçenekleri
        secim=$(zenity --list --title="Program Yönetimi" --width=400 --height=700 --text="Bir işlem seçin"\
            --column="Seçenekler" --cancel-label="Menüye Dön" \
            "1. Diskteki Alanı Göster" \
            "2. Diske Yedekle" \
            "3. Hata Kayıtlarını Göster" )
            
		#kullanıcı bir seçim yapmaz ise (cancel durumunu seçerse)
		if [ $? -ne 0 ]; then
	 		ana_menu
	 		return
	 	fi

        case "$secim" in
            "1. Diskteki Alanı Göster") alan_goster ;;
            "2. Diske Yedekle") diske_yedekle ;;
            "3. Hata Kayıtlarını Göster") hata_kayitlarini_goster ;;
            
            *) zenity --error --title="Hata" --text="Geçersiz seçim! Lütfen tekrar deneyin." ;;
        esac
    done
}

# 1. Diskteki Alanı Göster
alan_goster() {
    # İlgili dosyaların boyutunu göster
    du -h *.sh depo.csv kullanici.csv log.csv > disk_alan.txt
    zenity --text-info --title="Diskte Kapladığı Alan" --filename=disk_alan.txt --width=400 --height=400 \
    --cancel-label="Menüye Dön"
    rm -f disk_alan.txt
}

# Diske Yedekle
diske_yedekle() {
    # Yedekleme dizini oluştur
    yedek_dizini="yedekler"
    mkdir -p "$yedek_dizini"

    # İlerleme çubuğu başlat
    (
        echo "10"; sleep 2  # %10 tamamlandı
        echo "# depo.csv dosyası yedekleniyor..."; sleep 2
        if cp depo.csv "$yedek_dizini/"; then
            echo "50"  # %50 tamamlandı
        else
            # Başarısız işlem loga kaydediliyor
            hata_no=$(hata_no_belirleme)
            echo "$hata_no, $(date), Yedekleme Hatası, Yedekleme başarısız: depo.csv kopyalanamadı!" >> log.csv
            exit 1
        fi

        echo "# kullanici.csv dosyası yedekleniyor..."; sleep 2
        if cp kullanici.csv "$yedek_dizini/"; then
            echo "100"  # %100 tamamlandı
        else
            # Başarısız işlem loga kaydediliyor
            hata_no=$(hata_no_belirleme)
            echo "$hata_no, $(date), Yedekleme Hatası, Yedekleme başarısız: kullanici.csv kopyalanamadı!" >> log.csv
            exit 1
        fi

        echo "# Yedekleme işlemi tamamlandı."
    ) | zenity --progress --title="Yedekleme İşlemi"  --auto-close --text="Yedekleme başlatılıyor..."

    # Yedekleme tamamlandığında başarı veya hata durumunu kontrol et
    if [ $? -eq 0 ]; then
        zenity --info --title="Yedekleme Tamamlandı" --text="Dosyalar başarıyla '$yedek_dizini' dizinine yedeklendi." 
    else
        zenity --error --title="Yedekleme Başarısız" --text="Yedekleme işlemi sırasında bir hata oluştu." 
    fi
}

# 3. Hata Kayıtlarını Göster
hata_kayitlarini_goster() {
    if [ ! -f log.csv ]; then
        zenity --error --title="Hata" --text="Hata kayıt dosyası bulunamadı!"
        return
    fi

    # log.csv dosyasını görüntüle
    zenity --text-info --title="Hata Kayıtları" --filename=log.csv --width=500 --height=700 \
    --cancel-label="Menüye Dön"
}



# Ürün Ekleme Fonksiyonu
urun_ekle() {
    # Bu fonksiyonu sadece yöneticiler kullanabilir
    rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)
    if [ "$rol" != "1" ]; then
        # Rol 1 değilse yetki hatası
        zenity --error --title="Yetki Hatası" --text="Yetkiniz yetersiz! Bu sayfayı yalnızca yöneticiler kullanabilir." --ok-label="Menüye Dön"
        ana_menu
        return
    fi

    # Yeni ürün numarasını bul
    if [ -f "depo.csv" ]; then
        urun_no=$(awk -F',' 'NR>1 {if($1>max) max=$1} END {print max+1}' depo.csv)
    else
        urun_no=1
    fi

    # Form ile bilgileri al
    urun_bilgileri=$(zenity --forms --title="Ürün Ekle" --text="Yeni ürün bilgilerini girin:" \
        --add-entry="Ürün Adı" \
        --add-entry="Stok Miktarı (Pozitif Sayı)" \
        --add-entry="Birim Fiyatı (Pozitif Sayı)")
    
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün ekleme işlemi iptal edildi."
        return
    fi

    # Formdaki bilgileri ayır
    urun_adi=$(echo "$urun_bilgileri" | awk -F'|' '{print $1}')
    stok_miktari=$(echo "$urun_bilgileri" | awk -F'|' '{print $2}')
    birim_fiyat=$(echo "$urun_bilgileri" | awk -F'|' '{print $3}')

    # Kategori seçimi
    kategori=$(zenity --list --title="Kategori Seçimi" --text="Kategori seçin:" --width=400 --height=700 \
        --column="Kategori" \
        "Kırtasiye" "Elektronik" "Ev Eşyaları" "Gıda" "Giyim" "Mobilya" "Spor Malzemeleri" "Kozmetik" \
        "Oyuncak" "Hobi ve Sanat" "Beyaz Eşya" "Mutfak Gereçleri" "Bahçe ve Yapı Malzemeleri" \
        "Kamp ve Outdoor" "Petshop Ürünleri" "Oto Aksesuarları" "Sağlık ve Medikal" \
        "Ayakkabı ve Çanta" "Kitap ve Yayınlar" "Tekstil ve Kumaş")
    
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün ekleme işlemi iptal edildi."
        return
    fi
    
    # Doğrulamalar
    if [[ -z "$urun_adi" || "$urun_adi" =~ \  ]]; then
        zenity --error --title="Hata" --text="Ürün adı boş olamaz ve boşluk içeremez!"
        hata_no=$(hata_no_belirleme)
        echo "$hata_no, $(date), Hata: Geçersiz ürün adı" >> log.csv
        return
    fi

    # Aynı isim ve kategori kontrolü
    if grep -q ",$urun_adi,.*,$kategori$" depo.csv; then
        zenity --error --title="Hata" --text="Bu ürün adı ve kategoriyle başka bir kayıt bulunmaktadır. Lütfen farklı bir ad veya kategori seçiniz."
        hata_no=$(hata_no_belirleme)
        echo "$hata_no, $(date), Hata: Aynı isim ve kategoride ürün ekleme girişimi - $urun_adi ($kategori)" >> log.csv
        return
    fi

    if ! [[ "$stok_miktari" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı sadece pozitif sayı olmalıdır!"
        hata_no=$(hata_no_belirleme)
        echo "$hata_no, $(date), Hata: Geçersiz stok miktarı" >> log.csv
        return
    fi

    if ! [[ "$birim_fiyat" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        zenity --error --title="Hata" --text="Birim fiyatı sadece pozitif sayı olmalıdır!"
        hata_no=$(hata_no_belirleme)
        echo "$hata_no, $(date), Hata: Geçersiz birim fiyatı" >> log.csv
        return
    fi

    # İlerleme çubuğu
    (
        echo "10"; sleep 1
        echo "# Ürün bilgileri kontrol ediliyor..."; sleep 1
        echo "50"; sleep 1
        echo "# Ürün ekleniyor..."; sleep 1
        echo "100"; sleep 1
    ) | zenity --progress --title="Ürün Ekleme" --text="Ürün ekleniyor..." --auto-close

    # Ürün depo.csv dosyasına ekle
    echo "$urun_no,$urun_adi,$stok_miktari,$birim_fiyat,$kategori" >> depo.csv

    # Başarılı mesajı
    zenity --info --title="Başarılı" --text="Ürün başarıyla eklendi!"
    hata_no=$(hata_no_belirleme)
    echo "$hata_no, $(date), Başarı: Ürün eklendi - $urun_adi ($kategori)" >> log.csv
    
    hizli_yedek
}


# Ürün Listeleme Fonksiyonu
urun_listele() {
    # Depo dosyasını kontrol et
    if [ ! -f "depo.csv" ]; then
        zenity --error --title="Hata" --text="Envanter dosyası bulunamadı!"
        return
    fi

    # Depo dosyasındaki verileri düzgün hizalamak için oku ve işle
    envanter=$(awk -F',' '
    BEGIN {
        printf "%-10s %-20s %-10s %-10s %-15s\n", "Ürün No", "Ürün Adı", "Stok", "Fiyat", "Kategori";
        printf "---------------------------------------------------------------------------------\n";
    }
    NR > 1 {
        printf "%-10s %-20s %-10s %-10s %-15s\n", $1, $2, $3, $4, $5;
    }' depo.csv)

    # Envanteri Zenity ile göster
    echo "$envanter" | zenity --text-info --title="Ürün Envanteri" --width=450 --height=600
}


# Ürün Silme Fonksiyonu
urun_sil() {
    # Silme işlemi için yetki kontrolü
    rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)
    if [ "$rol" != "1" ]; then
        # Rol 1 değilse yetki hatası
        zenity --error --title="Yetki Hatası" --text="Yetkiniz yetersiz! Bu sayfayı yalnızca yöneticiler kullanabilir." --ok-label="Menüye Dön"
        ana_menu
        return
    fi

    # Kullanıcıdan silmek istediği ürünün adını iste
    urun_adi=$(zenity --entry --title="Ürün Silme" --text="Silmek istediğiniz ürünün adını girin:")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün silme işlemi iptal edildi."
        return
    fi

    # Girilen ürün adına ait kayıtlar kontrol ediliyor
    urun_kayitlari=$(awk -F',' -v urun="$urun_adi" '$2==urun {print $0}' depo.csv)
    if [ -z "$urun_kayitlari" ]; then
        zenity --error --title="Hata" --text="Bu isimde herhangi bir ürün bulunamadı!"
        return
    fi

    # Kullanıcıya aynı isimdeki farklı kategorideki ürünleri listele
    kategori_secimi=$(echo "$urun_kayitlari" | awk -F',' '{print $5}' | zenity --list --title="Kategori Seçimi" \
        --text="Lütfen bir kategori seçin:" --column="Kategoriler")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün silme işlemi iptal edildi."
        return
    fi

    # Seçilen ürünün kaydını bul
    silinecek_urun=$(echo "$urun_kayitlari" | awk -F',' -v kategori="$kategori_secimi" '$5==kategori {print $0}')
    if [ -z "$silinecek_urun" ]; then
        zenity --error --title="Hata" --text="Seçilen kategoriye ait ürün bulunamadı!"
        return
    fi

    # Ürün bilgilerini al (ID hariç)
    stok_miktari=$(echo "$silinecek_urun" | awk -F',' '{print $3}')
    birim_fiyat=$(echo "$silinecek_urun" | awk -F',' '{print $4}')
    kategori=$(echo "$silinecek_urun" | awk -F',' '{print $5}')

    # Silme işlemi için onay al
    zenity --question --title="Silme Onayı" \
        --text="Seçilen ürün silinecek:\n\nAdet: $stok_miktari\nFiyat: $birim_fiyat TL\nKategori: $kategori\n\nOnaylıyor musunuz?"
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün silme işlemi iptal edildi."
        return
    fi

   # Geçici dosyaya filtrelenen veriler yazılır
    grep -v "^$(echo "$silinecek_urun" | sed 's/[\/&]/\\&/g')$" depo.csv > temp_depo.csv

    # Silinen üründen sonra numaraları yeniden sıralama
    awk -F',' 'NR==1 {print $0} NR>1 {print NR-1 "," $2 "," $3 "," $4 "," $5}' temp_depo.csv > depo.csv
    rm temp_depo.csv

    # Kontrol: Silme işlemi başarılı mı?
    if grep -q "^$(echo "$silinecek_urun" | sed 's/[\/&]/\\&/g')$" depo.csv; then
        zenity --error --title="Hata" --text="Ürün CSV dosyasından silinemedi!"
        hata_no=$(hata_no_belirleme)
        echo "$hata_no, $(date), Hata: Ürün CSV dosyasından silinemedi - $urun_adi" >> log.csv
        return
    fi

    # Silme başarılı mesajı
    zenity --info --title="Başarılı" --text="Ürün başarıyla silindi:\n\nAdet: $stok_miktari\nFiyat: $birim_fiyat TL\nKategori: $kategori"
    hata_no=$(hata_no_belirleme)
    echo "$hata_no, $(date), Başarı: Ürün silindi - $urun_adi ($kategori)" >> log.csv
    
    hizli_yedek
    
}

# Ürün Güncelleme Fonksiyonu
urun_guncelle() {
    # Yetki kontrolü
    rol=$(awk -F':' -v user="$username" '$1==user {print $3}' kullanici.csv)
    if [ "$rol" != "1" ]; then
        zenity --error --title="Yetki Hatası" --text="Yetkiniz yetersiz! Bu sayfayı yalnızca yöneticiler kullanabilir."
        ana_menu
        return
    fi

    # Kullanıcıdan ürün adını al
    urun_adi=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün adını girin:")
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün güncelleme işlemi iptal edildi."
        return
    fi

    # Girilen ürün adına ait kayıtları bul
    urun_kayitlari=$(awk -F',' -v urun="$urun_adi" '$2==urun {print $0}' depo.csv)
    if [ -z "$urun_kayitlari" ]; then
        zenity --error --title="Hata" --text="Bu isimde herhangi bir ürün bulunamadı!"
        return
    fi

    # Kullanıcıya aynı isimdeki farklı kategorideki ürünleri listele
    kategori_secimi=$(echo "$urun_kayitlari" | awk -F',' '{print $5}' | zenity --list --title="Kategori Seçimi" \
        --text="Lütfen bir kategori seçin:" --column="Kategoriler" --width=400 --height=500)
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün güncelleme işlemi iptal edildi."
        return
    fi

    # Seçilen ürünün kaydını bul
    guncellenecek_urun=$(echo "$urun_kayitlari" | awk -F',' -v kategori="$kategori_secimi" '$5==kategori {print $0}')
    if [ -z "$guncellenecek_urun" ]; then
        zenity --error --title="Hata" --text="Seçilen kategoriye ait ürün bulunamadı!"
        return
    fi

    # Mevcut ürün bilgilerini ayır
    urun_no=$(echo "$guncellenecek_urun" | awk -F',' '{print $1}')
    stok_miktari=$(echo "$guncellenecek_urun" | awk -F',' '{print $3}')
    birim_fiyat=$(echo "$guncellenecek_urun" | awk -F',' '{print $4}')
    kategori=$(echo "$guncellenecek_urun" | awk -F',' '{print $5}')

    # Kullanıcıdan yeni bilgiler al
    urun_bilgileri=$(zenity --forms --title="Ürün Güncelle" --text="Yeni bilgileri girin (boş bırakırsanız mevcut değerler korunur):" \
        --add-entry="Yeni Ürün Adı (Mevcut: $urun_adi)" \
        --add-entry="Yeni Stok Miktarı (Mevcut: $stok_miktari)" \
        --add-entry="Yeni Birim Fiyatı (Mevcut: $birim_fiyat)")

    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün güncelleme işlemi iptal edildi."
        return
    fi

    # Kullanıcı girişlerini ayır
    yeni_urun_adi=$(echo "$urun_bilgileri" | awk -F'|' '{print $1}')
    yeni_stok_miktari=$(echo "$urun_bilgileri" | awk -F'|' '{print $2}')
    yeni_birim_fiyat=$(echo "$urun_bilgileri" | awk -F'|' '{print $3}')
    yeni_kategori=$(echo "$urun_bilgileri" | awk -F'|' '{print $4}')

	
    # Kategori seçimi (hazır liste)
    yeni_kategori=$(zenity --list --title="Kategori Seçimi" --text="Yeni kategori seçin (Mevcut: $kategori):" --column="Kategoriler" --width=400 --height=700 \
        "Kırtasiye" \
        "Elektronik" \
        "Ev Eşyaları" \
        "Gıda" \
        "Giyim" \
        "Mobilya" \
        "Spor Malzemeleri" \
        "Kozmetik" \
        "Oyuncak" \
        "Hobi ve Sanat" \
        "Kırtasiye ve Ofis Malzemeleri" \
        "Beyaz Eşya" \
        "Mutfak Gereçleri" \
        "Bahçe ve Yapı Malzemeleri" \
        "Kamp ve Outdoor" \
        "Petshop Ürünleri" \
        "Oto Aksesuarları" \
        "Sağlık ve Medikal" \
        "Ayakkabı ve Çanta" \
        "Kitap ve Yayınlar" \
        "Tekstil ve Kumaş")
        
        
    if [ $? -ne 0 ]; then
        zenity --warning --title="İptal" --text="Ürün güncelleme işlemi iptal edildi."
        return
    fi
        
    # Boş bırakılan alanları eski değerlerle doldur
    [ -z "$yeni_urun_adi" ] && yeni_urun_adi="$urun_adi"
    [ -z "$yeni_stok_miktari" ] && yeni_stok_miktari="$stok_miktari"
    [ -z "$yeni_birim_fiyat" ] && yeni_birim_fiyat="$birim_fiyat"
    [ -z "$yeni_kategori" ] && yeni_kategori="$kategori"
    
    # Negatif veya sıfır stok/fiyat kontrolü
    if ! [[ "$yeni_stok_miktari" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı sadece pozitif bir tam sayı olmalıdır!"
        return
    fi

    if ! [[ "$yeni_birim_fiyat" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        zenity --error --title="Hata" --text="Birim fiyatı sadece pozitif bir sayı olmalıdır!"
        return
    fi

    # Aynı isim ve kategoride ürün var mı kontrol et
    if grep -q ",$yeni_urun_adi,$yeni_stok_miktari,$yeni_birim_fiyat,$yeni_kategori" depo.csv; then
        zenity --error --title="Hata" --text="Bu ürün adı ve kategori kombinasyonu zaten mevcut!"
        urun_guncelle
        return
    fi

    # Ürün bilgilerini güncelle
    sed -i "s/^$guncellenecek_urun$/$urun_no,$yeni_urun_adi,$yeni_stok_miktari,$yeni_birim_fiyat,$yeni_kategori/" depo.csv

    # Güncelleme başarılı mesajı
    zenity --info --title="Başarılı" --text="Ürün bilgileri başarıyla güncellendi!"
    hata_no=$(hata_no_belirleme)
    echo "$hata_no, $(date), Başarı: Ürün güncellendi - $yeni_urun_adi ($yeni_kategori)" >> log.csv
    
    hizli_yedek
}

rapor_al() {
     while true; do	    
        # Program Yönetimi Seçenekleri
        secim=$(zenity --list --title="Rapor Türü Seçimi" --width=400 --height=500 --text="Bir rapor türü seçin:"\
            --column="Seçenekler" --cancel-label="Menüye Dön" \
            "1. Stokta Azalan Ürünler" \
            "2. En Yüksek Stok Miktarına Sahip Ürünler" \
            "3. Kategoriye Göre Ürün Sayısı" )
            
		#kullanıcı bir seçim yapmaz ise (cancel durumunu seçerse)
		if [ $? -ne 0 ]; then
	 		ana_menu
	 		return
	 	fi

        case "$secim" in
            "1. Stokta Azalan Ürünler") stokta_azalan_urunler ;;
            "2. En Yüksek Stok Miktarına Sahip Ürünler") en_yuksek_stok_urunler ;;
            "3. Kategoriye Göre Ürün Sayısı") kategoriye_gore_urun_sayisi ;;
            
            *) zenity --error --title="Hata" --text="Geçersiz seçim! Lütfen tekrar deneyin." ;;
        esac
    done
}

# Stokta Azalan Ürünler
stokta_azalan_urunler() {
    esik_degeri=$(zenity --entry --title="Eşik Değeri" --text="Eşik değerini girin:")
    if ! [[ "$esik_degeri" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Eşik değeri pozitif bir tam sayı olmalıdır!"
        return
    fi

    azalan_urunler=$(awk -F',' -v esik="$esik_degeri" 'NR > 1 && $3 < esik {printf "Ürün No: %s\nÜrün Adı: %s\nStok: %s\nFiyat: %s\nKategori: %s\n\n", $1, $2, $3, $4, $5}' depo.csv)

    if [ -z "$azalan_urunler" ]; then
        zenity --info --title="Rapor" --text="Eşik değerinin altında ürün bulunmamaktadır."
    else
        zenity --text-info --title="Stokta Azalan Ürünler" --width=400 --height=700 --filename=<(echo "$azalan_urunler")
    fi
}

# En Yüksek Stok Miktarına Sahip Ürünler
en_yuksek_stok_urunler() {
    esik_degeri=$(zenity --entry --title="Eşik Değeri" --text="Eşik değerini girin:")
    if ! [[ "$esik_degeri" =~ ^[0-9]+$ ]]; then
        zenity --error --title="Hata" --text="Eşik değeri pozitif bir tam sayı olmalıdır!"
        return
    fi

    yuksek_stoklu_urunler=$(awk -F',' -v esik="$esik_degeri" 'NR > 1 && $3 > esik {printf "Ürün No: %s\nÜrün Adı: %s\nStok: %s\nFiyat: %s\nKategori: %s\n\n", $1, $2, $3, $4, $5}' depo.csv)

    if [ -z "$yuksek_stoklu_urunler" ]; then
        zenity --info --title="Rapor" --text="Eşik değerinin üzerinde ürün bulunmamaktadır."
    else
        zenity --text-info --title="En Yüksek Stok Miktarına Sahip Ürünler" --width=400 --height=700 --filename=<(echo "$yuksek_stoklu_urunler")
    fi
}

# Kategoriye Göre Ürün Sayısı
kategoriye_gore_urun_sayisi() {
    if [ ! -f "depo.csv" ]; then
        zenity --error --title="Hata" --text="Depo dosyası bulunamadı!"
        return
    fi

    kategori_raporu=$(awk -F',' 'NR > 1 {kategori[$5]++} END {for (k in kategori) printf "Kategori: %s\nÜrün Sayısı: %d\n\n", k, kategori[k]}' depo.csv)

    if [ -z "$kategori_raporu" ]; then
        zenity --info --title="Rapor" --text="Depoda ürün bulunmamaktadır."
    else
        zenity --text-info --title="Kategoriye Göre Ürün Sayısı" --width=400 --height=700 --filename=<(echo "$kategori_raporu")
    fi
}


#sisteme girilmiş ve çıkış yapmak istersek çalışan fonksiyon
cikis() {
    # onay ekranı
    zenity --question --title="Çıkış Onayı" --text="Programdan çıkmak istediğinize emin misiniz?" \
    	   --ok-label="Çık" --cancel-label="Ana Menü"
    
    # kullanıcı cevabına göre işlem
    if [ $? -eq 0 ]; then
    	# evet seçeniğini seçerse
    	zenity --info --title="Çıkış" --text="Programdan çıkılıyor. Görüşmek üzere!"
    	exit 0
    else
    	# hayır seçeneğini seçerse
    	ana_menu
    fi		
}

#giriş ekranında sistemden çıkmak istersek çalışan fonksiyon
cikis_giris_ekrani() {
    # onay ekranı
    zenity --question --title="Çıkış Onayı" --text="Programdan çıkmak istediğinize emin misiniz?" \
    	   --ok-label="Giriş Menüsü" --cancel-label="Çık"
    
    # kullanıcı cevabına göre işlem
    if [ $? -eq 0 ]; then
    	# hayır seçeneğini seçerse
    	kullanici_adi_ekrani
    else
    	# evet seçeniğini seçerse
    	zenity --info --title="Çıkış" --text="Programdan çıkılıyor. Görüşmek üzere!"
    	exit 0
    fi		
}

# Ana Menü
ana_menu() {
    while true; do
	    secim=$(zenity --list --title="Ana Menü" --width=400 --height=700 --column="Seçenekler" --text="" \
		"1. Ürün Ekle (Yönetici)" \
		"2. Ürün Listele" \
		"3. Ürün Güncelle (Yönetici)" \
		"4. Ürün Sil (Yönetici)" \
		"5. Rapor Al" \
		"6. Kullanıcı Yönetimi (Yönetici)" \
		"7. Program Yönetimi (Yönetici)" \
		"8. Hesaptan Çık" \
		"9. Çıkış")
		
		#kullanıcı bir seçim yapmaz ise (cancel durumunu seçerse)
		if [ $? -ne 0 ]; then
	 		zenity --warning --title="Geçersiz seçim" --text="Geçersiz seçim! Menüye yönlendiriliyorsunuz."
	 		ana_menu
	 		return
	 	fi

	    case $secim in
		"1. Ürün Ekle (Yönetici)") urun_ekle ;;
		"2. Ürün Listele") urun_listele ;;
		"3. Ürün Güncelle (Yönetici)") urun_guncelle ;;
		"4. Ürün Sil (Yönetici)") urun_sil ;;
		"5. Rapor Al") rapor_al ;;
		"6. Kullanıcı Yönetimi (Yönetici)") kullanici_yonetimi ;;
		"7. Program Yönetimi (Yönetici)") program_yonetimi ;;
		"8. Hesaptan Çık")  
			zenity --question --title="Hesaptan Çıkış" --text="Hesaptan çıkmak istediğinizden emin misiniz?" \
                       --ok-label="Evet" --cancel-label="Hayır"
                	if [ $? -eq 0 ]; then
                    		kullanici_adi_ekrani  # Giriş ekranına geri dön
                    		return
                	fi   		
			;;
		  
		"9. Çıkış") cikis ;;
		*) zenity --error --title="Hata" --text="Geçersiz seçim!" ana_menu ;;
	    esac
    done
}

# Programı çalıştır

csv_dosya_kontrol 

kullanici_adi_ekrani







