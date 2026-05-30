FROM nousresearch/hermes-agent:latest

USER root

# Home Assistant add-ons persist /data.
# Hermes expects /opt/data, so point Hermes storage at persistent add-on storage.
RUN mkdir -p /data/hermes \
  && rm -rf /opt/data \
  && ln -s /data/hermes /opt/data

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]