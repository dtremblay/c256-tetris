# C256 Tetris
Plain Tetris Game for the C256 Foenix (https://c256foenix.com/).

This is a free game for the C256 Foenix.  The game uses very simple assembly code to get things done.
The game demonstrates the use of the SOF and keybaord interrupts, tiles, background images and music.

![Emulated Image](/screenshots/game.png)

The game is functional in the C256 Foenix IDE and the Rev C4 revision of the board.
The game has:
* four states: intro, play, game-over and hiscore username entry
* back-ground music
* special effects for tiles, rotate and lines
* High-Score Board

Still to be added are:
* Read and write high score from/to file.

## How to Play
To play the game, you will need either the actual C256 Foenix hardware or the C256 Foenix IDE (available here: https://github.com/Trinity-11/FoenixIDE).

The game starts in the intro screen.
Press <space> or joystick 1 <fire> button to start the game.

In game mode, you must try to complete full lines.  Once a line is full, it gets removed from the board and space is freed up.
To move the pieces left and right, use the <left-arrow> or <right-arrow> respectively.
If you're using a joystick, move left or right will move the pieces in the same direction.

To rotate the piece, press <space> or the joystick <fire> button.

The game is over once you run out of space at the top of the board.  You must try to avoid filling up the board by combining pieces to make full lines.

## Score
For every piece that drops to the bottom of the board, you get 25 points.

Removing a single line gives you a bonus of 100 points.
Removing two lines at a given time, gives you a bonus of 300 points.
Removing three lines at a given time, gives you a bonus of 600 points.
Removing four lines at a given time, gives you a bonus of 1000 points.

## Levels
The level is raised every 10 pieces.  When the level increases, the speed of the game also increases, so you will get less time to handle each piece.

## High-Scores
If at the end of your play, your score is in the top 10, you will be prompted to enter your name.
Only 6 characters are allowed.  Letters, numbers and spaces are accepted.

Press return when your name has been entered.
If you make an error, use the <backspace> key to delete.

## 




