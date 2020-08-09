section	.rodata
    X	        equ	12	    ; offset of pointer to co-routine X value  
    Y           equ	20	    ; offset of pointer to co-routine Y value 
    DIRECTION   equ 28      ; offset to drone DIRECTION
    SPEED       equ 36      ; offset to drone speed 
    SCORE       equ 44      ; offset to drone score
    ID          equ 48      ; offset to drone id
    MORTAL      equ 52      ; offset to drone livnes flag
    format_winner db "%s %d",0
    print_string db "%s",0
    print_winner db "The winner is:", 0

section	.bss

section .data
    extern drone_arr
    extern printer
    extern num_of_drones
    extern num_of_cycles
    extern num_of_steps
    moves_count dd 0
    cycle_count dd 0
    step_count dd 0
    index_kill dd 0
    index_active dd 0
    lowest_points dd 0
    cur_drone_to_kill dd 0
    killed_drones dd 0
    first_flag db 1
    line db 10,0

section .text
    global scheduler_func
    extern resume
    extern printer_func
    extern printf
    extern close


%macro reset_registers 0
    mov eax, 0
    mov ebx, 0
    mov ecx, 0
    mov edx, 0
%endmacro

%macro print_line 0
    pushad
    push line
    push print_string
    call printf
    add esp, 8
    popad
%endmacro

scheduler_func:
        ;(*) start from i=0
    ;(*)if drone (i%N)+1 is active
        ;(*) switch to the i’th drone co-routine
    ;(*) if i%K == 0 //time to print the game board
        ;(*) switch to the printer co-routine
    ;(*) if (i/N)%R == 0 && i%N ==0 //R rounds have passed
        ;(*) find M - the lowest number of targets destroyed, between all of the active drones
        ;(*) "turn off" one of the drones that destroyed only M targets.
    ;(*) i++
    ;(*) if only one active drone is left
        ;(*)print The Winner is drone: <id of the drone>
        ;(*) stop the game (return to main() function or exit)

        reset_registers
        cmp num_of_drones, 1
        je winner
check_drone:        
        mov dword ebx, [drone_arr]                  ; get drone array
        mov dword ecx, [index_active]               ; get index for active drones
        mov ebx, [ebx + 4 * ecx]                    ; get current drone
        mov byte dl, [ebx+MORTAL]
        cmp byte [ebx + MORTAL], 1                  ; check if alive
        jne dead_drone
        call resume                             ;hand control to drone
        inc dword [index_active]                   
        inc dword [step_count]
        inc dword [moves_count]          
        mov dword edx, [num_of_drones]          ; to check if last drone in array
        cmp dword edx, [index_active]
        jne continue
        mov dword [index_active], 0             ; zeros index_active in case of passing all drones
        
continue:
        mov dword edx, [num_of_drones]
        sub edx, [killed_drones]
        cmp edx, [moves_count]
        jne continue2
        mov dword [moves_count], 0
        inc dword [cycle_count]                        
continue2:       
        mov dword ecx, [step_count]             ; check if time to print    
        cmp ecx, [num_of_steps]
        jne no_print
        mov dword [step_count], 0                     ; need to print, zero step counter
        mov ebx, [printer]
        call resume                             ; hand control to printer

no_print:
        mov dword ecx, [cycle_count]
        cmp dword ecx, [num_of_cycles]                ; if cycles passed is enough to kill
        je kill

check_left:
        mov ecx, 0
        mov ecx, [num_of_drones]
        sub ecx, [killed_drones]                       ; check if only one drone left
        cmp dword ecx, 1
        je winner
        jmp scheduler_func

    
    dead_drone:
        inc dword [index_active]
        mov dword edx, [num_of_drones]          ; to check if last drone in array
        cmp dword edx, [index_active]
        jne check_drone
        mov dword [index_active], 0
        jmp check_drone


    kill:  
        mov dword [cycle_count], 0             ; zeros cycle count
kill_loop:
        mov dword ecx, [drone_arr]                    ; get drone array
        mov dword edx, [index_kill]             ; index for loop
        mov ecx, [ecx + 4 * edx]                ; get drone
        mov eax, 0
        mov byte al, [ecx+MORTAL]
        cmp byte [ecx + MORTAL], 0                   ; check if alive
        jne check_score                          ; if alive going to check the score
continue_kill:
        inc dword [index_kill]
        mov dword edx, [index_kill]             ; to check if we went through all drones
        cmp dword edx, [num_of_drones]
        jb kill_loop
        jmp finish_kill

    check_score:            ; drone is in ecx 
        mov al, [first_flag]            ; if this is the first drone to be checked
        cmp byte al, 1
        jne there_is_first
        mov byte [first_flag], 0        ; zero first flag
        mov dword eax, [ecx + SCORE]    ; get score of first drone
        mov dword [lowest_points], eax  ; use first drones score as lowest score
there_is_first:
        mov dword ebx, [ecx + SCORE]    ; get score of current drone
        cmp  dword ebx, [lowest_points] ; check if score is equal or lower then lower score so far
        ja continue_kill                ; if score is bigger, move to next drone
        mov dword [cur_drone_to_kill], ecx      ; if score is lower, save the current drone
        mov eax, [ecx + SCORE]          ; update the current lowest point
        mov [lowest_points], eax
        jmp continue_kill               ; go back to checking the rest of the drones
        
        
    finish_kill:
        mov dword [index_kill], 0             ; reset kill indedx
        mov byte [first_flag], 1
        mov dword [lowest_points], 0
        mov ecx, [cur_drone_to_kill]    ; get the drone to kill it
        mov byte [ecx + MORTAL], 0      ; kill the drone
        inc dword [killed_drones]             ; one more for the lolz
        jmp check_left                  ; continue
    

    winner:
        mov dword [index_active], 0
    keep_looking:                       ; find the last survivor
        mov edx, [index_active]
        mov ecx, [drone_arr]
        mov ecx, [ecx + edx * 4]
        inc dword [index_active]   
        cmp byte [ecx + MORTAL], 1           ; found
        jne keep_looking
        mov dword eax, [ecx + ID]       ; get id
        push eax
        push print_winner
        push format_winner
        call printf                     ; print requested output
        add esp, 12
        print_line
        call close                      ; calling close from main
