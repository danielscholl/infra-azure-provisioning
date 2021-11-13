FROM msosdu.azurecr.io/data-seed-base:v1

WORKDIR /usr/src/app

COPY access_token/get_access_token.sh ./
COPY data_init.sh ./

RUN chmod +x ./get_access_token.sh
RUN chmod +x ./data_init.sh
ENTRYPOINT [ "./data_init.sh" ]
