# COPR Makefile for automated nginx-mod-nchan builds
# Installs git if needed for COPR environment

# COPR provides outdir, set default for local testing
outdir ?= .

# Default nginx version if detection fails
NGINX_VERSION ?= 1.28.0

# Default target for COPR
srpm:
	@echo "=== Starting nginx-mod-nchan SRPM build ==="
	@echo "Output directory: $(outdir)"
	@echo "Working directory: $$(pwd)"
	@echo "User: $$(whoami)"
	
	# Install git if not available
	@if ! command -v git >/dev/null 2>&1; then \
		echo "=== Git not found, installing it ==="; \
		if command -v dnf >/dev/null 2>&1; then \
			echo "Using DNF to install git..."; \
			dnf install -y git || (echo "ERROR: Failed to install git with dnf" && exit 1); \
		elif command -v yum >/dev/null 2>&1; then \
			echo "Using YUM to install git..."; \
			yum install -y git || (echo "ERROR: Failed to install git with yum" && exit 1); \
		else \
			echo "ERROR: No package manager found to install git"; \
			exit 1; \
		fi; \
		echo "Git installed successfully"; \
	else \
		echo "=== Git is already available ==="; \
	fi
	
	# Verify git is now available
	@which git || (echo "ERROR: git still not found after installation attempt" && exit 1)
	
	# Try to detect nginx version, fall back to hardcoded
	@if command -v dnf >/dev/null 2>&1; then \
		echo "=== Detecting nginx version from repos ==="; \
		NGINX_VER=$$(dnf repoquery --latest-limit=1 --qf="%{version}" nginx 2>/dev/null || echo "$(NGINX_VERSION)"); \
	else \
		echo "=== DNF not available, using default nginx version ==="; \
		NGINX_VER="$(NGINX_VERSION)"; \
	fi; \
	echo "Using nginx version: $$NGINX_VER"; \
	\
	echo "=== Downloading nginx source tarball ==="; \
	if ! curl -L -o nginx-$$NGINX_VER.tar.gz http://nginx.org/download/nginx-$$NGINX_VER.tar.gz 2>/dev/null; then \
		echo "Failed to download nginx $$NGINX_VER, trying $(NGINX_VERSION)..."; \
		curl -L -o nginx-$(NGINX_VERSION).tar.gz http://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz || exit 1; \
		NGINX_VER="$(NGINX_VERSION)"; \
	fi; \
	\
	echo "=== Cloning nchan from GitHub ==="; \
	rm -rf nchan-master; \
	git clone --depth=50 https://github.com/slact/nchan.git nchan-master || exit 1; \
	\
	echo "=== Getting nchan version ==="; \
	NCHAN_VER=$$(cd nchan-master && (git describe --tags --always 2>/dev/null || git rev-parse --short HEAD) | sed 's/^v//' | sed 's/-/_/g'); \
	echo "nchan version: $$NCHAN_VER"; \
	\
	echo "=== Creating nchan tarball ==="; \
	tar czf nchan-$$NCHAN_VER.tar.gz -C . nchan-master --transform "s/^nchan-master/nchan-$$NCHAN_VER/" || exit 1; \
	\
	echo "=== Generating spec file ==="; \
	cat > nginx-mod-nchan.spec <<SPECEOF || exit 1; \
%global _hardened_build 1 \
%global nginx_user nginx \
\
%ifnarch s390 s390x \
%global with_gperftools 1 \
%endif \
\
%global with_aio 1 \
\
%if 0%{?fedora} > 22 \
%global with_mailcap_mimetypes 1 \
%endif \
\
%define nginx_ver $$NGINX_VER \
%define nchan_ver $$NCHAN_VER \
\
Name:              nginx-mod-nchan \
Epoch:             1 \
Version:           %{nginx_ver}_%{nchan_ver} \
Release:           1%{?dist} \
\
Summary:           Flexible pub/sub server for the modern web \
License:           MIT \
URL:               https://nchan.slact.net/ \
\
Source0:           nginx-%{nginx_ver}.tar.gz \
Source1:           nchan-%{nchan_ver}.tar.gz \
\
BuildRequires:     gcc \
BuildRequires:     make \
BuildRequires:     openssl-devel \
BuildRequires:     pcre-devel \
BuildRequires:     pcre2-devel \
BuildRequires:     zlib-devel \
\
%if 0%{?with_gperftools} \
BuildRequires:     gperftools-devel \
%endif \
\
BuildRequires:     gd-devel \
BuildRequires:     perl-devel \
BuildRequires:     perl-generators \
BuildRequires:     'perl(ExtUtils::Embed)' \
BuildRequires:     libxslt-devel \
BuildRequires:     systemd \
\
Requires:          nginx >= %{epoch}:%{nginx_ver} \
Requires:          openssl \
'Requires(post):    systemd' \
\
%description \
Nchan is a scalable, flexible pub/sub server for the modern web, built as a module \
for the Nginx web server. Messages are published to channels with HTTP POST requests \
or Websocket, and subscribed also through Websocket, long-polling, EventSource (SSE), \
old-fashioned interval polling, and more. \
\
%prep \
%setup -n nginx-%{nginx_ver} -q -a 1 \
\
%build \
export DESTDIR=%{buildroot} \
./configure \\ \
    --prefix=%{_datadir}/nginx \\ \
    --sbin-path=%{_sbindir}/nginx \\ \
    --modules-path=%{_libdir}/nginx/modules \\ \
    --conf-path=%{_sysconfdir}/nginx/nginx.conf \\ \
    --error-log-path=%{_localstatedir}/log/nginx/error.log \\ \
    --http-log-path=%{_localstatedir}/log/nginx/access.log \\ \
    --http-client-body-temp-path=%{_localstatedir}/lib/nginx/tmp/client_body \\ \
    --http-proxy-temp-path=%{_localstatedir}/lib/nginx/tmp/proxy \\ \
    --http-fastcgi-temp-path=%{_localstatedir}/lib/nginx/tmp/fastcgi \\ \
    --http-uwsgi-temp-path=%{_localstatedir}/lib/nginx/tmp/uwsgi \\ \
    --http-scgi-temp-path=%{_localstatedir}/lib/nginx/tmp/scgi \\ \
    --pid-path=/run/nginx.pid \\ \
    --lock-path=/run/lock/subsys/nginx \\ \
    --user=%{nginx_user} \\ \
    --group=%{nginx_user} \\ \
    --with-compat \\ \
    --with-debug \\ \
