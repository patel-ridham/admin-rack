FROM fluent/fluentd:v1.19.0-debian-1.0

USER root
WORKDIR /home/fluent
ENV PATH /home/fluent/.gem/2.3.0/bin/:$PATH

RUN buildDeps="make gcc g++ libc-dev ruby-dev libffi-dev patch" \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && echo 'gem: --no-document' >> /etc/gemrc \
    && gem install fluent-plugin-kafka \
    && gem install fluent-plugin-kubernetes \
    && gem install fluent-plugin-kubernetes_metadata_filter \
    && gem install fluent-plugin-record-reformer \
    && gem install fluent-plugin-secure-forward \
    && gem install fluent-plugin-systemd \
    && gem install zookeeper \
    && apt-get purge -y --auto-remove -o \
         APT::AutoRemove::RecommendsImportant=false $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && gem sources --clear-all \
    && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

#COPY ./conf/fluent.conf /fluentd/etc/
#COPY ./conf/kubernetes.conf /fluentd/etc/

#COPY plugins /fluentd/plugins/

ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT