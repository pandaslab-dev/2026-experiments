/*
  esp32 rage machine
  first-pass ble midi chord controller for ableton live

  library note:
  this sketch is written for the "BLE-MIDI" library by lathoub
  together with the "MIDI Library" by FortySevenEffects.

  try installing these in the arduino library manager:
  - BLE-MIDI
  - MIDI Library

  default esp32 include:
    #include <hardware/BLEMIDI_ESP32.h>

  if your esp32 setup works better with nimble, try swapping that line for:
    #include <hardware/BLEMIDI_ESP32_NimBLE.h>

  TODO later:
  - experiment with mpe / per-note expression
  - chord morphing based on the rage knob
*/

#include <Arduino.h>
#include <BLEMIDI_Transport.h>
#include <hardware/BLEMIDI_ESP32.h>
#include <MIDI.h>

BLEMIDI_CREATE_INSTANCE("esp32 rage machine", MIDI)

// ------------------------------
// easy-to-edit config
// ------------------------------
const int BUTTON_1_PIN = 13;
const int BUTTON_2_PIN = 12;
const int BUTTON_3_PIN = 14;
const int BUTTON_4_PIN = 27;
const int PANIC_BUTTON_PIN = 26;
const int RAGE_POT_PIN = 34;

const byte MIDI_CHANNEL_BASS = 1;
const byte MIDI_CHANNEL_CHORD = 2;
const byte MIDI_CHANNEL_CC = 2;

const byte MIDI_CC_RAGE_AMOUNT = 21;
const byte MIDI_VELOCITY_CHORD = 96;
const byte MIDI_VELOCITY_BASS = 108;

const unsigned long DEBOUNCE_MS = 30;
const int RAGE_CC_CHANGE_THRESHOLD = 2;

const byte CHORD_NOTE_COUNT = 4;
const byte NUM_CHORDS = 4;

// ------------------------------
// note map reference
// c4 = 60
// f#1 = 30, d1 = 26, a1 = 33, e1 = 28
// ------------------------------
struct ChordDefinition {
  const char *name;
  byte chordNotes[CHORD_NOTE_COUNT];
  byte bassRoot;
};

ChordDefinition chords[NUM_CHORDS] = {
  {"F#m9-ish", {57, 61, 64, 68}, 30},  // A3 C#4 E4 G#4, bass F#1
  {"Dmaj9-ish", {54, 57, 61, 64}, 26}, // F#3 A3 C#4 E4, bass D1
  {"Amaj9-ish", {61, 64, 68, 71}, 33}, // C#4 E4 G#4 B4, bass A1
  {"Eadd9-ish", {56, 59, 64, 66}, 28}  // G#3 B3 E4 F#4, bass E1
};

const int chordButtonPins[NUM_CHORDS] = {
  BUTTON_1_PIN,
  BUTTON_2_PIN,
  BUTTON_3_PIN,
  BUTTON_4_PIN
};

struct DebouncedButton {
  int pin;
  bool stableState;
  bool lastReading;
  unsigned long lastChangeTime;
};

DebouncedButton chordButtons[NUM_CHORDS];
DebouncedButton panicButton;

int currentChordIndex = -1;
int smoothedPotRaw = 0;
int lastSentRageValue = -1;
bool rageKnobInitialized = false;

void initButton(DebouncedButton &button, int pin);
bool buttonPressed(DebouncedButton &button);
void sendChord(int chordIndex);
void stopCurrentChord();
void panicAllNotesOff();
int readRageKnob();
void sendControlChangeIfChanged();

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println();
  Serial.println("esp32 rage machine booting...");
  Serial.println("starting BLE MIDI device: esp32 rage machine");

  for (int i = 0; i < NUM_CHORDS; i++) {
    initButton(chordButtons[i], chordButtonPins[i]);
  }
  initButton(panicButton, PANIC_BUTTON_PIN);

  pinMode(RAGE_POT_PIN, INPUT);
  analogReadResolution(12);

  MIDI.begin();

  Serial.println("buttons ready");
  Serial.println("turn the rage knob and press a chord button");
}

