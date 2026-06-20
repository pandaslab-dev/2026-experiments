## notes

- sketch file: `esp32-rage-machine.ino`
- ble midi target library: [lathoub arduino-ble-midi](https://github.com/lathoub/Arduino-BLE-MIDI)
- that library depends on the FortySevenEffects midi library
- if the esp32 build complains about the transport include, try the nimble variant mentioned in the sketch comments

## chord layout

- button 1: f#m9-ish top chord, bass f#
- button 2: dmaj9-ish top chord, bass d
- button 3: amaj9-ish top chord, bass a
- button 4: eadd9-ish top chord, bass e
- button 5: panic / all notes off

## rough todo

- confirm the best ble midi library/include combo in arduino ide on the actual board
- test note-off behavior in ableton and make sure nothing sticks
- maybe add led feedback after the basic version feels solid
- later maybe the rage knob can morph voicing instead of only sending cc
