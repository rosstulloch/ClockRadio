ClockRadio
====================

![Alt text](Art/Clock%20Radio%20Small.png)

Features
---------------------

Control is via three [Flic](http://flic.io) buttons.

The time is shown, in large friendly digits. The time separators flash.
Internet audio streams can be played, easily.

The current weather and a weather forecast is shown during the day. In the morning a weather radar is shown.  
At night, just the current temperature is shown.

An alarm turns on the radio.

iTunes album artwork is displayed from the iTunes store for the currently playing track.  
This feature is only available for radio stations which embed metadata into their audio streams.

![Alt text](Art/AlbumSmallCorner.png)

Features missing
---------------------

A preferences window.

How to customise
---------------------

The SketchUp model for my 3D printed Flic button holder is in the Art folder.

All the preferences are currently set in code.
General preferences are in `Preferences.swift`. Radio preferences are in `Stations.json`.

**You will need a [wunderground.com](https://www.wunderground.com/weather/api) developer id to receive weather information.**  
You will need to set this key in `WeatherUndergroundKey.swift`.

Flic button instructions
---------------------

Assume the buttons are arranged in a row in front of the phone, like this: [X X X]  
Buttons are identified by the app by name. The buttons need to be named: "left", "middle" and "right". Case doesn't matter.  
The first time you start the app you need to 'grab' each Flic button. To do this click the hamburger ("&#x11054;") symbol in the top left of the app. Repeat this for each of the three buttons.


Pressing the left button plays the left preset radio station.  
Pressing the right button plays the right preset radio station.

Double pressing the right button cycles over all the other available radio stations.

Pressing the centre button turns on the radio (if not already on, to the last station) and steps over each available sleep time.  
Holding down the centre button turns OFF the radio.

If the radio is turned on using the left or right buttons and a sleep time isn't chosen, the radio with turn off after 90 minutes.  
(This is to preserve battery life since my phone is plugged into a wall timer so it doesn't charge all the time).

License
-------
This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 License.  
[http://creativecommons.org/licenses/by-sa/4.0/](http://creativecommons.org/licenses/by-sa/4.0/)

Acknowledgements  
---------------------

Wunderground.com is used for weather data.  
<img src="https://www.wunderground.com/logos/images/wundergroundLogo_4c_horz.jpg" width="365" height="50">  
    <br />
MorningHasBroken.mp3 by acclivity is used for the alarm when a network isn't available.  
[https://freesound.org/people/acclivity/sounds/21199/#](https://freesound.org/people/acclivity/sounds/21199/#)  
It is licensed under the Attribution Noncommercial License:  
[http://creativecommons.org/licenses/by-nc/3.0/](http://creativecommons.org/licenses/by-nc/3.0/)


