FROM amazonlinux

WORKDIR /app

COPY ./requirements.txt requirements.txt

RUN yum -y update && yum -y install python3 python3-pip sudo

RUN pip3 install -r requirements.txt

COPY ./app.py /app

CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0"]

EXPOSE 5000