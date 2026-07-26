# poetry / black / ansible-playbook — one interpreter, three tools.
FROM python:3-alpine

RUN pip install --no-cache-dir poetry black ansible-core
