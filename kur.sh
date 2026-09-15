#!/usr/bin/env bash
# infra/kurulum/baslatici/kur.sh — BilsemGo AÇIK BAŞLATICI (yayın kopyası: github.com/Alora-Inc/bilsemgo-kur)
#
# NEDEN VAR
#   Ürün deposu ÖZELDİR; temiz bir Mac raw.githubusercontent adresinden özel dosya çekemez.
#   Bu dosya açık bir depoda yaşar ve tek satırın giriş kapısıdır:
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alora-Inc/bilsemgo-kur/main/kur.sh)"
#   (Homebrew'un kendi kurucu deseni: `curl | bash` DEĞİL — stdin tty kalır, sudo ve tarayıcı girişi çalışır.)
#
# NE YAPAR (yalnız devir; asıl kurucu özel depodadır)
#   1. macOS + sudo (yalnız CLT/Homebrew eksikse) → Command Line Tools → Homebrew → gh
#   2. `gh auth login --web` (insan; tarayıcı) → özel depoya ERİŞİM denetimi (yoksa çıkış 2: erişim iste)
#   3. Özel depodaki asıl kurucuyu (`infra/kurulum/kur.sh`) gh API ile çeker, sha256'sını basar
#   4. Ona devreder (exec): klon, dal seçimi, yedek keşfi, 12 aşamalı orkestratör oradadır.
#
# GÜVENLİK (özel deponun SEC-09 sözleşmesiyle aynı)
#   - Sır, token, ürün kodu İÇERMEZ; token argümanı/env'i KABUL ETMEZ — kimlik yalnız gh girişi.
#   - Özel dosya yalnız kimlik doğrulanmış gh API ile çekilir; hiçbir yerde `curl | bash` yoktur.
#   - Bu dosyanın kaynağı özel depoda `infra/kurulum/baslatici/kur.sh`; `make baslatici-yayinla` kopyalar.
#
# Kullanım: bash kur.sh [--depo owner/repo] [--dal <dal>] [--kuru] [-h] [-- asıl kurucunun bayrakları]
# Çıkış: 0 ok · 1 genel · 2 önkoşul/insan yarısı/erişim yok · 5 bütünlük; sonrası asıl kurucunun kodları.
set -eu

REPO_SLUG="Alora-Inc/bilsemgo"
BRANCH=""
DRY_RUN=0
INSTALLER_PATH="infra/kurulum/kur.sh"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
PASS=""

log()  { printf '· %s\n' "$*"; }
ok()   { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
die()  { printf '✗ %s\n' "$2" >&2; exit "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'USAGE'
Kullanım: bash kur.sh [bayraklar] [-- asıl kurucunun bayrakları]
  --depo <owner/repo>   Özel ürün deposu (varsayılan Alora-Inc/bilsemgo)
  --dal <dal>           Asıl kurucu bu daldan çekilir ve klon bu dala alınır (varsayılan main)
  --kuru                Planı bas, hiçbir şey yapma; 0 dön
  -h, --help            Bu yardım
Diğer bayraklar (--profil, --yedek, --dizin, --evet, --atla, --yalniz, --ez, --sifirla) asıl kurucuya
(özel depodaki infra/kurulum/kur.sh → bin/bilsemgo-kur) aynen aktarılır.
Token argümanı/env'i (GH_TOKEN, GITHUB_TOKEN) KABUL EDİLMEZ; kimlik yalnız `gh auth login --web`.
USAGE
}

need_arg() { [ -n "${2:-}" ] || die 1 "$1 bir değer ister."; }
pass_add() { PASS="${PASS}${PASS:+ }$(printf '%q' "$1")"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --depo) need_arg "$1" "${2:-}"; REPO_SLUG="$2"; shift ;;
    --dal) need_arg "$1" "${2:-}"; BRANCH="$2"; shift ;;
    --kuru) DRY_RUN=1; pass_add "--kuru" ;;
    --token|--token=*|-t|--gh-token|--gh-token=*) die 1 "Token argümanı KABUL EDİLMEZ — kimlik yalnız 'gh auth login --web' ile." ;;
    --) shift; while [ $# -gt 0 ]; do pass_add "$1"; shift; done; break ;;
    *) pass_add "$1" ;;
  esac
  shift
