# TODO: use a pre compiled docker image for speeding up CI workflow
FROM alpine:latest

LABEL "com.github.actions.name"="Play Pull Request"
LABEL "com.github.actions.description"="Automatically Check Pull Requests"
LABEL "com.github.actions.icon"="check-square"
LABEL "com.github.actions.color"="blue"

RUN    apk add --no-cache \
       bash \
       ca-certificates \
       curl \
       git \
       git-lfs \
       jq \
       openssh \
       perl \
       wget
#       make \
#       gcc

RUN perl -v

# install App::cpm
#COPY /cpanfile /action/cpanfile

WORKDIR /action

#RUN curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm
#RUN ./cpanm --version
#RUN ./cpanm --installdeps .

COPY /run.pl /action/run.pl
COPY /bin    /usr/bin/
COPY /fatlib /action/fatlib
COPY /lib    /action/lib
COPY /vendor /action/vendor

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]