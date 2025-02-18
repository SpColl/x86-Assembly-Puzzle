segment .data
		;this file contains a list of all the game boards,
		;and is used to dynamically fill boardList
	gameBoards			db "boards/boards.txt",0
		;these two files make up the two menu screens
	menuBoard			db "menu.txt",0
	levSelBoard			db "menu2.txt",0
		;these are the color codes used for various symbols
		;these colors are also part of colorCodeArray
	playerColor			db	27,"[38;5;173m",0
	helpStrColor		db	27,"[38;5;247m",0
	resetColor			db	27,"[0m",0
	keyColor			db	27,"[38;5;220m",0
	rockColor			db	27,"[38;5;94m",0
	rock2Color			db	27,"[38;5;7m",0
	pressColor			db	27,"[1;48;5;240;38;5;248m",0
	leverColor			db	27,"[38;5;69m",0
	pressDoorColor		db	27,"[38;5;242m",0
	stairsColor			db	27,"[38;5;124m",0
	buttonColor			db	27,"[38;5;14m",0
	activeBColor		db	27,"[38;5;13m",0
	gemColor			db	27,"[38;5;9m",0
	menuOptColor		db	27,"[38;5;240m",0
	iceColor			db	27,"[38;5;38m",0
	iceFloorColor		db  27,"[48;5;38m",0
	colorCodeArray		dd 	wallColor,    keyColor,       rockColor,   pressColor, \
							leverColor,   pressDoorColor, stairsColor, buttonColor, \
							activeBColor, gemColor,       menuOptColor,wallColor2, \
							playerColor,  rock2Color,     iceColor,    iceFloorColor, \
							resetColor
		;used for the board render
	boardFormat			db "%s",0
		;used as the format string for reading from files
	mode_r				db "r",0
		;ANSI escape sequence to clear/refresh the screen
	clear_screen_code	db	27,"[2J",27,"[H",27,"[0m",0
		;the blank space that gets pinted when the hint is not displayed
	hintBlank			db 10,10,10,10,10,0
		;displayed when a level is completed
	win_str				db	27,"[2J",27,"[H", "Level complete!",13,10,0
	waitStr				db	"Press Enter to continue.",13,10,0
		;this is where the coordinates loaded from a board file are stored
	coordString			db	"%d %d",0

segment .bss
		; this array stores the current rendered gameboard (HxW)
	board		resb	432
		;this array is used for changing states of doors
	doorLayer	resb	432
		;same as the door layer, but for floor objects, like water and plates
	floorLayer	resb	432
		;these variables store the current player position
	xpos		resd	1
	ypos		resd	1
		;used for navigating the menu screens
	foundOpt	resd	1
		;used for looking into colorCodeArray
	colorCode	resd	1
		;used for reseting color codes
	resColor	resd	1
		;used for displaying the hint text
	displayHint	resd	1
		;used for exiting to menu
	gameEnd		resd	1
		;used for exiting the game
	menuEnd		resd	1
		;used for resetting the game
	resetVar	resd	1
		;used for when the undo button is pressed
	undoPressed	resd	1
		;used for printing the final string to the screen
	frameBuffer	resb	2000
		;used for various color interactions
	lastColor	resd	1
		;used for the undo function
	inputCount	resd	1
	inputArray	resb	1000
		;This array stores the hint string read in from the board file.
	hintStr		resb	384
		;This array stores the names of all the game boards, and is
		;filled in the loadBoards function
	boardList	resb	2201
		;stores the main menu(s)
	mainMenu	resb	1041
	levelSelect	resb	1041
		;stores the color codes for the wall colors
	wallColor	resb	16
	wallColor2	resb	16
		;used for determining the color of the various game characters
	colorArray	resb	128
		;used for detremining which doors to change the status of
	condArray	resb	12
segment .text
	global	main
	extern	raw_mode_on
	extern 	raw_mode_off
	extern	system
	extern	getchar
	extern	printf
	extern	fopen
	extern	fgetc
	extern	fgets
	extern	fscanf
	extern	fclose
	extern 	sleep
	extern	strlen

main:
	push	ebp
	mov		ebp, esp
		call	colorFill
			; put the terminal in raw mode so the game works nicely
		call	raw_mode_on
			;populate boardList with all the game boards
		call	loadBoards
			;
		push	mainMenu
		push	menuBoard
		call	initMenu
		add		esp, 8
			;
		push	levelSelect
		push	levSelBoard
		call	initMenu
		add		esp, 8
			;
		push	11
		push	14
		push	mainMenu
		call	menuCycle
		add		esp, 12
			; restore old terminal functionality
		call raw_mode_off
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

;associates a color code with each of the possible game board elements
colorFill:
	push	ebp
	mov		ebp, esp
		mov		BYTE [colorArray + 'T'], 0   ;wall character
		mov		BYTE [colorArray + '-'], 4   ;horizontal line in menu
		mov		BYTE [colorArray + '|'], 4   ;vertical line in menu
		mov		BYTE [colorArray + 'R'], 2   ;normal rocks
		mov		BYTE [colorArray + 'I'], 13  ;light rocks
		mov		BYTE [colorArray + 'i'], 13  ;light rock on plate
		mov		BYTE [colorArray + 'P'], 3   ;plate
		mov		BYTE [colorArray + '^'], 9   ;gem door
		mov		BYTE [colorArray + '&'], 9   ;plate door with gem
		mov		BYTE [colorArray + '%'], 7   ;button door
		mov		BYTE [colorArray + '!'], 5   ;plate door
		mov		BYTE [colorArray + '*'], 8   ;grey button door
		mov		BYTE [colorArray + ')'], 10  ;menu option character
		mov		BYTE [colorArray + 'S'], 6   ;stairs
		mov		BYTE [colorArray + 'W'], 4   ;water
		mov		BYTE [colorArray + 'O'], 11  ;wall2 character
		mov		BYTE [colorArray + 'B'], 7   ;active button
		mov		BYTE [colorArray + 'b'], 7   ;inactive button
		mov		BYTE [colorArray + 'G'], 9   ;gem
		mov		BYTE [colorArray + 'g'], 9   ;gem on plate
		mov		BYTE [colorArray + 'K'], 1   ;key
		mov		BYTE [colorArray + 'L'], 4   ;active lever
		mov		BYTE [colorArray + 'l'], 4   ;inactive lever
		mov		BYTE [colorArray + 'h'], 9   ;gem on water
		mov		BYTE [colorArray + ' '], 32  ;empty space
		mov		BYTE [colorArray + 'E'], 14  ;Ice block
		mov		BYTE [colorArray + 'e'], 14  ;Ice floor
	mov		esp, ebp
	pop		ebp
	ret

