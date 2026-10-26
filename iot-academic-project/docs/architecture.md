# Architecture Diagram

## Data Flow
1. **ESP32** reads sensors and sends HTTP POST requests to the Symfony 7.4 API.
2. **Symfony API** validates the payload and saves it to **PostgreSQL 18**.
3. **Flutter App** sends HTTP GET requests to the Symfony API to display data.

## Network Diagram
[Insert draw.io or Lucidchart diagram here before submission]
