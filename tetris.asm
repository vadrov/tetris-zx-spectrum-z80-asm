;1996 RoVadSoft - Tetris
;2020 ������������ ��� ��������������� ��� �� �������, �� ��� ����� VadRov 
; ����-������ ��� ZX-Spectrum 
		device zxspectrum48

PRINT_INV_MSK 	equ %11111110 ;������� ����� ������ ��������
PRINT_OVR_MSK 	equ %11111101 ;������� ����� ������ ���������
PRINT_UTD_MSK 	equ %11111011 ;������� ����� ������ ������
PRINT_BFNT_MSK 	equ %11110111 ;������� ����� ������� ������
PRINT_VERT_MSK 	equ %11101111 ;������� ����� ���� ������
PRINT_UDG_MSK 	equ %11011111 ;������� ����� ������ UDG (������� ������������)

PRINT_INK_MSK	equ %11111000 ;������� ����� ������
PRINT_PAP_MSK	equ %11000111 ;������� ����� ������
PRINT_BRT_MSK	equ %10111111 ;������� ����� �������
PRINT_FLH_MSK	equ %01111111 ;������� ����� �������
		org 50000
tetris
		di
		ld sp,49999
		;���� ��������� �������������
		ld hl,0			;������������� �������� ������������ �����  
		ld (hiscore),hl
		ld (in_time),hl	;������������� ������� ������ ����
		;���� ������������:
		;��� 7 - �������� ������� 1 - ���./0 - ����.
		;��� 6 - ���� �����: 1 - ������������/0 - �����������
		;��� 5 - ����� "����� ������" 1 - ���./0 - ����., 
		;��� 4 - ������ ������ �� ��� ������� 1 - ���./0 - ����.
		;��� 3 - �������� �� ������ 1 - ���./0 - ����. (��� 0 ���������� ������)
		;���� 2,1,0 - ���������� ����� ������ �� ����� figures ��� ������ "����� ������"
		ld a,%11011000
		ld (config),a
		bit 3,a
		ld a,17
		jr z,tetris1
		xor a
tetris1
		ld (block_output_texture+1),a
		ei
		ld a,56
		ld (color_attr),a
		call select_keys
;		call 49152

