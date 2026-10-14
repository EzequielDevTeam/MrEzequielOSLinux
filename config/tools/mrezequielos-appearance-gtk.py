#!/usr/bin/python3
# SPDX-License-Identifier: GPL-3.0-or-later
# MrEzequielOS Appearance - central de visual em GTK4/libadwaita (igual Zorin Appearance).
# Layout, Tema, Efeitos, Desktop, Fundo e Interface. Cai para o modo zenity se faltar lib.
import os
import sys

try:
    import gi
    gi.require_version('Gtk', '4.0')
    gi.require_version('Adw', '1')
    from gi.repository import Gtk, Adw, Gio
except Exception as e:
    print('GTK indisponivel (%s), caindo para zenity' % e)
    os.execvp('mrezequielos-appearance', ['mrezequielos-appearance'] + sys.argv[1:])

APP_ID = 'dev.ezequiel.MrEzequielOSAppearance'
WALLPAPER = '/usr/share/backgrounds/mrezequielos-wallpaper.svg'
START_ICON = '/usr/share/pixmaps/mrezequielos-start.svg'

CORE_EXTS = [
    'zorin-taskbar@zorinos.com',
    'arcmenu@arcmenu.com',
    'appindicatorsupport@rgcjonas.gmail.com',
    'zorin-connect@zorinos.com',
    'user-theme@gnome-shell-extensions.gcampax.github.com',
]
OPT_EXTS = [
    ('blur', 'blur-my-shell@aunetx', 'Desfoque', 'Desfoque no painel e nas janelas'),
    ('icones', 'ding@rastersoft.com', 'Ícones no desktop', 'Pastas e lixeira na área de trabalho'),
    ('fogo', 'burn-my-windows@schneegans.github.com', 'Efeito fogo', 'Janelas abrem com energia'),
    ('cubo', 'desktop-cube@schneegans.github.com', 'Cubo 3D', 'Cubo ao trocar de área de trabalho'),
]

FAVS = ['brave-browser.desktop', 'org.gnome.Nautilus.desktop',
        'libreoffice-writer.desktop', 'org.gnome.Terminal.desktop',
        'org.gnome.Software.desktop']
PINS = [[{'id': 'brave-browser.desktop'}, {'id': 'org.gnome.Nautilus.desktop'}],
        [{'id': 'org.gnome.Terminal.desktop'}],
        [{'id': 'org.gnome.Software.desktop'}],
        [{'id': 'libreoffice-writer.desktop'}],
        [{'id': 'mrezequielos-help.desktop'}]]

DTB_POSITIONS = ('{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},'
                 '{"element":"activitiesButton","visible":false,"position":"stackedTL"},'
                 '{"element":"leftBox","visible":true,"position":"stackedTL"},'
                 '{"element":"taskbar","visible":true,"position":"centerMonitor"},'
                 '{"element":"centerBox","visible":true,"position":"stackedBR"},'
                 '{"element":"rightBox","visible":true,"position":"stackedBR"},'
                 '{"element":"dateMenu","visible":true,"position":"stackedBR"},'
                 '{"element":"systemMenu","visible":true,"position":"stackedBR"},'
                 '{"element":"desktopButton","visible":true,"position":"stackedBR"}]}')


def gs(schema, path=None):
    if path:
        return Gio.Settings.new_with_path(schema_id=schema, path=path)
    return Gio.Settings.new(schema_id=schema)


def sset(settings, key, kind, value):
    try:
        if key not in settings.list_keys():
            return False
        getattr(settings, 'set_' + kind)(key, value)
        return True
    except Exception:
        return False


def sget(settings, key, default=''):
    try:
        if key not in settings.list_keys():
            return default
        return settings.get_string(key)
    except Exception:
        return default


def bg():
    return gs('org.gnome.desktop.background')


def schema_ok(schema):
    try:
        src = Gio.SettingsSchemaSource.get_default()
        return src is not None and src.lookup(schema, True) is not None
    except Exception:
        return False


def ext_gs(schema, path):
    if not schema_ok(schema):
        return None
    try:
        return Gio.Settings.new_with_path(schema, path)
    except Exception:
        return None


def iface():
    return gs('org.gnome.desktop.interface')


def shell():
    return gs('org.gnome.shell')


def dtp():
    return ext_gs('org.gnome.shell.extensions.zorin-taskbar',
                  '/org/gnome/shell/extensions/zorin-taskbar/')


def arc():
    return ext_gs('org.gnome.shell.extensions.arcmenu',
                  '/org/gnome/shell/extensions/arcmenu/')


def ding_gs():
    return ext_gs('org.gnome.shell.extensions.ding',
                  '/org/gnome/shell/extensions/ding/')


