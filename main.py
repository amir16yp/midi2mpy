# see
# https://picozero.readthedocs.io/en/latest/gettingstarted.html
# to install the picozero library
from picozero import Speaker
from time import sleep_ms
# connect the red wire into pin 15, the black into GND
# you can also use a passive buzzer in the same way
speaker = Speaker(15)

def play_song(filename):   
    with open(filename) as file:
        lines = file.readlines()
        for line in lines:
            line_split = line.split(' ')
            cmd = line_split[0]
            if cmd == 'BEEP':
                freq = int(float(line_split[1]))
                duration = float(line_split[2]) / 1000
                speaker.play(freq, duration=duration)
            elif cmd == 'SLEEP':
                duration = int(float(line_split[1]))
                sleep_ms(duration)

