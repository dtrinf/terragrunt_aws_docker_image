
FROM alpine/terragrunt:1.3.6-eks

ENV GLIBC_VER=2.34-r0
ENV HELM_VER=v3.9.0
ENV HCL2JSON_VER=v0.3.6

RUN apk --no-progress --quiet update &&\
    apk --no-progress --quiet --no-cache add sudo zsh zsh-vcs shadow curl jq &&\
    curl -sL https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VER}/hcl2json_linux_amd64 -o /usr/local/bin/hcl2json &&\
    chmod +x /usr/local/bin/hcl2json

# install glibc compatibility for alpine
RUN apk --no-cache add \
    binutils \
    --virtual=.build-dependencies wget ca-certificates \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk \
    # && echo "antes" \
    && mv /etc/nsswitch.conf /etc/nsswitch.conf.bak \
    && apk add --force-overwrite --no-cache \
    glibc-${GLIBC_VER}.apk \
    glibc-bin-${GLIBC_VER}.apk \
    glibc-i18n-${GLIBC_VER}.apk \
    && mv /etc/nsswitch.conf.bak /etc/nsswitch.conf \
    && rm "/etc/apk/keys/sgerrand.rsa.pub" \
    && (/usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true) \
    && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
    && apk del glibc-i18n \
    && rm -rf "/root/.wget-hsts" \
    && apk del .build-dependencies \
    && rm "glibc-${GLIBC_VER}.apk" "glibc-bin-${GLIBC_VER}.apk" "glibc-i18n-${GLIBC_VER}.apk" \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
    awscliv2.zip \
    aws \
    /usr/local/aws-cli/v2/*/dist/aws_completer \
    /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/*/dist/awscli/examples \
    glibc-*.apk \
    && apk --no-cache del \
    binutils \
    curl \
    && rm -rf /var/cache/apk/*

RUN wget -O /tmp/helm.tar.gz https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz \
    && tar -zxvf /tmp/helm.tar.gz -C /tmp/ \
    && mv /tmp/linux-amd64/helm /usr/local/bin/ \
    && rm -rf /tmp/* \
    && helm plugin install https://github.com/databus23/helm-diff \
    && helm plugin install https://github.com/jkroepke/helm-secrets \
    && helm plugin install https://github.com/hypnoglow/helm-s3.git
