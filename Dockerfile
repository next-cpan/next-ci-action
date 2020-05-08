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

# install App::cpm
RUN curl -fsSL --compressed https://git.io/cpm > cpm && chmod +x

COPY cpanfile /action/
WORKDIR /action
RUN cpm -g install --cpanfile=cpanfile

COPY /bin /usr/bin/

ENTRYPOINT ["entrypoint.sh"]