;takes the game board file locations stored in gameBoards, 
;and stores them indiviudually into boardList
loadBoards:
	push	ebp
	mov		ebp, esp
			;create 1 local variable
		sub		esp, 4
			;open the gameBoards file
		push	mode_r
		push	gameBoards
		call	fopen
		add		esp, 8
			;store file pointer in local variable
		mov		DWORD[ebp - 4], eax
			;initialize the indexer
		mov		esi, 0
		ldBoardsLoop:
		lea		edx, [boardList + esi]
		cmp		eax, 0
		je		endBoardsLoop
				;read the line from file gameBoards into boardList
			push	DWORD [ebp - 4] ;gameBoards
			push	23 				;size
			push	edx 			;boardList
			call	fgets
			add		esp, 12
				;replace the new line with a null byte
			mov		BYTE [boardList + esi + 21], 0
		add		esi, 22
		jmp		ldBoardsLoop
		endBoardsLoop:
			;close the file
		push	DWORD [ebp - 4]
		call	fclose
		add		esp, 4
	mov		esp, ebp
	pop		ebp
	ret

;
initMenu:
	push	ebp
	mov		ebp, esp
		sub		esp, 4
			;open the file
		push	mode_r
		push	DWORD [ebp + 8]
		call	fopen
		add		esp, 8
			;store file pointer in local variable
		mov		DWORD[ebp - 4], eax
			;call readDisplay to populate mainMenu/levelSelect
		push	51 				 ;inc value
		push	52 				 ;fgets buffer
		push	DWORD [ebp + 12] ;array
		push	DWORD [ebp - 4]  ;file handle
		call	readDisplay
		add		esp, 16
			;close the file
		push	DWORD [ebp - 4]
		call	fclose
		add		esp, 4
	mov		esp, ebp
	pop		ebp
	ret

;has four arguments, file handle, array, fgets buffer, increment value
;reads in the game board
readDisplay:
	push	ebp
	mov		ebp, esp
		mov		ebx, DWORD [ebp + 12]
		mov		esi, 0
		topDisplayLoop:
			lea		edx, [ebx + esi] ;load the address of the respective array into edx
			push	DWORD [ebp + 8]  ;file handle
			push	DWORD [ebp + 16] ;fgets buffer
			push	edx 			 ;array
			call	fgets
			add		esp, 12
			cmp		eax, 0
			je		bottomDisplay
				add		esi, DWORD [ebp + 20] ;inc value
				mov		BYTE [ebx + esi], 13 ;replace null with carriage return
		inc		esi
		jmp		topDisplayLoop
		bottomDisplay:
		mov		BYTE [ebx + esi - 2], 10
	mov		esp, ebp
	pop		ebp
	ret

;has two arguments, xpos and ypos
;same as gameCycle, just for the menu
menuCycle:
    push	ebp
	mov		ebp, esp
        push	DWORD [ebp + 12]
		pop		DWORD [xpos]
		push	DWORD [ebp + 16]
		pop		DWORD [ypos]
        menuLoop:
            cmp		DWORD [menuEnd], 1
			je		menuLoop_end
                ;render the menu
            push	DWORD [ebp + 8] ; mainMenu
            push	52				; width of board
            push	1050			; total characters
            call	render
            add		esp, 12
                ;get action from user
            call	getchar
            push	eax
            	; store the current position
			mov		esi, DWORD [xpos]
			mov		edi, DWORD [ypos]
            	;based on input, change the cursor position
			call	checkInput

            mov		ecx, 0
			mov		eax, 52
			mul		DWORD [ypos]
			add		eax, DWORD [xpos]
				; check where to move the player based on input
			push	DWORD [ebp + 8]
			call	checkCharMenu
			add		esp, 8
        jmp		menuLoop    
        menuLoop_end:
        mov		DWORD [menuEnd], 0
        push	clear_screen_code
        call	printf
        add		esp, 4
    mov		esp, ebp
    pop		ebp
    ret

;has two arguments, saved user input, and the cursor location in the board
;determines what to do based on what the user inputed
checkCharMenu:
	push	ebp
	mov		ebp, esp
        mov		ebx, DWORD [ebp + 8]
        cmp		DWORD [ebp + 12], ' '
		jne		checkMove
                ;store cursor position for main menu
            push	DWORD [xpos]
            push	DWORD [ypos]
            cmp		ebx, mainMenu
            jne		notMainMenu
                cmp		DWORD [xpos], 14
                jne		closeMenu
                    	;enter the level select screen
					push	8         ;starting y value
					push	5         ;starting x value
					push	levelSelect
					call 	menuCycle
					add		esp, 12
					jmp		checkComplete
                closeMenu:
                    inc		DWORD [menuEnd]
                    jmp		checkComplete
            notMainMenu:
                cmp		DWORD [ypos], 18
                je		closeMenu
						;using the cursor location, determine both the level offset 
						;and the world offset within boardList					
					sub		DWORD [ypos], 8   ;subtract from ypos the height offset of levSelect,
					                          ;effectively obtaining the level id
					mov		eax, DWORD [xpos]
					sub		eax, 5            ;subtract from xpos the width offset of menu2
					mov		ecx, 4
					div		ecx               ;divide xpos by the offset between worlds,
					                          ;effectively obtaining the world id
						;call gameCycle
					push	DWORD [ypos] ;level id
					push	eax          ;world id
					call	gameCycle
					add		esp, 8
						;reset game state
					mov		DWORD [gameEnd], 0
            checkComplete:
                    ;retrieve the saved xpos and ypos
                pop		DWORD [ypos]
                pop		DWORD [xpos]
                jmp		moveCursor
        checkMove:
				;get cursor offset
			add		ebx, eax
				
			push	DWORD [ebp + 12] ; saved user input
				;If moving up or down, seek through the arry appropriately to find 
				;an acceptable cursor location
			cmp		DWORD [ebp + 12], 'w'
			je		walkBackTop
			cmp		DWORD [ebp + 12], 's'
			jne		notUpDown
			walkBackTop:
					;seek eiither left or right edge, depending on whether up or down was inputed.
				push	'-'
				push	's'
				jmp		checkCursor
			notUpDown:
					;if a or d is pressed, scan in the appropriate direction
				push	'|'
				push	'd'
			checkCursor:
			call	walkFunc
			add		esp, 12
			cmp		DWORD [foundOpt], 1
			je		moveCursor
				mov		DWORD [xpos], esi
				mov		DWORD [ypos], edi
			moveCursor:
	mov		esp, ebp
	pop		ebp
	ret

