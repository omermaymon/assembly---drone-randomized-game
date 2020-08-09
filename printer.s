section .rodata
    target_print db "%.2f, %.2f", 10, 0
    drone_print db "%d, %.2f, %.2f, %.2f, %.2f, %d", 10, 0
    X           equ 12          ; offset of pointer to drone's X value
    Y	        equ	20  	    ; offset of pointer to drone's Y value
    DIRECTION   equ 28          ; offset of pointer to drone's angle value
    SPEED       equ 36          ; offset of pointer to drone's speed value
    SCORE       equ 44          ; offset of pointer to drone's score value
    ID          equ 48          ; offset of pointer to drone's ID value
    MORTAL      equ 52          ; offset of pointer to drone's live state

section .data
    extern target
    extern drone_arr
    extern alive_drones

section .bss
    extern scheduler
    extern printf
    extern resume
    extern num_of_drones

section .text
    global printer_func
    extern resume
    
    printer_func:
        mov dword edx, [target]
        push dword [edx+Y+4]
        push dword [edx+Y]
        push dword [edx+X+4]
        push dword [edx+X]
        push dword target_print
        call printf                         ; prints terget's status
        add esp, 20
        mov ecx, 0
        ;mov dword edx, [num_of_drones]
        
        drones_loop:
            mov dword eax, [drone_arr]
            mov eax, [eax+ecx*4]
            mov edx, 0
            mov byte dl, [eax+MORTAL] 
            cmp byte dl, 1             ; checks if current drone lives
            jne after_printing
            pushad
            push dword [eax+SCORE]
            push dword [eax+SPEED+4]
            push dword [eax+SPEED]
            push dword [eax+DIRECTION+4]
            push dword [eax+DIRECTION]
            push dword [eax+Y+4]
            push dword [eax+Y]
            push dword [eax+X+4]
            push dword [eax+X]
            push dword [eax+ID]
            push drone_print
            call printf                     ; prints drone's status
            add esp, 44
            popad
        after_printing: 
            inc ecx
            cmp dword ecx, [num_of_drones]
            jne drones_loop
        
        mov ebx, [scheduler]
        call resume
        jmp printer_func