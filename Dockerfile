FROM jenkins/jenkins:lts-jdk11

ARG DOTNET_VERSION="dotnet-sdk-5.0"
ARG NODEJS_VERSION="setup_12.x"
ARG GRADLE_VERSION="gradle-6.2.1"
ARG PHP_VERSION="php7.4"

LABEL NAME="bsahub/jenkins-autotests"
LABEL VERSION="2.0"
LABEL MAINTAINER="Mykyta Potapenko @ github.com/potapy4"

USER root

RUN apt-get update && \
      apt-get -y install sudo lsb-release apt-transport-https ca-certificates wget && apt-get update && \
      # Add dotnet SDK
      wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg && \
      sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ && \
      wget https://packages.microsoft.com/config/debian/9/prod.list && \
      sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list && \
      sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg && \
      sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list && \
      # Add nodejs
      curl -sL https://deb.nodesource.com/$NODEJS_VERSION | sudo -E bash - && \
      # Add PHP
      sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
      echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list && \
      # Add Gradle
      wget -q https://services.gradle.org/distributions/$GRADLE_VERSION-bin.zip && \
      unzip $GRADLE_VERSION-bin.zip -d /opt && rm $GRADLE_VERSION-bin.zip && \
      # Install components
      apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && \
      apt-get -y install git-all \
      nodejs \
      $DOTNET_VERSION \
      $PHP_VERSION \
      $PHP_VERSION-json \
      $PHP_VERSION-xml \
      $PHP_VERSION-cli \
      $PHP_VERSION-mbstring && \
      # Install Composer
      curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
      # Clean up
      sudo apt-get -y autoremove && sudo apt-get -y clean

# Set Gradle in the environment variables
ENV GRADLE_HOME /opt/$GRADLE_VERSION
ENV PATH $PATH:/opt/$GRADLE_VERSION/bin

# Update the username and password
ENV JENKINS_USER admin
ENV JENKINS_PASS admin
ENV GITHUB_TOKEN ''

# Allows to skip Jenkins setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# Install jenkins plugins
COPY ./jenkins-plugins /usr/share/jenkins/plugins
RUN while read i ; \
                do /usr/local/bin/install-plugins.sh $i ; \
        done < /usr/share/jenkins/plugins

# Jenkins runs all grovy files from init.groovy.d dir
COPY ["default-user.groovy", "executors.groovy", "/usr/share/jenkins/ref/init.groovy.d/"]

# First time building of jenkins with the preconfigured job
COPY Run_Tests/config.xml /usr/share/jenkins/ref/jobs/Run_Tests/config.xml

VOLUME /var/jenkins_home
USER jenkins
