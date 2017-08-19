FROM alpine:3.6

ENV GOLANG_VERSION="1.8.3" \
  PUMP_VERSION="0.4.2"

# https://golang.org/issue/14851 (Go 1.8 & 1.7)
# https://golang.org/issue/17847 (Go 1.7)
COPY *.patch /go-alpine-patches/

RUN set -eux; \
  # install go
  # ref: https://github.com/docker-library/golang/tree/master/1.8/alpine3.6
  #
  \
  apk add --no-cache ca-certificates; \
  \
	apk add --no-cache --virtual .build-deps \
		bash \
		gcc \
		musl-dev \
		openssl \
		go \
    curl \
		tar \
    git \
	; \
	export \
# set GOROOT_BOOTSTRAP such that we can actually build Go
		GOROOT_BOOTSTRAP="$(go env GOROOT)" \
# ... and set "cross-building" related vars to the installed system's values so that we create a build targeting the proper arch
# (for example, if our build host is GOARCH=amd64, but our build env/image is GOARCH=386, our build needs GOARCH=386)
		GOOS="$(go env GOOS)" \
		GOARCH="$(go env GOARCH)" \
		GO386="$(go env GO386)" \
		GOARM="$(go env GOARM)" \
		GOHOSTOS="$(go env GOHOSTOS)" \
		GOHOSTARCH="$(go env GOHOSTARCH)" \
	; \
	\
	wget -O go.tgz "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz"; \
	echo '5f5dea2447e7dcfdc50fa6b94c512e58bfba5673c039259fd843f68829d99fa6 *go.tgz' | sha256sum -c -; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	cd /usr/local/go/src; \
	for p in /go-alpine-patches/*.patch; do \
		[ -f "$p" ] || continue; \
		patch -p2 -i "$p"; \
	done; \
	./make.bash; \
	\
  export \
    GOPATH="/go" \
    PATH="/go/bin:/usr/local/go/bin:$PATH" \
  ; \
  mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"; \
	go version; \
  \
  \
  # build tyk-pump
  #
  # download
  if ! curl -fL -o /tmp/${PUMP_VERSION}.tar.gz "https://github.com/TykTechnologies/tyk-pump/archive/${PUMP_VERSION}.tar.gz"; then \
    echo >&2 "error: failed to download 'tyk-pump-${PUMP_VERSION}' from github"; \
    exit 1; \
  fi; \
  tar -zxf /tmp/${PUMP_VERSION}.tar.gz -C /tmp; \
  \
  cd /tmp/tyk-pump-${PUMP_VERSION}; \
  \ 
  # Patch main.go
  sed -i '15 s/^/\/\//' main.go; \
  sed -i '177,184 s/^/\/\//' main.go; \
  \
  # build
  go get -t -d -v; \    
  go build -v; \
  go test -v; \
  cp tyk-pump-0.4.2 /usr/local/bin/tyk-pump; \
  \
  # clean up
  rm -rf /go-alpine-patches; \
	apk del .build-deps; \
  rm -rf /tmp/*; \
  rm -rf /usr/local/go/*; \
  rm -rf /go/*; \
  \
  # test run tyk-pump
  set +e; \
  tyk-pump; \
  exit 0

COPY ["pump.conf", "/"]

CMD ["tyk-pump", "--c=/pump.conf"]