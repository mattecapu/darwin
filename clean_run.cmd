@echo off
rd /S /Q "data\weights\%1"
rd /S /Q "data\plots\%1"
rd /S /Q "data\behaviours\%1"
del /Q "data\fitness\run%1.m"