;three arguments, character to compare to, character to look for, and user input
;walks through the menu board, until it either finds a stop or a viable option to move to
walkFunc:
	push	ebp
	mov		ebp, esp
		sub     esp, 4
        mov     DWORD [ebp - 4], eax
        mov     eax, DWORD [ebp + 12]
        mov     ecx, DWORD [ebp + 8]
        mov     DWORD [foundOpt], 0
		seekOpposite:
        mov     edx, 0
        topWalk:
        cmp     DWORD [foundOpt], 1
        je      secondComplete
        cmp		BYTE [ebx + edx], al
		je		firstComplete
            cmp		BYTE [ebx + edx], ')'
			jne		notOption
				mov     eax, DWORD [ebp - 4]
                add     eax, edx
                mov		ecx, 52
				xor		edx, edx
				div     ecx
                mov     DWORD [ypos], eax
                mov     DWORD [xpos], edx
                inc     DWORD [foundOpt]
                jmp     topWalk
            notOption:
            cmp		ecx, DWORD [ebp + 16]
            jne		mvLeft
                inc		edx
                jmp		topWalk
            mvLeft:
                dec		edx
                jmp		topWalk
        firstComplete:
		mov		eax, '|'
		cmp     ecx, 'd'
		mov		ecx, 'd'
        jne     seekOpposite
        secondComplete:
	mov		esp, ebp
	pop		ebp
	ret

;zeros out the proided array
zeroArray:
	push	ebp
	mov		ebp, esp
		xor		eax, eax
		mov		ecx, DWORD [ebp + 8]
		mov		edi, DWORD [ebp + 12]
		cld
		rep		stosb
	mov		esp, ebp
	pop		ebp
	ret

;has two arguments -- 
;everything that happens while playing the game is in here
gameCycle:
	push	ebp
	mov		ebp, esp
		sub		esp, 4
		resetGame:
		push	DWORD [ebp + 12]
		pop		DWORD [ebp - 4]
			;initialize the game state based on the board file
		push	DWORD [ebp + 12]
		push	DWORD [ebp + 8]
		call	initGame
		add		esp, 8
		
			;clear the input count and array
		mov		DWORD [inputCount], 0
		push	inputArray
		push	1000
		call	zeroArray
		add		esp, 8

		cmp		DWORD [gameEnd], 1
		je		gameLoop_end
		gameLoop:
			mov		DWORD [undoPressed], 0
				; draw the game board
			push	board
			push	24
			push	432
			call	render
			add		esp, 12
				; get an action from the user
			call	getchar
				;check where to move the player based on input	
			push 	DWORD [ebp + 12]
			push	DWORD [ebp + 8]
			call	checkInput
			pop		DWORD [ebp + 8]
			pop		DWORD [ebp + 12]
				;
			cmp		DWORD [gameEnd], 1
			je		gameLoop_end
			cmp		DWORD [resetVar], 1
			je		resetGame
			cmp		DWORD [undoPressed], 1
			je		gameLoop
					;move the input into inputArray & increment inputCount
				mov		ecx, DWORD [inputCount]
				mov		BYTE [inputArray + ecx], al
				inc		DWORD [inputCount]
					;save user input
				mov		ecx, eax
					; Find the new offset, using (W * y) + x = pos
				mov		eax, 24
				mul		DWORD [ypos]
				add		eax, DWORD [xpos]

				push	DWORD [ebp + 12] ;current level id
				call	checkCharGame
				pop		ebx 			 ;current/new level id
					;If the level was completed, proceed to the next one
				cmp		ebx, DWORD [ebp - 4]
				je		notComplete
					push	DWORD [ebp + 8]
					push	DWORD [ebp + 12]
					push	1
					push	9
					push	0
					call	changeLevFunc
					add		esp, 12
					pop		DWORD [ebp + 12]
					pop		DWORD [ebp + 8]
					jmp		resetGame
				notComplete:
		jmp		gameLoop
		gameLoop_end:
	mov		esp, ebp
	pop		ebp
	ret

;
checkInput:
	push	ebp
	mov		ebp, esp
		sub		esp, 4
			; store the current position
			; we will test if the new position is legal
			; if not, we will restore these
		mov		esi, DWORD [xpos]
		mov		edi, DWORD [ypos]
		mov		DWORD [displayHint], 0

		cmp		eax, 'x'
		je		exitGame
		cmp		eax, '-'
		je		changeLevel
		cmp		eax, '='
		je		changeLevel
		cmp		eax, '/'
		je		undo
		cmp		eax, 127
		je		resGame
		cmp		al, 'w'
		je 		moveUp
		cmp		al, 'a'
		je		moveLeft
		cmp		al, 's'
		je		moveDown
		cmp		al, 'd'	
		je		moveRight
		cmp		al, 'h'
		je		showHint
		jmp		inputFound
		exitGame:
			inc		DWORD [gameEnd]
			jmp		inputFound
		changeLevel:
			push	DWORD [ebp + 8]  ; world
			push	DWORD [ebp + 12] ; level
			cmp		eax, '-'
			jne		notSub
				push	-1
				push	0
				push	9
				jmp		changeLev
			notSub:
				push	1
				push	9
				push	0
			changeLev:
			call	changeLevFunc
			add		esp, 12
			pop		DWORD [ebp + 12]
			pop		DWORD [ebp + 8]
			jmp		inputFound
		undo:
			inc		DWORD [undoPressed]
			cmp		DWORD [inputCount], 0
			je		showHint
				mov		DWORD [ebp - 4], 0
				dec		DWORD [inputCount]
				
				push	DWORD [ebp + 12]
				push	DWORD [ebp + 8]
				call	initGame
				add		esp, 8
			
				undoLoop:
				xor		edx, edx
				mov		edx, DWORD [ebp - 4]
				cmp		edx, DWORD [inputCount]
				je		endUndoLoop
					xor		eax, eax
					mov		al, BYTE [inputArray + edx]
					call	checkInput
					mov		ecx, eax

					mov		eax, 24
					mul		DWORD [ypos]
					add		eax, DWORD [xpos]

					call	checkCharGame
				inc		DWORD [ebp - 4]
				jmp		undoLoop
				endUndoLoop:
				jmp		inputFound
		resGame:
			mov		DWORD [resetVar], 1
			jmp		inputFound
		moveUp:
			dec		DWORD [ypos]
			jmp		inputFound
		moveLeft:
			dec		DWORD [xpos]
			jmp		inputFound
		moveDown:
			inc		DWORD [ypos]
			jmp		inputFound
		moveRight:
			inc		DWORD [xpos]
			jmp		inputFound
		showHint:
			mov		DWORD [displayHint], 1	
		inputFound:
	mov		esp, ebp
	pop		ebp
	ret

