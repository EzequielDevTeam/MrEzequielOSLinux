#!/bin/bash
# Personaliza visual do Ubiquity (instalador): logo, tela welcome, slideshow
# Executado durante o build da ISO

set -euo pipefail

echo "[ubiquity-visual] Personalizando instalador..."

# Base do repo (funciona no build E no OTA; nada de caminho fixo /root/...).
BASE="$(cd "$(dirname "$0")/.." && pwd)"

# 1. Logo do MrEzequielOS na janela do Ubiquity
# O ubiquity-frontend-gtk usa /usr/share/pixmaps/ubiquity.png ou similar
if [ -f "$BASE/branding/logo.svg" ]; then
  cp "$BASE/branding/logo.svg" /usr/share/pixmaps/ubiquity.svg 2>/dev/null || true
  cp "$BASE/branding/logo.svg" /usr/share/pixmaps/mrezequielos-installer.svg 2>/dev/null || true
else
  echo "[ubiquity-visual] AVISO: branding/logo.svg ausente em $BASE"
fi

# 2. Patch no .desktop do ubiquity para usar nossa logo
DESKTOP_FILE="/usr/share/applications/ubiquity.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    cp "$DESKTOP_FILE" "$DESKTOP_FILE.bak"
    sed -i 's/^Icon=.*/Icon=mrezequielos-installer/' "$DESKTOP_FILE"
    echo "[ubiquity-visual] .desktop icon atualizado"
fi

# 3. Tela "Experimentar ou Instalar" (welcome screen do ubiquity)
# O ubiquity usa um arquivo .ui (Glade) ou HTML para a tela inicial
WELCOME_UI="/usr/share/ubiquity/gtk/welcome.ui"
if [ -f "$WELCOME_UI" ]; then
    cp "$WELCOME_UI" "$WELCOME_UI.bak"
    # Seds cirurgicos: nunca trocar "Ubuntu" puro (quebra ids internos do Glade).
    sed -i 's/Try or Install/Experimentar ou Instalar/g' "$WELCOME_UI"
    sed -i 's/Install Ubuntu/Instalar o MrEzequielOS/g' "$WELCOME_UI"
    sed -i 's/>Ubuntu</>MrEzequielOS</g' "$WELCOME_UI"
    echo "[ubiquity-visual] welcome.ui textos atualizados"
fi

# 4. Slideshow - atualizar HTMLs para nossos apps e usar nosso wallpaper
SLIDESHOW_DIR="/usr/share/ubiquity-slideshow/mrezequielos"
mkdir -p "$SLIDESHOW_DIR/screenshots"

# Copiar nosso wallpaper como background dos slides.
# Mantem .svg (original) e copia .png (mesmo conteudo) para as referencias antigas continuarem validas.
if [ -f "$BASE/branding/wallpaper.svg" ]; then
  for s in welcome office browse accessibility music photos gethelp usc; do
    cp "$BASE/branding/wallpaper.svg" "$SLIDESHOW_DIR/screenshots/$s.svg" 2>/dev/null || true
    cp "$BASE/branding/wallpaper.svg" "$SLIDESHOW_DIR/screenshots/$s.png" 2>/dev/null || true
  done
else
  echo "[ubiquity-visual] AVISO: branding/wallpaper.svg ausente em $BASE"
fi

# Gerar slideshow HTML personalizado
cat > "$SLIDESHOW_DIR/slideshow.css" << 'CSSEOF'
.slide {
    background: #1a1a2e;
    color: #e0e0e0;
    font-family: 'Inter', 'Ubuntu', sans-serif;
}
.slidetitle {
    color: #bb86fc;
    font-size: 2.5em;
    font-weight: 300;
}
.text p {
    font-size: 1.3em;
    line-height: 1.6;
    color: #c0c0c0;
}
.background {
    opacity: 0.15;
}
CSSEOF

cat > "$SLIDESHOW_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>MrEzequielOS - Instalação</title>
    <link rel="stylesheet" href="slideshow.css">
</head>
<body>
    <div id="slideshow"></div>
    <script>
        const slides = [
            'welcome.html',
            'browse.html',
            'office.html',
            'accessibility.html',
            'music.html',
            'photos.html',
            'gethelp.html',
            'usc.html'
        ];
        let current = 0;
        const container = document.getElementById('slideshow');
        
        function loadSlide(name) {
            fetch(name)
                .then(r => r.text())
                .then(html => {
                    container.innerHTML = html;
                });
        }
        
        function nextSlide() {
            current = (current + 1) % slides.length;
            loadSlide(slides[current]);
        }
        
        loadSlide(slides[0]);
        setInterval(nextSlide, 15000);
    </script>