def ls_dirs(path):
    try:
        return sorted(d for d in os.listdir(path)
                      if os.path.isdir(os.path.join(path, d)) and not d.startswith('.'))
    except OSError:
        return []


def apply_layout(name):
    if name == 'mac':
        shell().set_strv('enabled-extensions',
                         ['ding@rastersoft.com', 'blur-my-shell@aunetx',
                          'appindicatorsupport@rgcjonas.gmail.com',
                          'user-theme@gnome-shell-extensions.gcampax.github.com',
                          'dash-to-dock@micxgx.gmail.com'])
        try:
            d = ext_gs('org.gnome.shell.extensions.dash-to-dock',
                       '/org/gnome/shell/extensions/dash-to-dock/')
            if d is None:
                raise Exception('sem schema')
            d.set_string('dock-position', 'BOTTOM')
            d.set_boolean('extend-height', False)
        except Exception:
            pass
    elif name == 'ubuntu':
        iface().set_string('gtk-theme', 'Yaru')
        iface().set_string('color-scheme', 'default')
        iface().set_string('icon-theme', 'Papirus')
        shell().set_strv('enabled-extensions',
                         ['ding@rastersoft.com',
                          'appindicatorsupport@rgcjonas.gmail.com',
                          'ubuntu-dock@ubuntu.com'])
        shell().set_strv('favorite-apps', FAVS)
    else:
        gtk = 'ZorinPurple-Dark' if os.path.isdir('/usr/share/themes/ZorinPurple-Dark') else 'Yaru-dark'
        iface().set_string('gtk-theme', gtk)
        iface().set_string('color-scheme', 'prefer-dark')
        sset(iface(), 'accent-color', 'string', 'purple')
        shell().set_strv('favorite-apps', FAVS)
        shell().set_strv('enabled-extensions', CORE_EXTS + ['blur-my-shell@aunetx',
                                                             'ding@rastersoft.com'])
        shell().set_boolean('disable-user-extensions', False)
        d = dtp()
        if d is not None:
            d.set_string('panel-positions', '{"0": "BOTTOM"}')
            d.set_string('panel-sizes', '{"0": 48}')
            d.set_string('panel-element-positions', DTB_POSITIONS)
            d.set_int('global-border-radius', 12)
            d.set_boolean('trans-use-custom-opacity', True)
            d.set_double('trans-panel-opacity', 0.75)
            d.set_boolean('isolate-workspaces', True)
    a = arc()
    if a is not None:
        a.set_string('menu-button-appearance', 'Icon')
        if os.path.exists(START_ICON):
            a.set_string('menu-button-icon', START_ICON)
        a.set_int('menu-button-icon-size', 28)
        try:
            a.set_boolean('show-activities-button', False)
        except Exception:
            pass
    ding = ding_gs()
    if ding is not None:
        ding.set_boolean('show-home', True)
        ding.set_boolean('show-trash', True)


class AppearanceApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID)
        self.win = None

    def do_activate(self):
        try:
            Gtk.Settings.get_default().props.gtk_decoration_layout = ':minimize,maximize,close'
        except Exception:
            pass
        if not self.win:
            self.win = AppearanceWindow(self)
        self.win.present()


def toast_page(parent, title, ok=True):
    if ok:
        msg = 'Aplicado. Reinicie o computador para valer tudo.'
    else:
        msg = 'Falhou. Abra o app Diagnóstico e veja os detalhes.'
    try:
        dlg = Adw.AlertDialog.new(title, msg)
        dlg.add_response('ok', 'OK')
        dlg.present(parent)
    except Exception:
        try:
            dlg = Adw.MessageDialog.new(parent, title, msg)
            dlg.add_response('ok', 'OK')
            dlg.present()
        except Exception:
            pass


class AppearanceWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title='MrEzequielOS Appearance',
                         default_width=780, default_height=560)
        split = Adw.NavigationSplitView.new()
        self.set_content(split)
        sidebar = Adw.NavigationPage.new(Gtk.Label.new(''), 'Aparência')
        content = Adw.NavigationPage.new(Gtk.Label.new(''), '')
        sidebar_list = Gtk.ListBox.new()
        sidebar_list.add_css_class('navigation-sidebar')
        sidebar.set_child(sidebar_list)
        self.stack = Gtk.Stack.new()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        content.set_child(self.stack)
        content.set_title('MrEzequielOS Appearance')
        split.set_sidebar(sidebar)
        split.set_content(content)
        self.pages = {}
        for key, title in [('layout', 'Layout'), ('tema', 'Tema'),
                           ('efeitos', 'Efeitos'), ('desktop', 'Desktop'),
                           ('fundo', 'Fundo'), ('interface', 'Interface')]:
            row = Gtk.ListBoxRow.new()
            row.set_child(Gtk.Label.new(title))
            row.key = key
            sidebar_list.append(row)
            page = self.build_page(key)
            self.pages[key] = page
            self.stack.add_named(page, key)
        sidebar_list.connect('row-selected', self.on_row)
        sidebar_list.select_row(sidebar_list.get_row_at_index(0))

    def on_row(self, box, row):
        if row is not None:
            self.stack.set_visible_child_name(row.key)

    def pref_page(self):
        page = Adw.PreferencesPage.new()
        group = Adw.PreferencesGroup.new()
        page.add(group)
        return page, group

    def build_page(self, key):
        if key == 'layout':
            return self.page_layout()
        if key == 'tema':
            return self.page_tema()
        if key == 'efeitos':
            return self.page_efeitos()
        if key == 'desktop':
            return self.page_desktop()
        if key == 'fundo':
            return self.page_fundo()
        return self.page_interface()

    def apply_row(self, group, title, sub, callback):
        row = Adw.ActionRow.new()
        row.set_title(title)
        row.set_subtitle(sub)
        btn = Gtk.Button.new_with_label('Aplicar')
        btn.add_css_class('suggested-action')

        def _run(_b):
            try:
                ok = callback()
            except Exception:
                ok = False
            toast_page(self, title, ok=(ok is not False))

        btn.connect('clicked', _run)
        row.add_suffix(btn)
        group.add(row)

    def thumb(self, group, key):
        f = {'windows': '/usr/share/pixmaps/mrezequielos-layout-windows.svg',
             'mac': '/usr/share/pixmaps/mrezequielos-layout-mac.svg',
             'ubuntu': '/usr/share/pixmaps/mrezequielos-layout-ubuntu.svg'}.get(key, '')
        if f and os.path.exists(f):
            pic = Gtk.Picture.new_for_filename(f)
            pic.set_size_request(300, 180)
            group.add(pic)

    def page_layout(self):
        page, group = self.pref_page()
        self.thumb(group, 'windows')
        self.apply_row(group, 'Windows', 'Barra embaixo + menu iniciar (padrão)',
                       lambda: apply_layout('windows'))
        self.thumb(group, 'mac')
        self.apply_row(group, 'macOS', 'Barra em cima + dock embaixo',
                       lambda: apply_layout('mac'))
        self.thumb(group, 'ubuntu')
        self.apply_row(group, 'Ubuntu', 'Barra lateral esquerda',
                       lambda: apply_layout('ubuntu'))
        return page

    def combo_row(self, group, title, sub, options, current, callback):
        row = Adw.ComboRow.new()
        row.set_title(title)
        row.set_subtitle(sub)
        model = Gtk.StringList.new(options)
        row.set_model(model)
        try:
            row.set_selected(options.index(current))
        except ValueError:
            pass
        row.connect('notify::selected-item', lambda r, p: callback(options[r.get_selected()]))
        group.add(row)
        return row

    def page_tema(self):
        page, group = self.pref_page()
        themes = [t for t in ls_dirs('/usr/share/themes') if 'Zorin' in t or 'Yaru' in t or 'Adwaita' in t] or ['Yaru-dark']
        cur_gtk = iface().get_string('gtk-theme')
        self.combo_row(group, 'Aplicativos', 'Estilo das janelas e botões',
                       themes, cur_gtk,
                       lambda v: (iface().set_string('gtk-theme', v),
                                  self.sync_wm(v)))
        icons = [t for t in ls_dirs('/usr/share/icons')
                 if 'Zorin' in t or 'Tela' in t or 'Papirus' in t or 'Yaru' in t] or ['Papirus-Dark']
        cur_ico = iface().get_string('icon-theme')
        self.combo_row(group, 'Ícones', 'Pacote de ícones',
                       icons, cur_ico,
                       lambda v: iface().set_string('icon-theme', v))
        cursors = [t for t in ls_dirs('/usr/share/icons')
                   if os.path.exists(os.path.join('/usr/share/icons', t, 'cursors'))]
        if cursors:
            cur_cur = iface().get_string('cursor-theme')
            self.combo_row(group, 'Cursor', 'Ponteiro do mouse',
                           cursors, cur_cur,
                           lambda v: iface().set_string('cursor-theme', v))
        return page

    def sync_wm(self, gtk):
        try:
            gs('org.gnome.desktop.wm.preferences').set_string('theme', gtk)
        except Exception:
            pass

    def page_efeitos(self):
        page, group = self.pref_page()
        try:
            enabled = set(shell().get_strv('enabled-extensions'))
        except Exception:
            enabled = set()
        for key, uuid, title, sub in OPT_EXTS:
            row = Adw.SwitchRow.new()
            row.set_title(title)
            row.set_subtitle(sub)
            row.set_active(uuid in enabled)
            row.connect('notify::active',
                        lambda r, p, u=uuid: self.toggle_ext(u, r.get_active()))
            group.add(row)
        return page

    def toggle_ext(self, uuid, on):
        try:
            cur = list(shell().get_strv('enabled-extensions'))
            if on and uuid not in cur:
                cur.append(uuid)
            elif not on and uuid in cur:
                cur.remove(uuid)
            shell().set_strv('enabled-extensions', cur)
        except Exception:
            pass

    def page_desktop(self):
        page, group = self.pref_page()
        ding = ding_gs()
        if ding is None:
            row = Adw.ActionRow.new()
            row.set_title('Ícones no desktop indisponíveis')
            row.set_subtitle('Ative a extensão Ding nos Efeitos e abra de novo')
            group.add(row)
        else:
            try:
                for key, title in (('show-home', 'Pasta pessoal no desktop'),
                                   ('show-trash', 'Lixeira no desktop')):
                    row = Adw.SwitchRow.new()
                    row.set_title(title)
                    try:
                        row.set_active(ding.get_boolean(key))
                    except Exception:
                        pass
                    row.connect('notify::active',
                                lambda r, p, k=key: ding.set_boolean(k, r.get_active()))
                    group.add(row)
            except Exception:
                pass
        tap = Adw.SwitchRow.new()
        tap.set_title('Toque para clicar')
        tap.set_subtitle('Touchpad')
        try:
            t = gs('org.gnome.desktop.peripherals.touchpad')
            tap.set_active(t.get_boolean('tap-to-click'))
            tap.connect('notify::active',
                        lambda r, p: t.set_boolean('tap-to-click', r.get_active()))
        except Exception:
            pass
        group.add(tap)
        return page

    def page_fundo(self):
        page, group = self.pref_page()
        cands = []
        for root, _ds, fs in os.walk('/usr/share/backgrounds'):
            for f in sorted(fs):
                if f.lower().endswith(('.jpg', '.png', '.svg')):
                    cands.append(os.path.join(root, f))
            break
        try:
            sub = os.listdir('/usr/share/backgrounds/gnome')
            for f in sorted(sub):
                if f.lower().endswith(('.jpg', '.png')):
                    cands.append(os.path.join('/usr/share/backgrounds/gnome', f))
        except OSError:
            pass
        if os.path.exists(WALLPAPER):
            cands = [WALLPAPER] + [c for c in cands if c != WALLPAPER]
        cur = sget(bg(), 'picture-uri', '').replace('file://', '')
        opts = [os.path.basename(c) for c in cands[:20]] or ['(nenhum)']
        row = Adw.ComboRow.new()
        row.set_title('Papel de parede')
        row.set_subtitle('Fundo da área de trabalho')
        row.set_model(Gtk.StringList.new(opts))
        try:
            row.set_selected(opts.index(os.path.basename(cur)))
        except ValueError:
            pass

        def apply(idx):
            if 0 <= idx < len(cands[:20]):
                uri = 'file://' + cands[:20][idx]
                sset(bg(), 'picture-uri', 'string', uri)
                toast_page(self, 'Fundo')

        row.connect('notify::selected-item',
                    lambda r, p: apply(r.get_selected()))
        group.add(row)
        return page

    def page_interface(self):
        page, group = self.pref_page()
        anim = Adw.SwitchRow.new()
        anim.set_title('Animações')
        anim.set_subtitle('Desligar deixa mais rápido')
        try:
            anim.set_active(iface().get_boolean('enable-animations'))
            anim.connect('notify::active',
                         lambda r, p: iface().set_boolean('enable-animations',
                                                          r.get_active()))
        except Exception:
            pass
        group.add(anim)
        acc = [('Roxo (padrão)', 'purple'), ('Laranja', 'orange'),
               ('Azul', 'blue'), ('Verde', 'green'), ('Vermelho', 'red')]
        names = [a[0] for a in acc]
        cur = sget(iface(), 'accent-color', 'purple')
        sel = next((i for i, a in enumerate(acc) if a[1] == cur), 0)
        row = Adw.ComboRow.new()
        row.set_title('Cor de destaque')
        row.set_subtitle('Botões, interruptores e detalhes')
        row.set_model(Gtk.StringList.new(names))
        row.set_selected(sel)
        row.connect('notify::selected-item',
                    lambda r, p: sset(iface(), 'accent-color', 'string',
                                      acc[r.get_selected()][1]))
        group.add(row)
        return page


def main():
    app = AppearanceApp()
    app.run(sys.argv)


main()
