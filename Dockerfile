FROM gramoss/mini-run-base:void


ARG APP_HOME=/home/policr_mini


COPY _build/prod/rel/policr_mini $APP_HOME


WORKDIR $APP_HOME


ENV LANG=C.UTF-8
ENV PATH="$APP_HOME/bin:$PATH"


ENTRYPOINT [ "policr_mini", "start" ]
