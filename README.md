# Twinkle Twinkie's Chestoro Firmware
This is the firmware for Mr TwinkleTwinkie's Chestoro SAO.
The bulk of this code is a recycle from my Mad Cat Backpack project with the addition of the animation select button. 
 
License is MIT so do what you want with it just don't litigate me. 

Current firmware runs a loop that waits a random amount of time between 0 and 8 minutes then picks a random animation. 

Current animations:
1. classic fade out fade in (random off delay)
2. blink / wink (random length random eye (left, right, or both) 
3. lip lick rights
4. lip lick left
5. piano teeth (random number of loops) 
6. eye bobble (random number of loops)
7. talking (random number of loops) 
8. sparkles (all random) 

Animations are NOT weighted evenly. Blinking has a higher probability then the others while sparkles has the least. 

The animation button does 2 things 
1.) when held down it aborts any running delays. This let's the micro get out of any long animation loops quickly. (You will see the leds flicker until it is back at the start of the main loop.)
2.) When released it will pick the next animation off a fixed list with fixed nominal delays. 

The main reason for this button is a easy way to flip through all the animations to see them and a way to force some activity when it hits a long idle loop. (basically a show off button)  

Total code space use is ~39% so plenty of space for more animations if wanted. 


## MplabX
This is a mplabX 5.20 project. All programming / debug was done with a PicKit4.
The firmware source is all contained in .\MplabX\TwinkleTwinkie_Chestoro\TwinkleTwinkie_Chestoro.asm 
If you just want to program a backpack using .\MplabX\TwinkleTwinkie_Chestoro\TwinkleTwinkie_Chestoro.X\dist\default\production\TwinkleTwinkie_Chestoro.X.production.hex in microchip IPE is the fastest way. 

## Documentation
There is not much for documentation on this one. 

SAO can be purchased from TwinkleTwinkie here:
https://www.tindie.com/products/twinkletwinkie/twinkletwinkies-chestoro-badge-sao/

You will need a programing adapter to go from the PicKit to the SAO header. 

|PicKit|SAO|Use|
|----|----|----|
|1|6|Mclr|
|2|1|V+|
|3|2|Gnd|
|4|3|ISPDAT|
|5|4|ISPCLK|
|n/c|5|not used|

Note the square pin on the connector is pin 2.... Not my fault.



Copyright (c) 2019 Peter Shabino

Permission is hereby granted, free of charge, to any person obtaining a copy of this hardware, software, and associated documentation files 
(the "Product"), to deal in the Product without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Product, and to permit persons to whom the Product is furnished to do so, subject to the 
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Product.

THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
