FROM openaustralia/morph-base
MAINTAINER Seb Bacon <seb@opencorporates.com>

# libcurl is needed by typhoeus gem
RUN apt-get update
RUN apt-get -y install curl libxslt-dev libxml2-dev libcurl4-gnutls-dev poppler-utils

RUN curl -sSL https://get.rvm.io | bash -s stable
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc

RUN /bin/bash -l -c 'rvm install ruby-1.9.3-p545'

ADD angler-wrapper.rb /usr/bin/angler-wrapper.rb

ADD Gemfile /etc/Gemfile
RUN /bin/bash -l -c 'bundle install --gemfile /etc/Gemfile'

# Special handling for scraperwiki gem because rubygems doesn't support
# gems from git repositories. So we have to explicitly install it.
RUN mkdir /build
RUN git clone https://github.com/openaustralia/scraperwiki-ruby.git /build
RUN cd /build; git checkout morph_defaults
# rake install is not working so doing it in two steps
# TODO Figure out what is going on here
RUN /bin/bash -l -c 'cd /build; rake build'
RUN /bin/bash -l -c 'cd /build; gem install /build/pkg/scraperwiki-3.0.1.gem'
RUN rm -rf /build

# Special handling for openc gem because rubygems doesn't support
# gems from git repositories. So we have to explicitly install it.
RUN mkdir /build
RUN git clone https://github.com/openc/openc_bot.git /build
RUN cd /build; git checkout enumerators-and-iterators
# rake install is not working so doing it in two steps
# TODO Figure out what is going on here
RUN /bin/bash -l -c 'cd /build; rake build'
RUN /bin/bash -l -c 'cd /build; gem install /build/pkg/openc_bot-0.0.6.gem'
RUN rm -rf /build

# Add prerun script which will disable output buffering
ADD prerun.rb /usr/local/lib/prerun.rb
