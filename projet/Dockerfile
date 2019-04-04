FROM python:3.6-alpine
COPY . /code
WORKDIR /code
RUN apk update \
  && apk add --virtual .build-deps gcc python3-dev musl-dev libffi-dev \
  && apk del libressl-dev \
  && apk add openssl-dev \	
  && apk del openssl-dev \
  && apk add libressl-dev \
  && apk add mysql-client \
  && pip install -r requirements.txt
WORKDIR app
CMD ["python", "server.py"]
