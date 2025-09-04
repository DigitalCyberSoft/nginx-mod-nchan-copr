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
	echo "NOTE: Using forked repository with GCC 15 fixes until upstream PR #706 is merged"; \
	rm -rf nchan-master; \
	git clone --depth=50 https://github.com/DigitalCyberSoft/nchan.git nchan-master || exit 1; \
	\
	echo "=== Getting nchan version ==="; \
	NCHAN_VER=$$(cd nchan-master && (git describe --tags --always 2>/dev/null || git rev-parse --short HEAD) | sed 's/^v//' | sed 's/-/_/g'); \
	echo "nchan version: $$NCHAN_VER"; \
	\
	echo "=== Creating nchan tarball ==="; \
	tar czf nchan-$$NCHAN_VER.tar.gz -C . nchan-master --transform "s/^nchan-master/nchan-$$NCHAN_VER/" || exit 1; \
	\
	echo "=== Generating spec file ==="; \
	( \
	echo '%global _hardened_build 1'; \
	echo '%global nginx_user nginx'; \
	echo ''; \
	echo '%ifnarch s390 s390x'; \
	echo '%global with_gperftools 1'; \
	echo '%endif'; \
	echo ''; \
	echo '%global with_aio 1'; \
	echo ''; \
	echo '%if 0%{?fedora} > 22'; \
	echo '%global with_mailcap_mimetypes 1'; \
	echo '%endif'; \
	echo ''; \
	echo "%define nginx_ver $$NGINX_VER"; \
	echo "%define nchan_ver $$NCHAN_VER"; \
	echo ''; \
	echo 'Name:              nginx-mod-nchan'; \
	echo 'Epoch:             1'; \
	echo 'Version:           %{nginx_ver}_%{nchan_ver}'; \
	echo 'Release:           1%{?dist}'; \
	echo ''; \
	echo 'Summary:           Flexible pub/sub server for the modern web'; \
	echo 'License:           MIT'; \
	echo 'URL:               https://nchan.slact.net/'; \
	echo ''; \
	echo 'Source0:           nginx-%{nginx_ver}.tar.gz'; \
	echo 'Source1:           nchan-%{nchan_ver}.tar.gz'; \
	echo ''; \
	echo 'BuildRequires:     gcc'; \
	echo 'BuildRequires:     make'; \
	echo 'BuildRequires:     openssl-devel'; \
	echo 'BuildRequires:     pcre-devel'; \
	echo 'BuildRequires:     pcre2-devel'; \
	echo 'BuildRequires:     zlib-devel'; \
	echo ''; \
	echo '%if 0%{?with_gperftools}'; \
	echo 'BuildRequires:     gperftools-devel'; \
	echo '%endif'; \
	echo ''; \
	echo 'BuildRequires:     gd-devel'; \
	echo 'BuildRequires:     perl-devel'; \
	echo 'BuildRequires:     perl-generators'; \
	echo 'BuildRequires:     perl(ExtUtils::Embed)'; \
	echo 'BuildRequires:     libxslt-devel'; \
	echo 'BuildRequires:     systemd'; \
	echo ''; \
	echo 'Requires:          nginx >= %{epoch}:%{nginx_ver}'; \
	echo 'Requires:          openssl'; \
	echo 'Requires(post):    systemd'; \
	echo ''; \
	echo '%description'; \
	echo 'Nchan is a scalable, flexible pub/sub server for the modern web, built as a module'; \
	echo 'for the Nginx web server. Messages are published to channels with HTTP POST requests'; \
	echo 'or Websocket, and subscribed also through Websocket, long-polling, EventSource (SSE),'; \
	echo 'old-fashioned interval polling, and more.'; \
	echo ''; \
	echo '%prep'; \
	echo '%setup -n nginx-%{nginx_ver} -q -a 1'; \
	echo ''; \
	echo '%build'; \
	echo 'export DESTDIR=%{buildroot}'; \
	echo './configure \'; \
	echo '    --prefix=%{_datadir}/nginx \'; \
	echo '    --sbin-path=%{_sbindir}/nginx \'; \
	echo '    --modules-path=%{_libdir}/nginx/modules \'; \
	echo '    --conf-path=%{_sysconfdir}/nginx/nginx.conf \'; \
	echo '    --error-log-path=%{_localstatedir}/log/nginx/error.log \'; \
	echo '    --http-log-path=%{_localstatedir}/log/nginx/access.log \'; \
	echo '    --http-client-body-temp-path=%{_localstatedir}/lib/nginx/tmp/client_body \'; \
	echo '    --http-proxy-temp-path=%{_localstatedir}/lib/nginx/tmp/proxy \'; \
	echo '    --http-fastcgi-temp-path=%{_localstatedir}/lib/nginx/tmp/fastcgi \'; \
	echo '    --http-uwsgi-temp-path=%{_localstatedir}/lib/nginx/tmp/uwsgi \'; \
	echo '    --http-scgi-temp-path=%{_localstatedir}/lib/nginx/tmp/scgi \'; \
	echo '    --pid-path=/run/nginx.pid \'; \
	echo '    --lock-path=/run/lock/subsys/nginx \'; \
	echo '    --user=%{nginx_user} \'; \
	echo '    --group=%{nginx_user} \'; \
	echo '    --with-compat \'; \
	echo '    --with-debug \'; \
	echo '%if 0%{?with_aio}'; \
	echo '    --with-file-aio \'; \
	echo '%endif'; \
	echo '%if 0%{?with_gperftools}'; \
	echo '    --with-google_perftools_module \'; \
	echo '%endif'; \
	echo '    --with-http_ssl_module \'; \
	echo '    --with-http_v2_module \'; \
	echo '    --with-http_realip_module \'; \
	echo '    --with-http_addition_module \'; \
	echo '    --with-http_xslt_module=dynamic \'; \
	echo '    --with-http_image_filter_module=dynamic \'; \
	echo '    --with-http_sub_module \'; \
	echo '    --with-http_dav_module \'; \
	echo '    --with-http_flv_module \'; \
	echo '    --with-http_mp4_module \'; \
	echo '    --with-http_gunzip_module \'; \
	echo '    --with-http_gzip_static_module \'; \
	echo '    --with-http_auth_request_module \'; \
	echo '    --with-http_random_index_module \'; \
	echo '    --with-http_secure_link_module \'; \
	echo '    --with-http_degradation_module \'; \
	echo '    --with-http_slice_module \'; \
	echo '    --with-http_stub_status_module \'; \
	echo '    --with-http_perl_module=dynamic \'; \
	echo '    --with-mail=dynamic \'; \
	echo '    --with-mail_ssl_module \'; \
	echo '    --with-stream=dynamic \'; \
	echo '    --with-stream_ssl_module \'; \
	echo '    --with-stream_ssl_preread_module \'; \
	echo '    --with-pcre \'; \
	echo '    --with-pcre-jit \'; \
	echo '    --with-threads \'; \
	echo '    --add-dynamic-module=./nchan-%{nchan_ver} \'; \
	echo '    --with-cc-opt="%{optflags}" \'; \
	echo '    --with-ld-opt="$$RPM_LD_FLAGS -Wl,-E"'; \
	echo ''; \
	echo 'make %{?_smp_mflags}'; \
	echo ''; \
	echo '%install'; \
	echo 'make install DESTDIR=%{buildroot} INSTALLDIRS=vendor'; \
	echo ''; \
	echo 'find %{buildroot} -type f -iname "*.so" -exec chmod 0755 "{}" \;'; \
	echo ''; \
	echo 'install -p -d -m 0755 %{buildroot}%{_datadir}/nginx/modules'; \
	echo 'install -p -d -m 0755 %{buildroot}%{_libdir}/nginx/modules'; \
	echo ''; \
	echo 'echo '\''load_module "%{_libdir}/nginx/modules/ngx_nchan_module.so";'\'' \'; \
	echo '     > %{buildroot}%{_datadir}/nginx/modules/mod-nchan.conf'; \
	echo ''; \
	echo '%post'; \
	echo 'if [ $$1 -eq 1 ]; then'; \
	echo '    /usr/bin/systemctl restart nginx.service >/dev/null 2>&1 || :'; \
	echo 'fi'; \
	echo ''; \
	echo '%files'; \
	echo '%{_datadir}/nginx/modules/mod-nchan.conf'; \
	echo '%{_libdir}/nginx/modules/ngx_nchan_module.so'; \
	echo '%exclude /etc/nginx/*'; \
	echo '%exclude /usr/sbin/nginx'; \
	echo '%exclude /usr/share/man/*'; \
	echo '%exclude /usr/share/nginx/html/*'; \
	echo '%exclude %{_libdir}/nginx/modules/ngx_http_*.so'; \
	echo '%exclude %{_libdir}/nginx/modules/ngx_mail*.so'; \
	echo '%exclude %{_libdir}/nginx/modules/ngx_stream*.so'; \
	echo '%exclude %{_libdir}/perl5/*'; \
	echo ''; \
	echo '%changelog'; \
	echo "* $$(date '+%a %b %d %Y') COPR Builder - %{nginx_ver}_%{nchan_ver}-1"; \
	echo '- Automated build from GitHub master branch'; \
	echo '- Built against nginx version %{nginx_ver}'; \
	echo '- Using nchan commit %{nchan_ver}'; \
	) > nginx-mod-nchan.spec || exit 1; \
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