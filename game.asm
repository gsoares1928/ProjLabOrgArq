jmp main

tick : var #1
score : var #1

player_pos : var #1
bullet_pos : var #128

enemy_pos : var #128
enemy_delay : var #128

laser_pos : var #1
laser_active : var #1
laser_fuel : var #1

rand_state : var #1

map : var #1200
static map + #1190, #'S'
static map + #1191, #'c'
static map + #1192, #'o'
static map + #1193, #'r'
static map + #1194, #'e'

; Core
main :
	call init
main_loop:
	load r0, tick
	
	loadn r1, #4
	mod r1, r0, r1
	cz tick_bullet
	
	loadn r1, #3
	mod r1, r0, r1
	cz tick_player
	
	loadn r1, #3
	mod r1, r0, r1
	cz tick_laser
	
	loadn r1, #1
	mod r1, r0, r1
	cz tick_enemy
	
	loadn r1, #105
	mod r1, r0, r1
	cz tick_spawn_enemy
	
	inc r0
	store tick, r0
	call delay
	
	call show_score
	call check_game_over
	
	jmp main_loop
	
; initialize game state
init :
	loadn r0, #0
	store tick, r0
	store score, r0
	
	loadn r0, #562
	store player_pos, r0
	store laser_pos, r0
	
	loadn r0, #0
	store laser_active, r0
	
	loadn r0, #350
	store laser_fuel, r0
	
	loadn r0, #2222
	loadn r1, #enemy_pos
	loadn r2, #bullet_pos
	loadn r3, #128
init_loop_game :
	storei r1, r0
	storei r2, r0
	inc r1
	inc r2
	dec r3
	jnz init_loop_game
	
	loadn r5, #0
	loadn r0, #1200
init_map_loop :
	call erase
	inc r5
	dec r0
	jnz init_map_loop
	
	; draw player
	load r5, player_pos
	loadn r6, #']'
	call write
	rts
	
; end game and restart
game_over :
	loadn r0, #125
game_over_loop :
	call delay
	dec r0
	jnz game_over_loop
	
	call init
	rts
	
; check if the player lost
check_game_over :
	loadn r1, #bullet_pos
	loadn r2, #128
	load r3, player_pos
check_game_over_loop :
	loadi r4, r1
	cmp r4, r3
	jne check_game_over_continue
	call game_over
	rts
check_game_over_continue :
	inc r1
	dec r2
	jnz check_game_over_loop
	rts
	
; tick the laser
tick_laser :
	load r1, laser_fuel
	load r2, laser_active
	loadn r3, #0
	add r2, r2, r3
	jz tick_laser_end
tick_laser_erase :
	loadn r3, #40
	load r5, laser_pos
	inc r5
tick_laser_erase_loop :
	call erase
	inc r5
	mod r7, r5, r3
	jnz tick_laser_erase_loop
	
	loadn r3, #2
	cmp r2, r3
	jeq tick_laser_fix
	jmp tick_laser_nofix
	
tick_laser_fix :
	loadn r2, #0
	jmp tick_laser_end
tick_laser_nofix :
	loadn r3, #30
	cmp r1, r3
	jle tick_laser_end
	sub r1, r1, r3
	
tick_laser_draw :
	load r5, player_pos
	loadn r3, #2304
	loadn r6, #'>'
	add r6, r6, r3
	inc r5
	call write
	loadn r6, #'-'
	add r6, r6, r3
	loadn r3, #40
	inc r5
tick_laser_draw_loop :
	call write
	call kill_enemy
	inc r5
	mod r7, r5, r3
	jnz tick_laser_draw_loop
	
tick_laser_end:
	loadn r3, #3
	add r1, r1, r3
	loadn r3, #350
	cmp r1, r3
	jel tick_laser_save
	loadn r1, #350
tick_laser_save :
	store laser_fuel, r1
	store laser_active, r2
	load r5, player_pos
	store laser_pos, r5
	rts
	
; tick the player
tick_player :
	inchar r1
	
	load r5, player_pos
	loadn r6, #']'
	
tick_player_check_w:
	loadn r2, #'w'
	cmp r1, r2
	jeq tick_player_w
	jmp tick_player_check_s
tick_player_w:
	loadn r3, #40
	cmp r5, r3
	jle tick_player_end
	call erase
	sub r5, r5, r3
	call write
	store player_pos, r5

tick_player_check_s:
	loadn r2, #'s'
	cmp r1, r2
	jeq tick_player_s
	jmp tick_player_check_d
tick_player_s:
	loadn r3, #1120
	cmp r5, r3
	jeg tick_player_end
	call erase
	loadn r3, #40
	add r5, r5, r3
	call write
	store player_pos, r5
	
tick_player_check_d:
	loadn r2, #'d'
	cmp r1, r2
	jeq tick_player_d
	jmp tick_player_end
tick_player_d:
	loadn r3, #50
	load r4, laser_fuel
	cmp r4, r3
	jle tick_player_end
	
	loadn r3, #1
	store laser_active, r3
	rts
	
tick_player_end:
	loadn r3, #1
	load r4, laser_active
	cmp r3, r4
	jeq tick_player_end_two
	jmp tick_player_end_zero
tick_player_end_zero :
	loadn r3, #0
	store laser_active, r3
	rts
