# CoughDrop Cordova Misc
Miscellaneous helper functions used by CoughDrop-Cordova. As much as possible, these methods 
are available on both Android and iOS

listFile - List all files in app storage for a specified directory

lux - Register a listener for updates to camera-based ambient light levels

listApps - List registered apps if available (used for legacy feature, can probably be removes)

getAudioDevices - List available audio output options

setAudioMode - Set target of audio output. This can be used to send different voice outputs
to different audio targets, so for example, scanning prompts could be sent to headphones while
sentence and button sounds could be sent to the device's speaker instead.

setSystemVolume - Set the current volume for the device, if possible

bundleId - Current app ID, used for subscription checking

toggleKeyboardAccessoryBar - On iOS, disable the keyboard accessory bar. When using scanning
features, this accessory bar can appear even though the user is not typing a message, just
waiting to hit a single button to trigger a selection event.



## License
MIT License
