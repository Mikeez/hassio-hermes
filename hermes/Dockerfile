FROM nousresearch/hermes-agent:latest

USER root

# Home Assistant add-ons persist /data.
# Hermes expects /opt/data, so point Hermes storage at persistent add-on storage.
RUN mkdir -p /data/hermes \
  && rm -rf /opt/data \
  && ln -s /data/hermes /opt/data

COPY run.sh /etc/cont-init.d/03-ha-options
RUN chmod a+x /etc/cont-init.d/03-ha-options