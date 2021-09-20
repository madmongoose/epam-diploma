FROM amazonlinux

WORKDIR /app

COPY ./requirements.txt requirements.txt

RUN yum -y update && yum -y install python3 python3-pip sudo

RUN pip3 install -r requirements.txt

COPY ./fe.py /app

#COPY ./index.php /var/www/html/index.php
#CMD ["/usr/sbin/httpd","-D","FOREGROUND"]

ENTRYPOINT ["streamlit", "run"]

CMD ["fe.py"]

EXPOSE 8501

