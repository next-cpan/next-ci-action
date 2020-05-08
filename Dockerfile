FROM alpine:latest

LABEL "com.github.actions.name"="Play Pull Request"
LABEL "com.github.actions.description"="Automatically Check Pull Requests"
LABEL "com.github.actions.icon"="check-square"
LABEL "com.github.actions.color"="blue"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	perl \
	jq

RUN perl -v

# install App::cpm
COPY cpanfile /action/
WORKDIR /action
#RUN curl -fsSL --compressed https://git.io/cpm > cpm && chmod +x cpm
RUN curl -fsSL --compressed https://raw.githubusercontent.com/skaji/cpm/0.992/cpm > cpm && chmod +x cpm
RUN ./cpm --version
RUN ./cpm install -g --show-build-log-on-failure --cpanfile=./cpanfile

COPY /bin /usr/bin/

ENTRYPOINT ["entrypoint.sh"]