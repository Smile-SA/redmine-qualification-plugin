# Estimated Resolution Time Server

Run a microservice to estimate the resolution time of a ticket.

## Setup

The project requires python3 and pip3.

```bash
$ pip3 install Flask gunicorn numpy scipy scikit-learn
```

## Run

```bash
gunicorn -b 127.0.0.1:8080 main:app
```

## Use with Redmine qualification plugin

Qualification plugin configuration:

- Limit the query length: -1
- Tokenize the query: true
- Prepend the title: true
- Response path: prediction

Create a custom field for the estimated time and specify the following URL in field mappings: http://127.0.0.1:8080/predict?q=
