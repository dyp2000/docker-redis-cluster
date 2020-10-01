FROM redis:latest

LABEL maintainer="Dennis Y. Parygin <dyp2000@mail.ru>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get -y upgrade \
    && apt-get install -y apt-utils locales locales-all \
    && apt-get install -y --no-install-recommends \
        mc net-tools procps \
    && locale-gen ru_RU.UTF-8

ENV LANG ru_RU.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL ru_RU.UTF-8

CMD ["redis-server"]