</body>
</html>
HTMLEOF

# Copiar e adaptar slides do config
for slide in welcome browse office accessibility music photos gethelp usc; do
    src="$BASE/slideshow/${slide}.html"
    dst="$SLIDESHOW_DIR/${slide}.html"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
    else
        echo "[ubiquity-visual] AVISO: slide ausente $src"
    fi
done

# 5. Configurar ubiquity para usar nosso slideshow.
# Nao ha certeza de que o ubiquity leia /etc/ubiquity-slideshow.conf, entao
# espelhamos os slides tambem no diretorio padrao do pacote (com backup).
UBIQUITY_SLIDESHOW_CONF="/etc/ubiquity-slideshow.conf"
echo "slideshow=mrezequielos" > "$UBIQUITY_SLIDESHOW_CONF"
for std_dir in /usr/share/ubiquity-slideshow/ubuntu /usr/share/ubiquity-slideshow/kubuntu; do
    if [ -d "$std_dir" ] && [ "$std_dir" != "$SLIDESHOW_DIR" ]; then
        for f in "$SLIDESHOW_DIR"/*.html "$SLIDESHOW_DIR"/*.css; do
            [ -f "$f" ] || continue
            b="$(basename "$f")"
            [ -f "$std_dir/$b" ] && [ ! -f "$std_dir/$b.mre-bak" ] && cp "$std_dir/$b" "$std_dir/$b.mre-bak" 2>/dev/null || true
            cp "$f" "$std_dir/$b" 2>/dev/null || true
        done
        mkdir -p "$std_dir/screenshots"
        for s in "$SLIDESHOW_DIR/screenshots"/*; do
            [ -f "$s" ] || continue
            cp "$s" "$std_dir/screenshots/$(basename "$s")" 2>/dev/null || true
        done
        echo "[ubiquity-visual] slides espelhados em $std_dir"
    fi
done

# 6. Icone da janela: o branding-patches.sh ja define Icon=ubiquity (anaconda
# 512px do Zorin). Nada de GTK_WINDOW_ICON (variavel inexistente).

# 7. Melhorar aparência dos apps no slideshow - adicionar Brave, Firefox, etc.
cat > "$SLIDESHOW_DIR/browse.html" << 'HTMLEOF'
<div class="header"><h1 class="slidetitle">Navegue com Brave e Firefox</h1></div>
<div class="main wide">
    <div class="text">
        <div>
            <p>Brave (padrão): bloqueia anúncios e rastreadores nativamente. Firefox: sua alternativa livre e privativa.</p>
        </div>
    </div>
    <img class="background" src="screenshots/browse.png" />
</div>
HTMLEOF

cat > "$SLIDESHOW_DIR/office.html" << 'HTMLEOF'
<div class="header"><h1 class="slidetitle">LibreOffice completo</h1></div>
<div class="main wide">
    <div class="text">
        <div>
            <p>Writer, Calc e Impress em português, compatíveis com arquivos do Microsoft Office. Trabalhe sem pagar nada.</p>
        </div>
    </div>
    <img class="background" src="screenshots/office.png" />
</div>
HTMLEOF

cat > "$SLIDESHOW_DIR/usc.html" << 'HTMLEOF'
<div class="header"><h1 class="slidetitle">Loja de Apps (GNOME Software)</h1></div>
<div class="main wide">
    <div class="text">
        <div>
            <p>Milhares de aplicativos Flatpak e deb. Instale Steam, Discord, VS Code, Spotify e mais com um clique.</p>
        </div>
    </div>
    <img class="background" src="screenshots/usc.png" />
</div>
HTMLEOF

cat > "$SLIDESHOW_DIR/gethelp.html" << 'HTMLEOF'
<div class="header"><h1 class="slidetitle">Ajuda e Suporte</h1></div>
<div class="main wide">
    <div class="text">
        <div>
            <p>Documentação integrada, fórum da comunidade e diagnósticos do sistema. Ajuda sempre à mão.</p>
        </div>
    </div>
    <img class="background" src="screenshots/gethelp.png" />
</div>
HTMLEOF

echo "[ubiquity-visual] Instalador personalizado: logo, welcome screen, slideshow"