tick_player_end_two :
	loadn r3, #2
	store laser_active, r3
	rts
	
; tick all enemies
tick_enemy :
	loadn r1, #enemy_pos
	loadn r4, #enemy_delay
	loadn r2, #128
	loadn r3, #2222
	loadn r6, #'['
tick_enemy_loop :
	loadi r5, r1
	loadi r7, r4
	
	cmp r5, r3
	jeq tick_enemy_continue
	
	call write
	
	dec r7
	storei r4, r7
	jz tick_enemy_add_bullet
	jmp tick_enemy_continue
tick_enemy_add_bullet :
	dec r5
	call add_bullet
	
	call rand
	load r7, rand_state
	loadn r5, #45
	mod r7, r7, r5
	inc r7
	storei r4, r7
tick_enemy_continue :
	inc r1
	inc r4
	dec r2
	jnz tick_enemy_loop
	rts
	
; spawn an enemy at random position
tick_spawn_enemy :
	call rand
	load r5, rand_state
	loadn r1, #29
	loadn r2, #40
	mod r5, r5, r1
	inc r5
	mul r5, r5, r2
	dec r5
	dec r5
	call add_enemy
	rts
	
; tick all bullets
tick_bullet :
	loadn r1, #bullet_pos
	loadn r2, #128
	loadn r3, #2222
	loadn r4, #40
	loadn r6, #'<'
tick_bullet_loop :
	loadi r5, r1
	
	cmp r5, r3
	jeq tick_bullet_continue
	
	call erase
	dec r5
	call write
	storei r1, r5
	
	mod r7, r5, r4
	jnz tick_bullet_continue
	call erase
	storei r1, r3
tick_bullet_continue :
	inc r1
	dec r2
	jnz tick_bullet_loop
	rts
	
; delay function
delay :
	loadn r5, #90
delay_loop_1:
	loadn r6, #100
delay_loop_2:
	dec r6
	jnz delay_loop_2
	dec r5
	jnz delay_loop_1
	rts
	
; erase a position (r5 <- map[r5])
erase :
	push r6
	loadn r6, #map
	add r6, r6, r5
	loadi r6, r6
	call write
	pop r6
	rts
	
; write at a position (r5 <- r6)
write :
	outchar r6, r5
	rts
	
; generate the next pseudo-random number (rand_state out)
rand :
	push r0
	push r1
	push r2
	push r3
	load r0, rand_state
	loadn r1, #5
	loadn r2, #7
	loadn r3, #4273
	; (r1 * r0 + r2) mod r3
	mul r0, r0, r1
	mod r0, r0, r3
	add r0, r0, r2
	mod r0, r0, r3
	store rand_state, r0
	pop r3
	pop r2
	pop r1
	pop r0
	rts
	
; add an bullet at position r5
add_bullet :
	push r1
	push r2
	push r3
	push r4
	loadn r1, #bullet_pos
	loadn r2, #128
	loadn r3, #2222
add_bullet_loop :
	loadi r4, r1
	
	cmp r4, r3
	jne add_bullet_continue
	
	storei r1, r5
	jmp add_bullet_end
add_bullet_continue :
	inc r1
	dec r2
	jnz add_bullet_loop
add_bullet_end :
	pop r4
	pop r3
	pop r2
	pop r1
	rts
	
; add an enemy at position r5
add_enemy :
	push r1
	push r2
	push r3
	push r4
	push r6
	loadn r1, #enemy_pos
	loadn r6, #enemy_delay
	loadn r2, #128
	loadn r3, #2222
add_enemy_loop :
	loadi r4, r1
	
	cmp r4, r3
	jne add_enemy_continue
	
	storei r1, r5
	loadn r1, #1
	storei r6, r1
	jmp add_enemy_end
add_enemy_continue :
	inc r1
	inc r6
	dec r2
	jnz add_enemy_loop
add_enemy_end :
	pop r6
	pop r4
	pop r3
	pop r2
	pop r1
	rts
	
; check if there is an enemy at position r5, if true kill it
kill_enemy :
	push r1
	push r2
	push r3
	push r4
	loadn r1, #enemy_pos
	loadn r2, #128
	loadn r3, #2222
kill_enemy_loop :
	loadi r4, r1
	
	cmp r4, r5
	jne kill_enemy_continue
	
	storei r1, r3
	load r1, score
	inc r1
	store score, r1
	jmp kill_enemy_end
kill_enemy_continue :
	inc r1
	dec r2
	jnz kill_enemy_loop
kill_enemy_end :
	pop r4
	pop r3
	pop r2
	pop r1
	rts
	
; display the score
show_score :
	load r4, score
	loadn r1, #10
	loadn r2, #2816
	loadn r3, #'0'
	loadn r5, #1200
	
	mod r6, r4, r1
	add r6, r6, r2
	add r6, r6, r3
	div r4, r4, r1
	dec r5
	call write
	
	mod r6, r4, r1
	add r6, r6, r2
	add r6, r6, r3
	div r4, r4, r1
	dec r5
	call write
	
	mod r6, r4, r1
	add r6, r6, r2
	add r6, r6, r3
	div r4, r4, r1
	dec r5
	call write
	
	mod r6, r4, r1
	add r6, r6, r2
	add r6, r6, r3
	div r4, r4, r1
	dec r5
	call write
	rts
	