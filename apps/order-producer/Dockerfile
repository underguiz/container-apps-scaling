FROM python

RUN apt-get update &&\
    apt-get -y install cmake &&\
    pip install azure-servicebus

WORKDIR /app

COPY order-producer.py /app/

CMD exec python -u order-producer.py