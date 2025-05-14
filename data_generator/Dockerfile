FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the generator script
COPY generate_transactions.py .

CMD ["python", "generate_transactions.py"]
