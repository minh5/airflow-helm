FROM debian:jessie
MAINTAINER minh mai

ENV DEBIAN_FRONTEND    noninteractive
ENV TERM               linux
ENV AIRFLOW_HOME       /usr/local/airflow
ENV LANGUAGE           en_US.UTF-8
ENV LANG               en_US.UTF-8
ENV LC_ALL             en_US.UTF-8
ENV LC_CTYPE           en_US.UTF-8
ENV LC_MESSAGES        en_US.UTF-8
ENV LC_ALL             en_US.UTF-8
ENV KUBECTL_VERSION    1.7.11

# install system dependencies
RUN set -ex \
    && buildDeps=' \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libxml2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libxslt1-dev \
        zlib1g-dev \
        git \
        apt-utils \
        curl \
        netcat \
        locales \
        python3-setuptools \
        python3-requests \
    ' \
    && echo "deb http://http.debian.net/debian jessie-backports main" >/etc/apt/sources.list.d/backports.list \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends $buildDeps \
    && apt-get install -yqq -t jessie-backports libpq-dev \
    && easy_install3 pip

RUN sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d $AIRFLOW_HOME airflow

# install Python packages and Airflow
COPY ./requirements.txt .

RUN pip install -r requirements.txt \
    && pip install apache-airflow==1.9.0 \
    && apt-get remove --purge -yqq $buildDeps libpq-dev \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

RUN ln -s $(which python3) /usr/bin/python

# finishing up
USER airflow
COPY ./dags/ $AIRFLOW_HOME/dags
WORKDIR $AIRFLOW_HOME

EXPOSE 8080 5555 8793 5672
