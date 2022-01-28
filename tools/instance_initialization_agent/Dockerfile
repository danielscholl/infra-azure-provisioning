FROM alpine:3.13

# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1

COPY requirements.txt ./

RUN \
  # Update packages
  apk --no-cache upgrade && \
  \
  # Install Python
  apk add --no-cache python3 && \
  if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
  \
  # Install PiP
  python3 -m ensurepip && \
  rm -r /usr/lib/python*/ensurepip && \
  pip3 install --no-cache --upgrade -r requirements.txt && \
  if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

WORKDIR /usr/src/app

COPY config.json ./
COPY main.py ./
COPY utils.py ./
COPY configmap_utils.py ./
COPY partition_init_payload.json ./

CMD [ "python", "./main.py" ]