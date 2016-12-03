# Zato load-balancer

FROM ubuntu:16.04
MAINTAINER Rafał Krysiak <rafal@zato.io>

RUN ln -s -f /bin/true /usr/bin/chfn

# Install helper programs used during Zato installation
RUN apt-get update && apt-get install -y apt-transport-https \
    python-software-properties \
    software-properties-common \
    curl \
    telnet \
    sudo \
    nano \
    wget

# Add the package signing key
RUN curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -

# Add Zato repo to your apt
# update sources and install Zato
RUN apt-add-repository https://zato.io/repo/stable/2.0/ubuntu
RUN apt-get update && apt-get install -y zato

USER zato
WORKDIR /opt/zato

EXPOSE 11223 20151

RUN mkdir /opt/zato/ca
COPY zato.load_balancer.cert.pem /opt/zato/ca/
COPY zato.load_balancer.key.pem /opt/zato/ca/
COPY zato.load_balancer.key.pub.pem /opt/zato/ca/
COPY ca_cert.pem /opt/zato/ca/
COPY zato_load_balancer.config /opt/zato/
COPY zato_start_load_balancer /opt/zato/zato_start_load_balancer
COPY zato_from_config_create_load_balancer /opt/zato/zato_from_config_create_load_balancer


USER root
RUN chmod +x /opt/zato/zato_start_load_balancer \
             /opt/zato/zato_from_config_create_load_balancer

USER zato
RUN rm -rf /opt/zato/env/load-balancer && mkdir -p /opt/zato/env/load-balancer

RUN /opt/zato/zato_from_config_create_load_balancer
RUN sed -i 's/127.0.0.1:11223/0.0.0.0:11223/g' /opt/zato/env/load-balancer/config/repo/zato.config
RUN sed -i 's/localhost/0.0.0.0/g' /opt/zato/env/load-balancer/config/repo/lb-agent.conf

CMD ["/opt/zato/zato_start_load_balancer"]
