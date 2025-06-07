# Disting-NT lua Files

Here my first attempt to make a extended version of ADSR 
-- This script is designed for a modular synthesizer environment
-- PARAMETERS:
-- Attack 1ms to 30s with 1ms resolution
-- Decay 1ms to 30s with 1ms resolution 
-- Sustain 0% to 100% with 1% resolution
-- Release 1ms to 30s with 1ms resolution
-- EoA, EoD, EoS, EoR voltages 0V to 10V with 1V resolution
-- EoA, EoD, EoS, EoR durations 1ms to 5s with 1ms resolution
-- Offset in mV from -10V to +10V with 1mV resolution
-- Semitone adjustment from -120 to +120 with 1 semitone resolution equals to -10V to +10V
-- Inverted Envelope option (Normal/Inv)
-- Loop On/Off with pause and counting
-- Loop Mode (ADSR, AD, AR)
-- Inputs: Gate
-- Outputs: Envelope, EoA, EoD, EoS, EoR, CV mV, Pitch