%if 0%{?with_aio} \
    --with-file-aio \\ \
%endif \
%if 0%{?with_gperftools} \
    --with-google_perftools_module \\ \
%endif \
    --with-http_ssl_module \\ \
    --with-http_v2_module \\ \
    --with-http_realip_module \\ \
    --with-http_addition_module \\ \
    --with-http_xslt_module=dynamic \\ \
    --with-http_image_filter_module=dynamic \\ \
    --with-http_sub_module \\ \
    --with-http_dav_module \\ \
    --with-http_flv_module \\ \
    --with-http_mp4_module \\ \
    --with-http_gunzip_module \\ \
    --with-http_gzip_static_module \\ \
    --with-http_auth_request_module \\ \
    --with-http_random_index_module \\ \
    --with-http_secure_link_module \\ \
    --with-http_degradation_module \\ \
    --with-http_slice_module \\ \
    --with-http_stub_status_module \\ \
    --with-http_perl_module=dynamic \\ \
    --with-mail=dynamic \\ \
    --with-mail_ssl_module \\ \
    --with-stream=dynamic \\ \
    --with-stream_ssl_module \\ \
    --with-stream_ssl_preread_module \\ \
    --with-pcre \\ \
    --with-pcre-jit \\ \
    --with-threads \\ \
    --add-dynamic-module=./nchan-%{nchan_ver} \\ \
    --with-cc-opt="%{optflags}" \\ \
    --with-ld-opt="$$RPM_LD_FLAGS -Wl,-E" \
\
make %{?_smp_mflags} \
\
%install \
make install DESTDIR=%{buildroot} INSTALLDIRS=vendor \
\
find %{buildroot} -type f -iname '*.so' -exec chmod 0755 '{}' \\; \
\
install -p -d -m 0755 %{buildroot}%{_datadir}/nginx/modules \
install -p -d -m 0755 %{buildroot}%{_libdir}/nginx/modules \
\
echo 'load_module "%{_libdir}/nginx/modules/ngx_nchan_module.so";' \\ \
     > %{buildroot}%{_datadir}/nginx/modules/mod-nchan.conf \
\
%post \
if [ $$1 -eq 1 ]; then \
    /usr/bin/systemctl restart nginx.service >/dev/null 2>&1 || : \
fi \
\
%files \
%{_datadir}/nginx/modules/mod-nchan.conf \
%{_libdir}/nginx/modules/ngx_nchan_module.so \
%exclude /etc/nginx/* \
%exclude /usr/sbin/nginx \
%exclude /usr/share/man/* \
%exclude /usr/share/nginx/html/* \
%exclude %{_libdir}/nginx/modules/ngx_http_*.so \
%exclude %{_libdir}/nginx/modules/ngx_mail*.so \
%exclude %{_libdir}/nginx/modules/ngx_stream*.so \
%exclude %{_libdir}/perl5/* \
\
%changelog \
* $$(date '+%a %b %d %Y') COPR Builder - %{nginx_ver}_%{nchan_ver}-1 \
- Automated build from GitHub master branch \
- Built against nginx version %{nginx_ver} \
- Using nchan commit %{nchan_ver} \
SPECEOF
	echo "Spec file generated"; \
	\
	echo "=== Verifying generated files ==="; \
	ls -la nginx-$$NGINX_VER.tar.gz nchan-$$NCHAN_VER.tar.gz nginx-mod-nchan.spec || exit 1; \
	\
	echo "=== Building SRPM ==="; \
	rpmbuild -bs \
		--define "_sourcedir $$(pwd)" \
		--define "_specdir $$(pwd)" \
		--define "_builddir $$(pwd)" \
		--define "_srcrpmdir $(outdir)" \
		--define "_rpmdir $$(pwd)" \
		nginx-mod-nchan.spec || exit 1; \
	\
	echo "=== SRPM build complete ==="; \
	ls -la $(outdir)/*.src.rpm

clean:
	@rm -f *.tar.gz *.spec *.src.rpm *.patch *.rpm
	@rm -rf nchan-master

.PHONY: srpm clean