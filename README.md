# midi2mpy
midi to micropython
## Instructions
1) Install the [picozero](https://picozero.readthedocs.io/en/latest/gettingstarted.html) library.
2) copy main.py and mario.txt
3) connect a passive buzzer or small speaker to pin 15 (or any pwm pin, as long as you change it in the code)
4) Optional: convert your own midi song into the plaintext format: run `bash midi2txt.sh -m=your-midi-file.mid` on a linux based system, make sure the package `midi2abc` is installed. for windows users you can use WSL (google it)
