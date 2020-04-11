FROM jenkins/jenkins:lts
USER root

RUN apt-get update && \
      apt-get -y install sudo
RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
RUN apt-get update && \
    apt-get -y install apt-transport-https \
      ca-certificates \
      git-all \
      nodejs

#Update the username and password
ENV JENKINS_USER admin
ENV JENKINS_PASS admin
ENV GITHUB_TOKEN ''

# install jenkins plugins
COPY ./jenkins-plugins /usr/share/jenkins/plugins
RUN while read i ; \
                do /usr/local/bin/install-plugins.sh $i ; \
        done < /usr/share/jenkins/plugins

# allows to skip Jenkins setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# Jenkins runs all grovy files from init.groovy.d dir
# use this for creating default admin user
COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/

# First time building of jenkins with the preconfigured job
COPY Run_Tests/config.xml /usr/share/jenkins/ref/jobs/Run_Tests/config.xml

VOLUME /var/jenkins_home
USER jenkins