done
[ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ] || die 1 "GH_TOKEN/GITHUB_TOKEN ortam değişkeni KABUL EDİLMEZ — kaldırıp yeniden çalıştırın."
case "$REPO_SLUG" in */*) ;; *) die 1 "--depo owner/repo biçiminde olmalı: $REPO_SLUG" ;; esac
REF="${BRANCH:-main}"

[ "$(uname -s)" = "Darwin" ] || die 2 "Bu başlatıcı yalnız macOS içindir (uname: $(uname -s))."

brew_bin() {
  if [ -x /opt/homebrew/bin/brew ]; then printf '/opt/homebrew/bin/brew'
  elif [ -x /usr/local/bin/brew ]; then printf '/usr/local/bin/brew'
  else return 1; fi
}
clt_present() { [ -x /Library/Developer/CommandLineTools/usr/bin/git ]; }

if [ "$DRY_RUN" = "1" ]; then
  log "KURU KOŞU — hiçbir şey yapılmaz (sudo dahil)"
  printf '  1. macOS denetimi · sudo -v (yalnız CLT/Homebrew eksikse)\n'
  printf '  2. Command Line Tools: %s\n' "$(clt_present && echo 'var' || echo 'softwareupdate ile kurulur')"
  printf '  3. Homebrew: %s\n' "$(brew_bin >/dev/null 2>&1 && echo "var ($(brew_bin))" || echo "NONINTERACTIVE kurulur ($HOMEBREW_INSTALL_URL)")"
  printf '  4. gh: %s → gh auth login --hostname github.com --git-protocol https --web (insan)\n' "$(have gh && echo var || echo 'brew install gh')"
  printf '  5. gh repo view %s (erişim yoksa çıkış 2)\n' "$REPO_SLUG"
  printf '  6. gh api repos/%s/contents/%s?ref=%s → geçici dosya → sha256 basılır\n' "$REPO_SLUG" "$INSTALLER_PATH" "$REF"
  printf '  7. exec /bin/bash <asıl kurucu> --depo %s%s%s\n' "$REPO_SLUG" "${BRANCH:+ --dal $BRANCH}" "${PASS:+ $PASS}"
  exit 0
fi

# ── 1. sudo (yalnız gerekiyorsa) ───────────────────────────────────────────────
if ! clt_present || ! brew_bin >/dev/null 2>&1; then
  log "Command Line Tools / Homebrew kurulumu için yönetici parolası gerekir (bir kez)."
  sudo -v || die 2 "sudo alınamadı — bu hesap yönetici (admin) olmalı."
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null || true; sleep 50; done ) &
fi

# ── 2. Command Line Tools ─────────────────────────────────────────────────────
if ! clt_present; then
  log "Command Line Tools kuruluyor (softwareupdate)…"
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  label="$(softwareupdate -l 2>/dev/null | grep -E '^\*.*Command Line Tools' | tail -n 1 | sed -E 's/^\* Label: //; s/^\* //')"
  if [ -n "$label" ]; then sudo softwareupdate -i "$label" --verbose || true; fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  sudo xcode-select --switch /Library/Developer/CommandLineTools 2>/dev/null || true
  clt_present || die 2 "Command Line Tools kurulamadı — 'xcode-select --install' koşup bitince bu satırı yeniden çalıştırın."
fi
ok "Command Line Tools"

# ── 3. Homebrew ──────────────────────────────────────────────────────────────
if ! brew_bin >/dev/null 2>&1; then
  log "Homebrew kuruluyor (NONINTERACTIVE)…"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")" || die 2 "Homebrew kurulumu başarısız."
  brew_bin >/dev/null 2>&1 || die 2 "Homebrew kuruldu ama brew bulunamadı."
fi
eval "$("$(brew_bin)" shellenv)"
ok "Homebrew: $(brew_bin)"

# ── 4. gh + giriş ────────────────────────────────────────────────────────────
have gh || { log "gh kuruluyor…"; brew install gh || die 2 "brew install gh başarısız."; }
if ! gh auth status -h github.com >/dev/null 2>&1; then
  log "GitHub girişi (tarayıcı açılır; bu hesap özel depoya erişebilmeli)…"
  gh auth login --hostname github.com --git-protocol https --web || die 2 "gh auth login başarısız."
fi
gh auth setup-git >/dev/null 2>&1 || true
ok "gh: $(gh api user --jq .login 2>/dev/null || echo 'giriş yapıldı')"

# ── 5. Erişim denetimi ───────────────────────────────────────────────────────
gh repo view "$REPO_SLUG" --json name >/dev/null 2>&1 \
  || die 2 "Özel depoya erişimin yok: $REPO_SLUG — depo yöneticisinden (Alora-Inc) okuma yetkisi iste, sonra bu satırı yeniden çalıştır."

# ── 6. Asıl kurucuyu çek ─────────────────────────────────────────────────────
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bilsemgo-baslatici.XXXXXX")"
installer="$tmp/kur.sh"
gh api -H "Accept: application/vnd.github.raw+json" "repos/$REPO_SLUG/contents/$INSTALLER_PATH?ref=$REF" > "$installer" \
  || die 5 "Asıl kurucu çekilemedi: $REPO_SLUG@$REF:$INSTALLER_PATH"
head -n 1 "$installer" | grep -q '^#!' || die 5 "Çekilen dosya bir betik değil (ilk satır shebang değil)."
ok "Asıl kurucu: $REPO_SLUG@$REF:$INSTALLER_PATH · sha256 $(shasum -a 256 "$installer" | cut -c1-16)…"

# ── 7. Devir ────────────────────────────────────────────────────────────────
log "Devrediliyor: $installer --depo $REPO_SLUG${BRANCH:+ --dal $BRANCH}${PASS:+ $PASS}"
eval "set -- $PASS"
if [ -n "$BRANCH" ]; then
  exec /bin/bash "$installer" --depo "$REPO_SLUG" --dal "$BRANCH" "$@"
fi
exec /bin/bash "$installer" --depo "$REPO_SLUG" "$@"
