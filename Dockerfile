FROM debian:buster


RUN apt-get update \
    && apt-get install openssl -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt/lists/partial/*


ARG APP_HOME=/home/policr_mini


COPY _build/prod/rel/policr_mini $APP_HOME
COPY images "$APP_HOME/images"


WORKDIR $APP_HOME


ENV LANG=C.UTF-8
ENV PATH="$APP_HOME/bin:$PATH"
ENV MIX_ENV=prod


EXPOSE 4000


ENTRYPOINT [ "policr_mini", "start" ]