void loop() {
  MIDI.read();

  for (int i = 0; i < NUM_CHORDS; i++) {
    if (buttonPressed(chordButtons[i])) {
      sendChord(i);
    }
  }

  if (buttonPressed(panicButton)) {
    Serial.println("panic button pressed");
    panicAllNotesOff();
  }

  sendControlChangeIfChanged();
}

void initButton(DebouncedButton &button, int pin) {
  button.pin = pin;
  pinMode(button.pin, INPUT_PULLUP);

  bool initialState = digitalRead(button.pin);
  button.stableState = initialState;
  button.lastReading = initialState;
  button.lastChangeTime = 0;
}

bool buttonPressed(DebouncedButton &button) {
  bool reading = digitalRead(button.pin);

  if (reading != button.lastReading) {
    button.lastChangeTime = millis();
    button.lastReading = reading;
  }

  if ((millis() - button.lastChangeTime) > DEBOUNCE_MS && reading != button.stableState) {
    button.stableState = reading;

    if (button.stableState == LOW) {
      return true;
    }
  }

  return false;
}

void sendChord(int chordIndex) {
  if (chordIndex < 0 || chordIndex >= NUM_CHORDS) {
    return;
  }

  Serial.print("sending chord: ");
  Serial.println(chords[chordIndex].name);

  stopCurrentChord();

  MIDI.sendNoteOn(chords[chordIndex].bassRoot, MIDI_VELOCITY_BASS, MIDI_CHANNEL_BASS);

  for (int i = 0; i < CHORD_NOTE_COUNT; i++) {
    MIDI.sendNoteOn(chords[chordIndex].chordNotes[i], MIDI_VELOCITY_CHORD, MIDI_CHANNEL_CHORD);
  }

  currentChordIndex = chordIndex;
}

void stopCurrentChord() {
  if (currentChordIndex < 0 || currentChordIndex >= NUM_CHORDS) {
    return;
  }

  Serial.print("stopping chord: ");
  Serial.println(chords[currentChordIndex].name);

  MIDI.sendNoteOff(chords[currentChordIndex].bassRoot, 0, MIDI_CHANNEL_BASS);

  for (int i = 0; i < CHORD_NOTE_COUNT; i++) {
    MIDI.sendNoteOff(chords[currentChordIndex].chordNotes[i], 0, MIDI_CHANNEL_CHORD);
  }

  currentChordIndex = -1;
}

void panicAllNotesOff() {
  stopCurrentChord();

  for (int chordIndex = 0; chordIndex < NUM_CHORDS; chordIndex++) {
    MIDI.sendNoteOff(chords[chordIndex].bassRoot, 0, MIDI_CHANNEL_BASS);

    for (int noteIndex = 0; noteIndex < CHORD_NOTE_COUNT; noteIndex++) {
      MIDI.sendNoteOff(chords[chordIndex].chordNotes[noteIndex], 0, MIDI_CHANNEL_CHORD);
    }
  }

  // cc 123 = all notes off
  MIDI.sendControlChange(123, 0, MIDI_CHANNEL_BASS);
  MIDI.sendControlChange(123, 0, MIDI_CHANNEL_CHORD);

  currentChordIndex = -1;

  Serial.println("panic sent: note offs + cc123 on channels 1 and 2");
}

int readRageKnob() {
  int raw = analogRead(RAGE_POT_PIN);

  if (!rageKnobInitialized) {
    smoothedPotRaw = raw;
    rageKnobInitialized = true;
  }

  // simple smoothing to calm down analog jitter
  smoothedPotRaw = ((smoothedPotRaw * 7) + raw) / 8;

  int ccValue = map(smoothedPotRaw, 0, 4095, 0, 127);
  ccValue = constrain(ccValue, 0, 127);

  return ccValue;
}

void sendControlChangeIfChanged() {
  int rageValue = readRageKnob();

  if (lastSentRageValue == -1 || abs(rageValue - lastSentRageValue) >= RAGE_CC_CHANGE_THRESHOLD) {
    MIDI.sendControlChange(MIDI_CC_RAGE_AMOUNT, rageValue, MIDI_CHANNEL_CC);

    Serial.print("rage amount -> ");
    Serial.println(rageValue);

    lastSentRageValue = rageValue;
  }
}
