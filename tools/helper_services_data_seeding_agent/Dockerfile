FROM mcr.microsoft.com/azure-cli:2.39.0

RUN apk update
RUN apk add ca-certificates wget && update-ca-certificates
RUN apk add  libc6-compat
RUN apk add git

RUN apk add ca-certificates bash curl wget gettext jq bind-tools \
    && wget -q https://storage.googleapis.com/kubernetes-release/release/v1.21.2/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && chmod g+rwx /root \
    && mkdir /config \
    && chmod g+rwx /config \
    && apk add --update coreutils && rm -rf /var/cache/apk/*

WORKDIR /usr/src/app

COPY transfer.sh ./

RUN chmod +x transfer.sh
ENTRYPOINT [ "./transfer.sh" ]