;���� ����� ����
newgame	
		call inter_init  	;������������� ������ ���������� 2 ���������������:
							;- �������� �������, 
							;- ����� ����������� ������,
							;- ������ (����������)
		ld hl,0			
		ld (score),hl	;������������� �������� ����� ��� ����� ���� 
		ld (lines),hl	;������������� ����������� �����
		ld a,0	;������������� ������� ��������� ������
		ld (color_attr),a
		ld (stakan_vodka_color),a ;����������, ����� ���� "������" � "������" ���������
		rra             ;������ � ���� ���� ������
		rra
		rra
		and 7
		out (#fe),a
		call clrscr		;������� ������	
		call stakan		;��������� �������		
		ld hl,interface_string ;������� �� ������
		call print
		call prn_best_result 	;������ ������� ���������� � ����
		call figure_list		;����� ������ �����
		ld hl,statistics_fig	;������������� ���������� ��������� �����
		ld (hl),0
		ld de,statistics_fig+1
		ld bc,14-1
		ldir
		ld de,fig		;���������� ������� ��������������� ������ � �����
		call copyfig
		call rotation_fig_rnd  ;������� ������ �� ��������������� ����� ��������
		ld a,c			;�������� ������� ������
		ld (attr),a
		xor a			
		ld (tick),a		;������������� �������
		ld (sec),a
		ld (min),a
		ld (contour_shift),a ;������������� �������� ��� ������� ������ ����� �������
		inc a
		ld (level),a	;������������� ������ ����
		call time1		;����� �������� ������� ���� (00:00)
;����� ������
newfig
		ld hl,0
		ld (contour_pos),hl ;������������� ��������� ������� ������ �� ��� �������
		call figure_statictics	;����� ���������� �� �������
		ld iy,stakan_vodka_color
		call lines_clear 	;�������� � �������� ����������� ����� � ������� 
							;(�� ������ � a' ���������� ����������� �����)
		call scoreupdate	;���������� ����� ����
		call prnscore	;����� ����� ����
		call levupd		;������ ������ (�������� ����)
		ld de,next_fig  ;���������� ��������� ��������������� ������ � �����
		call copyfig
		call rotation_fig_rnd ;������� ��������� ������ �� rnd ��������
		ld a,c			;�������� ��������� ������
		ld (next_attr),a
		ld hl,#5800+2*32+25 ;����� �� ����� ��������� ������
		ld de,next_fig
		call block_output_var
		ld a,(attr)
		ld b,a	        ;� b - �������� ������� ������
		ld hl,#5800+0*32+15	;����� ��������� ������� ������� ������ � ������� ���������
		push hl
		exx 
		pop hl
		exx
		xor a
		call saveloadfig	;������ ����� ������ �� ��������������� ������
newfig0
		call block_check    ;��������: ����� �� �������� ������ � ����� �����������?
		or a
		jp z,newfig1	
		ld de,#5800+0*32+15 ;����� ����, ���� ����� ������ ���������� � ��������� �������
		ex de,hl
		and a
		sbc hl,de
		ex de,hl
		jr nz,newfig0_
		ld hl,(hiscore)	;���������� ������������� ����� ����, ���� ������� ���� ��� ������
		ld de,(score)
		and a
		sbc hl,de
		jr nc,gameover
		ld (hiscore),de
		ld hl,in_time
		ld bc,(sec)
		ld (hl),c ;�������
		inc hl
		ld (hl),b ;������
gameover
		call inter_deinit ;��������� ����������� ���������� ���������
		call screen_off
		jp newgame
newfig0_					;���� �� ���
		push hl
		ld hl,sndfx1		;���� ������, ������� �� ���
		ld a,1
		call newfx
		pop hl
		exx						
		ld c,0
		exx
		ld a,(config)
		bit 4,a
		call nz,print_contour	;������� ������
		ld c,b
		call block_output		;��������� ����
		;�������� ��������� ������
		ld hl,#5800+2*32+25
		ld de,next_fig
		ld c,(iy)
		call block_output_var
		;��������� ������ ������ �������
		ld a,(next_attr)
		ld (attr),a
		ld hl,next_fig
		ld de,fig
		ld bc,4
		ldir
		jp newfig
newfig1
		xor a
		ld (flag_update),a
		ld a,(level)
		ld c,a
		ld a,15
		sub c
		;���� ��������, � �������� �������� ������������ ����������
		;� �������� ��������� ������ � ������������ � ����������� ������������
newfig2
		push af
		ld a,(config)
		bit 4,a
		call nz,check_contour
		halt
		call block_update
		ld a,(inkey)
		inc a
		jr nz,newfig3
newfig2_1
		pop af
		dec a
		jr nz,newfig2
		exx
		ld de,32
		add hl,de
		exx
		jp newfig0
newfig3
		ld a,(slip_inkey) ;��������� �� "��������" �������
		or a
		jr z,newfig3_1    ;"���������" ���
		ld a,(inkey)
		bit 0,a			  ;��������� "��������" ������� ���������� ��������� ������ 
		jr z,newfig2_1
		bit 2,a			  ;��������� "��������" ������� ���������� ������ � ����
		jr z,newfig2_1
		bit 4,a			  ;��������� "��������" ������� ���������� ���������� �������� ������ 
		jr z,newfig2_1
		ld a,(slip_count) ;��������� �������� ���������� ��������� "��������", 
		cp 4			  ;�� � �������� �������� ������� �������
		jr c,newfig2_1
		xor a			  ;���������� ������� "���������"
		ld (slip_count),a
newfig3_1		
		ld a,(inkey)
		rrca
		call nc,rotate
		rrca
		call nc,right
		rrca
		call nc,pause
		rrca
		call nc,left
		rrca
		call nc,drop
newfig4
		pop af
		jp newfig2
;������� "����������" ������
screen_off
		ld e,4
		ld c,7
screen_off1
		ld hl,#5800
		ld b,6
screen_off1_1
		halt
		djnz screen_off1_1
		ld b,3
screen_off2		
		ld a,(hl)
		and c
		ld (hl),a
		inc l
		jr nz,screen_off2
		inc h
		djnz screen_off2
		srl c
		dec e
		jr nz,screen_off1
		ret
;���������� ������ �� ������
block_update
		ld a,(flag_update)  ;��������� ���� ����������
		or a
		ret nz
		inc a
		ld (flag_update),a
		call figure_reset 	;������� ������
		exx
		push hl
		exx
		pop hl
		ld a,1	;�������� ������ � �������� ����� �� ����������������
		call saveloadfig
		call figure_set 	;������� ������
		ret

;��������
rotate
		push af
		ld de,tmp_fig
		call rotfig			;������� ������
		call block_check	;��������� ����������� ������
		or a				
		jr nz,rotate1   	;����� ����������
rotate0						;�������� ������� 
		push hl             ;������ �������� ������ � ��������� ������ �� ������ ������ �� ����
		ld hl,sndfx3
		ld a,1
		call newfx
		pop hl
		xor a
		ld (flag_update),a
rotate0_1
		pop af
		ret
rotate1
		xor a				;��� ������������� ������ ������ ����� ��������
		call saveloadfig	;��������������� ������ �� ��������� ������ �� ������ ������� ������
		jr rotate0_1
;�������� ������ ������
right
		push af
		exx
		inc hl
		exx
		call block_check	;��������� ����������� ������
		or a
		jr z,right2
		exx
		dec hl
		exx
right1
		pop af
		ret
right2
		xor a
		ld (flag_update),a
		jr z,right1
;�������� ������ �����
left
		push af
		exx
		dec hl
		exx
		call block_check	;��������� ����������� ������
		or a
		jr z,right2
		exx
		inc hl
		exx
		jr right1
		
;���������� �������� ������ ����
drop
		push af
		push hl
		ld hl,sndfx2
		ld a,1
		call newfx
		pop hl
		xor a
		ld (drop_flag),a
drop1
		exx
		ld de,32
		add hl,de
		exx
		call block_check	;��������� ����������� ������
		or a
		jr nz,drop3
		ld a,(drop_flag)
		or a
		jr nz,drop2
		inc a
		ld (drop_flag),a
drop2
		xor a
		ld (flag_update),a
		halt
		call block_update
		jr drop1
drop3
		exx
		ld de,-32
		add hl,de
		exx
		pop af
		ret
	
;����� � ����
pause
		di
		push af
		push bc
		ld bc,0
pause1
		dec bc
		ld a,b
		or c
		jr nz,pause1
pause2				;�������� ������� ����� �������
		xor a		;������� ���� ������ ������� � 0 (������� ��� ��������)
		in a,(#fe)
		cpl
		and 31
		jr z,pause2
		pop bc
		pop af
		ei
		ret
		
;������� ������ � ������
figure_set
		;����� ������� ������ ����� �������
		exx
		ld c,1
		exx
		ld a,(config)
		bit 4,a
		call nz,print_contour
		;����� ������
		ld c,b
		call block_output
		ret
		
;������� ������ � ������		
figure_reset
		;�������� ������� ������
		exx
		ld c,0
		exx
		ld a,(config)
		bit 4,a
		call nz,print_contour
		;�������� ������
		ld c,(iy)
		call block_output
		ret
		
;�������� ����������� �����
;�������� ����� � ����������� �� ���������� ����������� �����
;���������� ����� ����� � a'
scoreupdate	
		ex af,af'
		ld e,a
		ex af,af'
		inc e
		dec e
		ret z
		ld d,0
		ld hl,(lines)
		add hl,de
		ld (lines),hl
		ld b,e			;���������� ����� �� ���������� ����� �� ���������:
		ld de,10		;1 ����� - 10 �����
		ld hl,(score)	;2 ����� - 25 �����
newfig_add_score		;3 ����� - 45 �����
		add hl,de		;4 ����� - 70 �����
		push hl
		ld hl,5
		add hl,de
		ex de,hl
		pop hl
		djnz newfig_add_score
		ld (score),hl
		ret
		
;������� �������� ����� ��� ����������
figure_list
		xor a
		ld b,7
		ld hl,#5800+1*32+2
figure_list1
		push af
		push bc
		push hl
		ld de,fig
		call copyfig1
		pop hl
		call block_output
		pop bc
		pop af
		inc a
		ld de,96
		add hl,de
		djnz figure_list1
		ret
		
;������� ���������� �� �������
figure_statictics
		ld hl,statistics_fig
		ld d,7
		ld ix,stat_at
		ld iy,0
figure_statictics1
		ld a,7
		sub d
		ld e,a
		add a,a
		add a,e
		add a,3
		ld (ix+1),a
		push de
		push hl
		ld hl,stat_at
		call print
		pop hl
		pop de
		ld c,(hl)
		inc hl
		ld b,(hl)
		inc hl
		add iy,bc
		ld a,5
		call print_dec
		dec d
		jr nz,figure_statictics1
		ld hl,stat_alls
		call print
		push iy
		pop bc
		ld a,5
		call print_dec
		ret

;����� ����������� ������ ����������
;� d ��������� ������ ����������(��� ������� - ������� ������)
;0 ��� - �������� 
;1 ��� - ������
;2 ��� - �����
;3 ��� - �����
;4 ��� - �������
keys
		ld d,255		
		ld hl,key_drop
		call inputkey
		rl d		
		ld hl,key_left
		call inputkey
		rl d
		ld hl,key_pause
		call inputkey
		rl d
		ld hl,key_right
		call inputkey
		rl d
		ld hl,key_rotate
		call inputkey
		rl d
		ld hl,slip_count
		ld a,(inkey) ;�������� �� �������� �������
		cp d
		ld a,d
		jr z,keys1
		ld (inkey),a
		xor a
		ld (slip_inkey),a ;�������������� ���� 
		ld (hl),a		  ;� ������� ���������
		ret
keys1	
		ld a,1
		ld (slip_inkey),a
		inc (hl)          ;����������� ������� ���������
		ret		
; ������������ ������� ���� � ����������� �� ���������� ����������� �����
; ������� ������������� ����� ������ 10 ����������� �����
levupd
		ld hl,lines_at
		call print
		ld bc,(lines)
		push bc
		ld a,5
		call print_dec
		pop hl
		ld de,10
		xor a
levupd1
		inc a
		or a
		sbc hl,de
		jr nc,levupd1
		ld (level),a
		push af
		ld hl,level_at
		call print
		pop af
		ld b,0
		ld c,a
		ld a,5
		call print_dec
		ret

;���������� ��������������� ������ � ������������� �� � ����� �� ������ � de
;�� ������ � C ������� ������ (�������� ��������� ���� 6 ������������)
;�������� � ������ ������������ �� ������ config:
;��� 6 - ���� �����: 1 - ������������/0 - �����������,
;��� 5 - ����� "����� ������" 1 - ���./0 - ����., 
;���� 2,1,0 - ���������� ����� ������ �� ����� figures ��� ������ "����� ������"
copyfig
		ld ix,config 	;����� ����� ������������
		ld a,(ix)		;� ������ ����� ������ ����� ������ ���� 2,1,0
		ld c,7
		bit 5,a      	;�������� ������ ������ ���������/���������� ������
		jr z,copyfig0
		and c		 	;������ �� ������ (����� ������ ������ �� 0 �� 6)
		cp c
		jr nz,copyfig1
		xor a
		jr copyfig1
copyfig0
		ld a,r			;� � ��������� �������� ����������� r
		and c
		cp c
		jr z,copyfig0
copyfig1
		ld hl,statistics_fig
		push af
		push de
		add a,a
		ld d,0
		ld e,a
		add hl,de
		ld e,(hl)
		inc hl
		ld d,(hl)
		inc de
		ld (hl),d
		dec hl
		ld (hl),e
		pop de
		pop af
		ld hl,figures
		ld b,0
		ld c,a
		add hl,bc
		;������������/����������� �����
		cpl				;����������� ����
		rlca
		rlca
		rlca
		and 8+16+32
		ld c,a
		ld a,(stakan_vodka_color)
		ld b,a
		and 8+16+32
		cp c
		jr nz,copyfig2
		cpl
		and 8+16+32
		ld c,a
copyfig2
		ld a,b
		rra
		rra
		rra
		and 7
		or c
		ld c,a
		push de
		xor a
		ld (de),a
		inc de
		ld b,3 
copyfig3 
		rld			;������� ������� (���� 7... 4) ������ ������ hl ����������� 
					;� ������� ������� ������������ (���� 3...0), 
					;������� ������� ������������ ����������� � ������� ������� ������ ������, 
					;� ������� ������� ������ ������ � � ������� ������� ������ ������
		ld (de),a
		inc de
		djnz copyfig3
		pop de
		ret
		
;������� ������ �� ��������������� ����� ��������
;����� ������ �� ������ � de
rotation_fig_rnd 
		ld a,r
		rra
		rra
		rra
		and 7
		ret z		
		ld b,a
rotation_fig_rnd1
		call rotfig
		djnz rotation_fig_rnd1
		ret		
;������
stakan
		ld ix,stakan_data1
		ld c,0
		ld b,24
stakan1
		ld (ix+1),c
		push bc
		push ix
		pop hl
		call print
		pop bc
		inc c
		djnz stakan1
		ld hl,vadsoft_txt
		jp print

;����� ������� ����� ����
prnscore
		ld hl,score_at
		call print
		ld bc,(score)
		ld a,5
		jp print_dec
;����� ������� ���������� � �������, �� ������� �� ��� ���������
prn_best_result		
		ld hl,hiscore_at
		call print
		ld bc,(hiscore)
		ld a,5
		call print_dec
		ld hl,intime_at
		call print
		ld hl,(in_time)
		ld b,0
		ld c,h
		ld a,128+2
		call print_dec
		ld a,":"
		call printsym
		ld c,l
		ld a,128+2
		jp print_dec
		
lines_light
		call lines_check ;���������� ���������� ����������� ����� � �� ������
		ex af,af'
		ld b,a
		ex af,af'
		inc b
		dec b
		ret z			;���� ����������� ����� ���, �� ������
		xor a
		ld (mig),a
		ld a,6
lines_light_mig
		push af
		exx 
		ld c,a
		exx
		ld c,5
lines_light0
		push bc
		ld ix,lines_table
lines_light1
		ld l,(ix)
		inc ix
		ld h,(ix)
		inc ix
		ld e,c
		dec e
		ld d,0
		push hl
		add hl,de
		pop de
		push hl
		ld a,10
		sub c
		ld h,0
		ld l,a
		add hl,de
		ex de,hl
		pop hl
		exx
		ld a,c
		exx
		cp 1
		push bc
		jr nz,lines_light2
		ld a,(stakan_vodka_color)
		ld c,a
		jr lines_light3
lines_light2
		ld c,%00010000
		ld a,(mig)
		or c
		ld c,a
lines_light3
		ld (hl),c
		ld (de),a
		pop bc
		djnz lines_light1
		halt
		pop bc
		dec c 
		jr nz,lines_light0
		ld a,(mig)
		xor 64
		ld (mig),a
		pop af
		dec a
		jr nz,lines_light_mig
		ret

;���� ����������� ����� ������� � ���������� �� ������ � table_str
;�� ������ � a' ���������� ����������� �����
lines_check
		ld b,23
		ld hl,#5800+23*32+12
		ex af,af'
		xor a
		ex af,af'
		exx
		ld a,(stakan_vodka_color)
		and %00111000
		ld b,a
		exx
		ld ix,lines_table
lines_check1
		push hl
		push bc
		ld b,10
		call cpir_paper
		pop bc
		pop hl
		jr z,lines_check2
		ex af,af'
		inc a
		ex af,af'
		ld (ix),l
		inc ix
		ld (ix),h
		inc ix
lines_check2
		ld de,-32
		add hl,de
		djnz lines_check1
		ret

;������� ����������� ����� �������
lines_clear
		call lines_light
		ex af,af'
		ld b,a
		ex af,af'
		inc b
		dec b
		ret z			;���� ����������� ����� ���, �� ������
   		ld a,b
		ld hl,sndfx4	;���� - �������� �����
		call newfx
		ld ix,lines_table
		ld de,0
lines_clear1
		push bc
		push de
		ld l,(ix)		;� hl ����� ����������� ������
		inc ix
		ld h,(ix)
		inc ix
		add hl,de
		ld a,h			;�� ������ ���������� ����� ������
		ld b,l			;����� � ����� �������� ������� ��� �������� ��������� �� ������� ��� ������
		rl b
		rla
		rl b
		rla
		rl b
		rla
		and 31
		ld b,a
		jr z,lines_clear4
lines_clear2
		push bc
		push hl
		ld de,-32
		add hl,de
		pop de
		push hl
		push de
		push hl
		ld a,h
		add a,a
		add a,a
		add a,a
		and #7f
		ld h,a
		ld a,d
		add a,a
		add a,a
		add a,a
		and #7f
		ld d,a
		ld b,8
lines_clear3
		push bc
		push de
		push hl
		ld bc,10
		ldir
		pop hl
		pop de
		pop bc
		inc h
		inc d
		djnz lines_clear3
		pop hl
		pop de
		ld bc,10
		ldir
		pop hl 
		pop bc
		djnz lines_clear2	
		pop hl
		pop bc
		ld de,32
		add hl,de
		ex de,hl
		djnz lines_clear1
		ret
lines_clear4
		pop bc
		ret

;����� (�� ������� ����������) � ������ ���������� � ��������� � b', ��� ����������� ������ ���� "������"
;���� ����� �������, �� �� ������ ���������� ���� ���� Z, ��� ���� � b �������� ���������� �����
;���� ������ �� ������, �� ���� ���� �� ������ �������
cpir_paper
		ld a,(hl)
		and %00111000
		exx
		cp b
		exx
		ret z
		inc hl
		dec b
		jr nz,cpir_paper
		ld c,2 ;����� ����� ����
		dec c
		ret
		
;����������/��������������� � �����/�� ������ ������� ������
;a = 0 - ����������, � �������� �� 0 - ���������������
saveloadfig 
		push bc
		push de
		push hl
		ld hl,fig
		ld de,tmp_fig
		or a
		jr z,saveloadfig1
		ex de,hl
saveloadfig1 
		ld bc,4
		ldir
		pop hl
		pop de
		pop bc
		ret

;�������� ������ (����� ������ � de)
rotfig
		push bc
		push de
		push hl
		ex de,hl
		push hl
		ld c,(hl)
		inc hl
		ld b,(hl)
		inc hl
		ld e,(hl)
		inc hl
		ld d,(hl)
		pop hl
		ld lx,4
rotfig1
        xor a
        rr c 
        rla
        rr b 
        rla
        rr e
        rla
        rr d 
        rla
        ld (hl),a 
        inc hl
		dec lx
        jr nz, rotfig1
		pop hl
		pop de
		pop bc
		ret		
		
;�������� ����������� ������ ������ � ������ � hl'
;hl - ������� ������� (�����) ������ � ������� ���������
;hl' - �������������� ������� (�����) ������ � ������� ���������
;�� ������ � = 0, ���� ��, ����� � = 1
block_check
		ld de,fig       ;������� ������
		ld a,(stakan_vodka_color)
		and %00111000
		exx
		ld de,tmp_fig	;�������������� ������
		push bc
		push hl
		inc hl
		inc hl
		inc hl
		ld b,4
		ld c,a
block_check1
		ld a,(de)
		push bc
		ld b,4
block_check2
		rra
		jr nc,block_check3
		;�������� �� ����� ������ �� ������� �������
		ex af,af'
		ld a,l 	
		and 31
		cp 12
		jr c,block_check2_1
		cp 22
		jr nc,block_check2_1
		ld a,h
		cp 91
		jr nc,block_check2_1
		;-------------------------------------------
		;�������� �� ������� � �������� �������
		ld a,(hl)
		and %00111000
		cp c
		jr z,block_check5	;������� ������
		call block_check_adr
		jr z,block_check5	;� �������� ����� �� ������� ������
block_check2_1
		ex af,af'
		pop bc
		ld a,1
		jr block_check4
block_check3
		dec hl
		djnz block_check2
		push de
		ld de,36
		add hl,de
		pop de
		inc de
		pop bc
		djnz block_check1
		xor a
block_check4
		pop hl
		pop bc
		exx
		ret
block_check5
		ex af,af'
		jr block_check3
		
;��������������� ��������� ��� block_check
;�������� ��� �� � ���������� �� ������ � hl �������� ������� ������
block_check_adr
		ld (block_element_addr),hl
		exx
		push bc
		push de
		push hl
		inc hl
		inc hl
		inc hl
		ld b,4
block_check_adr1
		ld a,(de)
		ld c,4
block_check_adr2
		rra
		push af
		push de
		ld de,(block_element_addr)
		or a
		ex de,hl
		sbc hl,de
		ex de,hl
		pop de
		jr z,block_check_adr4		;������ �������
		pop af
		dec hl
		dec c
		jr nz,block_check_adr2
		push de
		ld de,36
		add hl,de
		pop de
		inc de
		djnz block_check_adr1
block_check_adr3
		ld a,2					;��� ������ ����� ����
block_check_adr3_1
		dec a			
		pop hl
		pop de
		pop bc
		exx
		ret
block_check_adr4
		pop af
		jr c,block_check_adr5
		;������� �� ����������� ������
		jr block_check_adr3
block_check_adr5
		;������� ����������� ������
		ld a,1					;��� ��������� ����� ����
		jr block_check_adr3_1
		
;����� ������
;hl - ������� ������� (�����) ������ � ������� ���������
;c - �������
block_output
		ld de,fig
block_output_var
		ld a,(stakan_vodka_color)
		and %00111000 ;��� ��������� ����� ������ � ����� ������� � ������� ����� ������� ������
		exx
		ld b,a
		exx
		ld a,c
		and %00111000
		exx
		cp b
		ld c,0		 ;c' - ���� �������� ������ (0 - �������, 1 - �������)
		jr z,block_output0
		ld c,1
block_output0
		exx
		ld ix,kirpich ;������ ������ (8 ����), ������������ ������� �������
block_output_kirpich
		exx
		inc c
		dec c
		exx
		jr nz,block_output_kirpich1
		ld ix,kirpich_clear ;������� ������� "�������", ���� ������� ����/������
block_output_kirpich1
		push bc
		push hl
		exx 
		push hl
		exx
		inc hl
		inc hl
		inc hl
		ld b,4
block_output2
		ld a,h 
		add a,a
		add a,a
		add a,a
		and #7f
		ex af,af'
		ld a,l
		exx
		ld l,a
		ex af,af'
		ld h,a
		exx
		ld a,(de)
		push bc
		ld b,4
block_output3
		rra
		jr nc,block_output5
block_output_texture		
		jr block_output_texture_off
block_output_texture_on
		ex af,af'
		exx
		push hl
		ld b,8
		push ix
		pop de
block_output4
		ld a,(de)
		ld (hl),a
		inc	de
		inc h
		djnz block_output4
		pop hl
		exx
		ex af,af'
block_output_texture_off
		ld (hl),c
block_output5
		dec hl
		exx
		dec hl
		exx
		djnz block_output3
		push de
		ld de,36
		add hl,de
		pop de
		inc de
		pop bc
		djnz block_output2
		exx
		pop hl
		exx
		pop hl
		pop bc
		ret
		
mute
		ld      (count),a  ; "��������"
		ret
; ����������� ����������
inter_init    
		xor a
		ld (count),a
		ld (slip_count),a
		ld (slip_inkey),a
		ld (tick),a
		ld (sec),a
		ld (min),a
		ld (time_dat_counter),a
		ld (time_update_counter),a
		ld a,255
		ld (inkey),a
		ld a,24       ; ��� ������� jr
		ld (65535),a
		ld a,195      ; ��� ������� jp
		ld (65524),a
		ld hl,intr    ; hl=����� �����������
		ld (65525),hl
		ld hl,65024
		ld de,65025
		ld bc,256
		ld (hl),255   ; ����� ���������� - 65535
		ld a,h
		ldir               ; ���������� �������
		di
		ld i,a
		im 2
		ei
		ret
; ���������� ����������
inter_deinit    
		di
		ld a,63
		ld i,a
		im 1
		ei
		ret
; ������������� �������
newfx    
		ld ix,config
		bit 7,(ix)
		ret z
		di
		ld (count),a
		xor a
		ld (flag),a
		ld (addr),hl
		ld (curadd),hl
		ei
		ret

intr     				;���������� ����������
		push af         ;���������� ���������
		ex af,af'
		push af
		ex af,af'
		push bc         
		push de
		push hl
		exx
		push bc
		push de
		push hl
		exx
		push ix
		push iy
test     
		ld a,(count)  ; a=������� ����������
		or a          ; ���� ��� ������ ?
		jr z,exit
		ld hl,(curadd); hl=������� �����
next     
		ld a,(hl)
		inc hl
		cp 254        ; a=254 ? (������ �����)
		jr nz,cont1
		ld (addr),hl  ; ��������� ���������� ������
		jr next
cont1    
		cp 255        ; a=255 ? (�����)
		jr nz,cont2
		ld hl,(addr)  ; �������������� ����������
		ld (curadd),hl; ������ ����� ������
		ld hl,count
		dec (hl)       ; ���������� �������� ����������
		jr test
cont2    
		or a          ; a=0 ? (�������������)
		jr nz,cont3
		ld a,(flag)
		cpl                ; �������������� a
		ld (flag),a
		jr next
cont3    
		ld b,a        ; b=�������
		ld c,(hl)     ; c=������������
		inc hl
		ld (curadd),hl; ���������� �������� ������
		ld a,(stakan_vodka_color)        ; a=���� �������
		rra
		rra
		rra
		and 7
		ld e,a
		ld a,(flag)   ; a=����
		or a          ; a=0 ?
		ld a,e
		jr nz,noise
tone     
		xor 16         ; ��������������� ����
		out (254),a
		push bc
		djnz $
		pop bc
		dec c
		jr nz,tone
		jr exit
noise    
		ld hl,100    ; ��������������� ����
		ld d,a
nois2   ld a,(hl)
		and 248
		or d
		out (254),a
		push bc
		djnz $
		pop bc
		inc hl
		dec c
		jr nz,nois2
exit    
		call keys ;����� ����������� ������
		call time ;����������
;		call 49152+5
		pop iy
		pop ix
		exx
		pop hl
		pop de
		pop bc
		exx
		pop hl
		pop de
		pop bc
		ex af,af'
		pop af
		ex af,af'
		pop af
		ei
		ret 
		
;����������
		;����� ����� +1 ��� � ����� ������� ���� 1 ��� � �������
time 
		ld hl,time_update_counter
		inc (hl)
		ld a,2
		cp (hl)
		call z,time3
time0
		ld hl,tick  ;1/50 ������� ����������� ������� ����� 
		inc (hl)
		ld a,50
		cp (hl)
		ret nz
		ld (hl),0
		inc hl      ;����� ������ 50 ����� ����������� ������� ������
		inc (hl)
		ld a,60
		cp (hl)		
		jr nz,time1
		ld (hl),0  
		inc hl      ;����� ������ 60 ������ ����������� ������� �����
		inc (hl)
		;����� ����� � ������ �������� ������� ����
time1
		ld a,(color_attr) ;����������� ��������� ������
		push af
		ld hl,(pos_at) ; ����������� ������� ������
		push hl
		ld hl,time_at
		call print
		ld a,(min)
		ld c,a
		ld b,0
		ld a,128+2 ;����� �������� ���������� ���� -> ��� 7 � � ���������� (���� � ������� 00:00)
		call print_dec
		ld a,(time_dat_counter)
		ld d,0
		ld e,a
		ld hl,time_dat_cursor
		add hl,de
		ld a,(hl)
		call printsym
		ld a,(sec)
		ld c,a
		ld a,128+2
		call print_dec
time2
		pop hl				;�������������� ������� ������ � ���������
		ld (pos_at),hl
		pop af
		ld (color_attr),a
		ret
time3
		ld (hl),0
		ld a,(color_attr)
		push af
		ld hl,(pos_at)
		push hl
		ld hl,time_at_razdel
		call print
		ld a,(time_dat_counter)
		inc a
		cp 4
		jr c,time3_1
		xor a
time3_1
		ld (time_dat_counter),a
		ld d,0
		ld e,a
		ld hl,time_dat_cursor
		add hl,de
		ld a,(hl)
		call printsym
		jr time2

; ������ ����� �� bc � ������������ �� 5 �������� ������� (0...65535)
; � � ����, ������������:
; ��� 7 - ����� ���������� �����: 1 - ��������, 0 - �� ��������
; ���� 2,1,0 - ���������� �������� (�������� - 5, ������� - 1)
print_dec
		push de
		push hl
		push bc
        ld hl,table
		ld c,a
		res 6,c
		and 7		;������ �� ������: �������� ������� 1
		jr z,print_dec4
		cp 6		;�������� �������� 5
		jr nc,print_dec4
		ld b,a
		ld a,5
		sub b
		add a,a
		ld e,a
		ld d,0
		add hl,de ;��������� ����� � ������� (� ����������� �� �������)
print_dec1
		ld e,(hl)        
        inc hl            
        ld d,(hl)        
        inc hl            
        ex (sp),hl       
        xor a             
print_dec2
		inc a             
        sbc hl,de         
        jr nc,print_dec2
        add hl,de         
		add a,"0"-1
						  ;�������� �� ���������� ����:
        ld d,b			  ;���� ������ "�������" - 0 �������� � ����� ������
		dec d
		jr z,print_dec3
		bit 7,c           ;�������� ��������� ����� ������ ���������� �����:
		jr nz,print_dec3  ;�� ��������� �������� -> �������
		bit 6,c			  ;�� ��������� �������� -> ��������� ���� ������ ������ �������� �����
		jr nz,print_dec3  ;������ �������� ����� ��� ���������� -> �������� ����� ��� �������� �� 0		
		cp 48			  ;������ �������� ����� �� ���������� - ��������� ������� ����� �� 0
		jr z,print_dec3_1 ;������� ����� ���������� 0 -> ���������� ���
		set 6,c			  ;������ �������� ����� -> ��������� ���� ������ ������ �������� �����
print_dec3
        call printsym
print_dec3_1
        ex (sp),hl       
        djnz print_dec1
print_dec4
        pop bc            
		pop hl
		pop de
        ret                  
;������ �������
;� - ��� �������
;pos_at - ����� ������� ������
printsym
		push bc
		push de
		push hl
		ld de,(font)
		ld h,0
		ld l,a
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,de
		ex de,hl
		ld hl,(pos_at)
		ld b,8
		push hl
		ld a,(print_parametr)
		ld c,a
printsym1
		ld a,(de)
		bit 3,c				;�������� ������ �������� ������
		jr z,printsym1_inv
		exx
		ld e,a
		or a
		rra
		or e
		exx
printsym1_inv
		bit 0,c				;�������� ������ ��������
		jr z,printsym1_bold
		cpl					;����������� ���� ���� ����� �������
printsym1_bold
		bit 1,c				;�������� ������ ���������
		jr z,printsym1_over
		xor (hl)
printsym1_over	
		ld (hl),a
		inc de
		inc h
		djnz printsym1
		pop hl
		push hl
		ld a,h    ;��������
		and #18
		rrca
		rrca
		rrca
		add a,#58
		ld h,a
		ld a,(color_attr)
		ld (hl),a
		pop hl
		inc l
		jr nz,printsym2
		ld a,h
		add a,8
		ld h,a
		cp #58
		jr c,printsym2
		ld h,#40    
printsym2
		ld (pos_at),hl
		pop hl
		pop de
		pop bc
		ret

;������ ����������� �����|������ �� 90 �������� �������
;� - ��� �������
;pos_at - ����� ������� ������
printverticalsym 
		push bc
		push de
		push hl
		ld de,(font)
		ld h,0
		ld l,a
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,de
		ex de,hl
		ld a,(print_parametr)
		ld c,a
		ld b,8
		ld hl,temp_sym
		push hl
printverticalsym_1
		ld a,(de)
		bit 3,c
		jr z,printverticalsym_2
		exx
		ld e,a
		and a
		rra
		or e
		exx
printverticalsym_2
		bit 0,c
		jr z,printverticalsym_2_1
		cpl
printverticalsym_2_1
		ld lx,8
		push hl
printverticalsym_3
		and a
		bit 2,c
		jr z,printverticalsym_4
		rla
		rr	(hl)
		jr printverticalsym_5
printverticalsym_4
		rra
		rl (hl)
printverticalsym_5		
		inc hl
		dec lx
		jr nz,printverticalsym_3
		pop hl
		inc de
		djnz printverticalsym_1
		pop de
		ld hl,(pos_at)
		ld b,8
		push hl
printverticalsym_6
		ld a,(de)
		bit 1,c
		jr z,printverticalsym_7
		xor (hl)
printverticalsym_7
		ld (hl),a
		inc de
		inc h
		djnz printverticalsym_6
		pop hl
		push hl
		ld a,h    ;��������
		and #18
		rrca
		rrca
		rrca
		add a,#58
		ld h,a
		ld a,(color_attr)
		ld (hl),a
		pop hl
		bit 2,c
		jr nz,printverticalsym_7_1
		ld a,l
		sub 32
		ld l,a
		jr nc,printverticalsym_8
		ld a,h
		sub 8
		ld h,a
		cp #40
		jr nc,printverticalsym_8
		ld h,#50
		inc l
		jr nz,printverticalsym_8
		ld l,#e0
		jr printverticalsym_8
printverticalsym_7_1
		ld a,32
		add a,l
		ld l,a
		jr nc,printverticalsym_8
		ld a,h
		add a,8
		ld h,a
		cp #58
		jr c,printverticalsym_8
		ld h,#40
		dec l
		ld a,l
		cp 255
		jr c,printverticalsym_8
		ld l,31
printverticalsym_8
		ld (pos_at),hl
printverticalsym_exit
		pop hl
		pop de
		pop bc
		ret
		
;������� ������ - ��������� ������� ���������
;����� �������� ������� ���������� �������� �������� � color_attr
clrscr
		ld hl,#4000
		ld (pos_at),hl
		ld (hl),0
		ld d,h
		ld e,l
		inc de
		ld bc,6144
		ldir
		ld a,(color_attr)
		ld (hl),a
		ld bc,767
		ldir
		ret

;������ ����� � ������������ ���������:
;12 - ������ ������������ + 2 ����� (����� ������)
;13 - ���������� ������ + 1 ����
;14 - ������� ������ + 1 ����, 
;15 - ����������� ������ (����� �����, ������ ����) + 1 ����, 
;16 - ���� ������ + 1 ����, 
;17 - ���� ������ + 1 ����,
;18 - ����� ������� (flash) + 1 ����
;19 - ����� ���������� ������� (bright) + 1 ����
;20 - ����� �������� (inverse)+ 1 ����,
;21 - ����� ��������� (over) + 1 ����,
;22 - ������� ������ + 2 �����, 
;� hl ����� ������, ����� ������ - 0
print
		ld a,(print_parametr)
		ld c,a
		ld a,(hl)          	;����� ��� ������� �� ������ (� hl - ����� ������ (��������� �� ������))
							;� �������� � a
		inc hl				;���������� ��������� �� ��������� ������ � ������
		or a				;���� ������� ��� ������� 0, 
		ret z				;�� �������, �.�. 0 ������ ����� ������
		cp 12			   	;�������� �� ����������� ���:
		jr c,print_unknow	;��� �����������, ���� �� 12 � ������,
		cp 23 				;�� �� ������ 22
		jr nc,print1
		sub 12				;�� ������������ ���� �������� 13 
							;� �������� ���������� ����� ��������� � ������� ������� ��������
							;��������� ����������� �����
		add a,a				;�������� ���� ����� �� 2 (����� ��������� �� 2 ����)
		ld de,print			;������� � ���� ����� �������� �� ������������ ��������� ������������ ����
		push de				;������ � ����� ������ ����������� ���������� ������������ ������
		ld d,0				;� de �������� � ������� ����������� ����������� �����
		ld e,a
		push hl				;���������� ��������� �� ��������� ������ � ������
		ld hl,table_at_procedure	;� hl ����� (���������) ������� (�� �������) � �������� �������� ��������� ����������� �����
		add hl,de			;��������� � de, �������� �� �������
		ld e,(hl)			;� e ������� ���� ������ ��������� ��������� ������������ ����
		inc hl				;����������
		ld d,(hl) 			;� d ������� ���� ������ ��������� ��������� ������������ ����
		ex de,hl	;����� -> � hl ����� ��������� ��������� ���������������� ������������ ����
		ex (sp),hl  ;����� -> � ���� ����� ���������, � � hl ����� ����������� �������� hl 
					;(��������� �� ��������� ������ � ������)
		ret			;������� �� ������������ ��������� ������������ ����
					;��� ���������� ret ���������� ���������� �������, ������������� �� ������, ������������
					;�� �����, � ����� �� �������� �� ������� ����� ����� ��������� ��������� ������������ ����
print1  
		cp 32				;�������� �� ��� ������� ������ 32
		jr c,print_unknow
print2
		bit 4,c
		jr z,print3
		call printverticalsym
		jr print
print3
		call printsym		;����� ������������ ������ ������� �� �
		jr print			;������� � �������� ���������� ������� � ������
print_unknow 				;��� ������� ������ 32 
		ld a,"?"			;�������� �� ��� ����� �������
		jr print2

;��������� ������������ ���� ����� ������� ������
print_at22
		push bc
		ld b,(hl)
		inc hl
		ld c,(hl)
		inc hl
		ld a,c	;������ �� ������ ��� ��������� ������� ������: 
		cp 32   ;������� 0...31 
		jr nc,print_at22_1
		ld a,b
		cp 24   ;������ 0...23 
		jr nc,print_at22_1
		and #18
		or #40
		ld d,a
		ld a,b
		and #07
		rrca
		rrca
		rrca
		add a,c
		ld e,a
		ld (pos_at),de
print_at22_1
		pop bc
		ret
;����������� ������ (����� �����, ������ ����)
print_at15
		ld d,PRINT_UTD_MSK
		ld e,2
print_at15_1
		ld a,(hl)
		inc hl
print_at15_2
		or a
		jr z,print_at15_3
		ld a,1
print_at15_2_1
		inc e
		dec e
		jr z,print_at15_3
		rla
		dec e
		jr print_at15_2_1
print_at15_3
		ld e,a
		ld a,d
		cpl
		and e
		ld e,a
		ld a,(print_parametr)
		and d
		or e
		ld (print_parametr),a
		ret
;���������� ������: ������������ ��� ��������������
print_at13
		ld d,PRINT_VERT_MSK
		ld e,4
		jr print_at15_1
;������ ������������ (���������������� ������� ���������� ������� � 48 ����, �.�. "0" - ����)
print_at12
		ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ld a,d
		or e
		ld a,(print_parametr)
		jr nz,print_at12_1
		res 5,a
		ld (print_parametr),a
		push hl
		ld hl,font_data
		jr print_at12_2
print_at12_1
		set 5,a
		ld (print_parametr),a
		push hl
		ex de,hl
		ld de,-8*48
		add hl,de
print_at12_2
		ld (font),hl
		pop hl
		ret
;������� ������
print_at14
		ld d,PRINT_BFNT_MSK
		ld e,3
		jr print_at15_1
;�������� (inverse)
print_at20
		ld d,PRINT_INV_MSK
		ld e,0
		jr print_at15_1
;��������� (over)
print_at21
		ld d,PRINT_OVR_MSK
		ld e,1
		jr print_at15_1
;�������
print_at16 
		ld d,PRINT_INK_MSK
		ld e,0
print_at16_1
		ld a,(hl)
		inc hl
print_at16_2
		inc e
		dec e
		jr z,print_at16_3
		rla
		dec e
		jr print_at16_2
print_at16_3
		ld e,a
		ld a,d
		cpl
		and e
		ld e,a
		ld a,(color_attr)
		and d
		or e
		ld (color_attr),a
		ret
;������ 
print_at17
		ld d,PRINT_PAP_MSK
		ld e,3
		jr print_at16_1
;�������
print_at18
		ld d,PRINT_FLH_MSK
		ld e,7
		jr print_at16_1
;�������
print_at19
		ld d,PRINT_BRT_MSK
		ld e,6
		jr print_at16_1		
;���������� ����� ������ ������� (���������� contour_check_at)
;hl - ����� ������ � ������� ��������� (�������)
check_contour
		exx
		push hl
		exx
check_contour1
		exx
		ld de,32
		add hl,de
		exx
		call block_check
		or a
		jr z,check_contour1
		exx
		ld de,-32
		add hl,de
		ld (contour_check_at),hl
		pop hl
		exx
		ret

;�������/������� ������ ������
;hl - ������� ������� ��� �' != 0, � - ��������
;c' = 0 - �������, c' != 0 - �������
print_contour
		ld a,(stakan_vodka_color)
		exx
		inc c
		dec c
		exx
		jr z,print_contour1
		and %11111000
		ld c,a
		cpl
		rra
		rra
		rra
		and %00000111
		or c
print_contour1
		ld c,a
		push bc
		push hl
		exx
		push bc
		push hl
		inc c
		dec c
		exx
		jr z,print_contour2
		ld hl,(contour_check_at)
		ld (contour_pos),hl
print_contour2
		ld hl,(contour_pos)
		ld a,h
		or l
		jr z,print_contour4
		exx
		ld de,contour
		ld a,(contour_shift)
		inc c
		dec c
		jr z,print_contour3
		ld b,a
		add a,a
		add a,a
		add a,a
		add a,e
		ld e,a
		ld a,b
		jr nc,print_contour2_1
		inc d
print_contour2_1
		inc a
		cp 4
		jr c,print_contour3_1
		xor a
print_contour3_1
		ld (contour_shift),a
print_contour3
		push de
		pop ix
		exx
		ld de,fig
		call block_output_kirpich
		exx
		inc c
		dec c
		exx
		jr nz,print_contour4
		ld hl,0
		ld (contour_pos),hl
print_contour4
		exx
		pop hl
		pop bc
		exx
		pop hl
		pop bc
		ret
;�������� ������� �������/���������� ������������ ������� ������ � �������, ����� ������� � hl
;�� ������ ���� �������� �������, ���� �������/���������� ������, ����� ����������
inputkey
		ld a,(hl)
		or a
		jr nz,inputkey1
inputkey0
		scf
		ret
inputkey1
		in a,(#fe)
		inc hl
		cpl
		and 31
		cp (hl)
		jr nz,inputkey0
		inc hl
		ld a,(hl)
		or a
		jr nz,inputkey1
		scf
		ccf
		ret
; �������� ������� ��� ���������� ������ � ��������
; � ���. IX - ����� ���� ��������� ����� � ������ � ������ ���������� ��� ���������������� ��������
; � ����� ���������� ������ ��� �������� �������� ������ �� 8 ������, 
; �.�. 1 �������� ����� ���� ������ �������� �� 40 ������ ������������ (� ������ ��, �� �� �������� �����������,
; �.�. ��� ����� �������� ������� ����� 1 ��������)
definekeys
		push ix
		pop hl
		ld b,16
definekeys0
		ld (hl),0
		inc hl
		djnz definekeys0
		ei
		ld b,10
definekeys0_1		;����������� ����� ~200��
		halt
		djnz definekeys0_1
definekeys1
		xor a		;��������: ������ ��
		in a,(#fe)	;���� �� ���� �������?
		cpl
		and 31
		jr z,definekeys1	;����, ���� �� ������ �������
		halt 				;����������� ����� ~20�� ��� ��������� ������� ���������� ������ � ���������� "��������" ��� ����
		ld b,8
		ld d,0
		ld e,#fe
definekeys2
		ld a,e
		in a,(#fe)
		cpl
		and 31
		jr z,definekeys3
		ld (ix),e		;���������� ������� ������ ������ �����
		ld (ix+1),a		;���������� ��������� ���
		inc d
		ld a,8			;�������� ������� ����� ���� ������ ������������ �� 8 ������
		cp d			;���� �������� ����� ���������, �� �������
		ret z
		inc ix
		inc ix
definekeys3
		sll e			;��������� ���� ���������� (���������� ������������� � 0 ���� �������� ������� ������ �����)
		djnz definekeys2
		ret
;��������� ������ ������ ����������
select_keys
		xor a
		ld (color_attr),a
		call clrscr
		ld hl,define_keys_txt
		call print
		ld hl,select_keys_table
select_keys1
		ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ld a,d
		or e
		jr nz,select_keys1_1
		jp screen_off
select_keys1_1
		ld c,(hl)
		inc hl
		ld b,(hl)
		inc hl
		push hl
		push bc
		push de
		pop ix
		call running_line
		pop ix
select_keys2
		call definekeys
		inc d				;�� ���� ������� �� ������?
		dec d
		jr z,select_keys2
		ld hl,okey_txt
		call print
		pop hl
		jr select_keys1
;��������� ���� ������/����� �� �������
;bc - ������� ����� ���������� ���� (row,col)
;de - ������ � ������ ���� (height,width)
;��� 7 ���. b ����������, ���� ��������� ������, ������� - ��������� �����
window_scroll_rtlt
		ld a,b
		and #18
		or #40
		ld h,a
		ld a,b
		and #07
		rrca
		rrca
		rrca
		add a,c
		bit 7,b
		jr nz,window_scroll_rtlt1 ;��������� ������?
		add a,e
		dec a
window_scroll_rtlt1
		ld l,a
		ld a,d
		or a
		rla
		rla
		rla
		ld d,a ;������� ����� ���������� (������ �������� �� 8)
window_scroll_rtlt2
		push hl
		ld c,e
		or a
window_scroll_rtlt3
		bit 7,b
		jr z,window_scroll_rtlt4
		rr (hl)
		inc hl
		jr window_scroll_rtlt5
window_scroll_rtlt4
		rl (hl)
		dec hl
window_scroll_rtlt5		
		dec c
		jr nz,window_scroll_rtlt3
		pop hl
		inc h
		ld a,h
		and #07
		jr nz,window_scroll_rtlt6
		ld a,l
		add a,32
		ld l,a
		jr c,window_scroll_rtlt6
        ld a,h
		sub #08
        ld h,a
window_scroll_rtlt6
		dec d
		jr nz,window_scroll_rtlt2
		ret

;������� ������
;ix - ����� ����� ������ ������
;�������� � ����� ��� ������:
;0,1 - ������� ����� ���������� ���� (row,col)
;2,3 - ������ � ������ ���� (height,width)
;4,5 - ����� ������ � �������
running_line
		ld a,(ix)
		and #18
		or #40
		ld h,a
		ld a,(ix)
		and #07
		rrca
		rrca
		rrca
		add a,(ix+1)
		add a,(ix+3)
		dec a
		ld l,a
		ld (running_addr_scr),hl
		ld l,(ix+4)  ;� hl ����� ������ � �������
		ld h,(ix+5)
running_line_s
		ld a,(hl)
		inc hl
		or a
		ret z      ;0 - ����� ������
		cp 12
		jr c,running_line_unknow
		cp 23
		jr nc,running_line_s1
		sub 12
		add a,a
		ld de,running_line_s
		push de
		ld d,0
		ld e,a
		push hl
		ld hl,table_at_procedure
		add hl,de
		ld e,(hl)
		inc hl
		ld d,(hl)
		ex de,hl
		ex (sp),hl
		ret
running_line_unknow
		ld a,"."
running_line_s1
		push hl
		ld l,a
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		ld de,(font)
		add hl,de
		ld de,tmp_sym
		push de
		ld a,(print_parametr)
		ld c,a
		ld b,8
running_line0
		ld a,(hl)
		bit 3,c				;���������� �����?
		jr z,running_line0_1
		exx
		ld e,a
		and a
		rra
		or e
		exx
running_line0_1
		bit 0,c				;�������� �������?
		jr z,running_line0_2
		cpl
running_line0_2		
		ld (de),a
		inc hl
		inc de
		djnz running_line0
		pop de
		ld b,8
		exx
		ld b,0
		exx
running_line1
		exx
		inc b
		dec b
		jr nz,running_line1_1
		halt
		ld b,2
running_line1_1
		dec b
		exx
		push bc
		push de		
		ld b,(ix)
		ld c,(ix+1)
		res 0,b
		ld d,(ix+2)
		ld e,(ix+3)
		call window_scroll_rtlt
		pop de
		ld b,8
		ld hl,(running_addr_scr)
		push de
running_line2
		ld a,(de)
		or a
		rla
		ld (de),a
		jr nc,running_line3
		set 0,(hl)
running_line3
		inc de
		inc h
		djnz running_line2
		pop de
		pop bc
		djnz running_line1	
		dec h ;���������� �������� (1 ��� �� 8 �������)
		ld a,h
		and #18
		rrca
		rrca
		rrca
		add a,#58
		ld h,a
		push hl
		ld a,l
		inc a
		ld c,(ix+3)
		sub c
		ld e,a
		inc a
		ld l,a
		ld d,h
		xor a
		ld b,a
		or c
		jr z,running_line4
		ldir
running_line4
		pop hl
		ld a,(color_attr)
		ld (hl),a
		pop hl
		jp running_line_s

;���������� � BC ����� ������, ����� ������� � HL
strlen
		ld bc,0
strlen1
		ld a,(hl)
		or a
		ret z
		inc bc
		inc hl
		jr strlen1
define_keys_txt
		db 22,3,8,16,6,17,0,14,0,19,1,"����� ����������",19,0
		db 22,21,2,16,6,"1996, 2022 VadSoft, VadRov"
		db 22,22,7,12
		dw dzen
		db 16,7,17,0
		db "01",12
		dw 0
		db 16,7,"dzen.ru/vadrov"
		db 22,23,4,12
		dw youtube
		db 16,2,17,0,"0",16,7,17,2,"1",16,2,17,0,"2",12
		dw 0
		db 16,7,"youtube.com/@VadRov",0
key_left_txt
		db 22, 6,2,16,6,17,0," �������� �����",19,1," �����  ",19,0,22,6,26,0	
key_right_txt
		db 22, 8,2,16,6,17,0," �������� �����",19,1," ������ ",19,0,22,8,26,0	
key_rotate_txt
		db 22,10,2,16,6,17,0,19,1," ��������",19,0," �����        ",22,10,26,0	
key_drop_txt
		db 22,12,2,16,6,17,0,19,1," ������",19,0," ����� �� ���   ",22,12,26,0	
key_pause_txt
		db 22,14,2,16,6,17,0,19,1," �����",19,0," � ����          ",22,14,26,0
okey_txt
		db 16,4,17,0,"OK",14,0,0
key_left_run
		db 6,2,1,23
		dw key_left_txt
key_right_run
		db 8,2,1,23
		dw key_right_txt
key_rotate_run
		db 10,2,1,23
		dw key_rotate_txt
key_drop_run
		db 12,2,1,23
		dw key_drop_txt
key_pause_run
		db 14,2,1,23
		dw key_pause_txt
select_keys_table
		dw key_left_run,key_left,key_right_run,key_right,key_rotate_run,key_rotate,key_drop_run,key_drop,key_pause_run,key_pause,0
;������ �������� ��������
sndfx1	db 1,3,2,3,4,3,5,3,7,3,8,3,255 ; ������������ ������
sndfx2	db 40,7,50,8,60,9,70,10,80,11,90,12,255; ���������� ������� ������
sndfx3	db 60,3,50,3,40,3,30,3,20,3,10,3,255 ; �������� ������
sndfx4	db 1,40,5,200,5,0,50,5,200,5,1,60,5,200,5,1,70,5,200,5,1,80,5,200,5,190,255; �������� ����������� �����
interface_string
		db 22,0,24,16,1,17,6, " ����� "
		db 22,7,24,16,0,17,4, " ����� "
		db 22,10,24,16,1,17,6," ����  "
		db 22,13,24,16,1,17,6," ����� "
		db 22,16,24,16,0,17,4,"�������"
		db 22,19,24,16,6,17,1,"������ "
		db 22,22,24,16,6,17,1," ����� "
		db 22,0,0,16,1,17,4,"����������",0
vadsoft_txt
		db 22,23,10,14,0,15,0,19,1,16,6,17,0,13,1,"1996,2020 VadSoft,VadRov"
		db 22,1,23,14,0,15,1,19,1,13,1,12
		dw youtube
		db 16,2,17,0,"0",16,7,17,2,"1",16,2,17,0,"2",12
		dw 0
		db 16,6,17,0,"youtube.com/@VadRov"
		db 21,0,19,0,14,0,13,0,0
time_at
		db 22,8,25,16,7,17,0,0
time_at_razdel
		db 22,8,27,16,7,17,0,0
score_at 
		db 22,11,25,16,7,17,0,0
lines_at 
		db 22,14,25,16,7,17,0,0
level_at 
		db 22,17,25,16,7,17,0,0
hiscore_at
		db 22,20,25,16,2,17,0,0
intime_at
		db 22,23,25,16,2,17,0,0
;������ ����� 
;��� ����������: ������ ��� 0, ������ - ������� �������, ������ - ������� �������, ��������� - 0
figures	
		;O
		db %01100110
        ;I
        db %11110000
        ;S
        db %00110110
        ;Z
        db %01100011
        ;L
        db %01110100
        ;J
        db %01110001
		;T
        db %01110010

game_graph
		db %10100101
		db %11111010
		db %11110101
		db %11001010
		db %11100101
		db %11111010
		db %11110101
		db %10001010
		
		db %10100101
		db %01011111		
		db %10101111
		db %01010011
		db %10100111
		db %01011111
		db %10101111
		db %01010001
		
kirpich
		db %00000000  
		db %01111110
		db %01000000
		db %01000010
		db %01000010
		db %01000010
		db %01011110
		db %00000000
youtube
		db %00011111
		db %00111111
		db %00111111
		db %00111111
		db %00111111
		db %00111111
		db %00111111
		db %00011111

		db %00000000
		db %01100000
		db %01111000
		db %01111110
		db %01111110
		db %01111000
		db %01100000
		db %00000000
		
		db %11111000
		db %11111100
		db %11111100
		db %11111100
		db %11111100
		db %11111100
		db %11111100
		db %11111000
dzen
		db %00000001
		db %00000001
		db %00000111
		db %00111111
		db %00000111
		db %00000001
		db %00000001
		db %00000000
		db %00000000
		db %00000000
		db %11000000
		db %11111000
		db %11000000
		db %00000000
		db %00000000
		db %00000000
contour
		db %10001000  
		db %00000001
		db %00000000
		db %00000000
		db %10000000
		db %00000001
		db %00000000
		db %01000100
		
		db %01000100  
		db %00000000
		db %00000001
		db %10000000
		db %00000000
		db %00000000
		db %00000001
		db %10001000
		
		db %00100010  
		db %00000000
		db %10000000
		db %00000001
		db %00000000
		db %00000000
		db %10000000
		db %00010001
		
		db %00010001  
		db %10000000
		db %00000000
		db %00000000
		db %00000001
		db %10000000
		db %00000000
		db %00100010
stat_at 
		db 22,0,6,16,7,17,0,0
stat_alls 
		db 22,23,0,16,7,17,0,"�����:",0
stakan_data1
		db 22,0,11,16,1,17,0,19,1,12
		dw game_graph
		db "0",12
		dw 0
		db "          ",12
		dw game_graph
		db "1",12
		dw 0
		db 0
kirpich_clear 
		db 0,0,0,0,0,0,0,0
time_dat_cursor
		db #7c,#2f,#2d,#5c
table 	
		dw 10000,1000,100,10,1
table_at_procedure
		dw print_at12,print_at13,print_at14,print_at15,print_at16,print_at17,print_at18,print_at19,print_at20,print_at21,print_at22
font_data
		BINARY "font8x8.bin"
contour_check_at	ds 2
contour_pos 		ds 2
contour_shift 		ds 1

;���� ������������ ����		
config 	ds 1

;�������� � ������� ��������� ������ ZX
color_attr ds 1
stakan_vodka_color ds 1

;��������� ������ ��������:
;��� 0 - �������� (inverse)
;��� 1 - ��������� (over)
;��� 2 - ������� �� 90 �������� 0 - �����, 1 - ������
;��� 3 - ������� ������ 0 - �������, 1 - ���������
;��� 4 - ������ ����� ����� ������� - 0; 1 - ������ ���� (��� ��� 2 = 1) ���� ����� ����� (��� ��� 2 = 0)
;��� 5 - ������� ������������ 1 - ���., 0 - ����.
print_parametr ds 1

fig		ds 4
next_fig ds 4
tmp_fig ds 4
statistics_fig ds 14 

attr	ds 1
next_attr ds 1      

reg		ds 1

lines	ds 2
level 	ds 1

score	ds 2
hiscore ds 2
in_time ds 2

inkey 	ds 1
slip_inkey ds 1
slip_count ds 1

tick	ds 1
sec		ds 1
min		ds 1

pos_at	ds 2

addr	ds 2          ; ��������� ����� ����� ������
curadd  ds 2          ; ������� ����� � ����� ������
count   ds 1          ; ���������� ����������
flag    ds 1          ; ���� ���/���
font	dw font_data

time_dat_counter	ds 1
time_update_counter	ds 1
block_element_addr 	ds 2
lines_table			ds 8
flag_update			ds 1
drop_flag 			ds 1
mig					ds 1
temp_sym ds 8
running_addr_scr
		ds 2
tmp_sym
		ds 8
key_rotate
		ds 16
key_left
		ds 16
key_right
		ds 16
key_drop
		ds 16
key_pause
		ds 16
end
		display "Size ",/d,end-tetris," bytes"
 
		savebin "tetris.bin",tetris,end-tetris
		savesna "tetris.sna",tetris