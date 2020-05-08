# could probably use a lighter source image
FROM perldocker/perl-tester:5.30

LABEL "com.github.actions.name"="Play Pull Request"
LABEL "com.github.actions.description"="Automatically Check Pull Requests"
LABEL "com.github.actions.icon"="check-square"
LABEL "com.github.actions.color"="blue"

RUN apt-get update && \
        apt-get dist-upgrade -y && \
        apt-get install -y curl jq egrep

RUN perl -v

# install App::cpm
COPY /cpanfile /action/cpanfile
WORKDIR /action
#RUN curl -fsSL --compressed https://git.io/cpm > cpm && chmod +x cpm
#RUN curl -fsSL --compressed https://raw.githubusercontent.com/skaji/cpm/0.992/cpm > cpm && chmod +x cpm
#RUN curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm
#RUN ./cpanm --version
RUN cpanm --installdeps .

COPY /run.pl /action/run.pl
COPY /lib /action/lib
COPY /bin /usr/bin/

ENTRYPOINT ["entrypoint.sh"]