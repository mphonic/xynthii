# xynthii

A follow-up to the 2006 standalone noise-maker [Xynthi](https://mockfuneral.github.io/2020/12/11/xynthi), originally inspired by the EMS Synthi A, but not an emulation. Xynthii is rebuilt from the ground up and contains some additions and consolidations, upgraded oscillators and filters, and a host of UX improvements and features.

![Screenshot of xynthii](https://github.com/mphonic/xynthii/blob/main/images/xynthii-gui.png)

# Donate
[Venmo](https://account.venmo.com/u/Bhob-Rainey)

[PayPal](https://paypal.me/bhobrainey)

This is a one-person operation. Please enjoy the fruits of open source software and share your own work. Also consider donating to help offset the massive effort and swaths of time eaten up in the creation, testing, and documenting of these wild tools. It really, really helps!

## Installation

This software needs to be run in [Supercollider](https://supercollider.github.io/downloads.html), which is free. You don't need to know anything about Supercollider to use xynthii, but if you know Supercollider, you can use it to incorporate and control xynthii in a vast array of situations.

Xynthii uses three extension packages. If you are a beginner and are running OSX or Windows on a relatively modern machine, you can install these using the "easy" method:

Open Supercollider and, within Supercollider, open `init.scd` from this package. Run the code in `init.scd` (instructions are in the file). This should install extensions in the proper location. Quit and reopen Supercollider, and you should be good to go. You can double-check by opening `test-install.scd` and running the code there.

If you get errors using the above method or you use Linux or are simply a more seasoned Supercollider user, you can install the extensions manually. It is a simple process that just requires downloading some files and moving them to the appropriate folder:

Download [sc3-plugins](https://github.com/supercollider/sc3-plugins/releases), [OversamplingOscillators](https://github.com/spluta/OversamplingOscillators/releases/tag/0.3.3), and [Ported Plugins](https://github.com/madskjeldgaard/portedplugins/releases/tag/v0.4.1). These are all zip files, so make sure to unzip them after download. 

There are instructions in the sc3-plugins README that explain how to install. The process is the same for each extension:

1. Find your Supercollider Extensions folder. To do this, you can open a new document in Supercollider and type `Platform.userExtensionDir.openOS`. With your cursor on the same line as this bit of code, hit shift-Return (Mac) or shift-Enter. Your Extensions folder should open in your OS.
2. Drag the unzipped folders into your Extensions folder. Some extensions may have different folders for different architectures, like one for 32-bit systems vs 64-bit. Choose the one that is appropriate for your system.
3. Close and reopen Supercollider. You should be good to go. You can test by opening `test-install.scd` and running the code.

If you are using OSX and your system is attempting to quarantine the extensions, see the section at the bottom of this document, [Mac Users and Quarantine](#mac-users-and-quarantine). The `init.scd` script attempts to avoid this, and there is a separate file that should unquarantine all of your extensions if you installed them manually, `unquarantine-mac-extensions.scd`.

## Important Supercollider Key Commands

1. Run a single line of code: Put your cursor on the line and hit shift-Enter (Windows / Linux) or shift-Return (Mac).
2. Run a block of code (multiple lines of code between parentheses): Put your cursor anywhere inside the block of code. Without selecting any text, hit ctrl-Enter (cmd-Return on Mac).
3. Stop all running sound: Hit ctrl-. or cmd-. on Mac (that's "control-period" or "command-period").

## Making Sound

In Supercollider, open the `play-xynthii.scd` file. Put your cursor somewhere within this block of code:
```
( // ONLY RUN THIS IF XYNTHII ISN'T ALREADY RUNNING
(Document.current.dir ++ "/xynthii.scd").loadPaths;
~makeXynthii.value({|d| ~xynthii = d });
)
```
Then hit ctrl-Enter (cmd-Return on Mac). In the Post Window (bottom right panel), you should see some text spitting out. At the end of that text, you should see:
```
Creating modules...
Modules created
Starting synths...
Synths started
Loading settings...
Settings loaded.
Ready to go.
```
Xynthii is now running, but you'll probably want an interface. Put your cursor on this line:
```
~xynthii.makeGui();
```
Then hit shift-Enter (shift-Return on Mac). The xynthii interface should open (it may open in a background window, so check your app tray / dock for a grey cube icon). Hit "L" on the interface to load presets.

"S" allows you to save the current state as a preset. "R" records the audio into the `/recordings` folder (remember to hit it again to stop recording). Hitting ctrl-. (cmd-. on Mac) will stop everything and close the interface window. Just repeat the steps above to start again.

The [Donate](#donate) button reminds you to donate. Did I mention that it really, really helps?

## Modules that Sync with Other Modules

Buttons with the "^" symbol allow you to sync a given module with another one. 

With the oscillators, O2 and O3 can be synced with the frequency of O1. The frequency knobs then express intervals from O1 frequency. O2 and O3 will follow modulations of O1's frequency when synced. You can add individual modulation to synced oscillator frequencies by modulating `freqscale` rather than `freq` (`freqscale` will have to be something other than 0 for modulation to occur). See [The Mod Pod](#the-mod-pod) section below.

With the envelopes, E2 and E3 can be gated via E1's gate using the "^" buttons. 

Additionally, the clock module (CL) can be used to gate E1 so that it cycles. Toggling the button "<" between E1 and CL will create / remove this connection.

## MIDI Control and MIDI Learn

The `midi-control.scd` file allows you to use a keyboard to play xynthii and to record quantized values into the sequencer. Running the MIDI block of code will perform the necessary connections and open a small interface for setting filter keytracking, velocity sensitivity, legato, and bend range. It also allows recording keypresses into the xynthii sequencer via the record button and accompanying settings.

Whether you run from the `midi-control.scd` file or not, the majority of knobs in the xynthii interface can be assigned to MIDI cc's via MIDI learn. Just make sure MIDI is connected to Supercollider by running the line `MIDIIn.connectAll`. Shift-click on a knob and then move a MIDI control. A mapping should be created. To remove a mapping, alt-shift-click (option-shift-click on Mac) on the knob you want to clear. When you save a preset, the mappings are saved along with it. When you close the GUI window or change presets, the current mappings are cleared and replaced if applicable.

You can create more permanent mappings using the Supercollider language. That subject is outside the scope of this document.

## Keyboard Shortcuts for Knobs

When a knob is "focused" (which happens when you click on or tab to one), there are keys you can press to do common things:

* r random value
* n set to minimum
* x set to maximum
* c set to center
* ] increment
* [ decrement
* up arrow increment
* down arrow decrement
* right arrow increment
* left arrow decrement

## Setting Values from Text Boxes

You can enter specific values for controls using the text boxes below the accompanying knob. For frequencies, you can also enter note names like C3, A#5, Eb2, etc. Note that this does not apply to O2 and O3 when they are synced with O1, since the frequency value in those cases is an interval from O1 and not an independent frequency.

## The Oscillators

Each oscillator can toggle between two waveforms, saw/tri and pulse (O2 and O3) or sine and saw/tri (O1). O2 and O3 can have their frequencies synced with O1 (see above). They can also be set to a low frequency range via the L/F button. The `pw` knob affects the shape of the waveform in all circumstances, including the sine wave.

The frequency modulation algorithm is a somewhat exotic version of exponential fm. This means that you won't very easily make DX-7 style sounds but that you can quite easily get full-range fm for intense modulations.

## The Envelopes

E1 is the "traditional" Synthi trapezoid envelope shape with variable attack and decay. Depressing the "Gate" button will activate the envelope until "Rel" is pressed to release it. You can also gate this envelope with the CL module as described above in order to make it cycle.

E2 and E3 are customizable envelopes. If set to "Once", gate will behave like it does with E1, with the envelope holding at the second to last node until "Rel" is pressed. If set to "Loop", the envelope will loop between the second and second to last nodes until released. "ADSR" mode will limit the envelope to five nodes and keep the 3rd and 4th nodes at the same level. "Free" allows you to use up to 16 nodes in any configuration. 

Move a node to change its position. To add a node, double click between existing nodes. To remove a node, double click on the node you want to remove. To change the curve of a segment, drag on the line between nodes. Note that the synthesized envelope will only update once the mouse button is released.

You can copy E2 to E3 and vice versa by hitting the respective ">" or "<" button between them.

Using the envelopes in the traditional sense of "putting a sound through an envelope" requires you to route an envelope to `V1 env` and / or `V2 env` (and then route a sound to `V1` and / or `V2`). See [The Routing Matrix](the-routing-matrix) below. These are VCA-type modules, and it is possible to route signals besides envelopes to them for effects like ring modulation. Note that the default preset routes all oscillators and the noise generator to `V1` and routes E1 (the trapezoid) to `V1 env`. This is a fairly standard envelope configuration, which can, of course, be altered and made more complex. 

## The Routing Matrix

The grid on the right of the interface is the routing matrix. This is where you control where signals flow. The rows of the matrix are outputs, and the columns are inputs. To hear a sound, something will have to be routed to the input of at least one of the two output modules, `OU1` and `OU2`.

Any output can be routed to multiple inputs. Feedback, like connecting `O1` to `O1 fm`, is perfectly fine, though if you send, say, the filter output into the filter input (`F` to `F`), you'll likely just get some screeching.

Clicking on a square in the grid toggles the connection between output and input. You can also attenuate an existing connection: alt-click (option-click on Mac) an existing connection and start dragging. A small knob will appear. This lowers the amplitude of the output signal at that connection only. If a connection is attenuated, the knob will stay visible in that square.

## The Mod Pod

While the routing matrix deals with audio rate signals and a fixed set of inputs, the mod pod allows you to modulate just about any paramter at control rate. To modulate a parameter, select that paramter from the top of a set of three dropdown menus. Then, from the bottom of the three menus, choose a modulator. Use the knob to change the intensity of modulation (the knob is bipolar -- centered means no modulation). You can also select an additional modulator from the middle menu. This modulator will modulate the intensity of the bottom modulator, and the intensity of this modulation can be controlled by the knob to the right of the middle menu. An example of using the middle menu might be vibrato that grows as a note is sustained: modulate the frequency and / or amp of an oscillator by a triangle LFO, and modulate the intensity of that LFO by an envelope that ramps up over time.

Some LFO options have names that start with "Trig". These LFOs are triggered whenever E1's gate goes from off to on. They can be used to sync modulation changes to this gate. See the `trigboomchuck` preset for an example.

Speaking of gates, the envelope gates can be modulated using the `gatemod` parameter (`E1 gatemod`, etc.). In this case, whenever an LFO goes from less than or equal to 0 to greater than 0, a gate will be triggered. This will not, however, result in any of the Trig LFOs reacting. See the `diamondixon` preset for an example (wait for it to make a sound -- the gate modulation allows for asymmetrical silences).

## The Sequencer

There is a sixteen step, two-voice sequencer that can be used in a variety of ways. Even though the top steps are labeled "Pitch" and the bottom "Vel", either can be used to modulate anything. They have both audio (`SEQ p` and `SEQ v` in the matrix) and control (`SEQ pk` and `SEQ vk` in the mod pod) rate outputs. The two sets of buttons to the left allow for mapping Pitch and / or Vel to any of the oscillators' frequencies. This mapping produces a different range of frequencies than routing SEQ p or SEQ q to the oscillators' fm and can be used to produce tuned sequences (most easily entered via a MIDI keyboard using `midi-control.scd`). 

The tempo of the sequencer can be modulated in the mod pod. Note that, once a step is reached, the time calculated for that step is fixed until the sequencer moves to the next step. This means that, if you wind up modulating the tempo such that it gets extremely slow on a given step, there is no way to speed up that step by changing the modulation -- you just have to wait. See the `no gallop for old men` preset for an example.

You can, of course, use an external MIDI sequencer instead, or use the Supercollider language to write complex and exotic sequences. This sequencer is good for working within limited parameters and can be especially useful for creating a variety of percussive sounds from a single preset.

## The X/Y Controller

The Synthi A had a joystick that could be routed in the matrix. Here, we have an X/Y controller that can be used as a modulator in the mod pod. A number of the example presets use the XY module, so look for `XY x` and `XY y` in the modulators and experiment with using it (try `feedthee` and `feedthee squared`).

The modulation in the mod pod is "linear", which means in practice that it modulates further "down" than "up". For example, if you set `XY x` to modulate O1 frequency at full strength, center will be no modulation, fully to the right will double the frequency, and fully to the left will bring the frequency to near zero. So, moving to the left has a more drastic effect than moving to the right. Careful setting of parameters and modulation strength will make these types of controls feel more intuitive.

## Bypassing Modules

For modules that make sound (as opposed to modules like envelopes), you can double-click on the module to bypass it. This will silence modules like oscillators, and it will cause a signal to pass unaffected through effects like reverb and delay. Double-click again to unbypass. Individual modulations in the mod pod can also be bypassed in this way.

## Mac Users and Quarantine

It's possible that OSX will complain about the extensions and try to quarantine them. The `init.scd` script attempts to avoid this, and there is an additional file you can run separately called `unquarantine-mac-extensions.scd`. If your extensions are still quarantined after these steps, you can unquarantine them by opening the terminal and running `xattr -c <the_extensions_folders_with_scx_files_in_them>/*.scx`. You'll need to run this for each extension. Use `Platform.userExtensionDir.openOS` as above to find the main extensions folder, then go into each extension folder and find the folder that has files that end in `.scx`. To get the whole `<the_extensions_folder_with_scx_files_in_them>`, select the folder you just found and hit option-command-c. This should copy the path, which you can then paste into the above command; i.e., `xattr -c /Users/me/Library/Application Support/SuperCollider/Extensions/SC3plugins/*.scx`. 

Marcin Paczkowski has written a [script to do this](https://scsynth.org/t/building-supercollider-and-plugins-on-mac-m1/4626/60?u=mphonic), as well.