# BilsemGo başlatıcı (açık depo)

Bu depo tek bir dosya taşır: `kur.sh`. Amacı, temiz bir Mac'te **tek satırla** BilsemGo geliştirme
ortamının kurulumunu başlatmaktır. Ürün deposu özeldir; bu başlatıcı sır, token ya da ürün kodu
içermez, yalnız ön koşulları kurar ve sizi GitHub'a sokup asıl kurucuya devreder.

## Tek satır

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alora-Inc/bilsemgo-kur/main/kur.sh)"
```

Ön koşul: Alora-Inc altındaki özel `bilsemgo` deposuna **okuma yetkisi** olan bir GitHub hesabı.
Yetkiniz yoksa başlatıcı 2 ile çıkar ve depo yöneticisinden erişim istemenizi söyler.

## Ne olur

1. macOS denetimi; Command Line Tools ve Homebrew eksikse yönetici parolası sorulur (bir kez).
2. `gh` kurulur; `gh auth login --web` ile tarayıcıdan GitHub'a girersiniz.
3. Özel depodaki asıl kurucu (`infra/kurulum/kur.sh`) kimlik doğrulanmış gh API'siyle çekilir,
   sha256 özeti ekrana basılır.
4. Asıl kurucuya devredilir: depo klonlanır (varsayılan `~/Github/BilsemGO`), dal seçilir, 12 aşamalı
   orkestratör araç zincirini, bağımlılıkları, Colima yığınını ve veriyi kurar; sonunda doktor raporu
   ve "kaldığımız yer" özeti basılır.

Üç insan dokunuşu kaçınılmazdır: yönetici parolası, tarayıcı girişi ve (yalnız kendi yedeğini geri
yükleyenler için) yedek anahtarı. Gerisi otomatiktir; ilk kurulum ağ hızına göre 45–90 dakika sürer.

## Bayraklar

`--depo owner/repo` (varsayılan `Alora-Inc/bilsemgo`) · `--dal <dal>` (asıl kurucu bu daldan çekilir,
klon bu dala alınır) · `--kuru` (yalnız planı basar) · `-h`. Geri kalan bayraklar asıl kurucuya aynen
aktarılır: `--profil cekirdek|tam|ios|android`, `--yedek <dizin|auto>`, `--dizin <yol>`, `--evet`,
`--atla NN`, `--yalniz NN`, `--ez`, `--sifirla`.

Örnek — belirli bir dalı tam profille kurmak:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alora-Inc/bilsemgo-kur/main/kur.sh)" -- --dal main --profil tam
```

## Güvenlik

- Token argümanı ya da `GH_TOKEN`/`GITHUB_TOKEN` ortam değişkeni kabul edilmez; kimlik yalnız
  `gh auth login --web` ile alınır (Keychain'de kalır, betiğe geçmez).
- Özel dosya hiçbir zaman `curl | bash` ile çalıştırılmaz; yalnız gh API ile çekilir, özeti basılır.
- Bu dosyanın kaynağı özel depodaki `infra/kurulum/baslatici/kur.sh` dosyasıdır; oradaki değişiklik
  `make baslatici-yayinla` ile buraya kopyalanır. Buradaki dosyayı doğrudan düzenlemeyin.

## Sorun giderme

- **"Özel depoya erişimin yok"**: hesabınızın Alora-Inc/bilsemgo deposunda en az okuma yetkisi olmalı.
- **Tarayıcı açılmadı**: `gh auth login --hostname github.com --web` komutunu elle koşup kodu girin, sonra
  tek satırı yeniden çalıştırın.
- **CLT kurulumu takıldı**: `xcode-select --install` ile GUI kurulumunu bitirip yeniden çalıştırın.
- Kurulumun kendisiyle ilgili her şey özel depodaki `infra/kurulum/README.md` içindedir.
