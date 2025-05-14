FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY index_suspicious.py .

ENV PYTHONUNBUFFERED=1
CMD ["python", "-u", "index_suspicious.py"]