@ECHO OFF
START "%~n0" PowerShell -executionpolicy bypass -Sta -windowstyle hidden -File "%~dp0%~n0.ps1"