;
changeLevFunc:
	push	ebp
	mov		ebp, esp
		inc		DWORD [resetVar]
			;increase or decrease level ID
		mov		eax, DWORD [ebp + 16]
		add     DWORD [ebp + 20], eax
			;if level ID is below zero or above nine, change world
		cmp		DWORD [ebp + 20], 0
		jl		changeWorld
		cmp		DWORD [ebp + 20], 9
		jle		endChangeLev
		changeWorld:
			mov		eax, DWORD [ebp + 16]
			add		DWORD [ebp + 24], eax
			mov		eax, DWORD [ebp + 8]
			mov		DWORD [ebp + 20], eax
		endChangeLev:
	mov		esp, ebp
	pop		ebp
	ret

;handles what should happen once input is received
checkCharGame:
	push	ebp
	mov		ebp, esp
		cmp		BYTE [floorLayer + eax], 'W'
		je		pDefault
		cmp		BYTE [board + eax], ' '
		je		canMove
		cmp		BYTE [board + eax], 'R'
		je		pRock
		cmp		BYTE [board + eax], 'I'
		je		pRock
		cmp		BYTE [board + eax], 'E'
		je		pRock
		cmp		BYTE [board + eax], 'S'
		je		pStairs
		cmp		BYTE [board + eax], 'B'
		je		pButton
		cmp		BYTE [board + eax], 'b'
		je		pButton
		cmp		BYTE [board + eax], 'G'
		je		pGem
		jmp		pDefault
		pRock:
			push	eax ; push player offset
			push	ecx
			lea		ebx, [board + eax]
			lea		eax, [floorLayer + eax]
			call	pushObj
			pop		ecx
			pop		eax
			jmp		canMove
		pStairs:
				; clear the screen and print winstr
			push	win_str
			call	printf
			add		esp, 4
				;hold that on the screen
			push	2
			call	sleep
			add		esp, 4
				;print the waitstr
			push	waitStr
			call	printf
			add		esp, 4
				;loop until enter is pressed
			garbageLoop:
			call	getchar
			cmp		eax, 13
			jne		garbageLoop
				;inc the board counter
			inc		DWORD [ebp + 8]
			jmp		canMove
		pButton:
			cmp		BYTE [board + eax], 'B'
			jne		bActive
				mov		BYTE [board + eax], 'b'
				jmp		pDefault
			bActive:
				mov		BYTE [board + eax], 'B'
				jmp		pDefault
		pGem:
			mov		BYTE [board + eax], ' '
			jmp		canMove
		pDefault:
			mov		DWORD [xpos], esi
			mov		DWORD [ypos], edi
			jmp		canMove
		canMove:
		cmp		DWORD [xpos], esi
		jne		checkIce
		cmp		DWORD [ypos], edi
		je		checkDone
		checkIce:
			cmp		BYTE [floorLayer + eax], 'e'
			jne		checkDone
				lea		edx, [floorLayer + eax]
				lea		ebx, [board + eax]
				
				push	DWORD [ypos]
				push	DWORD [xpos]
				push	eax ;current offset in board
				push	ecx ;saved user input
				push	edx ;current floor address
				push	ebx ;current board address
				call	iceMove
				add		esp, 16
				pop		DWORD [xpos]
				pop		DWORD [ypos]
		checkDone:
		push	floorLayer	
		push	board
		call 	doorChange
		add		esp, 8
	mov		esp, ebp
	pop		ebp
	ret
	
;handles the interactions between the player and movable objects
;ebx holds the current address of boardLayer, and eax holds the current address of floorLayer
;edx holds the next address of floorLayer, and ecx holds the next address of boardLayer
pushObj:
	push	ebp
	mov		ebp, esp
		sub		esp, 4
		mov		ecx, DWORD [ebp + 8]
		mov		DWORD [ebp - 4], ecx
			;Check which direction the rock is moving
		cmp		DWORD [ebp - 4], 'w'
		je		nextDir1
		cmp		DWORD [ebp - 4], 'a'
		je		nextDir2
		cmp		DWORD [ebp - 4], 's'
		je		nextDir3
		cmp		DWORD [ebp - 4], 'd'
		je		nextDir4
		jmp		pushEnd
			;Load the address of the next space in the array 
			;according to the direction the rock is moivng
		nextDir1:
			lea		ecx, [ebx - 24]
			lea		edx, [eax - 24]
			jmp		moveObj
		nextDir2:
			lea		ecx, [ebx - 1]
			lea		edx, [eax - 1]
			jmp		moveObj
		nextDir3:
			lea		ecx, [ebx + 24]
			lea		edx, [eax + 24]
			jmp		moveObj
		nextDir4:
			lea		ecx, [ebx + 1]
			lea		edx, [eax + 1]
		moveObj:
			;Check if the character the rock was pushed into is a valid move
			;if not, reset the position of the player
		cmp		BYTE [ecx], ' '
		jne		objStop
		objMove:
			cmp		BYTE [edx], 'W'
			jne		notOnWater
				mov		cl, BYTE [ebx]
				mov		BYTE [ebx], ' '
				mov		BYTE [edx], cl
				jmp		pushEnd
			notOnWater:
			mov		al, BYTE [ebx]
			mov		BYTE [ebx], ' '
			mov		BYTE [ecx], al
			
			cmp		BYTE [edx], 'e'
			je		isIce
			cmp		BYTE [ecx], 'E'
			jne		notIce
			isIce:
				push	DWORD [ypos]
				push	DWORD [xpos]
				push	DWORD [ebp + 12]
				push	DWORD [ebp - 4]
				push	edx
				push	ecx
				call	iceMove
				add		esp, 24
			notIce:
			jmp		pushEnd
		objStop:	
		
		cmp		BYTE [ebx], 'I'
		jne		pathBlocked
			cmp		BYTE [ecx], 'I'
			jne		pathBlocked
				push	ebx
				push	ecx
				
				mov		ebx, ecx
				mov		eax, edx
				push	DWORD [ebp + 12]
				push	DWORD [ebp - 4]
				call	pushObj
				add		esp, 8
				
				pop		ecx
				pop		ebx
				cmp		BYTE [ecx], ' '
				je		notOnWater
		pathBlocked:
		mov		DWORD [xpos], esi
		mov		DWORD [ypos], edi
		pushEnd:
	mov		esp, ebp
	pop		ebp
	ret

