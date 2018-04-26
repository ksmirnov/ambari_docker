FROM centos/systemd

# Installing EPEL and some essential packages
RUN yum install -y --quiet epel-release \
 && yum -y --quiet update \
 && yum install -y --quiet \
    bzip2 \
    initscripts \
    ntp \
    openssh-clients \
    openssh-server \
    sudo \
    wget

# TODO: Resolve HOME dynamically
ENV HOME "/root"

# Configure SSH free key access
RUN echo 'root:hortonworks' | chpasswd \
 && ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' \
 && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
 && sed -i '/pam_loginuid.so/c session    optional     pam_loginuid.so'  /etc/pam.d/sshd \
 && echo -e "Host *\n StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Installing Miniconda & PySpark
RUN wget -nv http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh -O ~/miniconda.sh \
 && bash ~/miniconda.sh -b -p $HOME/miniconda \
 && rm -f ~/miniconda.sh

# Setting environment variables
ENV PATH "$HOME/miniconda/bin:$PATH"
ENV PYTHON "$HOME/miniconda/bin/python"
ENV PYTHONPATH "$PYTHON"

RUN ~/miniconda/bin/conda update -y conda \
 && ~/miniconda/bin/conda install -y pyspark

# Installing Ambari server
RUN wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.5.2.0/ambari.repo \
    -O /etc/yum.repos.d/ambari.repo \
 && yum repolist \
 && yum install -y ambari-server

# Final cleaning
RUN yum clean all

EXPOSE 22 8080 8081 8082 8083 8084 8085 8086 8087 8088

CMD ["/usr/sbin/init"]

