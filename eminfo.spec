Summary: pluginable platform written by perl/shell for linux ops.
Name: eminfo
Version: 1.0.0
Release: beta2
License: GPLv3
Group:  Extension
Packager: Zhang Guangzheng <zhang.elinks@gmail.com>
BuildRoot: /var/tmp/%{name}-%{version}-%{release}-root
Source0: eminfo-1.0.0-beta2.tgz
Source1: eminfo.init
Requires: coreutils,bash,e2fsprogs,procps,psmisc,util-linux,SysVinit
Requires: gawk,sed,python,perl,grep,tar,gzip,curl,bc,nc
Requires(post): chkconfig
Requires(preun): chkconfig, initscripts
Requires(postun): coreutils

%description 
pluginable platform written by perl/shell for linux ops.

%prep
%setup -q

%build

%install 
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d/
cp -a *  $RPM_BUILD_ROOT/usr/local/eminfo/
cp -a    %{SOURCE1} $RPM_BUILD_ROOT/etc/rc.d/init.d/%{name}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0755, root, root) %{_initrddir}/%{name}
%attr(0755, root, root) /usr/local/%{name}

%post
/sbin/chkconfig --add %{name}
ln -sv /usr/local/eminfo/eminfo /usr/bin/eminfo
/usr/local/eminfo/bin/setinit rpminit

%preun
/sbin/service %{name} stop >/dev/null 2>&1
/sbin/chkconfig --del %{name}

%postun
[ -d /usr/local/eminfo ] && mv /usr/local/eminfo /usr/local/eminfo_$(date +%s)

%changelog
* Mon Sep 23 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- redesgin by perl/shell for eminfo-1.0.0-beta2.rpm
- seperated into three packets: main/plugin/tool
* Sun May 11 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- init buildrpm for eminfo-1.0.0-beta1.rpm
