# Proje Adı: **Zenity ile Geliştirilmiş Stok ve Kullanıcı Yönetim Sistemi**

## Proje Tanıtımı

Bu proje, Zenity aracılığıyla geliştirilmiş bir stok ve kullanıcı yönetim sistemidir. Program; ürün ekleme, silme, listeleme, raporlama gibi temel stok yönetim işlemleri ile kullanıcı yönetimini kapsar. Kullanımı kolay bir arayüzle tasarlanan bu sistem, kullanıcıların çeşitli yönetimsel işlemleri hızlı ve güvenilir bir şekilde gerçekleştirmesini sağlar. Ayrıca, veri yedekleme mekanizması ile veri kaybı riski minimize edilmiştir.

---

## Kurulum

### 1. Gereksinimler

- **Linux** işletim sistemi
- **Zenity** yüklenmiş olmalı
- **Bash** kabuğu desteklenmelidir

### 2. Kurulum Aşamaları

1. **Depoyu Klonlayın:**

   ```bash
   git clone https://github.com/kullaniciadi/projeadi.git
   cd projeadi
   ```

2. **Dosya İzinlerini Ayarlayın:**

   ```bash
   chmod +x main.sh
   ```

3. **Gerekli Dizini Oluşturun:**

   ```bash
   mkdir yedekler
   ```

4. **Zenity Kontrolü:**
   Zenity'nin kurulu olduğundan emin olun. Aşağıdaki komutla kontrol edebilirsiniz:

   ```bash
   zenity --version
   ```

   Zenity kurulu değilse, aşağıdaki komutla yükleyebilirsiniz:

   ```bash
   sudo apt install zenity
   ```

---

## Nasıl Çalıştırılır?

1. Ana betiği çalıştırın:

   ```bash
   ./main.sh
   ```

2. Giriş ekranından bir hesapla oturum açın. <br>
    &nbsp;&nbsp;Varsayılan yönetici hesabı: <br>
      &nbsp;&nbsp;&nbsp;Kullanıcı Adı: 1 <br>
      &nbsp;&nbsp;&nbsp;Şifre: 1 <br>
3. Ana menüdeki seçeneklerden birini seçerek çeşitli işlemleri gerçekleştirin.

---

## Program Özellikleri

### 1. **Kullanıcı Yönetimi**

- **Yeni Kullanıcı Ekleme:** İsim, şifre ve rol belirlenerek kullanıcı eklenir.
- **Kullanıcı Güncelleme:** Kullanıcıların şifre, isim, rol ve durum bilgileri güncellenebilir.
- **Kullanıcı Silme:** Kullanıcılar güvenli bir şekilde sistemden kaldırılabilir.

### 2. **Stok Yönetimi**

- **Ürün Ekleme:** Sistem, benzersiz ürün numarası oluşturur ve yeni ürünlerin stok, fiyat ve kategori bilgilerini kaydeder.
- **Ürün Güncelleme:** Ürünlerin adı, stok miktarı, fiyatı ve kategorisi değiştirilebilir.
- **Ürün Silme:** Kritik işlemler için onay ekranı kullanılarak ürünler kaldırılır.

### 3. **Raporlama**

- **Stok Azalan Ürünler:** Kullanıcının belirlediği eşik değeri altında kalan ürünler listelenir.
- **En Yüksek Stoklu Ürünler:** Belirli bir eşik değerine göre en fazla stok miktarına sahip ürünler gösterilir.
- **Kategori Bazlı Ürün Sayısı:** Her kategori için toplam ürün sayısını gösterir.

### 4. **Veri Yedekleme**

- Tüm kritik işlemlerden sonra otomatik olarak yedekler dizinine veriler kaydedilir.
- Yedekleme işlemleri programdan bağımsız olarak düzenli bir şekilde yapılır.

---

## Sık Sorulan Sorular (FAQ)

### 1. Proje sırasında karşılaştığınız en büyük teknik sorun neydi ve nasıl çözdünüz?

Projede karşılaştığımız en büyük sorun, ürünlerin kategori ve isim bilgilerinin çakışmasıydı. Bunu, kategori ve isim bilgilerinin bir arada kontrol edilmesini sağlayan bir doğrulama mekanizması geliştirerek çözdük.

### 2. Zenity kullanırken sizi en çok zorlayan kısım hangisiydi?

Zenity ile birden fazla buton eklemek özellikle zorlayıcıydı. "Extra button" desteği olmayan Zenity sürümünde çözüm olarak farklı ekranlar ve akışlar kullandık.

### 3. Bir hatayla karşılaştığınızda bunu çözmek için hangi adımları izlediniz?

1. **Log Kayıtları:** Log dosyasından hata mesajlarını kontrol ettik.
2. **Deneme-Tecrübe:** Sorunu izole ederek çalışma ortamında denemeler yaptık.
3. **Doküman Kontrolü:** Zenity'nin resmi dokümanlarını ve bash betik yazım kaynaklarını inceledik.

### 4. Ürün güncelleme fonksiyonunu geliştirirken, bir ürünün adı aynı olsa da farklı bir kategoride olabileceğini fark ettiniz mi? Bunu nasıl çözdünüz?

Evet, bu durumu fark ettik ve kategori bazlı kontrol mekanizması ekledik. Bu sayede aynı isme sahip farklı kategorideki ürünler sistemde ayrı şekilde saklanabildi.

### 5. Eğer bir kullanıcı programı beklenmedik şekilde kapatırsa, veri kaybını önlemek için ne yaptınız?

Kritik işlemlerden sonra otomatik olarak "yedekler" dizinine veri yedekleri alındı. Bu, program kapanışından bağımsız olarak veri kaybını önledi.

---

## Tanıtım Videosu

https://youtu.be/c4e54cEMP20

---

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Daha fazla bilgi için `LICENSE` dosyasına bakabilirsiniz.

