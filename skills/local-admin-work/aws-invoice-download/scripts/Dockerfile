FROM amazon/aws-cli:latest AS awscli
FROM python:3.12-slim
COPY --from=awscli /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
WORKDIR /app
COPY download_invoices.py .
ENTRYPOINT ["python", "download_invoices.py"]
