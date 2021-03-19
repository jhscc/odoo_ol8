#Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Unified Directory (OUD)
#
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# See oud.download file 
# Also see patches.download file in the patches directory

# From JDK as Base for the OUD Image
# ----------------------------------
FROM oraclelinux:8 as base

# Maintainer
# ----------
LABEL "maintainer"="Work Wise Consulting"                      \
      "provider"="WorkWise"                                               \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "volume.user_projects"="/opt/oracle/user_projects"                \
      "port.adminldaps"="1444"                                          \
      "port.adminhttps"="1888"                                          \
      "port.ldap"="1389"                                                \
      "port.ldaps"="1636"                                               \
      "port.http"="1080"                                                \
      "port.https"="1081"                                               \
      "port.replication"="1898"                                         

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV BASE_DIR=/opt/odoo \
    LOG_DIR=/var/log/odoo \
    USER_ODOO=odoo \
    ODOO_VERSION=13 \
    ODOO_BRANCH=13.0
#
# Creation of User, Directories and Installation of OS packages
# ----------------------------------------------------------------
USER root
RUN mkdir -p ${BASE_DIR}
RUN useradd -m -U -r -d ${BASE_DIR} -s /bin/bash ${USER_ODOO}
RUN	chown -R ${USER_ODOO}:${USER_ODOO} ${BASE_DIR} 
RUN	dnf config-manager --set-enabled ol8_codeready_builder
RUN	dnf install -y libxml2-devel libevent-devel libpq-devel libjpeg-devel nodejs npm libxml2-devel xmlsec1-devel xmlsec1-openssl-devel libtool-ltdl-devel python3 python3-devel git gcc libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox-0.12.5-1.centos8.x86_64.rpm \
  	&& dnf clean all \
  	&& rm -rf /var/cache/yum

RUN mkdir -p ${LOG_DIR}
RUN touch ${LOG_DIR}/odoo.log
RUN chown -R ${USER_ODOO}:${USER_ODOO} ${LOG_DIR}

COPY ./odoo.conf ${BASE_DIR}/odoo.conf
RUN chown -R ${USER_ODOO}:${USER_ODOO} ${BASE_DIR}

USER odoo

RUN mkdir -p ${BASE_DIR}/odoo-custom-addons
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/OCA/crm
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/OCA/timesheet
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/OCA/project
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/OCA/project-reporting
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/OCA/sale-workflow
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/Trust-Code/trustcode-addons
RUN mkdir -p ${BASE_DIR}/odoo-custom-addons/Trust-Code/odoo-brasil

RUN git clone https://github.com/odoo/odoo.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo
RUN git clone https://github.com/OCA/crm.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/OCA/crm
RUN git clone https://github.com/OCA/timesheet.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/OCA/timesheet
RUN git clone https://github.com/OCA/project.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/OCA/project
RUN git clone https://github.com/OCA/project-reporting.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/OCA/project-reporting
RUN git clone https://github.com/OCA/sale-workflow.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/OCA/sale-workflow
RUN git clone https://github.com/Trust-Code/trustcode-addons.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/Trust-Code/trustcode-addons
RUN git clone https://github.com/Trust-Code/odoo-brasil.git --depth 1 --branch ${ODOO_BRANCH} ${BASE_DIR}/odoo-custom-addons/Trust-Code/odoo-brasil

COPY ./odoo-custom-addons-${ODOO_VERSION}/. ${BASE_DIR}/odoo-custom-addons/

ENV VIRTUAL_ENV=/opt/odoo/venv/bin/
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN $VIRTUAL_ENV/bin/pip3 install --upgrade pip \
    && $VIRTUAL_ENV/bin/pip3 install --upgrade setuptools wheel psycopg2 PyPDF2 psycopg2-binary \
    && $VIRTUAL_ENV/bin/pip3 install --upgrade -r ${BASE_DIR}/odoo-custom-addons/Trust-Code/odoo-brasil/requirements.txt \
    && $VIRTUAL_ENV/bin/pip3 install --upgrade -r ${BASE_DIR}/odoo/requirements.txt \
    && $VIRTUAL_ENV/bin/pip3 install --upgrade -r ${BASE_DIR}/odoo-custom-addons/Trust-Code/trustcode-addons\requirements.txt \
    && $VIRTUAL_ENV/bin/pip3 install --upgrade -r ${BASE_DIR}/odoo-custom-addons/OCA/sale-workflow\requirements.txt 

CMD ["python3","/opt/odoo/odoo/odoo-bin","-c","/opt/odoo/odoo.conf"]

EXPOSE 8069
USER root