;handles ice physics
;ebp + 16 has the saved user input (used for determining directionyyyy)
;ebp + 12 has the 'current' board position, and ebp + 8 has the 'current' floor position
iceMove:
	push	ebp
	mov		ebp, esp
		push	DWORD [ebp + 24]      ;save current xpos
		push	DWORD [ebp + 28]      ;save current ypos
		mov		ebx, DWORD [ebp + 8]  ;set ebx = current board address
		mov		edx, DWORD [ebp + 12] ;set edx  current floor address

		mov		eax, DWORD [ebp + 8]
		sub		eax, DWORD [ebp + 20]

		cmp		DWORD [ebp + 16], 'w'
		je 		iceMoveUp
		cmp		DWORD [ebp + 16], 'a'
		je		iceMoveLeft
		cmp		DWORD [ebp + 16], 's'
		je		iceMoveDown
		cmp		DWORD [ebp + 16], 'd'	
		je		iceMoveRight
		iceMoveUp:
			cmp		eax, board
			jne		notPlayerUp
				dec		DWORD [ebp + 28]
			notPlayerUp:
			mov		ecx, -24
			jmp		iceChangeFound
		iceMoveLeft:
			cmp		eax, board
			jne		notPlayerLeft
				dec		DWORD [ebp + 24]
			notPlayerLeft:
			mov		ecx, -1
			jmp		iceChangeFound
		iceMoveDown:
			cmp		eax, board
			jne		notPlayerDown
				inc		DWORD [ebp + 28]
			notPlayerDown:
			mov		ecx, 24
			jmp		iceChangeFound
		iceMoveRight:
			cmp		eax, board
			jne		notPlayerRight
				inc		DWORD [ebp + 24]
			notPlayerRight:
			mov		ecx, 1
		iceChangeFound:
		add		DWORD [ebp + 20], ecx
		lea		ebx, [ebx + ecx]
		lea		edx, [edx + ecx]
		neg		ecx

		cmp 	BYTE [ebx], ' '
		jne		noIceMove
			cmp		BYTE [edx], 'W'
			je		noIceMove
				cmp		BYTE [ebx + ecx], 'E'
				je		nextIceCheck
				cmp		BYTE [edx + ecx], 'e'
				jne		yesIceMove
				nextIceCheck:
					cmp		BYTE [ebx + ecx], ' '
					je		movePlayer
						push	eax
						mov		al, BYTE [ebx + ecx]
						mov		BYTE [ebx + ecx], ' '
						mov		BYTE [ebx], al
						pop		eax
					movePlayer:
					push	DWORD [ebp + 28]
					push	DWORD [ebp + 24]
					push	DWORD [ebp + 20]
					push	DWORD [ebp + 16]
					push	edx
					push	ebx
					call	iceMove
					add		esp, 16
					pop		DWORD [ebp + 24]
					pop		DWORD [ebp + 28]
					jmp		yesIceMove
		noIceMove:
			pop		DWORD [ebp + 28]
			pop		DWORD [ebp + 24]

			cmp		eax, board
			je		yesIceMove
				cmp		BYTE [edx], 'W'
				jne		noIceWater
					cmp		BYTE [ebx + ecx], 'E'
					je		yesIceMove
					mov		al, BYTE [ebx+ ecx]
					mov		BYTE [ebx + ecx], ' '
					mov		BYTE [edx], al
					jmp		yesIceMove
				noIceWater:
				cmp		BYTE [ebx + ecx], 'E'
				je		switchLev
				cmp		BYTE [edx + ecx], 'e'
				jne		yesIceMove
				switchLev:
					cmp		BYTE [ebx], 'L'
					je		activeLev
					cmp		BYTE [ebx], 'l'
					je		inactiveLev
					jmp		yesIceMove
					inactiveLev:
						mov		BYTE [ebx], 'L'
						jmp		yesIceMove
					activeLev:
						mov		BYTE [ebx], 'l'
						jmp		yesIceMove
		yesIceMove:
	mov		esp, ebp
	pop		ebp
	ret

initGame:
	push	ebp
	mov		ebp, esp

		mov		eax, 220
		mul		DWORD [ebp + 8]
		mov		ebx, eax
		mov		eax, 22
		mul		DWORD [ebp + 12]
		add		eax, ebx
			;if the previous board was the last one, close the game
		cmp		BYTE [boardList + eax], 0
		jne		validBoard
			inc		DWORD[gameEnd]
			jmp		endInit
		validBoard:
			;display the initial board, or update it to the next one
		lea		ecx, [boardList + eax]
		push	ecx
		call	init_gameBoard
		add		esp, 4
			;iniitalize game variables
		mov		DWORD [displayHint], 1
		mov		DWORD [gameEnd], 0
		mov		DWORD [resetVar], 0
			;initialize door status
		push	floorLayer
		push	board
		call 	doorChange
		add		esp, 8
		endInit:
	mov		esp, ebp
	pop		ebp
	ret

