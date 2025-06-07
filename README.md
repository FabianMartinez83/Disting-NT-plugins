# Disting-NT lua Files

Here my first attempt to make a extended version of ADSR <br>
-- This script is designed for a modular synthesizer environment <br>
-- PARAMETERS:<br>
-- Attack 1ms to 30s with 1ms resolution<br>
-- Decay 1ms to 30s with 1ms resolution <br>
-- Sustain 0% to 100% with 1% resolution<br>
-- Release 1ms to 30s with 1ms resolution<br>
-- EoA, EoD, EoS, EoR voltages 0V to 10V with 1V resolution<br>
-- EoA, EoD, EoS, EoR durations 1ms to 5s with 1ms resolution<br>
-- Offset in mV from -10V to +10V with 1mV resolution<br>
-- Semitone adjustment from -120 to +120 with 1 semitone resolution equals to -10V to +10V<br>
-- Inverted Envelope option (Normal/Inv)<br>
-- Loop On/Off with pause and counting<br>
-- Loop Mode (ADSR, AD, AR)<br>
-- Inputs: Gate<br>
-- Outputs: Envelope, EoA, EoD, EoS, EoR, CV mV, Pitch<br>