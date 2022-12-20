
FROM alpine/terragrunt:1.2.3-eks

RUN apk --no-progress --quiet update &&\
    apk --no-progress --quiet --no-cache add sudo zsh zsh-vcs shadow

ENV GLIBC_VER=2.31-r0
ENV HELM_VER=v3.9.0

# install glibc compatibility for alpine
RUN apk --no-cache add \
        binutils \
        curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
        glibc-i18n-${GLIBC_VER}.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
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