section	.rodata
    drone_print db "~~%.2f,~~", 10, 0
    format_int db "%d", 0
    format_float db "%lf", 0
    COFUNC      equ 0       ; offset to courtine func
    SPP	        equ	4	    ; offset to courtine stack
    STKP        equ 8       ; offset of stack for freeing
    X	        equ	12	    ; offset of pointer to co-routine X value  
    Y           equ	20	    ; offset of pointer to co-routine Y value 
    DIRECTION   equ 28      ; offset to drone DIRECTION
    SPEED       equ 36      ; offset to drone speed 
    SCORE       equ 44      ; offset to drone score
    ID          equ 48      ; offset to drone id
    MORTAL      equ 52      ; offset to drone livnes flag
    COSIZE      equ 12      ; total size of basic co-routine
    TRGTSIZE    equ 28      ; total size of target struct          
    DRONESIZE   equ 53      ; total size of drone struct
    STKSIZE     equ 16*1024 

    fix_0_100   dt  0.0015259021896         ; 100 / max_int
    fix_0_360   dt  0.0054932478828         ; 360 / max_int
    fix_0_120   dt  0.0018310826276         ; 120 / max_int
    fix_0_20    dt  0.0003051804379         ; 20  / max_int

    num_10      dd  10
    num_60      dd  60
    max_int     dd  65535
    
section	.bss
    extern printf

    global num_of_drones
    global num_of_cycles
    global num_of_steps
    global dist
    global seed
    global value
    global curr
    SPT resd 1
    value resq 1
    num_of_drones resd 1
    num_of_cycles resd 1
    num_of_steps resd 1
    dist resq 1
    seed resd 1
    curr resd 1

section .data
    
    global target
    global scheduler
    global lfsr
    global drone_arr
    global printer
    lfsr dd 0
    target dd 0
    drone_arr dd 0
    current_drone dd 0   ; pointer for drones
    printer dd 0
    scheduler dd 0
    index dd 0
    saver dw 0
section .text
    align 16
    global main
    global close
    global resume
    global random
    global convert_0_100
    global convert_0_360
    global convert_10_10
    global convert_60_60
    extern sscanf
    extern target_func
    extern drone_func
    extern printer_func
    extern scheduler_func
    extern malloc   
    extern free


%macro reset_registers 0
    mov eax, 0
    mov ebx, 0
    mov ecx, 0
    mov edx, 0
%endmacro

