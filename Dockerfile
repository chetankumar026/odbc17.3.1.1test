# STAGE: main
# -----------
# The main image that is published.
# Use the official RHEL base image with Python 3.11
FROM registry.access.redhat.com/ubi8/python-311


ARG TARGETPLATFORM

COPY requirements.txt .

RUN \
  ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
  "linux/amd64")   echo "x86-64bit" ;; \
  "linux/arm64")   echo "aarch64"   ;; \
  *)               echo ""          ;; esac) && \
  echo "ARCH=$ARCH" && \
  # Install build dependencies
RUN yum -y update && \
    yum -y install curl unixODBC unixODBC-devel && \
    curl -sSL -O https://packages.microsoft.com/config/rhel/7/prod.repo && \
    mv prod.repo /etc/yum.repos.d/mssql-release.repo && \
    ACCEPT_EULA=Y yum -y install msodbcsql17-17.3.1.1-1
  # Install dependencies (pyobdc)
  pip install --upgrade pip && \
  pip install -r requirements.txt && rm requirements.txt && \
  # Cleanup build dependencies
  apt-get remove -y curl apt-transport-https debconf-utils g++ gcc rsync unixodbc-dev build-essential gnupg2 && \
  apt-get autoremove -y && apt-get autoclean -y

# STAGE: test
# -----------
# Image used for running tests.
FROM main AS test

COPY requirements-dev.txt .
RUN pip install -r requirements-dev.txt
WORKDIR /test
COPY test ./test

CMD pylint -v -E **/*.py && pytest -v
