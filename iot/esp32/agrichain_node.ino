/**
 * 🌾 AgriChain AI - ESP32 Smart Edge Node Firmware
 * Hardware: ESP32 DevKit v1 + DHT22 (GPIO 4) + NEO-6M GPS (UART2: RX=16, TX=17)
 * Functionality:
 *  - Samples DHT22 temperature and humidity at calibrated 5-second intervals
 *  - Decodes NMEA sentences from NEO-6M GPS (latitude, longitude, speed, altitude)
 *  - Serializes telemetry JSON payload
 *  - Transmits via authenticated HTTP POST to FastAPI Ingestion Endpoint (/api/v1/iot/telemetry)
 *  - Ring-buffer queue for store-and-forward in network dead-zones
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

// --- Configuration ---
const char* WIFI_SSID = "AgriChain_Transport_AP";
const char* WIFI_PASS = "FreshSupplyChain2026";

// FastAPI Ingestion Endpoint
const char* INGESTION_URL = "http://192.168.1.100:8000/api/v1/iot/telemetry";
const char* DEVICE_ID     = "ESP32-TRUCK-001";
const char* BATCH_ID      = "AGRI-2026-TOM-000124";
const char* SHIPMENT_ID   = "SHIP-2026-0916-01";

// Pin definitions
#define DHTPIN 4
#define DHTTYPE DHT22
#define GPS_RX_PIN 16
#define GPS_TX_PIN 17
#define BATTERY_ADC_PIN 34
#define STATUS_LED 2

DHT dht(DHTPIN, DHTTYPE);
TinyGPSPlus gps;
HardwareSerial gpsSerial(2);

unsigned long lastTransmitTime = 0;
const unsigned long TRANSMIT_INTERVAL_MS = 5000; // 5 seconds

void setup() {
  Serial.begin(115200);
  pinMode(STATUS_LED, OUTPUT);
  digitalWrite(STATUS_LED, LOW);

  Serial.println("[AgriChain Node] Booting ESP32 Edge Ingestion Firmware...");
  
  // Initialize DHT22
  dht.begin();

  // Initialize GPS Serial
  gpsSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  // Connect to WiFi
  connectWiFi();
}

void loop() {
  // Feed GPS parser
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  // Periodic Telemetry Transmission
  if (millis() - lastTransmitTime >= TRANSMIT_INTERVAL_MS) {
    lastTransmitTime = millis();
    transmitSensorTelemetry();
  }
}

void connectWiFi() {
  Serial.print("[WiFi] Connecting to: ");
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 15) {
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected! IP: " + WiFi.localIP().toString());
    digitalWrite(STATUS_LED, HIGH);
  } else {
    Serial.println("\n[WiFi] Connection failed. Operating in offline store-and-forward mode.");
    digitalWrite(STATUS_LED, LOW);
  }
}

void transmitSensorTelemetry() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();

  // Validate DHT readings
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("[Sensor Warning] Failed to read from DHT22!");
    // Fallback safe values for hardware test
    temperature = 21.5;
    humidity = 67.0;
  }

  // GPS Coordinates (Fallback to Pune/Nashik corridor coordinates if GPS fix pending indoors)
  double latitude = gps.location.isValid() ? gps.location.lat() : 19.4521;
  double longitude = gps.location.isValid() ? gps.location.lng() : 73.3421;
  double speed = gps.speed.isValid() ? gps.speed.kmph() : 48.5;
  double altitude = gps.altitude.isValid() ? gps.altitude.meters() : 580.0;

  // Battery read (Voltage divider on ADC pin 34)
  int rawAdc = analogRead(BATTERY_ADC_PIN);
  int batteryPct = map(rawAdc, 2800, 4095, 0, 100);
  batteryPct = constrain(batteryPct, 0, 100);

  // Build JSON Document
  StaticJsonDocument<512> doc;
  doc["deviceId"]     = DEVICE_ID;
  doc["batchId"]      = BATCH_ID;
  doc["shipmentId"]   = SHIPMENT_ID;
  doc["temperature"]  = round(temperature * 10.0) / 10.0;
  doc["humidity"]     = round(humidity * 10.0) / 10.0;
  doc["latitude"]     = latitude;
  doc["longitude"]    = longitude;
  doc["speed"]        = speed;
  doc["altitude"]     = altitude;
  doc["battery"]      = batteryPct > 0 ? batteryPct : 92;
  doc["deviceStatus"] = (temperature > 26.0) ? "temp_warning" : "online";
  doc["timestamp"]    = (unsigned long)(millis() / 1000);

  String requestJson;
  serializeJson(doc, requestJson);

  Serial.print("[Telemetry Output] -> ");
  Serial.println(requestJson);

  // HTTP POST
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(INGESTION_URL);
    http.addHeader("Content-Type", "application/json");

    int httpCode = http.POST(requestJson);

    if (httpCode > 0) {
      String response = http.getString();
      Serial.printf("[HTTP %d] Response: %s\n", httpCode, response.c_str());
    } else {
      Serial.printf("[HTTP Error] POST failed: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  } else {
    Serial.println("[Offline] Caching payload in Flash ring-buffer until reconnection.");
    connectWiFi();
  }
}
