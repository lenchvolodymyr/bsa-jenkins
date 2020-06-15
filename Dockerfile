FROM jenkins/jenkins:jdk11

LABEL NAME="bsahub/jenkins-autotests"
LABEL VERSION="1.0"
LABEL MAINTAINER="Nikita Potapenko @ github.com/potapy4"

USER root

RUN apt-get update && \
      apt-get -y install sudo lsb-release apt-transport-https ca-certificates && apt-get update && \
      # Add dotnet SDK
      wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg && \
      sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ && \
      wget https://packages.microsoft.com/config/debian/9/prod.list && \
      sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list && \
      sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg && \
      sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list && \
      # Add nodejs
      curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
      # Add PHP
      sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
      echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list && \
      # Add Gradle
      wget -q https://services.gradle.org/distributions/gradle-6.2.1-bin.zip && \
      unzip gradle-6.2.1-bin.zip -d /opt && rm gradle-6.2.1-bin.zip && \
      # Install components
      apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && \
      apt-get -y install git-all \
      nodejs \
      dotnet-sdk-3.1 \
      php7.4 \
      php7.4-json \
      php7.4-xml \
      php7.4-cli \
      php7.4-mbstring && \
      # Install Composer
      curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
      # Clean up
      sudo apt-get -y autoremove && sudo apt-get -y clean

# Set Gradle in the environment variables
ENV GRADLE_HOME /opt/gradle-6.2.1
ENV PATH $PATH:/opt/gradle-6.2.1/bin

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
# use this for creating default admin user
COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/

# Setup executors
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/

# First time building of jenkins with the preconfigured job
COPY Run_Tests/config.xml /usr/share/jenkins/ref/jobs/Run_Tests/config.xml

VOLUME /var/jenkins_home
USER jenkins
