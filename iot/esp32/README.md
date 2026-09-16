# 📡 AgriChain AI - ESP32 Hardware Edge Node Guide

## Overview
The AgriChain AI ESP32 smart edge node continuously samples ambient refrigeration and environmental conditions inside cold-chain freight trucks and transmits signed telemetry packets to the AgriChain AI FastAPI Ingestion Endpoint.

## Pinout & Wiring Diagram

```text
       ESP32 NodeMCU                       Sensors / Modules
  ┌───────────────────────┐
  │                   3V3 ├────────────► VCC (DHT22 & NEO-6M GPS)
  │                   GND ├────────────► GND (Common Ground)
  │                GPIO 4 ├────────────► DATA (DHT22 with 10k pullup)
  │        GPIO 16 (RXD2) ├────────────► TX (NEO-6M GPS Module)
  │        GPIO 17 (TXD2) ├────────────► RX (NEO-6M GPS Module)
  │               GPIO 34 ├────────────► Analog Voltage Divider (Battery Monitor)
  │                GPIO 2 ├────────────► Onboard Status LED
  └───────────────────────┘
```

## Required Arduino Libraries
1. `DHT sensor library` by Adafruit (v1.4.6+)
2. `Adafruit Unified Sensor` (v1.1.14+)
3. `TinyGPSPlus` by Mikal Hart (v1.0.3+)
4. `ArduinoJson` by Benoit Blanchon (v6.21.4+)
5. `WiFi` & `HTTPClient` (Standard ESP32 Core)

## Flashing Instructions
1. Open `agrichain_node.ino` in Arduino IDE or PlatformIO.
2. Select Board: **ESP32 Dev Module**.
3. Configure `WIFI_SSID` and `WIFI_PASS` in `agrichain_node.ino`.
4. Set `INGESTION_URL` to your FastAPI server IP (e.g. `http://192.168.1.100:8000/api/v1/iot/telemetry`).
5. Upload firmware and open Serial Monitor at **115200 baud**.
6. The node will obtain GPS fix, verify WiFi connection, and start transmitting live telemetry every 5 seconds.
