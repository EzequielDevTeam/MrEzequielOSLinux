#!/bin/bash
# Personaliza visual do Ubiquity (instalador): logo, tela welcome, slideshow
# Executado durante o build da ISO

set -euo pipefail

echo "[ubiquity-visual] Personalizando instalador..."

# 1. Logo do MrEzequielOS na janela do Ubiquity
# O ubiquity-frontend-gtk usa /usr/share/pixmaps/ubiquity.png ou similar
cp /root/MrEzequielOS/config/branding/logo.svg /usr/share/pixmaps/ubiquity.svg 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/logo.svg /usr/share/pixmaps/mrezequielos-installer.svg 2>/dev/null || true

# Patch no ubiquity para usar nossa logo como window icon
UBQUITY_MAIN="/usr/lib/ubiquity/ubiquity/frontend/gtk_ui.py"
if [ -f "$UBQUITY_MAIN" ]; then
    cp "$UBQUITY_MAIN" "$UBQUITY_MAIN.bak"
    python3 << 'PYEOF'
import re

with open("/usr/lib/ubiquity/ubiquity/frontend/gtk_ui.py", "r") as f:
    content = f.read()

# Procurar onde define window icon e adicionar nossa logo
# Geralmente no __init__ do GtkUI ou similar
old_init = "class GtkUI(GObject.Object):"
if old_init in content:
    # Adicionar set_icon_name no construtor se não tiver
    pass

# Método mais direto: patch no arquivo .desktop do ubiquity
PYEOF
    echo "[ubiquity-visual] gt_ui.py verificado"
else
    echo "[ubiquity-visual] AVISO: $UBQUITY_MAIN não encontrado"
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
    # Substituir textos e logo no arquivo Glade
    sed -i 's/Ubuntu/MrEzequielOS/g' "$WELCOME_UI"
    sed -i 's/Try or Install/Experimentar ou Instalar/g' "$WELCOME_UI"
    sed -i 's/Install MrEzequielOS/Instalar MrEzequielOS/g' "$WELCOME_UI"
    echo "[ubiquity-visual] welcome.ui textos atualizados"
fi

# 4. Slideshow - atualizar HTMLs para nossos apps e usar nosso wallpaper
SLIDESHOW_DIR="/usr/share/ubiquity-slideshow/mrezequielos"
mkdir -p "$SLIDESHOW_DIR/screenshots"

# Copiar nosso wallpaper como background dos slides
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/welcome.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/office.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/browse.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/accessibility.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/music.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/photos.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/gethelp.png" 2>/dev/null || true
cp /root/MrEzequielOS/config/branding/wallpaper.svg "$SLIDESHOW_DIR/screenshots/usc.png" 2>/dev/null || true

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
    src="/root/MrEzequielOS/config/slideshow/${slide}.html"
    dst="$SLIDESHOW_DIR/${slide}.html"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        # Ajustar referências de imagem
        sed -i 's|screenshots/|screenshots/|g' "$dst"
    fi
done

# 5. Configurar ubiquity para usar nosso slideshow
UBIQUITY_SLIDESHOW_CONF="/etc/ubiquity-slideshow.conf"
echo "slideshow=mrezequielos" > "$UBIQUITY_SLIDESHOW_CONF"

# 6. Patch no ubiquity frontend para setar window icon na inicialização
# Criar um wrapper que roda antes do ubiquity
cat > /usr/local/bin/mrezequielos-ubiquity-wrapper << 'WRAPEOF'
#!/bin/bash
# Wrapper para definir icon da janela do ubiquity
export GTK_WINDOW_ICON=/usr/share/pixmaps/mrezequielos-installer.svg
exec ubiquity gtk_ui "$@"
WRAPEOF
chmod +x /usr/local/bin/mrezequielos-ubiquity-wrapper

# Atualizar .desktop para usar wrapper
if [ -f "$DESKTOP_FILE" ]; then
    sed -i 's|^Exec=.*|Exec=mrezequielos-ubiquity-wrapper|' "$DESKTOP_FILE"
fi

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