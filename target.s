section .rodata
    X	        equ	12	    ; offset of pointer to target's co-routine X value
    Y	        equ	20	    ; offset of pointer to target's co-routine Y value
    
section .data
    extern target
    extern scheduler
section .bss
    extern value
section .text
    global target_func
    extern random
    extern convert_0_100
    extern resume

    target_func:
        call createTarget
        mov ebx, [scheduler]
        call resume
        jmp target_func        

    createTarget:
        call random
        call convert_0_100          ; [value] has new X coordinate
        mov dword eax, [target]
        mov dword ebx, [value]
        mov dword ecx, [value+4]
        mov [eax+X], ebx            ; update new X coordinate
        mov [eax+X+4], ecx
        call random
        call convert_0_100          ; [value] has new Y coordinate
        mov ebx, 0
        mov ecx, 0
        mov dword eax, [target]
        mov dword ebx, [value]
        mov dword ecx, [value+4]
        mov [eax+Y], ebx            ; update new Y coordinate
        mov [eax+Y+4], ecx
        ret