FROM python:3.9.6-alpine3.14

RUN apk add --no-cache --upgrade bash
RUN apk add --no-cache --upgrade curl

WORKDIR /usr/src/app

COPY access_token/get_access_token.sh ./
COPY entitlements_init/data_init.sh ./

RUN chmod +x ./get_access_token.sh
RUN chmod +x ./data_init.sh
ENTRYPOINT [ "./data_init.sh" ]