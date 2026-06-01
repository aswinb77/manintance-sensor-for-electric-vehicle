#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <OneWire.h>
#include <DallasTemperature.h>

#include "model.h"
#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

/* ================= WIFI ================= */
#define WIFI_SSID       "WiFi"
#define WIFI_PASSWORD   "987654321"

/* ================= FIREBASE ================= */
#define API_KEY   "AIzaSyB2vMqTJfGNkq778zlxzmPqVLAffRrzxE8"
#define DATABASE_URL "https://tinyml-project-default-rtdb.asia-southeast1.firebasedatabase.app/"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;


/* ================= PINS ================= */
#define CURRENT_PIN     34
#define VOLTAGE_PIN     35
#define PROX_PIN        27
#define ONE_WIRE_BUS    13

#define MOTOR_IN1       25
#define MOTOR_IN2       26
#define RELAY_PIN       14

#define ADC_MAX 4095.0
#define VREF 3.3

#define ACS_SENSITIVITY 0.100
float ACS_ZERO = 1.65;

#define VOLTAGE_DIVIDER_RATIO 5.0
#define RELAY_THRESHOLD_VOLTAGE 12.0

Adafruit_MPU6050 mpu;
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

/* ================= TinyML ================= */
constexpr int tensorArenaSize = 12 * 1024;
uint8_t tensorArena[tensorArenaSize];

tflite::MicroInterpreter* interpreter;
TfLiteTensor* input;
TfLiteTensor* output;

float mean[5]  = {0.4326696, 59.437582, 11.385936, 3.370626, 0.7636};
float scale[5] = {0.24341072, 17.14594904, 0.71536257, 1.52225675, 0.42487062};

/* ======================================================= */

float readCurrent() {
  long sum = 0;
  for (int i = 0; i < 1000; i++) {
    sum += analogRead(CURRENT_PIN);
    delayMicroseconds(200);
  }
  float voltage = (sum / 1000.0) * VREF / ADC_MAX;
  float current = (voltage - ACS_ZERO) / ACS_SENSITIVITY;
  return (abs(current) < 0.25) ? 0 : current;
}

float readVoltage() {
  long sum = 0;
  for (int i = 0; i < 50; i++) {
    sum += analogRead(VOLTAGE_PIN);
    delayMicroseconds(200);
  }
  return ((sum / 50.0) * VREF / ADC_MAX) * VOLTAGE_DIVIDER_RATIO;
}

float readVibration() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  float magnitude = sqrt(
    a.acceleration.x * a.acceleration.x +
    a.acceleration.y * a.acceleration.y +
    a.acceleration.z * a.acceleration.z
  );

  return abs(magnitude - 9.81);
}

float readTemperature() {
  sensors.requestTemperatures();
  return sensors.getTempCByIndex(0);
}

/* ================= WIFI + FIREBASE CONNECT ================= */
void connectFirebase() {

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }

  Serial.println("\nWiFi Connected");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Same method as working servo project
  Firebase.signUp(&config, &auth, "", "");
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Firebase Initialized");
}


/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(2000);

  pinMode(PROX_PIN, INPUT);
  pinMode(MOTOR_IN1, OUTPUT);
  pinMode(MOTOR_IN2, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);

  digitalWrite(MOTOR_IN1, HIGH);
  digitalWrite(MOTOR_IN2, LOW);
  digitalWrite(RELAY_PIN, LOW);

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  sensors.begin();
  mpu.begin();

  connectFirebase();

  const tflite::Model* model = tflite::GetModel(motor_model);

  static tflite::MicroMutableOpResolver<5> resolver;
  resolver.AddFullyConnected();
  resolver.AddRelu();
  resolver.AddSoftmax();

  static tflite::MicroInterpreter static_interpreter(
    model, resolver, tensorArena, tensorArenaSize
  );

  interpreter = &static_interpreter;

  if (interpreter->AllocateTensors() != kTfLiteOk) {
    Serial.println("Tensor allocation failed!");
    while (1);
  }

  input  = interpreter->input(0);
  output = interpreter->output(0);

  Serial.println("System + TinyML Ready");
}

/* ================= LOOP ================= */
void loop() {

  float vibration   = readVibration();
  float temperature = readTemperature();
  float voltage     = readVoltage();
  float current     = readCurrent();
  int brake_wear    = digitalRead(PROX_PIN);

  bool relayState = false;
  if (voltage > RELAY_THRESHOLD_VOLTAGE) {
    digitalWrite(RELAY_PIN, HIGH);
    relayState = true;
  } else {
    digitalWrite(RELAY_PIN, LOW);
  }

  /* ===== TinyML Input ===== */
  input->data.f[0] = (vibration   - mean[0]) / scale[0];
  input->data.f[1] = (temperature - mean[1]) / scale[1];
  input->data.f[2] = (voltage     - mean[2]) / scale[2];
  input->data.f[3] = (current     - mean[3]) / scale[3];
  input->data.f[4] = (brake_wear  - mean[4]) / scale[4];

  interpreter->Invoke();

  float normal   = output->data.f[0];
  float warning  = output->data.f[1];
  float critical = output->data.f[2];

  String result;

  if (critical > warning && critical > normal)
    result = "CRITICAL";
  else if (warning > normal)
    result = "WARNING";
  else
    result = "NORMAL";

  Serial.println("Uploading to Firebase...");


  /* ================= SERIAL OUTPUT ================= */

  Serial.println("\n========== SENSOR DATA ==========");

  Serial.print("Voltage     : ");
  Serial.print(voltage, 2);
  Serial.println(" V");

  Serial.print("Current     : ");
  Serial.print(current, 2);
  Serial.println(" A");

  Serial.print("Temperature : ");
  Serial.print(temperature, 2);
  Serial.println(" C");

  Serial.print("Vibration   : ");
  Serial.print(vibration, 3);
  Serial.println(" m/s^2");

  Serial.print("Brake Wear  : ");
  Serial.println(brake_wear);

  Serial.print("Relay State : ");
  Serial.println(relayState ? "ON" : "OFF");

  Serial.println("----------------------------------");

  Serial.println("------ TinyML Prediction ------");

  Serial.print("Normal   : ");
  Serial.println(normal, 4);

  Serial.print("Warning  : ");
  Serial.println(warning, 4);

  Serial.print("Critical : ");
  Serial.println(critical, 4);

  Serial.print("RESULT   : ");
  Serial.println(result);

  Serial.println("================================");


  if (Firebase.ready()) {

    Serial.println("Uploading to RTDB...");

    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/voltage", voltage);
    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/current", current);
    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/temperature", temperature);
    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/vibration", vibration);
    Firebase.RTDB.setInt(&fbdo, "/motor_monitor/brake_wear", brake_wear);

    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/normal", normal);
    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/warning", warning);
    Firebase.RTDB.setFloat(&fbdo, "/motor_monitor/critical", critical);
    Firebase.RTDB.setString(&fbdo, "/motor_monitor/result", result);

    Serial.println("Upload Done");

  } else {
    Serial.println("Firebase Not Ready...");
  }



  delay(2000);
}
