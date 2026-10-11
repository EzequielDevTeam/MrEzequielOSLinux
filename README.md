# MrEzequielOS 🐧
Baseado no Ubuntu 24.04 LTS (Noble) + GNOME Minimal estilo Zorin OS (leve e bonito).

**Licença:** código sob [GPLv3](LICENSE) — pode estudar e modificar, mas quem
redistribuir tem que manter aberto. Nome, logo e identidade visual são marca
exclusiva do projeto (veja [TRADEMARK.md](TRADEMARK.md)).

## O que é?
MrEzequielOS = Ubuntu minimal (debootstrap) + `gnome-core` + `gdm3` + taskbar Windows (Dash to Panel) + menu iniciar (ArcMenu) + tema escuro + apps essenciais.
ISO com boot BIOS + UEFI (Secure Boot desligado no v1).

> "geome" que você falou é o **GNOME**. É bonito mas pesado, então vamos usar o **gnome-core** (versão leve).

## Estrutura
```
MrEzequielOS/
├── build.sh                  # build local (Ubuntu 24.04)
├── packages.list             # pacotes da ISO
├── config/
│   ├── gnome/settings.ini    # tema, wallpaper, dock
│   └── branding/os-release   # nome MrEzequielOS
└── .github/workflows/build-iso.yml  # compila no GitHub (git)
```

## Como compilar

### Opção A - No GitHub (recomendado, "dentro do git")
1. Crie repo no GitHub via CLI:
```bash
cd /root/MrEzequielOS
git init
git add .
git commit -m "MrEzequielOS v1.0"
gh repo create MrEzequielOS --public --source=. --push
```
2. Vá em Actions > build-iso > Run workflow
3. Baixe a ISO em Artifacts (fica pronta em ~20-30min)

### Opção B - Local (precisa Ubuntu 24.04)
```bash
chmod +x build.sh
sudo ./build.sh
# ISO sai em: out/MrEzequielOS-1.0-amd64.iso
```

### Opção C - Cubic (mais fácil visual)
Se quiser personalizar na mão:
```bash
sudo apt install cubic
# Abra o Cubic, escolha ubuntu-24.04-desktop-amd64.iso como base,
# na aba terminal cole o conteúdo de packages.list
```
