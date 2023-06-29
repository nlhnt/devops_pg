FROM redhat/ubi9:latest

RUN dnf update -y \
    && dnf upgrade -y \
    && dnf install python3

COPY requirements.txt ./requirements.txt
COPY src/check_gpu.py ./app/check_gpu.py

RUN python3 -m venv venv \
    && source venv/bin/activate \
    && pip install -r ./requirements.txt

USER 0

CMD : \
    && source venv/bin/activate \
    && python ./app/check_gpu.py
