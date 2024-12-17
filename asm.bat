@echo off
64tass %1 --mw65c02 --long-address --output-exec GAME_START --intel-hex -o %~n1.hex --list %~n1.lst
REM 64tass --mw65c02 --long-address --output-exec GAME_START --c256-pgz -o %~n1.pgz --list %~n1.lst
