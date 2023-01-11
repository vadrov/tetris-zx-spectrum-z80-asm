;1996 RoVadSoft - Tetris
;2020 Адаптировано для кроссассемблера тем же автором, но под ником VadRov 
; Мини-Тетрис для ZX-Spectrum 
		device zxspectrum48

PRINT_INV_MSK 	equ %11111110 ;битовая маска режима инверсии
PRINT_OVR_MSK 	equ %11111101 ;битовая маска режима наложения
PRINT_UTD_MSK 	equ %11111011 ;битовая маска режима печати
PRINT_BFNT_MSK 	equ %11110111 ;битовая маска толщины шрифта
PRINT_VERT_MSK 	equ %11101111 ;битовая маска типа строки
PRINT_UDG_MSK 	equ %11011111 ;битовая маска режима UDG (символы пользователя)

PRINT_INK_MSK	equ %11111000 ;битовая маска чернил
PRINT_PAP_MSK	equ %11000111 ;битовая маска бумаги
PRINT_BRT_MSK	equ %10111111 ;битовая маска яркости
PRINT_FLH_MSK	equ %01111111 ;битовая маска мигания
		org 50000
tetris
		di
		ld sp,49999
		;вход начальная инициализация
		ld hl,0			;инициализация счетчика максимальных очков  
		ld (hiscore),hl
		ld (in_time),hl	;инициализация времени лучшей игры
		;байт конфигурации:
		;бит 7 - звуковые эффекты 1 - вкл./0 - выкл.
		;бит 6 - цвет фигур: 1 - разноцветные/0 - одноцветные
		;бит 5 - режим "одной фигуры" 1 - вкл./0 - выкл., 
		;бит 4 - контур фигуры на дне стакана 1 - вкл./0 - выкл.
		;бит 3 - текстура на блоках 1 - вкл./0 - выкл. (при 0 недоступен контур)
		;биты 2,1,0 - определяют номер фигуры из блока figures для режима "одной фигуры"
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

