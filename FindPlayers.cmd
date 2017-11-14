@ECHO OFF
START "%~n0" PowerShell -executionpolicy bypass -Sta -File "%~dp0%~n0.ps1"
