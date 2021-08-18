FROM mcr.microsoft.com/azure-cli:2.15.1

RUN apk update
RUN apk add ca-certificates wget && update-ca-certificates

WORKDIR /usr/src/app

COPY data_seeding_agent/seed_data.sh ./
COPY test_data/Legal_COO.json ./test_data/

RUN chmod +x ./seed_data.sh
ENTRYPOINT [ "./seed_data.sh" ]