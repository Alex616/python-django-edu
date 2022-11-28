# Образ с системными зависимостями
FROM python:3.11 AS deps-image

RUN groupadd --gid 999 test \
  && useradd --uid 999 --gid test --shell /bin/bash --create-home test

RUN apt-get update && \
	apt-get install -y \
      mime-support \
      dictionaries-common \
      wamerican


RUN mkdir /app
WORKDIR /app


# Ставим питонячие зависимости
FROM deps-image AS build-image

RUN apt-get update && \
    apt-get install -y \
      git \
      gcc \
      build-essential

RUN pip install pipenv

COPY Pipfile Pipfile.lock ./

RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    # обязательно нужно установить wheel внутрь venv
    pip install wheel && \
    pipenv install --dev

# Образ для разработки
FROM build-image AS dev-image

RUN apt-get install -y vim curl make
SHELL ["/bin/bash", "-c"]
RUN echo $'#!/bin/bash \n\
. /opt/venv/bin/activate && pipenv $@' > /usr/bin/entrypoint.sh \
    && chmod a+rx /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["shell"]

# Образ для запуска на бою
FROM deps-image


RUN mkdir -p /opt/app && chown -R test:test /opt/app

COPY --from=build-image /opt/venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /opt/app
COPY --chown=test:test . .

USER test
RUN mkdir -p /opt/app/static

# не задаём entrypoint т.к надо запускать как uwsgi, так и python manage.py
ENTRYPOINT []

RUN python api/manage.py collectstatic --noinput

#CMD ["uwsgi", "--ini", "settings/uwsgi.ini"]
CMD []
