FROM ubuntu:19.10

ADD start.sh /start.sh

RUN apt-get update && apt-get install -y openssh-server --no-install-recommends
RUN mkdir /var/run/sshd
RUN sed -i \
	  -e 's~^PasswordAuthentication yes~PasswordAuthentication no~g' \
	  -e 's~^#PermitRootLogin yes~PermitRootLogin no~g' \
	  -e 's~^#UseDNS yes~UseDNS no~g' \
	  -e 's~^\(.*\)/usr/libexec/openssh/sftp-server$~\1internal-sftp~g' \
		/etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV \
	SSH_USER="app-admin" \
	SSH_USER_PASSWORD="app-admin" \
	SSH_USER_HOME="/home/%u" \
	TZ="Asia/Shanghai"   
ENV	NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/start.sh"]

