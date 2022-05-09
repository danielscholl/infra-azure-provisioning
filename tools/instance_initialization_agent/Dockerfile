# https://github.com/docker-library/python/blob/master/3.8/alpine3.15/Dockerfile
# This is a python 3.8 base image based on alpine linux distribution
FROM msosdu.azurecr.io/python-base:3.8

ENV PYTHONUNBUFFERED=1

COPY requirements.txt ./
COPY config.json ./
COPY main.py ./
COPY utils.py ./
COPY configmap_utils.py ./
COPY partition_init_payload.json ./
COPY keyvault_secret_placeholders.json ./

# Install gcc and dependent libraries
RUN apk add build-base
RUN apk add libffi-dev

RUN pip3 install --no-cache --upgrade -r requirements.txt

CMD [ "python", "./main.py" ]