# Use an official lightweight Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install Flask
RUN pip install flask

# Copy application code
COPY app.py .

# Expose port 8080 and define entrypoint
EXPOSE 8080
CMD ["python", "app.py"]
