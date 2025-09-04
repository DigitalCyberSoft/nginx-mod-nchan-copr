# COPR Makefile for automated nginx-mod-nchan builds  
# This fetches the latest nginx version from Fedora repos and builds nchan from git master

# Default target for COPR
srpm:
	@echo "Starting nginx-mod-nchan SRPM build"
	
	# Query the latest nginx version from Fedora repositories
	@echo "Querying latest nginx version from Fedora repos..."
	$(eval NGINX_VERSION := $(shell dnf repoquery --latest-limit=1 --qf="%{version}" nginx 2>/dev/null || echo "1.28.0"))
	@echo "Found nginx version: $(NGINX_VERSION)"
	
	# Download nginx SRPM from Fedora to get patches
	@echo "Downloading nginx SRPM from Fedora..."
	@dnf download --source nginx --destdir=.
	
	# Extract patches from the SRPM
	@echo "Extracting patches from nginx SRPM..."
	@rpm2cpio nginx-*.src.rpm | cpio -idmv "*.patch" 2>/dev/null || true
	
	# Download nginx source tarball
	@echo "Downloading nginx source tarball..."
	@curl -L -o nginx-$(NGINX_VERSION).tar.gz http://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz || \
		(echo "Failed to download nginx $(NGINX_VERSION), trying fallback to 1.26.2..." && \
		 curl -L -o nginx-1.26.2.tar.gz http://nginx.org/download/nginx-1.26.2.tar.gz && \
		 mv nginx-1.26.2.tar.gz nginx-$(NGINX_VERSION).tar.gz)
	
	# Clone latest nchan from GitHub
	@echo "Cloning latest nchan from GitHub..."
	@rm -rf nchan-master
	@git clone https://github.com/slact/nchan.git nchan-master
	
	# Get nchan version, create tarball, and generate spec file
	@NCHAN_VERSION=$$(cd nchan-master && (git describe --tags --always 2>/dev/null || git rev-parse --short HEAD) | sed 's/^v//' | sed 's/-/_/g'); \
	echo "nchan version: $$NCHAN_VERSION"; \
	echo "Creating nchan tarball..."; \
	tar czf nchan-$$NCHAN_VERSION.tar.gz -C . nchan-master --transform "s/^nchan-master/nchan-$$NCHAN_VERSION/"; \
	echo "Generating spec file..."; \
	( \
	echo '%global  _hardened_build     1'; \
	echo '%global  nginx_user          nginx'; \
	echo ''; \
	echo '# gperftools exist only on selected arches'; \
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
	echo "%define nchan_ver $$NCHAN_VERSION"; \
	echo '%define nginx_ver $(NGINX_VERSION)'; \
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
	if [ -f nginx-auto-cc-gcc.patch ]; then echo 'Patch0:            nginx-auto-cc-gcc.patch'; fi; \
	i=1; for patch in nginx-*.patch; do \
		[ -f "$$patch" ] && [ "$$patch" != "nginx-auto-cc-gcc.patch" ] && echo "Patch$$i:            $$patch" && i=$$((i+1)); \
	done; \
	echo ''; \
	echo '%if 0%{?with_gperftools}'; \
	echo 'BuildRequires:     gperftools-devel'; \
	echo '%endif'; \
	echo 'BuildRequires:     openssl-devel'; \
	echo 'BuildRequires:     pcre-devel'; \
	echo 'BuildRequires:     pcre2-devel'; \
	echo 'BuildRequires:     zlib-devel'; \
	echo 'BuildRequires:     gd-devel'; \
	echo 'BuildRequires:     perl-devel'; \
	echo 'BuildRequires:     perl-generators'; \
	echo 'BuildRequires:     perl(ExtUtils::Embed)'; \
	echo 'BuildRequires:     libxslt-devel'; \
	echo 'BuildRequires:     systemd'; \
	echo ''; \
	echo 'Requires:          nginx-filesystem >= %{epoch}:%{nginx_ver}-%{release}'; \
	echo 'Requires:          nginx >= %{epoch}:%{nginx_ver}-%{release}'; \
	echo 'Requires:          openssl'; \
	echo 'Requires:          pcre2'; \
	echo 'Requires(post):    systemd'; \
	echo 'Provides:          webserver'; \
	echo ''; \
	echo '%description'; \
	echo 'Nchan is a scalable, flexible pub/sub server for the modern web, built as a module'; \
	echo 'for the Nginx web server. Messages are published to channels with HTTP POST requests'; \
	echo 'or Websocket, and subscribed also through Websocket, long-polling, EventSource (SSE),'; \
	echo 'old-fashioned interval polling, and more.'; \
	echo 'https://nchan.slact.net'; \
	echo ''; \
	echo '%prep'; \
	echo '%setup -n "nginx-%{nginx_ver}" -q -a 1'; \
	if [ -f nginx-auto-cc-gcc.patch ]; then echo '%patch 0 -p0'; fi; \
	i=1; for patch in nginx-*.patch; do \
		[ -f "$$patch" ] && [ "$$patch" != "nginx-auto-cc-gcc.patch" ] && echo "%patch $$i -p1" && i=$$((i+1)); \
	done; \
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
	echo '    --with-http_addition_module \'; \
	echo '    --with-http_auth_request_module \'; \
	echo '    --with-http_dav_module \'; \
	echo '    --with-http_degradation_module \'; \
	echo '    --with-http_flv_module \'; \
	echo '    --with-http_gunzip_module \'; \
	echo '    --with-http_gzip_static_module \'; \
	echo '    --with-http_image_filter_module=dynamic \'; \
	echo '    --with-http_mp4_module \'; \
	echo '    --with-http_perl_module=dynamic \'; \
	echo '    --with-http_random_index_module \'; \
	echo '    --with-http_realip_module \'; \
	echo '    --with-http_secure_link_module \'; \
	echo '    --with-http_slice_module \'; \
	echo '    --with-http_ssl_module \'; \
	echo '    --with-http_stub_status_module \'; \
	echo '    --with-http_sub_module \'; \
	echo '    --with-http_v2_module \'; \
	echo '    --with-http_v3_module \'; \
	echo '    --with-http_xslt_module=dynamic \'; \
	echo '    --with-mail=dynamic \'; \
	echo '    --with-mail_ssl_module \'; \
	echo '    --with-pcre \'; \
	echo '    --with-pcre-jit \'; \
	echo '    --with-stream=dynamic \'; \
	echo '    --with-stream_ssl_module \'; \
	echo '    --with-stream_ssl_preread_module \'; \
	echo '    --with-threads \'; \
	echo '    --add-dynamic-module=./nchan-%{nchan_ver} \'; \
	echo '    --with-cc-opt="%{optflags} $$(pcre2-config --cflags 2>/dev/null || pcre-config --cflags)" \'; \
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
	echo '# Use restart instead of reload because nchan does not support reload'; \
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
	echo '- Built against Fedora nginx version %{nginx_ver}'; \
	echo '- Using nchan commit %{nchan_ver}'; \
	) > nginx-mod-nchan.spec; \
	echo "Spec file generated successfully"
	
	# Build SRPM
	@echo "Building SRPM..."
	@rpmbuild -bs \
		--define "_sourcedir $(PWD)" \
		--define "_specdir $(PWD)" \
		--define "_builddir $(PWD)" \
		--define "_srcrpmdir $(outdir)" \
		--define "_rpmdir $(PWD)" \
		nginx-mod-nchan.spec
	
	@echo "SRPM build complete"

# Clean target for local testing
clean:
	@rm -f *.tar.gz *.spec *.src.rpm *.patch *.rpm
	@rm -rf nchan-master

.PHONY: srpm clean