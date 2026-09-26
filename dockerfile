# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

FROM alpine:3.21
LABEL maintainer="Safiyu <safiyucloud@gmail.com>"

VOLUME /media

RUN apk add --no-cache bash figlet curl

# Create dedicated group and user
RUN addgroup -g 1000 -S jellyfix && \
    adduser -u 1000 -S jellyfix -G jellyfix

WORKDIR /app
COPY . /app

RUN chmod 755 /app/entry.sh /app/cron.sh /app/replace.sh && \
    chown -R jellyfix:jellyfix /app

ENV CRON_STRING="0 */6 * * *"
ENV JF_API_KEY=
ENV JF_URL=

ENTRYPOINT ["sh", "/app/cron.sh"]
