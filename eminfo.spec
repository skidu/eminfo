Summary: 	pluginable platform written by perl/shell for linux ops.
Name: 		eminfo
Version: 	1.0
Release: 	beta6
License: 	GPLv3
Group:  	Extension
Packager: 	Zhang Guangzheng <zhang.elinks@gmail.com>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	eminfo-1.0-beta6.tgz
Source1: 	eminfo.init
Requires: 		coreutils >= 5.97, bash >= 3.1
Requires:		e2fsprogs >= 1.39, procps >= 3.2.7
Requires:		psmisc >= 22.2, util-linux >= 2.13
Requires:		SysVinit >= 2.86, nc >= 1.84
Requires: 		gawk >= 3.1.5, sed >= 4.1.5
Requires:		perl >= 5.8.8, grep >= 2.5.1
Requires:		tar >= 1.15.1, gzip >= 1.3.5
Requires:		curl >= 7.15.5, bc >= 1.06
Requires:		findutils >= 4.2.27
Requires(post): 	chkconfig
Requires(preun): 	chkconfig, initscripts
Requires(postun): 	coreutils >= 5.97
#
# All of version requires are based on OS rhel5.1 release
#

%description 
pluginable platform written by perl/shell for linux ops.

%prep
%setup -q

%build

%install 
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && /bin/rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/eminfo/
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d/
cp -a *  $RPM_BUILD_ROOT/usr/local/eminfo/
cp -a    %{SOURCE1} $RPM_BUILD_ROOT/etc/rc.d/init.d/%{name}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && /bin/rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0755, root, root) %{_initrddir}/%{name}
/usr/local/%{name}

%post
/sbin/chkconfig --add %{name}
if [ -L "/usr/bin/eminfo" ]; then
	:
else
	/bin/ln -s /usr/local/eminfo/eminfo /usr/bin/eminfo
fi
/bin/bash /usr/local/eminfo/bin/setinit rpminit

%preun
/sbin/service %{name} stop >/dev/null 2>&1
/sbin/chkconfig --del %{name}

%postun
if [ -L "/usr/bin/eminfo" ]; then
	/bin/rm -f /usr/bin/eminfo
else
	:
fi

%changelog
* Tue Nov 12 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- eminfo-1.0-beta6.rpm release
- check shs in makedir
* Tue Oct 29 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- eminfo-1.0-beta5.rpm release
- update lastrun/nextrun on plugin terminated as timeout
- update handler output to fit sendmail
- add eminfo argument takesnap/t
* Wed Oct 24 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- eminfo-1.0-beta4.rpm release
- various misforma check on plugin output
- strict on plugin/handler max output length
- speed up on plugin/handler huge output
- speed up on smtphost/posthost connection
- bug fix
* Sun Oct 13 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- fixed some bugs for eminfo-1.0-beta3 release
* Mon Sep 23 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- redesgin by perl/shell for eminfo-1.0-beta2.rpm
- seperated into three packets: main/plugin/tool
* Sun May 11 2013 Guangzheng Zhang <zhang.elinks@gmail.com>
- init buildrpm for eminfo-1.0-beta1.rpm
