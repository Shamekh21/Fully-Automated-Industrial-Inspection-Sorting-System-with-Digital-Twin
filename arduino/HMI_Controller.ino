#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2); // change to 0x3F if LCD stays blank

const int LED_WHITE = 4;
const int LED_BLUE  = 5;
const int LED_RED   = 6;

String inputString  = "";
bool stringComplete = false;

void setup() {
  Serial.begin(9600);
  inputString.reserve(32);

  pinMode(LED_WHITE, OUTPUT);
  pinMode(LED_BLUE,  OUTPUT);
  pinMode(LED_RED,   OUTPUT);

  lcd.init();
  lcd.backlight();

  // Power-on state
  digitalWrite(LED_WHITE, HIGH);
  digitalWrite(LED_BLUE,  LOW);
  digitalWrite(LED_RED,   LOW);

  lcd.setCursor(0, 0);
  lcd.print("System Ready    ");
  lcd.setCursor(0, 1);
  lcd.print("                ");
}

void loop() {
  if (stringComplete) {
    inputString.trim();

    if (inputString == "OK") {
      digitalWrite(LED_BLUE, HIGH);
      digitalWrite(LED_RED,  LOW);
      lcd.setCursor(0, 0);
      lcd.print("OK (No Defect)  ");
      lcd.setCursor(0, 1);
      lcd.print("                ");
    }
    else if (inputString == "DEFECT") {
      digitalWrite(LED_RED,  HIGH);
      digitalWrite(LED_BLUE, LOW);
      lcd.setCursor(0, 0);
      lcd.print("Defective Part  ");
      lcd.setCursor(0, 1);
      lcd.print("                ");
    }
    else if (inputString == "RESET") {
      digitalWrite(LED_BLUE,  LOW);
      digitalWrite(LED_RED,   LOW);
      // white LED stays ON always
      lcd.setCursor(0, 0);
      lcd.print("System Ready    ");
      lcd.setCursor(0, 1);
      lcd.print("                ");
    }
    else if (inputString == "MANUAL") {
      digitalWrite(LED_BLUE, LOW);
      digitalWrite(LED_RED,  LOW);
      lcd.setCursor(0, 0);
      lcd.print("Edit Manual     ");
      lcd.setCursor(0, 1);
      lcd.print("                ");
    }

    inputString    = "";
    stringComplete = false;
  }
}

void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == '\n') {
      stringComplete = true;
    } else {
      inputString += inChar;
    }
  }
}