main:
    push ebp
    mov ebp, esp
    reset_registers
    mov eax, [ebp+12]                       ; pointer to args array                        ; args
    mov ebx, [eax + 4] 
    
    
    get_args:
        pushad
        push num_of_drones
        push format_int
        push ebx 
        call sscanf
        add esp,12
        popad
        mov dword ebx, [eax + 8]
        pushad
        push num_of_cycles
        push format_int
        push ebx
        call sscanf
        add esp,12
        popad 
        mov dword ebx, [eax + 12]
        pushad 
        push num_of_steps
        push format_int
        push ebx
        call sscanf
        add esp,12
        popad
        mov ebx, [eax + 16]
        pushad
        push dist
        push format_float
        push ebx
        call sscanf
        add esp,12
        popad


        mov ebx, [eax + 20]
        pushad
        push seed
        push format_int
        push ebx
        call sscanf
        add esp,12
        mov dword edx, [seed]
        mov dword [lfsr], edx    

    start:
       
        start_target:
            reset_registers
            finit                       
            push dword TRGTSIZE             ; size of target
            call malloc
            add esp, 4
            mov dword [target], eax
            push STKSIZE                    ; size of stack
            call malloc
            add esp, 4
            mov ecx, [target]
            mov dword [ecx + COFUNC], target_func   ;pointer to target func for coroutine
            mov dword [ecx + STKP],    eax         ;pointer to stack for delete
            add eax, STKSIZE
            mov [ecx+SPP], eax
            reset_registers
            call random                             ; generate x value
            call convert_0_100
            mov ebx, [target]
            mov ecx, [value]
            mov edx, [value+4]
            mov [ebx + X], ecx                      ; input of X value
            mov [ebx + X+4], edx
            call random                             ; generate y value
            call convert_0_100
            mov ecx, 0
            mov edx, 0
            mov ecx, [value]
            mov edx, [value+4]
            mov [ebx + Y], ecx                      ; input y value
            mov [ebx + Y+4], edx
            mov [SPT], esp
            mov edx, [ebx + COFUNC]                   ; to push into coroutine stack
            mov esp, [ebx + SPP]
            push edx
            pushfd
            pushad
            mov [ebx + SPP], esp                    ; set courtine stackpointer after pushes
            mov esp, [SPT]                          ; return the previous stackpointer


        start_drones:
            reset_registers
            mov ecx, [num_of_drones]
            shl ecx, 2                      ; 4 bytes for each drone
            push ecx
            call malloc
            add esp, 4
            mov [drone_arr], eax            ; pointer to drone array


            make_drones:
                ;reset_registers
                inc dword [index]
                push DRONESIZE
                call malloc
                add esp, 4
                mov ebx, [drone_arr]
                mov ecx, [index]
                mov [ebx + ecx * 4 - 4], eax    ; put drone
                mov [current_drone], eax
                push STKSIZE
                call malloc
                add esp, 4
                mov ebx, [current_drone]
                mov dword [ebx], drone_func           ; func of courtine
                mov [ebx + STKP], eax           ; pointer to stack for delete
                add eax, STKSIZE                
                mov [ebx + SPP], eax           ; stack
                call random                     ; get x val
                call convert_0_100
                mov ecx, [value]
                mov edx, [value+4]
                mov [ebx + X], ecx
                mov [ebx + X+4], edx
                mov ecx, 0
                mov edx, 0
                call random                     ; get y val
                call convert_0_100
                mov ecx, [value]
                mov edx, [value+4]
                mov [ebx + Y], ecx
                mov [ebx + Y+4], edx
                mov ecx, 0
                mov edx, 0
                call random                     ; getting initial heading              
                call convert_0_360
                mov ecx, [value]
                mov edx, [value+4]
                mov [ebx + DIRECTION], ecx
                mov [ebx + DIRECTION+4], edx
                mov ecx, 0
                mov edx, 0
                call random
                call convert_0_100                   ; get initial speed
                mov ecx, [value]
                mov edx, [value+4]
                mov [ebx + SPEED], ecx
                mov [ebx + SPEED+4], edx
                mov dword [ebx + SCORE], 0            ; start score at 0
                mov ecx, 0
                mov edx, 0
                mov ecx, [index]
                mov [ebx + ID], ecx             ; id is index
                mov byte [ebx + MORTAL], 1           ; drone start alive
                mov dword eax, [ebx + COFUNC]
                mov [SPT], esp
                mov esp, [ebx + SPP]
                push eax
                pushfd
                pushad
                mov [ebx +SPP], esp
                mov dword esp, [SPT]
                mov dword edx, [num_of_drones]
                cmp edx, [index]
                jne make_drones


        start_printer:
            reset_registers
            push COSIZE           ; size of regular courtine
            call malloc
            add esp, 4
            mov [printer], eax      ; saving printer struct for later
            push STKSIZE
            call malloc
            add esp, 4
            mov dword ebx, [printer]        ; get printer struct
            mov dword [ebx + COFUNC], printer_func    ; now points to func
            mov [ebx + STKP], eax
            add eax, STKSIZE
            mov [ebx + SPP], eax            ; points to begin of stack
            mov eax, [ebx + COFUNC]         
            mov [SPT], esp
            mov esp, [ebx + SPP]
            push eax
            pushfd
            pushad
            mov [ebx + SPP], esp
            mov esp, [SPT]


        start_scheduler:
            reset_registers 
            push COSIZE                 ; for scheduler struct
            call malloc
            add esp, 4
            mov dword [scheduler], eax  ;   pointer to scheduler
            push STKSIZE                ; stack of courtine
            call malloc
            add esp, 4
            mov ebx, [scheduler]
            mov dword [ebx + COFUNC], scheduler_func      ; puting func in struct
            mov [ebx + STKP], eax                   ; pointer of stack for free
            add eax, STKSIZE
            mov [ebx + SPP], eax                    ; pointer to stack
            mov eax, [ebx + COFUNC]
            mov [SPT], esp
            mov esp, [ebx + SPP]
            push eax
            pushfd
            pushad
            mov [ebx + SPP], esp
            mov esp, [SPT] 

    run_sched:
        pushad
        
        mov [SPT], esp
        mov ebx, [scheduler]
        jmp do_resume

    resume:
        pushfd
        pushad
        mov edx, [curr]
        mov [edx+SPP], esp
    do_resume:
        mov esp, [ebx+SPP]
        mov [curr], ebx
        popad
        popfd
        ret
            
    close:
        reset_registers
        mov esp, [SPT]          ; delete printer
        mov ebx, [printer]
        call delete
        mov ebx, [target]       ; delete target
        call delete
        mov ebx, [scheduler]    ; delete scheduler
        call delete             
        call delete_drones      ; delete drones 
        mov dword eax, 1        ; exiting
        mov dword ebx, 0
        int 0x80


        delete: ;expects in ebx
            push dword [ebx + STKP]
            call free
            add esp, 4
            push ebx
            call free
            add esp, 4
            ret

        delete_drones:
            reset_registers
            mov ecx, [num_of_drones]
            mov ebx, [drone_arr]
            mov ebx, [ebx + 4 * ecx - 4]
            pushad
            push dword [ebx + STKP]
            call free 
            add esp, 4
            popad
            pushad
            push ebx
            call free
            add esp, 4
            popad
            dec dword [num_of_drones]
            cmp dword [num_of_drones], 0
            jne delete_drones
            mov dword ebx, [drone_arr]
            push ebx
            call free
            add esp, 4
            ret
            

