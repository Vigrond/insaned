FROM gcc:bullseye AS insaned-build

ENV APP_DIR=/app
WORKDIR "$APP_DIR"

COPY Makefile "$APP_DIR/"
COPY src "$APP_DIR/src"

RUN apt-get update \
  && apt-get install -yq \
    libsane-dev \
  && rm -rf /var/lib/apt/lists/*;

RUN make

FROM debian:bookworm-slim as insane-base

RUN apt-get update \
  && apt-get install -yq \
    sane \
    sane-utils \
    sane-airscan \
    ipp-usb \
    curl \
    jq \
  && rm -rf /var/lib/apt/lists/*;

FROM insane-base AS insane-core
ENV APP_DIR=/app
WORKDIR "$APP_DIR"

COPY --from=insaned-build "$APP_DIR" .

# copy binary and scripts
RUN cp insaned /usr/bin
RUN chmod +x /usr/bin/insaned
RUN touch /etc/default/insaned

# copy over event scripts and make them executable
COPY events /etc/insaned/events
RUN chmod +x /etc/insaned/events/*

# forward logs to docker
#RUN ln -sf /dev/stdout /var/log/insaned.log

COPY entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT [ "/entrypoint.sh" ]