doorChange:
	push	ebp
	mov		ebp, esp
		sub		esp, 4
		mov		ecx, DWORD [ebp + 12]
		mov		edx, DWORD [ebp + 8]
		mov		DWORD [ebp - 4], 0
		mov		eax, 0
		checkLoop:
		cmp		eax, 432
		je		checkLoop_End
			;change the values in condArray to a 1 if the door must close
			;b,G,l,P -> indeces 0,1,2,3
			cmp		BYTE [edx + eax], 'b'
			je		checkButton
			cmp		BYTE [edx + eax], 'G'
			je		checkGem
			cmp		BYTE [edx + eax], 'l'
			je		checkLever
			cmp		BYTE [ecx + eax], 'P'
			je		checkPlate
			jmp		nextCondCheck
			checkButton:
				mov		BYTE [condArray + 0], 1
				jmp		nextCondCheck
			checkGem:
				mov		BYTE [condArray + 1], 1
				jmp		nextCondCheck
			checkLever:
				mov		BYTE [condArray + 2], 1
				jmp		nextCondCheck
			checkPlate:
				cmp		BYTE [edx + eax], ' '
				jne		nextCondCheck
					mov		BYTE [condArray + 3], 1
			nextCondCheck:
		inc		eax
		jmp		checkLoop
		checkLoop_End:

		mov		eax, 0
		changeLoop:
		cmp		eax, 432
		je		changeLoop_End
			cmp		BYTE [doorLayer + eax], 0
			je		nextChangeCheck
				cmp		BYTE [doorLayer + eax], ' '
				je		closedDoor
					cmp		BYTE [board + eax], ' '
					jne		nextChangeCheck
						cmp		BYTE [doorLayer + eax], '%'
						je		isOpenBDoor
						cmp		BYTE [doorLayer + eax], '*'
						je		isOpenGBDoor
						cmp		BYTE [doorLayer + eax], '^'
						je		isOpenGDoor
						cmp		BYTE [doorLayer + eax], '!'
						je		isOpenPDoor
						jmp		nextChangeCheck
						isOpenBDoor:
							cmp		BYTE [condArray + 0], 1
							jne		nextChangeCheck
								call	layerSwap
								jmp		nextChangeCheck
						isOpenGBDoor:
							cmp		BYTE [condArray + 0], 0
							jne		nextChangeCheck
								call	layerSwap
								jmp		nextChangeCheck
						isOpenGDoor:
							cmp		BYTE [condArray + 1], 1
							jne		nextChangeCheck
								call	layerSwap
								jmp		nextChangeCheck
						isOpenPDoor:
							cmp		BYTE [condArray + 3], 1
							jne		nextChangeCheck
								call	layerSwap
								jmp		nextChangeCheck
				closedDoor:
					cmp		BYTE [board + eax], '%'
					je		isClosedBDoor
					cmp		BYTE [board + eax], '*'
					je		isClosedGBDoor
					cmp		BYTE [board + eax], '^'
					je		isClosedGDoor
					cmp		BYTE [board + eax], '!'
					je		isClosedPDoor
					isClosedBDoor:
						cmp		BYTE [condArray + 0], 0
						jne		nextChangeCheck
							call	layerSwap
							jmp		nextChangeCheck
					isClosedGBDoor:
						cmp		BYTE [condArray + 0], 1
						jne		nextChangeCheck
							call	layerSwap
							jmp		nextChangeCheck
					isClosedGDoor:
						cmp		BYTE [condArray + 1], 0
						jne		nextChangeCheck
							call	layerSwap
							jmp		nextChangeCheck
					isClosedPDoor:
						cmp		BYTE [condArray + 3], 0
						jne		nextChangeCheck
							call	layerSwap
			nextChangeCheck:
		inc		eax
		jmp		changeLoop
		changeLoop_End:
		push	condArray
		push	12
		call	zeroArray
		add		esp, 8
	mov		esp, ebp
	pop		ebp
	ret

;read in the data from the respective level file
init_gameBoard:
	push	ebp
	mov		ebp, esp
			; FILE* and loop counter
			; ebp-4, ebp-8
		sub		esp, 8
			; clear doorLayer and floorLayer
		push	doorLayer
		push	432
		call	zeroArray
		add		esp, 8
		
		push	floorLayer
		push	432
		call	zeroArray
		add		esp, 8
			; open the file
		push	mode_r
		push	DWORD[ebp + 8]
		call	fopen
		add		esp, 8
		mov		DWORD [ebp - 4], eax
			;read wallcolor 1
		push	wallColor
		push	DWORD [ebp - 4]
		call	readWallCol
		add		esp, 8
			;read wallcolor 2
		push	wallColor2
		push	DWORD [ebp - 4]
		call	readWallCol
		add		esp, 8
			;load the player's starting position
		push	ypos
		push	xpos
		push	coordString
		push	DWORD [ebp - 4]
		call	fscanf
		add		esp, 16
			;eat the new line
		push	DWORD [ebp - 4]
		call	fgetc
		add		esp, 4

		mov		ebx, 0
		insertColor:
		cmp		BYTE [helpStrColor + ebx], 0
		je		colorInserted
			mov		cl, BYTE [helpStrColor + ebx]
			mov		BYTE [hintStr + ebx], cl
		inc		ebx
		jmp		insertColor
		colorInserted:
			;load in the hint string
		mov		esi, 0
		mov		BYTE [hintStr + ebx], 10
		inc		ebx
		topInitLoop:
		cmp		esi, 3
		je		endInitLoop
			lea		eax, [hintStr + ebx]
			push	DWORD [ebp - 4]
			push	128
			push	eax
			call	fgets
			add		esp, 12
				;get the next offset and put it in ebx
			push	eax
			call	strlen
			add		esp, 4
			add		ebx, eax
				;add a carriage return
			mov		BYTE [hintStr + ebx], 13
			inc		ebx
		inc		esi
		jmp		topInitLoop
		endInitLoop:
		mov		BYTE [hintStr + ebx], 10
		mov		BYTE [hintStr + ebx + 1], 0
			; read the file data into the global buffer
			; line-by-line so we can ignore the newline characters
		lea		eax, [board]
		push	23
		push	24
		push	eax
		push	DWORD [ebp - 4]
		call	readDisplay
		add		esp, 16
			;populate the door and floor layer
		mov		edx, 24*18
		mov		edi, 0
		objLoop:
		cmp		edi, edx
		je		endObjCheck
			cmp		BYTE [board + edi], 'g'
			je		yesGemPlate
			cmp		BYTE [board + edi], 'h'
			je		yesGemWater
			cmp		BYTE [board + edi], 'i'
			je		yesLightPlate
			cmp		BYTE [board + edi], 'P'
			je		yesPlate
			cmp		BYTE [board + edi], 'W'
			je		yesWater
			cmp		BYTE [board + edi], '!'
			je		yesDoor
			cmp		BYTE [board + edi], '_'
			je		yesDoor
			cmp		BYTE [board + edi], '%'
			je		yesDoor
			cmp		BYTE [board + edi], '*'
			je		yesDoor
			cmp		BYTE [board + edi], '^'
			je		yesDoor
			cmp		BYTE [board + edi], '&'
			je		yesGPDoor
			cmp		BYTE [board + edi], 'e'
			je		yesFloorIce
			mov		BYTE [doorLayer + edi], 0
			mov		BYTE [floorLayer + edi], 0
			jmp		noObj
			yesGemWater:
				mov		BYTE [board + edi], 'G'
				mov		BYTe [floorLayer + edi], 'R'
				jmp		noObj
			yesGemPlate:
				mov		BYTE [board + edi], 'G'
				mov		BYTE [floorLayer + edi], 'P'
				jmp		noObj
			yesLightPlate:
				mov		BYTE [board + edi], 'I'
				mov		BYTE [floorLayer + edi], 'P'
				jmp		noObj
			yesPlate:
				mov		BYTE [board + edi], ' '
				mov		BYTE [floorLayer + edi], 'P'
				jmp		noObj
			yesWater:
				mov		BYTE [board + edi], ' '
				mov		BYTE [floorLayer + edi], 'W'
				jmp		noObj
			yesDoor:
				mov		BYTE [doorLayer + edi], ' '
				mov		BYTE [floorLayer + edi], 0
				jmp		noObj
			yesGPDoor:
				mov		BYTE [doorLayer + edi], ' '
				mov		BYTE [floorLayer + edi], 'P'
				jmp		noObj
			yesFloorIce:
				mov		BYTE [board + edi], ' '
				mov		BYTE [floorLayer + edi], 'e'
			noObj:
		inc		edi
		jmp		objLoop
		endObjCheck:
			; close the open file handle
		push	DWORD [ebp - 4]
		call	fclose
		add		esp, 4
	mov		esp, ebp
	pop		ebp
	ret