random:
        pushad
        mov ebx, 0
        mov eax, [lfsr]
        mov ebx, eax
        shr ebx, 1
        and ax, 0x002d              ; 0000000000101101
        jp add_zero
        add bx, 0x8000              ; 1000000000000000 adding 1 at msb
        add_zero:
        mov dword [lfsr], ebx
        popad
        ret

;random:
;        pushad
;        mov ecx, 16
;        loop_16:
;        ;mov ebx, 0
;        mov eax, [lfsr]
;        ;mov ebx, eax
;        ;shr ebx, 1
;        mov word [saver], 0
;        and eax, 0x002d              ; 0000000000101101
;        test eax, eax
;        jp add_zero
;        inc word [saver]
;        ;add ebx, 0x8000              ; 1000000000000000 adding 1 at msb
;        add_zero:
;        mov ax, [saver]
;        shl ax, 15
;        shr word [lfsr], 1
;        add [lfsr], ax
;        loop loop_16, ecx
;        mov dword [lfsr], ebx
;        popad
;        ret

    convert_0_360:              ; put in [value] number between 0 to 360
        pushad
        fld tword [fix_0_360]
        fimul dword [lfsr]
        fstp qword [value]
        popad
        ret

    convert_0_100:              ; put in [value] number between 0 to 100 
        pushad
        fld tword [fix_0_100]
        fimul dword [lfsr]
        fstp qword [value]
        popad
        ret

    convert_60_60:              ; put in [value] number between -60 to 60
        pushad
        fld tword [fix_0_120]
        fimul dword [lfsr]
        fisub dword [num_60]
        fstp qword [value]
        popad
        ret

    convert_10_10:              ; put in [value] number between (-10)-10
        pushad
        fld tword [fix_0_20]
        fimul dword [lfsr]
        fisub dword [num_10]
        fstp qword [value]
        popad
        ret

