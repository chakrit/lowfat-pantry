# poetry / black / ansible-playbook — one interpreter, three tools.
# The venv is not isolation; it is the shortest route past alpine's
# externally-managed-environment guard without --break-system-packages.
FROM lowfat-capture-base

RUN apk add --no-cache python3 py3-pip \
    && python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir poetry black ansible-core
