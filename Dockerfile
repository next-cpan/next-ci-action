# TODO: use a pre compiled docker image for speeding up CI workflow
FROM perldocker/perl-tester:5.30

LABEL "com.github.actions.name"="Play Pull Request"
LABEL "com.github.actions.description"="Automatically Check Pull Requests"
LABEL "com.github.actions.icon"="check-square"
LABEL "com.github.actions.color"="blue"

RUN apt-get update && \
        apt-get dist-upgrade -y && \
        apt-get install -y \
              curl \
              jq \
              bash \
              wget \
              jq \
              make \
              gcc

RUN perl -v
RUN perl -MDevel::Peek -E 'say q[ok]'

# install App::cpm
COPY /cpanfile /action/cpanfile
WORKDIR /action

RUN curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm
RUN ./cpanm --version
RUN ./cpanm --installdeps .

COPY /run.pl /action/run.pl
COPY /lib /action/lib
COPY /bin /usr/bin/

ENTRYPOINT ["entrypoint.sh"]