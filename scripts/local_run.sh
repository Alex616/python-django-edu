#!/bin/sh
set -e

cd /opt/app/ && api/manage.py migrate --noinput &&
  cd api &&
  uwsgi --ini api/uwsgi.ini
