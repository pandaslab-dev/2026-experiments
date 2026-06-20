this is a small esp32 bluetooth midi controller for messing with ethereal rage chords in ableton. not trying to be fancy yet. first goal is just buttons send chords, knob sends rage amount.

## what this is

very early wip arduino project for an esp32 dev board.

- 4 buttons send fixed top chords over ble midi
- 1 panic button tries to shut everything up
- 1 knob sends midi cc #21 for a macro called `RAGE`

## current goal

get a reliable first version working with ableton on mac:

- press button, old chord stops
- new chord plays
- bass root goes on midi channel 1
- chord notes go on midi channel 2
- knob sends cc #21 without jittering too much

## parts list

- esp32 dev board
- 4 momentary buttons for chords
- 1 momentary button for panic
- 1 potentiometer, around 10k is fine
- jumper wires
- breadboard or some messy prototype situation
- usb cable for the esp32

## rough wiring

buttons use internal pullups, so each button goes from gpio to gnd.

| thing | gpio | notes |
| --- | --- | --- |
| chord button 1 | 13 | pressed = LOW |
| chord button 2 | 12 | pressed = LOW |
| chord button 3 | 14 | pressed = LOW |
| chord button 4 | 27 | pressed = LOW |
| panic button | 26 | pressed = LOW |
| rage pot wiper | 34 | analog input |
| rage pot outer leg | 3v3 | |
| rage pot other outer leg | gnd | |

## ableton setup

- pair/connect the `esp32 rage machine` ble midi device on your mac
- in ableton live, enable it as a midi input
- make one midi track for the pad / saw / choir / whatever top synth
- make another midi track for bass or 808
- route or filter midi so channel 1 hits bass and channel 2 hits the chord sound
- map cc `21` to an audio effect rack macro named `RAGE`
- put a limiter at the end of the chain while testing

## what the rage knob does

the knob sends midi cc `21` from `0-127`. the idea is to map that one control to a bunch of chaos at once: saturation, overdrive, wobble, filter brightness, width, reverb send, whatever feels correct.

## future ideas

- mpe version later
- chord inversions or voicing spread
- hold / latch mode
- arpeggiate when rage is high
- more knobs
- leds so it looks a little less mysterious

## warning

keep the volume low when testing. distortion, saturation, clipping, feedback, and stacked synth layers can get loud fast.
