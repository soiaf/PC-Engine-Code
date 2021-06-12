There are 2 sample PC Engine pieces of code here to playback audio samples (in the form of PCM data).
pcmplayback.asm
pcmplaybacktimer.asm

pcmplayback.asm works by reading in a raw (no header) PCM audio data file, where the PCM data has 5-bit 
size. To playback the sound sample at the correct speed, you would need to modify the delay produced by
the ActualDelay code, so for higher sample rate this delay should be less, for lower sample rate it should
be more.
pcmplaybacktimer.asm also works by reading in a raw (no header) PCM audio data file, where the PCM data has 
5-bit size. However it uses the TIMER interrupt to playback the audio at the correct speed. For this reason 
the sample rate for your raw PCM data should be 7 KHz.  

The PC Engine needs PCM data to be in 5-bit form in order to use. How do we get data into this non standard 
format?
There are 2 programs included here that can be used (source code is included)
conv5bit - Thanks to spr299 for this code to convert 8/16 bit PCM data to 5 bit PCM data. This takes a raw
PCM file and converts it to the correct format for use with the PCE playback code. 
pce5bitpcm - This code works slightly differently, this takes an input file of raw PCM data that is only using
5 bits in range and maps it so it can be used with the PC Engine playback code. This approach allows you to 
use an audio editor to make changes to the data with the hope of producting better audio output quality.
As an example of how you would product a file for use with pce5bitpcm 
Get an audio file of your choice. Use an audio editor (in my case I use Cool Edit 2000)
Change the sample rate to be a lower value (for pcmplaybacktimer.asm it will have to be 7000 Hz) - lowering
the sample rate will introduce noise, but has to be done both to reduce the file size of the output and to
ensure that the PC Engine can actually play it back.
Change the bit size (resolution) to 8 bit - again, if your source file is not already 8 bit this will add
noise, but again is required.
In Cool Edit 2000 the above 2 steps are done in Edit->Convert Sample Type
You now need to quieten the sample - this is done by changing the amplitude. If you reduce the amplitude of
a signal by -6dB, you effectively half its loudness - this can be viewed as being the same as removing one bit
of signal range. So if we reduce the amplitude by -18dB, we remove 3 bits. I tend to set the reduction in 
amplitude to be -19dB to handle rounding errors etc. This will make your sound sample not as loud, but will
make it suitable for conversion.
In Cool Edit 2000, this can be done by Transform->Amplitude->Amplify and setting amplification to -19dB
You then save your file as a raw PCM file.
In Cool Edit 2000 this is done by File->Save As and selecting "PCM Raw Data" as the "Save as type".
The output from this can be then used by pce5bitpcm to produce a file that can be played back on the PC
Engine.
Obviously conv5bit is quicker/easier to use, but depending on your requirements, using an audio editor with
pce5bitpcm can give you more flexibilty and potentially better results.