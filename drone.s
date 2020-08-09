section .rodata
    drone_print db "~~%.2f,~~", 10, 0
    
    X           equ 12          ; offset of pointer to drone's X value
    Y	        equ	20  	    ; offset of pointer to drone's Y value
    DIRECTION   equ 28          ; offset of pointer to drone's angle value
    SPEED       equ 36          ; offset of pointer to drone's speed value
    SCORE       equ 44          ; offset of pointer to drone's score value
    ID          equ 48          ; offset of pointer to drone's ID value
    MORTAL      equ 52          ; offset of pointer to drone's live state
    
    num_0   dd  0
    num_10  dd  10
    num_60  dd  60
    num_180 dd  180
    num_100 dd  100
    num_360 dd  360
    
section .data
    extern target
    extern scheduler
    extern curr

    extra_agnle dq 0                ; value of new add angle
    extra_speed dq 0                ; value of new add speed
    saver   dq 0
    testt    dq 0
    num dd 0
section .bss

    extern num_of_drones
    extern lfsr
    extern dist
    extern printf    
    extern value

section .text
    global drone_func
    extern random
    extern convert_60_60
    extern convert_10_10
    extern resume
    
    ;5 8 10 30 15019

    drone_func:
            finit
            call random
            call convert_60_60              ; random number in [-60,60]
            mov dword ecx, [value]          ; value of new add angle
            mov dword edx, [value+4]
            mov dword [extra_agnle], ecx
            mov dword [extra_agnle+4], edx
            call random
            call convert_10_10
            mov dword ecx, [value]          ; value of new add speed
            mov dword edx, [value+4]
            mov dword [extra_speed], ecx
            mov dword [extra_speed+4], edx
            mov ebx, [curr]
            
                                            ; ~~~~~ changing to new location ~~~~~
            fld qword [ebx+DIRECTION]       
            fldpi
            fmulp
            fild dword [num_180]
            fdivp                           ; convert to radian
            
                ; ~~ y cord ~~
            ;fsincos                     ; ST0=sin(a)  ST1=cos(a)
            fsin
            fmul qword [ebx+SPEED]      ; ST0=SPEED*sin(a)    ST1=cos(a)    
            fld qword [ebx+Y]           ; ST0=Y   ST1=SPEED*sin(a)    ST2=cos(a)    
            faddp                       ; ST0=Y+(SPEED*sin(a))    ST1=cos(a)
            fldz                        ; insert 0
            fcomip ST0, ST1             ; check if y < 0
            ja y_plus_100
            fild dword [num_100]
            fcomip ST0, ST1             ; check if y > 100
            jb y_minus_100
            jmp y_good_number
        y_minus_100: fisub dword [num_100]
            jmp y_good_number
        y_plus_100: fiadd dword [num_100]
        y_good_number:                  ;   0 < y < 100
            fstp qword [ebx+Y]                             ; TODO CHANGE to register
            
            fld qword [ebx+DIRECTION]         ; ~~~~~ changing to new location ~~~~~
            fldpi
            fmulp
            fild dword [num_180]
            fdivp                             ; convert to radian
            
                ; ~~ x cord ~~
            fcos
            fmul qword [ebx+SPEED]      ; ST0=SPEED*cos(a)
            fld qword [ebx+X]           ; ST0=X   ST1=SPEED*cos(a)    
            faddp                       ; ST0=X+(SPEED*cos(a))
            fldz                        ; insert 0
            fcomip ST0, ST1             ; check if x < 0
            ja x_plus_100
            fild dword [num_100]
            fcomip ST0, ST1             ; check if x > 100
            jb x_minus_100
            jmp x_good_number
        x_minus_100: fisub dword [num_100]
            jmp x_good_number
        x_plus_100: fiadd dword [num_100]
        x_good_number:                  ;   0 < y < 100
            fstp qword [ebx+X]
        

            fld qword [ebx+DIRECTION]       ; ~~~~~ update new direction ~~~~~
            fld qword [extra_agnle]         ; push extra angle value
            faddp
            fldz                            ; insert 0
            fcomip ST0, ST1                 ; check 0 > dir
            ja plus_360
            fild dword [num_360]
            fcomip ST0, ST1                 ; check 360 > dir
            jb minus_360
            jmp d_good_number
        minus_360:  fisub dword [num_360]
                jmp d_good_number
        plus_360:   fiadd dword [num_360]
        d_good_number:
            fstp qword [ebx+DIRECTION]
           
            fld qword [ebx+SPEED]           ; ~~~~~ update new speed ~~~~~
            fld qword [extra_speed]         ; push extra speed value
            faddp
            fldz                            ; insert 0
            fcomip ST0, ST1                 ; check 0 > speed
            ja change_to_0
            fild dword [num_100]
            fcomip ST0, ST1                 ; check 100 < speed
            jb change_to_100
            jmp p_good_number
        change_to_0:   
                fstp qword [ebx+SPEED]
                fldz
                jmp p_good_number
        change_to_100:  fstp qword [ebx+SPEED]
                fild dword [num_100]
        p_good_number:
            fstp qword [ebx+SPEED]

            call mayDestroy
            
            cmp eax, 0                      ; check if need to kill drone
            je dont_kill
            inc dword [ebx+SCORE]          ; destroy the target
            mov ebx, [target]
            call resume
            jmp drone_func

        dont_kill:                          ; proceed to scheduler
            mov ebx, [scheduler]
            call resume
            jmp drone_func

    mayDestroy:
            mov dword edx, [target]
            fld qword [ebx+Y]                   ; ~~~ add Y cords ~~~
            fld qword [edx+Y]
            fsubp                               ; ST0 = D_Y - T_Y
            fld ST0
            fmulp                               ; ST0 = (D_Y-T_Y)^2
            
            fld qword [ebx+X]                   ; ~~~ add X cords ~~~
            fld qword [edx+X]
            fsubp                               ; ST0 = D_X - T_X     ST1 =(D_Y-T_Y)^2
            fld ST0
            fmulp                               ; ST0 = (D_X-T_X)^2   ST1 =(D_Y-T_Y)^2
            faddp                               ; ST0 = (D_X-T_X)^2 + (D_Y-T_Y)^2
            fsqrt                               
            fld qword [dist]   

            ;pushad
            ;fst qword [testt]
            ;push dword [testt+4]
            ;push dword [testt]
            ;push drone_print
            ;call printf
            ;add esp, 12
            ;popad
            
            fcomip ST0, ST1                     ; check dist > current distance
            jae destroy
            mov eax, 0
            ret
        destroy:
            mov eax, 1
            ret
