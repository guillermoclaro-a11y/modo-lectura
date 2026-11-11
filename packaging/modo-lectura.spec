# RPM spec for Fedora (also works as a COPR package).
# Repository: https://github.com/guillermoclaro-a11y/modo-lectura
%global forge_user guillermoclaro-a11y

Name:           modo-lectura
Version:        1.1.0
Release:        1%{?dist}
Summary:        Plasma widget for distraction-free reading sessions
License:        MIT
URL:            https://github.com/%{forge_user}/modo-lectura
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  make
BuildRequires:  python3
BuildRequires:  systemd-rpm-macros
Requires:       plasma-workspace >= 6.0
Requires:       polkit
Requires:       python3-gobject
Requires:       libnotify
Requires:       pulseaudio-utils
Requires:       systemd

%description
Reading Mode (Modo lectura) is a KDE Plasma 6 widget that starts timed reading
sessions. During a session it blocks YouTube and any other sites you choose,
mutes notifications and optionally locks the screen; when time is up it shows
a notification and plays an alarm. Sites are always unblocked again, even after
a logout or reboot.

%prep
%autosetup

%build
%make_build

%check
make check

%install
%make_install PREFIX=%{_prefix} LIBEXECDIR=%{_libexecdir}/%{name} \
    POLKITDIR=%{_datadir}/polkit-1/actions UNITDIR=%{_unitdir}

%post
%systemd_post modo-lectura-unblock.service

%preun
if [ $1 -eq 0 ] && [ -x %{_libexecdir}/%{name}/unblock ]; then
    %{_libexecdir}/%{name}/unblock || :
fi
%systemd_preun modo-lectura-unblock.service

%postun
%systemd_postun modo-lectura-unblock.service

%files
%license LICENSE
%doc README.md README.en.md
%{_bindir}/modo-lectura
%{_libexecdir}/%{name}/
%{_datadir}/plasma/plasmoids/org.guillermo.modolectura/
%{_datadir}/polkit-1/actions/org.guillermo.modolectura.policy
%{_unitdir}/modo-lectura-unblock.service

%changelog
* Wed Nov 04 2026 Guillermo Claro <267127106+guillermoclaro-a11y@users.noreply.github.com> - 1.1.0-1
- Polkit instead of sudo, configurable sites, translations, accessibility