;has the arguments of height, width, character array
;[ebp + 8], [ebp + 12], [ebp + 16]
render:
	push	ebp
	mov		ebp, esp
		sub		esp, 4
			; clear the screen
		push	clear_screen_code
		call	printf
		add		esp, 4
			;if rendering game board, display hint text
		mov		ebx, DWORD [ebp + 16]
		cmp		ebx, board
		jne		renMenu
			cmp		DWORD [displayHint], 0
			je		noHint
				push	hintStr
				jmp		printHint
			noHint:
				push	hintBlank
			printHint:
			call	printf
			add		esp, 4
		renMenu:
		mov		DWORD [lastColor], 100
			;initialize frame buffer index
		mov		ecx, 0
		
		mov		DWORD [ebp - 4], 0
		renLoop_start:
		mov		eax, DWORD [ebp + 8]
		cmp		DWORD [ebp - 4], eax
		je		renLoop_end
					; check if (xpos,ypos)=(x,y)
				mov		edi, DWORD [ebp - 4]
				
				mov		eax, DWORD [ypos]
				mul		DWORD [ebp + 12]
				add		eax, DWORD [xpos]
				
				cmp		eax, DWORD [ebp - 4]
				jne		print_board
					cmp		ebx, levelSelect
					je		menuPrint
					cmp		ebx, mainMenu
					jne		printPlayer
					menuPrint:
						mov		DWORD [colorCode], 10
						mov		dl, '>'
						jmp		playerFound
					printPlayer:
						call	rColor
						mov		DWORD [colorCode], 12
						mov		dl, 'O'
					playerFound:
						;add the respective color code to the frame buffer
					call	colorFunc
					mov		BYTE [frameBuffer + ecx], dl
					inc		ecx
					jmp		print_end
				print_board:
				mov		dl, BYTE [ebx + edi]

				cmp		ebx, levelSelect
				je		isMenuRender
				cmp		ebx, mainMenu
				jne		isGameRender
				isMenuRender:
					call	mcharRender
					jmp		print_end
				isGameRender:
					call	charRender
					jmp		print_end
				print_end:
					;if a menu opt was printed, skip past the selection text
				cmp		BYTE [ebx + edi], ')'
				jne		notOpt
					call	skipLoop
				notOpt:
		inc		DWORD [ebp - 4]
		jmp		renLoop_start
		renLoop_end:
		mov		BYTE [frameBuffer + ecx], 0
		push	frameBuffer
		push	boardFormat
		call	printf
		add		esp, 8
	mov		esp, ebp
	pop		ebp
	ret

;skips over the text following a menu option
skipLoop:
	push	ebp
	mov		ebp, esp
		push	ebx
		add		ebx, edi
		mov		esi, 0
		skipLoopTop:
		cmp		BYTE [ebx + esi + 1], ' '
		je		skipLoopEnd
			mov		dl, BYTE [ebx + esi + 1]
			mov		BYTE [frameBuffer + ecx], dl
			inc		ecx
			inc		DWORD [ebp + 8]
		inc		esi
		jmp		skipLoopTop
		skipLoopEnd:
		pop		ebx
	mov		esp, ebp
	pop		ebp
	ret

mcharRender:
	push	ebp
	mov		ebp, esp
		call	colorSearch
		cmp		BYTE [ebx + edi], ' '
		je		mAddChar
		cmp		BYTE [ebx + edi], '-'
		je		foundBorder
		cmp		BYTE [ebx + edi], '|'
		je		foundBorder
		cmp		BYTE [ebx + edi], ')'
		je		menuOpt
		cmp		BYTE [ebx + edi], 31
		jle		mAddChar
		jmp		notBorder
		menuOpt:
			mov		dl, ' '
			jmp		foundBorder
		notBorder:
			mov		DWORD [colorCode], 7
		foundBorder:
		call	colorFunc
		mAddChar:
			;load the displayed character into the frame buffer
		mov		BYTE [frameBuffer + ecx], dl
		inc		ecx
	mov		esp, ebp
	pop		ebp
	ret

