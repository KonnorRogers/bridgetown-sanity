FROM ruby:2.7-alpine as builder

RUN apk add --no-cache --virtual \
    # required
    nodejs-dev yarn bash \
    tzdata build-base libffi-dev \
    curl git \
    #
    # nice to haves
    libnotify-dev vim

FROM builder as bridgetownrb-app

# This is to fix an issue on Linux with permissions issues
ARG USER_ID=${USER_ID:-1000}
ARG GROUP_ID=${GROUP_ID:-1000}
ARG DOCKER_USER=${DOCKER_USER:-user}
ARG APP_DIR=${APP_DIR:-/home/user/bridgetown-app}

# Create a non-root user
RUN addgroup -g $GROUP_ID -S $GROUP_ID
RUN adduser --disabled-password -G $GROUP_ID --uid $USER_ID -S $DOCKER_USER

# Create and then own the directory to fix permissions issues
RUN mkdir -p $APP_DIR
RUN chown -R $USER_ID:$GROUP_ID $APP_DIR

# Define the user running the container
USER $USER_ID:$GROUP_ID

# . now == $APP_DIR
WORKDIR $APP_DIR

# COPY is run as a root user, not as the USER defined above, so we must chown it
COPY --chown=$USER_ID:$GROUP_ID Gemfile* $APP_DIR/
RUN gem install bundler
RUN bundle install

# For webpacker / node_modules
COPY --chown=$USER_ID:$GROUP_ID package.json $APP_DIR
COPY --chown=$USER_ID:$GROUP_ID yarn.lock $APP_DIR

RUN yarn install

CMD ["yarn", "start"]

