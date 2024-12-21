# Proje Adı: **Zenity ile Geliştirilmiş Stok ve Kullanıcı Yönetim Sistemi**

## Proje Tanıtımı
Bu proje, Zenity aracılığıyla geliştirilmiş bir stok ve kullanıcı yönetim sistemidir. Program; ürün ekleme, silme, listeleme, raporlama gibi temel stok yönetim işlemleri ile kullanıcı yönetimini kapsar. Kullanımı kolay bir arayüzle tasarlanan bu sistem, kullanıcıların çeşitli yönetimsel işlemleri hızlı ve güvenilir bir şekilde gerçekleştirmesini sağlar.

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
    Zenity kurulu değilse, aşağdaki komutla yükleyebilirsiniz:
    ```bash
    sudo apt install zenity
    ```

---

## Nasıl Çalıştırılır?
1. Ana betiği çalıştırın:
    ```bash
    ./main.sh
    ```

2. Giriş ekranından bir hesapla oturum açın.
3. Ana menüdeki seçeneklerden birini seçerek çeşitli işlemleri gerçekleştirin.

---

## Kullanım Talimatları
### 1. **Kullanıcı Yönetimi**
- Yeni bir kullanıcı eklemek veya var olanı güncellemek için "Kullanıcı Yönetimi" seçeneğini kullanın.
- Yöneticiler ek özelliklere erişim sağlayabilir.

### 2. **Stok Yönetimi**
- Ürün ekleme, silme ve güncelleme işlemleri "Yönetici" yetkisi gerektirir.
- Raporlama seçenekleriyle stok analizi yapabilirsiniz.

### 3. **Veri Yedekleme**
- Program, kritik işlemlerden sonra otomatik olarak "yedekler" dizinine veri yedekler.

---

## Sık Sorulan Sorular (FAQ)

### 1. Proje sırasında karşılaştığınız en büyük teknik sorun neydi ve nasıl çözdünüz?
Projede karşılaştığımız en büyük sorun, ürünlerin kategori ve isim bilgilerinin çakışmasıydı. Bunu, kategori ve isim bilgilerinin bir arada kontrol edilmesini sağlayan bir doğrulama mekanizması geliştirerek çözdük.

### 2. Zenity kullanırken sizi en çok zorlayan kısım hangisiydi?
Zenity ile birden fazla buton eklemek özellikle zorlayıcıydı. "Extra button" desteği olmayan Zenity sürümünde çözüm olarak farklı ekranlar ve akışlar kullandık.

### 3. Bir hatayla karşılaştığınızda bunu çözmek için hangi adımları izlediniz?
1. **Log Kızımlama:** Log dosyasından hata mesajlarını kontrol ettik.
2. **Deneme-Tecrübe:** Sorunu izole ederek çalışma ortamında denemeler yaptık.
3. **Doküman Kontrolü:** Zenity'nin resmi dokümanlarını ve bash betik yazım kaynaklarını inceledik.

### 4. Ürün güncelleme fonksiyonunu geliştirirken, bir ürünün adı aynı olsa da farklı bir kategoride olabileceğini fark ettiniz mi? Bunu nasıl çözdünüz?
Evet, bu durumu fark ettik ve kategori bazlı kontrol mekanizması ekledik. Bu sayede aynı isme sahip farklı kategorideki ürünler sistemde ayrı şekilde saklanabildi.

### 5. Eğer bir kullanıcı programı beklenmedik şekilde kapatırsa, veri kaybını önlemek için ne yaptınız?
Kritik işlemlerden sonra otomatik olarak "yedekler" dizinine veri yedekleri alındı. Bu, program kapanışından bağımsız olarak veri kaybını önledi.

---

## Katkıda Bulunma
1. Depoyu fork edin.
2. Kendi branch'ınızı oluşturun: `git checkout -b yeni-ozellik`
3. Değişikliklerinizi yapın ve commit edin: `git commit -m 'Yeni bir özellik ekle'`
4. Branch'ınızı push edin: `git push origin yeni-ozellik`
5. Bir pull request oluşturun.

---

## Lisans
Bu proje MIT lisansı altında lisanslanmıştır. Daha fazla bilgi için `LICENSE` dosyasına bakabilirsiniz.