charRender:
	push	ebp
	mov		ebp, esp
			;compare the current byte to the various game objects, then
			;change the symbol and color accordingly
		cmp		BYTE [floorLayer + edi], 0
		je		notFloor
			cmp		BYTE [floorLayer + edi], 'W'
			je		rFWater
			cmp		BYTE [floorLayer + edi], 'R'
			je		rFWater
			cmp		BYTE [floorLayer + edi], 'I'
			je		rFWater
			cmp		BYTE [floorLayer + edi], 'P'
			je		rFPlate
			cmp		BYTE [floorLayer + edi], 'e'
			je		rFIce
			jmp		notFloor
			rFWater:
				cmp		BYTE [floorLayer + edi], 'W'
				jne		floorRock
					mov		dl, 'W'
					jmp		notFloor
				floorRock:
					cmp		BYTE [ebx + edi], ' '
					jne		gemWater
						mov		DWORD [colorCode], 7
						mov		dl, 'R'
						jmp		noSearch
					gemWater:
					jmp		notFloor
			rFPlate:
				mov		DWORD [colorCode], 3
				mov		DWORD [resColor], 1
				mov		dl, 'P'
				call	colorFunc
				cmp		BYTE [ebx + edi], ' '
				je		notFloor
					mov		dl, BYTE [ebx + edi]
					jmp		notFloor
			rFIce:
				mov		DWORD [colorCode], 15
				mov		DWORD [resColor], 1
				mov		dl, ' '
				cmp		BYTE [ebx + edi], ' '
				je		notFloor
					mov		dl, BYTE [ebx + edi]
		notFloor:
		call	colorSearch
		noSearch:
		cmp		BYTE [ebx + edi], 'T'
		je		rWall
		cmp		BYTE [ebx + edi], 'O'
		je		rWall
		cmp		BYTE [ebx + edi], ' '
		je		rSpace
		cmp		BYTE [ebx + edi], '-'
		je		rSpace
		cmp		BYTE [ebx + edi], '|'
		je		rSpace
		cmp		BYTE [ebx + edi], 'R'	
		je		rRock
		cmp		BYTE [ebx + edi], 'I'
		je		rRock
		cmp		BYTE [ebx + edi], 'E'
		je		rIce
		cmp		BYTE [ebx + edi], 'G'
		je		rGem
		cmp		BYTE [ebx + edi], '_'
		je		rDoor
		cmp		BYTE [ebx + edi], '!'
		je		rDoor
		cmp		BYTE [ebx + edi], '%'
		je		rDoor
		cmp		BYTE [ebx + edi], '*'
		je		rDoor
		cmp		BYTE [ebx + edi], '^'
		je		rDoor
		cmp		BYTE [ebx + edi], '&'
		je		rDoor
		cmp		BYTE [ebx + edi], 31
		jle		addChar
		jmp		rDefault
		rWall:
			mov		DWORD [resColor], 1
			mov		dl, ' '
			jmp		rDefault
		rSpace:
			cmp		BYTE [floorLayer + edi], 0
			jne		rDefault
			mov		dl, ' '
			jmp		addChar
		rRock:
			mov		dl, 'R'
			jmp		rDefault
		rGem:
			mov		DWORD [colorCode], 9
			mov		dl, 'G'
			jmp		rDefault
		rIce:
			mov		dl, 'I'
			jmp		rDefault
		rDoor:
			mov		dl, '#'
		rDefault:
		call	colorFunc
		addChar:
			;load the displayed character into the frame buffer
		mov		BYTE [frameBuffer + ecx], dl
		inc		ecx
		cmp		DWORD [resColor], 1
		jne		noReset
			cmp		BYTE [floorLayer + edi + 1], 'P'
			je		noReset
			cmp		BYTE [ebx + edi + 1], 'T'
			je		noReset
			call	rColor
			mov		DWORD [lastColor], 50
		noReset:
	mov		esp, ebp
	pop		ebp
	ret

colorSearch:
	push	ebp
	mov		ebp, esp
		cmp		BYTE [colorArray + edx], 32
		jge		noChange
			xor		eax, eax
			mov		al, BYTE [colorArray + edx]
			mov		DWORD [colorCode], eax
		noChange:
	mov		esp, ebp
	pop		ebp
	ret

;moves door characters between board and doorlayer
layerSwap:
	push 	ebp
	mov		ebp, esp
		mov		cl, BYTE [board + eax]
		mov		dl, BYTE [doorLayer + eax] 
		mov		BYTE [board + eax], dl
		mov		BYTE [doorLayer + eax], cl
	mov		esp, ebp
	pop 	ebp
	ret

;prints out a color code depending on the byte to be printed
colorFunc:	
	push	ebp
	mov		ebp, esp
		push	edx
		;use the num in colorCode to load the correct code into edi
		mov		esi, DWORD[colorCode]
			;if the character being loaded into the frame buffer isn't the same as the last one,
			;load each of the bytes for the color code into the frame buffer until we reach a null byte
		cmp		DWORD [lastColor], 3
		je		colorAnyway
		cmp		DWORD [lastColor], esi
		je		redundantColor
			colorAnyway:
			mov		esi, DWORD[colorCodeArray + esi * 4]
			mov		eax, 0
			colorLoop:
			cmp		BYTE [esi + eax], 0
			je		endColorLoop
				mov		dl, BYTE [esi + eax]
				mov		BYTE [frameBuffer + ecx], dl
				inc		ecx
			inc		eax
			jmp		colorLoop
			endColorLoop:
			push	DWORD [colorCode]
			pop		DWORD [lastColor]
		redundantColor:
		pop		edx
	mov		esp, ebp
	pop		ebp
	ret
;reads in both wallcolor1 and wallcolor2
readWallCol:
	push	ebp
	mov		ebp, esp
		;load in the color for the walls
		mov		ebx, DWORD [ebp + 12]
		mov		BYTE [ebx], 27
		lea		eax, [ebx + 1]
		push	DWORD [ebp + 8]
		push	15
		push	eax
		call	fgets
		add		esp, 12
			;remove new line char
		lea		eax, [ebx]
		push	eax
		call	strlen
		add		esp, 4
		mov		BYTE [ebx + eax - 1], 0
	mov		esp, ebp
	pop		ebp
	ret

;prints a reset code
rColor:
	push	ebp
	mov		ebp, esp
		mov		esi, 0
		resetColorLoop:
		cmp		BYTE [resetColor + esi], 0
		je		endResetColorLoop
			mov		al, BYTE [resetColor + esi]
			mov		BYTE [frameBuffer + ecx], al
			inc		ecx
		inc		esi
		jmp		resetColorLoop
		endResetColorLoop:
		mov		DWORD [resColor], 0
	mov		esp, ebp
	pop		ebp
	ret