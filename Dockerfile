FROM openaustralia/morph-base
MAINTAINER Seb Bacon <seb@opencorporates.com>

# Set the locale
RUN locale-gen en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

# libcurl is needed by typhoeus gem
RUN apt-get update
RUN apt-get -y install curl libxslt-dev libxml2-dev libcurl4-gnutls-dev poppler-utils

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc

RUN /bin/bash -l -c 'rvm install ruby-1.9.3-p545'


# Volume for sharing wrapper script
VOLUME /utils

# Special handling for scraperwiki gem because rubygems doesn't support
# gems from git repositories. So we have to explicitly install it.
RUN mkdir /build
RUN git clone https://github.com/openaustralia/scraperwiki-ruby.git /build
RUN cd /build; git checkout morph_defaults
# rake install is not working so doing it in two steps
# TODO Figure out what is going on here
RUN /bin/bash -l -c 'cd /build; rake --trace build'
RUN /bin/bash -l -c 'cd /build; gem install /build/pkg/scraperwiki-3.0.1.gem'
RUN rm -rf /build

# Add prerun script which will disable output buffering
ADD prerun.rb /usr/local/lib/prerun.rb

# Install apache tika
# Required for tika
RUN apt-get update
RUN apt-get -y install openjdk-7-jre-headless
RUN /bin/bash -l -c 'cd /tmp && curl http://mirror.ox.ac.uk/sites/rsync.apache.org/tika/tika-app-1.7.jar > /usr/local/tika-app-1.7.jar'

ADD Gemfile /etc/Gemfile
RUN /bin/bash -l -c 'bundle install --gemfile /etc/Gemfile'
# For some reason bundle install doesn't install everything, so we need to do it twice
RUN /bin/bash -l -c 'rm /etc/Gemfile.lock'
RUN /bin/bash -l -c 'bundle install --gemfile /etc/Gemfile'

RUN mkdir /tmp/build
RUN git clone https://github.com/OpenAddressesUK/turbot-runner /tmp/build/turbot-runner
RUN cd /tmp/build/turbot-runner && /bin/bash -l -c 'gem build turbot-runner.gemspec ; gem install `ls *gem`'

RUN git clone https://github.com/OpenAddressesUK/openc-schema /tmp/build/openc-schema
RUN cd /tmp/build/openc-schema && /bin/bash -l -c 'gem build openc-schema.gemspec ; gem install `ls *gem`'

VOLUME /output