;вход новая игра
newgame	
		call inter_init  	;инициализация режима прерывания 2 обеспечивающего:
							;- звуковые эффекты, 
							;- опрос управляющих клавиш,
							;- таймер (секундомер)
		ld hl,0			
		ld (score),hl	;инициализация счетчика очков для новой игры 
		ld (lines),hl	;инициализация заполненных линий
		ld a,0	;инициализация текущих атрибутов экрана
		ld (color_attr),a
		ld (stakan_vodka_color),a ;желательно, чтобы цвет "бумаги" и "чернил" совпадали
		rra             ;бордюр в цвет фона экрана
		rra
		rra
		and 7
		out (#fe),a
		call clrscr		;очистка экрана	
		call stakan		;отрисовка стакана		
		ld hl,interface_string ;надписи на экране
		call print
		call prn_best_result 	;печать лучшего результата в игре
		call figure_list		;вывод списка фигур
		ld hl,statistics_fig	;инициализация статистики появления фигур
		ld (hl),0
		ld de,statistics_fig+1
		ld bc,14-1
		ldir
		ld de,fig		;распаковка текущей псевдослучайной фигуры в буфер
		call copyfig
		call rotation_fig_rnd  ;поворот фигруы на псевдослучайное число оборотов
		ld a,c			;атрибуты текущей фигуры
		ld (attr),a
		xor a			
		ld (tick),a		;инициализация таймера
		ld (sec),a
		ld (min),a
		ld (contour_shift),a ;инициализация смещения для контура фигуры внизу стакана
		inc a
		ld (level),a	;инициализация уровня игры
		call time1		;вывод текущего времени игры (00:00)
;новая фигура
newfig
		ld hl,0
		ld (contour_pos),hl ;инициализация положения контура фигуры на дне стакана
		call figure_statictics	;вывод статистики по фигурам
		ld iy,stakan_vodka_color
		call lines_clear 	;проверка и удаление заполненных рядов в стакане 
							;(на выходе в a' количество заполненных линий)
		call scoreupdate	;обновление очков игры
		call prnscore	;вывод очков игры
		call levupd		;расчет уровня (скорости игры)
		ld de,next_fig  ;распаковка следующей псевдослучайной фигуры в буфер
		call copyfig
		call rotation_fig_rnd ;поворот следующей фигуры на rnd оборотов
		ld a,c			;атрибуты следующей фигуры
		ld (next_attr),a
		ld hl,#5800+2*32+25 ;вывод на экран следующей фигуры
		ld de,next_fig
		call block_output_var
		ld a,(attr)
		ld b,a	        ;в b - атрибуты текущей фигуры
		ld hl,#5800+0*32+15	;адрес начальной позиция текущей фигуры в области атрибутов
		push hl
		exx 
		pop hl
		exx
		xor a
		call saveloadfig	;делаем копию фигуры во вспомогательном буфере
newfig0
		call block_check    ;проверка: можно ли выводить фигуру в новых координатах?
		or a
		jp z,newfig1	
		ld de,#5800+0*32+15 ;конец игры, если вывод фигуры невозможен в начальной позиции
		ex de,hl
		and a
		sbc hl,de
		ex de,hl
		jr nz,newfig0_
		ld hl,(hiscore)	;обновление максимального счета игры, если текущий счет был больше
		ld de,(score)
		and a
		sbc hl,de
		jr nc,gameover
		ld (hiscore),de
		ld hl,in_time
		ld bc,(sec)
		ld (hl),c ;секунды
		inc hl
		ld (hl),b ;минуты
gameover
		call inter_deinit ;включение стандартных прерываний спектрума
		call screen_off
		jp newgame
newfig0_					;блок на дне
		push hl
		ld hl,sndfx1		;звук фигуры, упавшей на дно
		ld a,1
		call newfx
		pop hl
		exx						
		ld c,0
		exx
		ld a,(config)
		bit 4,a
		call nz,print_contour	;стираем контур
		ld c,b
		call block_output		;обновляем блок
		;стирание следующей фигуры
		ld hl,#5800+2*32+25
		ld de,next_fig
		ld c,(iy)
		call block_output_var
		;следующую фигуру делаем текущей
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
		;цикл задержки, в процессе которого опрашивается клавиатура
		;и задается положение фигуры в соответствии с управляющим воздействием
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
		ld a,(slip_inkey) ;проверяем на "залипщие" клавищи
		or a
		jr z,newfig3_1    ;"залипаний" нет
		ld a,(inkey)
		bit 0,a			  ;запрещаем "залипать" клавише управления вращением фигуры 
		jr z,newfig2_1
		bit 2,a			  ;запрещаем "залипать" клавише управления паузой в игре
		jr z,newfig2_1
		bit 4,a			  ;запрещаем "залипать" клавише управления ускоренным падением фигуры 
		jr z,newfig2_1
		ld a,(slip_count) ;остальным клавишам управления разрешаем "залипать", 
		cp 4			  ;но с заданным периодом повтора нажатия
		jr c,newfig2_1
		xor a			  ;сбрасываем счетчик "залипания"
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
;плавное "выключение" экрана
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
;обновление фигуры на экране
block_update
		ld a,(flag_update)  ;проверяем флаг обновления
		or a
		ret nz
		inc a
		ld (flag_update),a
		call figure_reset 	;стираем фигуру
		exx
		push hl
		exx
		pop hl
		ld a,1	;копируем фигуру в основной буфер из вспомогательного
		call saveloadfig
		call figure_set 	;выводим фигуру
		ret

;вращение
rotate
		push af
		ld de,tmp_fig
		call rotfig			;вращаем фигуру
		call block_check	;проверяем возможность вывода
		or a				
		jr nz,rotate1   	;вывод невозможен
rotate0						;вращение успешно 
		push hl             ;выдаем звуковой эффект и обновляем фигуру на экране дальше по коду
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
		xor a				;при невозможности вывода фигуры после вращения
		call saveloadfig	;восстанавливаем фигуру во временном буфере из буфера текущей фигуры
		jr rotate0_1
;движение фигуры вправо
right
		push af
		exx
		inc hl
		exx
		call block_check	;проверяем возможность вывода
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
;движение фигуры влево
left
		push af
		exx
		dec hl
		exx
		call block_check	;проверяем возможность вывода
		or a
		jr z,right2
		exx
		inc hl
		exx
		jr right1
		
;ускоренное движение фигуры вниз
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
		call block_check	;проверяем возможность вывода
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
	
;пауза в игре
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
pause2				;ожидание нажатия любой клавиши
		xor a		;старщий байт адреса сброшен в 0 (выбраны все полуряды)
		in a,(#fe)
		cpl
		and 31
		jr z,pause2
		pop bc
		pop af
		ei
		ret
		
;выводит фигуру и контур
figure_set
		;вывод контура фигуры внизу стакана
		exx
		ld c,1
		exx
		ld a,(config)
		bit 4,a
		call nz,print_contour
		;вывод фигуры
		ld c,b
		call block_output
		ret
		
;стирает фигуру и контур		
figure_reset
		;стирание контура фигуры
		exx
		ld c,0
		exx
		ld a,(config)
		bit 4,a
		call nz,print_contour
		;стирание фигуры
		ld c,(iy)
		call block_output
		ret
		
;пересчет заполненных линий
;пересчет очков в зависимости от количества заполненных линий
;количество новых линий в a'
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
		ld b,e			;начисление очков за заполнение линий по алгоритму:
		ld de,10		;1 линия - 10 очков
		ld hl,(score)	;2 линии - 25 очков
newfig_add_score		;3 линии - 45 очков
		add hl,de		;4 линии - 70 очков
		push hl
		ld hl,5
		add hl,de
		ex de,hl
		pop hl
		djnz newfig_add_score
		ld (score),hl
		ret
		
;выводит картинки фигур для статистики
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
		
;выводит статистику по фигурам
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

;опрос управляющих клавиш клавиатуры
;в d состояние клавиш управления(бит сброшен - клавиша нажата)
;0 бит - вращение 
;1 бит - вправо
;2 бит - пауза
;3 бит - влево
;4 бит - падение
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
		ld a,(inkey) ;проверка на залипшие клавиши
		cp d
		ld a,d
		jr z,keys1
		ld (inkey),a
		xor a
		ld (slip_inkey),a ;инициализируем флаг 
		ld (hl),a		  ;и счетчик залипания
		ret
keys1	
		ld a,1
		ld (slip_inkey),a
		inc (hl)          ;увеличиваем счетчик залипания
		ret		
; рассчитывает уровень игры в зависимости от количества заполненных линий
; уровень увеличивается через каждые 10 заполненных линий
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

;генерирует псевдослучайную фигуру и распаковывает ее в буфер по адресу в de
;на выходе в C атрибут фигуры (согласно настройки бита 6 конфигурации)
;работает с байтом конфигурации по адресу config:
;бит 6 - цвет фигур: 1 - разноцветные/0 - одноцветные,
;бит 5 - режим "одной фигуры" 1 - вкл./0 - выкл., 
;биты 2,1,0 - определяют номер фигуры из блока figures для режима "одной фигуры"
copyfig
		ld ix,config 	;адрес байта конфигурации
		ld a,(ix)		;в режиме одной фигуры номер фигуры биты 2,1,0
		ld c,7
		bit 5,a      	;проверка режима работы случайная/постоянная фигура
		jr z,copyfig0
		and c		 	;защита от дурака (номер фигуры только от 0 до 6)
		cp c
		jr nz,copyfig1
		xor a
		jr copyfig1
copyfig0
		ld a,r			;в а состояние регистра регенерации r
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
		;разноцветной/одноцветный режим
		cpl				;инвертируем биты
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
		rld			;Старшая тетрада (биты 7... 4) ячейки памяти hl переносится 
					;в младшую тетраду аккумулятора (биты 3...0), 
					;младшая тетрада аккумулятора переносится в младшую тетраду ячейки памяти, 
					;а младшая тетрада ячейки памяти — в старшую тетраду ячейки памяти
		ld (de),a
		inc de
		djnz copyfig3
		pop de
		ret
		
;ротация фигуры на псевдослучайное число оборотов
;адрес фигуры по адресу в de
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
;стакан
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

;вывод текущих очков игры
prnscore
		ld hl,score_at
		call print
		ld bc,(score)
		ld a,5
		jp print_dec
;вывод лучшего результата и времени, за которое он был достигнут
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
		call lines_check ;определяем количество заполненных строк и их адреса
		ex af,af'
		ld b,a
		ex af,af'
		inc b
		dec b
		ret z			;если заполненных строк нет, то уходим
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

;ищет заполненные линии стакана и записывает их адреса в table_str
;на выходе в a' количество заполненных линий
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

;убирает заполненные линии стакана
lines_clear
		call lines_light
		ex af,af'
		ld b,a
		ex af,af'
		inc b
		dec b
		ret z			;если заполненных строк нет, то уходим
   		ld a,b
		ld hl,sndfx4	;звук - удаление рядов
		call newfx
		ld ix,lines_table
		ld de,0
lines_clear1
		push bc
		push de
		ld l,(ix)		;в hl адрес заполненной строки
		inc ix
		ld h,(ix)
		inc ix
		add hl,de
		ld a,h			;по адресу определяем номер строки
		ld b,l			;номер и будет означать сколько раз сдвигать пробегать по строкам для сдвига
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

;поиск (до первого совпадения) в строке знакоместа с атрибутом в b', где учитывается только цвет "бумаги"
;если поиск успешен, то на выходе установлен флаг нуля Z, при этом в b обратный порядковый номер
;если арибут не найден, то флаг нуля на выходе сброшен
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
		ld c,2 ;сброс флага нуля
		dec c
		ret
		
;запоминает/восстанавливает в буфер/из буфера текущую фигуру
;a = 0 - запонимает, а отличное от 0 - восстанавливает
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

;вращение фигуры (адрес фигуры в de)
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
		
;проверка возможности вывода фигуры с адреса в hl'
;hl - текущая позиция (адрес) фигуры в области атрибутов
;hl' - предполагаемая позиция (адрес) фигуры в области атрибутов
;на выходе а = 0, если Ок, иначе а = 1
block_check
		ld de,fig       ;текущая фигура
		ld a,(stakan_vodka_color)
		and %00111000
		exx
		ld de,tmp_fig	;предполагаемая фигура
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
		;проверка на выход фигуры за пределы стакана
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
		;проверка на пустоту в квадрате стакана
		ld a,(hl)
		and %00111000
		cp c
		jr z,block_check5	;квадрат пустой
		call block_check_adr
		jr z,block_check5	;в квадрате часть от текущей фигуры
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
		
;вспомогательная процедура для block_check
;выясняет нет ли в знакоместе по адресу в hl элемента текущей фигуры
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
		jr z,block_check_adr4		;адреса совпали
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
		ld a,2					;для сброса флага нуля
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
		;квадрат не принадлежит фигуре
		jr block_check_adr3
block_check_adr5
		;квадрат принадлежит фигуре
		ld a,1					;для установки флага нуля
		jr block_check_adr3_1
		
;вывод фигуры
;hl - текущая позиция (адрес) фигуры в области атрибутов
;c - атрибут
block_output
		ld de,fig
block_output_var
		ld a,(stakan_vodka_color)
		and %00111000 ;при равенстве цвета фигуры и цвета пустоты в стакане будем удалять фигуру
		exx
		ld b,a
		exx
		ld a,c
		and %00111000
		exx
		cp b
		ld c,0		 ;c' - флаг удаления фигуры (0 - удаляем, 1 - выводим)
		jr z,block_output0
		ld c,1
block_output0
		exx
		ld ix,kirpich ;массив данных (8 байт), определяющие рисунок кирпича
block_output_kirpich
		exx
		inc c
		dec c
		exx
		jr nz,block_output_kirpich1
		ld ix,kirpich_clear ;рисунок кирпича "нулевой", если стираем блок/контур
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
		ld      (count),a  ; "заглушка"
		ret
; подключение прерываний
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
		ld a,24       ; код команды jr
		ld (65535),a
		ld a,195      ; код команды jp
		ld (65524),a
		ld hl,intr    ; hl=адрес обработчика
		ld (65525),hl
		ld hl,65024
		ld de,65025
		ld bc,256
		ld (hl),255   ; адрес прерывания - 65535
		ld a,h
		ldir               ; заполнение таблицы
		di
		ld i,a
		im 2
		ei
		ret
; отключение прерываний
inter_deinit    
		di
		ld a,63
		ld i,a
		im 1
		ei
		ret
; инициализация эффекта
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

intr     				;обработчик прерывания
		push af         ;сохранение регистров
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
		ld a,(count)  ; a=счетчик повторений
		or a          ; есть что играть ?
		jr z,exit
		ld hl,(curadd); hl=текущий адрес
next     
		ld a,(hl)
		inc hl
		cp 254        ; a=254 ? (начало цикла)
		jr nz,cont1
		ld (addr),hl  ; изменение начального адреса
		jr next
cont1    
		cp 255        ; a=255 ? (конец)
		jr nz,cont2
		ld hl,(addr)  ; восстановление начального
		ld (curadd),hl; адреса блока данных
		ld hl,count
		dec (hl)       ; уменьшение счетчика повторений
		jr test
cont2    
		or a          ; a=0 ? (переключатель)
		jr nz,cont3
		ld a,(flag)
		cpl                ; инвертирование a
		ld (flag),a
		jr next
cont3    
		ld b,a        ; b=частота
		ld c,(hl)     ; c=длительность
		inc hl
		ld (curadd),hl; сохранение текущего адреса
		ld a,(stakan_vodka_color)        ; a=цвет бордюра
		rra
		rra
		rra
		and 7
		ld e,a
		ld a,(flag)   ; a=флаг
		or a          ; a=0 ?
		ld a,e
		jr nz,noise
tone     
		xor 16         ; воспроизведение тона
		out (254),a
		push bc
		djnz $
		pop bc
		dec c
		jr nz,tone
		jr exit
noise    
		ld hl,100    ; воспроизведение шума
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
		call keys ;опрос управляющих клавиш
		call time ;секундомер
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
		
;секундомер
		;точка входа +1 тик и вывод времени игры 1 раз в секунду
time 
		ld hl,time_update_counter
		inc (hl)
		ld a,2
		cp (hl)
		call z,time3
time0
		ld hl,tick  ;1/50 секунды увеличиваем счетчик тиков 
		inc (hl)
		ld a,50
		cp (hl)
		ret nz
		ld (hl),0
		inc hl      ;через каждые 50 тиков увеличиваем счетчик секунд
		inc (hl)
		ld a,60
		cp (hl)		
		jr nz,time1
		ld (hl),0  
		inc hl      ;через каждые 60 секунд увеличиваем счетчик минут
		inc (hl)
		;точка входа в печать текущего отсчета игры
time1
		ld a,(color_attr) ;запоминание атрибутов печати
		push af
		ld hl,(pos_at) ; запоминание позиции печати
		push hl
		ld hl,time_at
		call print
		ld a,(min)
		ld c,a
		ld b,0
		ld a,128+2 ;будем выводить незначащие нули -> бит 7 в а установлен (часы в формате 00:00)
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
		pop hl				;восстановление позиции печати и атрибутов
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

; печать числа из bc с разрядностью до 5 степеней десятки (0...65535)
; в А флаг, определяющий:
; бит 7 - вывод незначащих нулей: 1 - выводить, 0 - не выводить
; биты 2,1,0 - количество разрядов (максимум - 5, минимум - 1)
print_dec
		push de
		push hl
		push bc
        ld hl,table
		ld c,a
		res 6,c
		and 7		;защита от дурака: разрядов минимум 1
		jr z,print_dec4
		cp 6		;разрядов максимум 5
		jr nc,print_dec4
		ld b,a
		ld a,5
		sub b
		add a,a
		ld e,a
		ld d,0
		add hl,de ;начальный адрес в таблице (в зависимости от разряда)
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
						  ;проверка на незначащие нули:
        ld d,b			  ;если разряд "единицы" - 0 печатаем в любом случае
		dec d
		jr z,print_dec3
		bit 7,c           ;проверка состояния флага вывода незначащих нулей:
		jr nz,print_dec3  ;их разрешено выводить -> выводим
		bit 6,c			  ;их запрещено выводить -> проверяем флаг вывода первой значащей цифры
		jr nz,print_dec3  ;первая значащая цифра уже выводилась -> печатаем цифру без проверки на 0		
		cp 48			  ;первая значащая цифра не выводилась - проверяем текущую цифру на 0
		jr z,print_dec3_1 ;текущая цифра незначащий 0 -> пропускаем его
		set 6,c			  ;первая значащая цифра -> установим флаг вывода первой значащей цифры
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
;печать символа
;а - код символа
;pos_at - адрес позиции печати
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
		bit 3,c				;проверка режима толстого шрифта
		jr z,printsym1_inv
		exx
		ld e,a
		or a
		rra
		or e
		exx
printsym1_inv
		bit 0,c				;проверка режима инверсии
		jr z,printsym1_bold
		cpl					;инвертируем биты если режим включен
printsym1_bold
		bit 1,c				;проверка режима наложения
		jr z,printsym1_over
		xor (hl)
printsym1_over	
		ld (hl),a
		inc de
		inc h
		djnz printsym1
		pop hl
		push hl
		ld a,h    ;атрибуты
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

;печать повернутого влево|вправо на 90 градусов символа
;а - код символа
;pos_at - адрес позиции печати
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
		ld a,h    ;атрибуты
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
		
;очистка экрана - установка текущих атрибутов
;перед очисткой следует установить желаемые атрибуты в color_attr
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

;печать строк с управляющими символами:
;12 - символ пользователя + 2 байта (адрес набора)
;13 - ориентация строки + 1 байт
;14 - толщина шрифта + 1 байт, 
;15 - направление шрифта (снизу вверх, сверху вниз) + 1 байт, 
;16 - цвет чернил + 1 байт, 
;17 - цвет бумаги + 1 байт,
;18 - режим мигания (flash) + 1 байт
;19 - режим повышенной яркости (bright) + 1 байт
;20 - режим инверсии (inverse)+ 1 байт,
;21 - режим наложения (over) + 1 байт,
;22 - позиция печати + 2 байта, 
;в hl адрес строки, конец строки - 0
print
		ld a,(print_parametr)
		ld c,a
		ld a,(hl)          	;берем код символа из строки (в hl - адрес строки (указатель на строку))
							;и помещаем в a
		inc hl				;перемещаем указатель на следующий символ в строке
		or a				;если текущий код символа 0, 
		ret z				;то выходим, т.к. 0 задает конец строки
		cp 12			   	;проверка на управляющий код:
		jr c,print_unknow	;код управляющий, если он 12 и больше,
		cp 23 				;но не больше 22
		jr nc,print1
		sub 12				;из управляющего кода вычитаем 13 
							;и получаем порядковый номер процедуры в таблице адресов процедур
							;обработки управляющих кодов
		add a,a				;умножаем этот номер на 2 (адрес процедуры из 2 байт)
		ld de,print			;заносим в стек адрес возврата из подпрограммы обработки управляющего кода
		push de				;именно с этого адреса продолжится выполнение подпрограммы печати
		ld d,0				;в de смещение в таблице подпрограмм управляющих кодов
		ld e,a
		push hl				;запоминаем указатель на следующий символ в строке
		ld hl,table_at_procedure	;в hl адрес (указатель) таблицы (на таблицу) с адресами процедур обработки управляющих кодов
		add hl,de			;суммируем с de, смещаясь по таблице
		ld e,(hl)			;в e младший байт адреса процедуры обработки управляющего кода
		inc hl				;перемещаем
		ld d,(hl) 			;в d старший байт адреса процедуры обработки управляющего кода
		ex de,hl	;обмен -> в hl адрес процедуры обработки соответствующего управляющего кода
		ex (sp),hl  ;обмен -> в стек адрес процедуры, а в hl ранее сохраненное значение hl 
					;(указатель на следующий символ в строке)
		ret			;переход на подпрограмму обработки управляющего кода
					;при выполнении ret управление передается команде, расположенной по адресу, извлекаемому
					;из стека, а ранее мы положили на вершину стека адрес процедуры обработки управляющего кода
print1  
		cp 32				;проверка на код символа меньше 32
		jr c,print_unknow
print2
		bit 4,c
		jr z,print3
		call printverticalsym
		jr print
print3
		call printsym		;вызов подпрограммы печати символа из а
		jr print			;возврат к проверке следующего символа в строке
print_unknow 				;код символа меньше 32 
		ld a,"?"			;заменяем на код знака вопроса
		jr print2

;обработка управляющего кода смены позиции печати
print_at22
		push bc
		ld b,(hl)
		inc hl
		ld c,(hl)
		inc hl
		ld a,c	;защита от дурака при установке позиции печати: 
		cp 32   ;столбцы 0...31 
		jr nc,print_at22_1
		ld a,b
		cp 24   ;строки 0...23 
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
;направление текста (снизу вверх, сверху вниз)
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
;ориентация строки: вертикальная или горизонтальная
print_at13
		ld d,PRINT_VERT_MSK
		ld e,4
		jr print_at15_1
;символ пользователя (пользовательские символы печатаются начиная с 48 кода, т.е. "0" - нуля)
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
;толщина шрифта
print_at14
		ld d,PRINT_BFNT_MSK
		ld e,3
		jr print_at15_1
;инверсия (inverse)
print_at20
		ld d,PRINT_INV_MSK
		ld e,0
		jr print_at15_1
;наложение (over)
print_at21
		ld d,PRINT_OVR_MSK
		ld e,1
		jr print_at15_1
;чернила
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
;бумага 
print_at17
		ld d,PRINT_PAP_MSK
		ld e,3
		jr print_at16_1
;мигание
print_at18
		ld d,PRINT_FLH_MSK
		ld e,7
		jr print_at16_1
;яркость
print_at19
		ld d,PRINT_BRT_MSK
		ld e,6
		jr print_at16_1		
;определяет адрес вывода контура (переменная contour_check_at)
;hl - адрес фигуры в области атрибутов (позиция)
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

;выводит/стирает контур фигуры
;hl - позиция контура при с' != 0, с - атрибуты
;c' = 0 - стирает, c' != 0 - выводит
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
;проверка нажатия клавиши/комбинации конфигурация которой задана в таблице, адрес которой в hl
;на выходе флаг переноса сброшен, если клавиша/комбинация нажата, иначе установлен
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
; привязка клавиши или комбинации клавиш к действию
; в рег. IX - адрес куда поместить порты и данные с портов клавиатуры для соответствующего действия
; с целью комбинации клавиш для действия возможно чтение до 8 портов, 
; т.е. 1 действие может быть задано нажатием до 40 клавиш одновременно (в теории да, но на практике неприменимо,
; т.к. это будет означать наличие всего 1 действия)
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
definekeys0_1		;выдерживаем паузу ~200мс
		halt
		djnz definekeys0_1
definekeys1
		xor a		;проверка: нажата ли
		in a,(#fe)	;хотя бы одна клавиша?
		cpl
		and 31
		jr z,definekeys1	;ждем, пока не нажата клавиша
		halt 				;выдерживаем паузу ~20мс для поддержки нажатия комбинации клавиш и устранения "дребезга" при этом
		ld b,8
		ld d,0
		ld e,#fe
definekeys2
		ld a,e
		in a,(#fe)
		cpl
		and 31
		jr z,definekeys3
		ld (ix),e		;запоминаем старший разряд адреса порта
		ld (ix+1),a		;запоминаем состояние бит
		inc d
		ld a,8			;максимум клавиши могут быть нажаты одновременно на 8 портах
		cp d			;если достигли этого максимума, то выходим
		ret z
		inc ix
		inc ix
definekeys3
		sll e			;следующий порт клавиатуры (поочередно установливаем в 0 биты старшего разряда адреса порта)
		djnz definekeys2
		ret
;процедура выбора клавиш управления
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
		inc d				;ни одна клавиша не нажата?
		dec d
		jr z,select_keys2
		ld hl,okey_txt
		call print
		pop hl
		jr select_keys1
;скроллинг окна вправо/влево на пиксель
;bc - верхняя левая координата окна (row,col)
;de - высота и ширина окна (height,width)
;бит 7 рег. b установлен, если скроллинг вправо, сброшен - скроллинг влево
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
		jr nz,window_scroll_rtlt1 ;скроллинг вправо?
		add a,e
		dec a
window_scroll_rtlt1
		ld l,a
		ld a,d
		or a
		rla
		rla
		rla
		ld d,a ;столько линий перемещаем (высоту умножили на 8)
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

;бегущая строка
;ix - адрес блока данных строки
;смещения в блоке для данных:
;0,1 - верхняя левая координата окна (row,col)
;2,3 - высота и ширина окна (height,width)
;4,5 - адрес строки с текстом
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
		ld l,(ix+4)  ;в hl адрес строки с текстом
		ld h,(ix+5)
running_line_s
		ld a,(hl)
		inc hl
		or a
		ret z      ;0 - конец строки
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
		bit 3,c				;утолщенный шрифт?
		jr z,running_line0_1
		exx
		ld e,a
		and a
		rra
		or e
		exx
running_line0_1
		bit 0,c				;инверсия символа?
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
		dec h ;перемещаем атрибуты (1 раз на 8 сдвигов)
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

;возвращает в BC длину строки, адрес которой в HL
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
		db 22,3,8,16,6,17,0,14,0,19,1,"ВЫБОР УПРАВЛЕНИЯ",19,0
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
		db 22, 6,2,16,6,17,0," Движение блока",19,1," Влево  ",19,0,22,6,26,0	
key_right_txt
		db 22, 8,2,16,6,17,0," Движение блока",19,1," Вправо ",19,0,22,8,26,0	
key_rotate_txt
		db 22,10,2,16,6,17,0,19,1," Вращение",19,0," блока        ",22,10,26,0	
key_drop_txt
		db 22,12,2,16,6,17,0,19,1," Бросок",19,0," блока на дно   ",22,12,26,0	
key_pause_txt
		db 22,14,2,16,6,17,0,19,1," Пауза",19,0," в игре          ",22,14,26,0
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
;данные звуковых эффектов
sndfx1	db 1,3,2,3,4,3,5,3,7,3,8,3,255 ; столкновение фигуры
sndfx2	db 40,7,50,8,60,9,70,10,80,11,90,12,255; ускоренное падение фигуры
sndfx3	db 60,3,50,3,40,3,30,3,20,3,10,3,255 ; вращение фигуры
sndfx4	db 1,40,5,200,5,0,50,5,200,5,1,60,5,200,5,1,70,5,200,5,1,80,5,200,5,190,255; удаление заполненных линий
interface_string
		db 22,0,24,16,1,17,6, " Далее "
		db 22,7,24,16,0,17,4, " Время "
		db 22,10,24,16,1,17,6," Очки  "
		db 22,13,24,16,1,17,6," Линии "
		db 22,16,24,16,0,17,4,"Уровень"
		db 22,19,24,16,6,17,1,"Рекорд "
		db 22,22,24,16,6,17,1," Время "
		db 22,0,0,16,1,17,4,"Статистика",0
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
;данные фигур 
;при распаковке: первый ряд 0, второй - старшая тетрада, третий - младшая тетрада, четвертый - 0
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
		db 22,23,0,16,7,17,0,"Всего:",0
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

;байт конфигурации игры		
config 	ds 1

;атрибуты в формате атрибутов экрана ZX
color_attr ds 1
stakan_vodka_color ds 1

;параметры вывода символов:
;бит 0 - инверсия (inverse)
;бит 1 - наложение (over)
;бит 2 - поворот на 90 градусов 0 - влево, 1 - вправо
;бит 3 - толщина шрифта 0 - обычная, 1 - удвоенная
;бит 4 - печать строк слева направо - 0; 1 - сверху вниз (при бит 2 = 1) либо снизу вверх (при бит 2 = 0)
;бит 5 - символы пользователя 1 - вкл., 0 - выкл.
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

addr	ds 2          ; начальный адрес блока данных
curadd  ds 2          ; текущий адрес в блоке данных
count   ds 1          ; количество повторений
flag    ds 1          ; флаг тон/шум
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