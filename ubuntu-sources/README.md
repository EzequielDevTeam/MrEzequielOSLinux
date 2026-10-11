# Código-fonte do Ubuntu (para customização profunda)

O Ubuntu completo tem ~30 mil pacotes (centenas de GB) — inviável copiar
tudo para o git. O padrão profissional é baixar o fonte **sob demanda**
só dos pacotes que vamos mexer (`apt source`).

## Como baixar o fonte de um pacote (no Ubuntu 24.04)

```bash
cd ubuntu-sources
./fetch-sources.sh casper ubiquity gnome-shell
# fonte vai para ubuntu-sources/<pacote>/ com .dsc + .tar + .debian.tar
```

O script habilita `deb-src`, baixa e registra a versão em `VERSIONS.txt`.

## Pacotes que customizamos no MrEzequielOS

Lista padrão em `packages.txt`:

| Pacote | Por que |
|---|---|
| `casper` | boot da sessão live (autologin, hostname, usuário live) |
| `ubiquity` | instalador gráfico (textos, slides, marca) |
| `ubiquity-slideshow-ubuntu` | slides do instalador (trocar por MrEzequielOS) |
| `gnome-shell` | shell (se um dia forkar algo visual) |
| `gdm3` | tela de login (tema do greeter) |
| `mutter` | compositor (efeitos/janelas) |
| `plymouth` | splash de boot (usamos tema `spinner` por padrão) |
| `grub2` | bootloader (tema do menu, textos) |

## Fluxo de mudança no fonte

1. `./fetch-sources.sh <pacote>`
2. Edita em `ubuntu-sources/<pacote>/`
3. Recompila: `cd ubuntu-sources/<pacote> && dpkg-buildpackage -us -uc -b`
4. O `.deb` gerado entra no `packages.list` ou é instalado via hook
   (documentar no README do pacote)

NÃO commitar fontes gigantes sem necessidade — só o que for mexido.
