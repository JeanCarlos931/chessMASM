INCLUDE Irvine32.inc
include Macros.inc 


.data
    ; Matriz original de 8x8
    matriz BYTE 'T', 'C', 'A', 'R', 'K', 'A', 'C', 'T'  ; Fila 1
    m2       BYTE 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'  ; Fila 2
    m3       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 3
    m4       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 4
    m5       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 5
    m6       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 6
    m7       BYTE 'p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'  ; Fila 7
    m8       BYTE 't', 'c', 'a', 'k', 'r', 'a', 'c', 't'  ; Fila 8

    ; Matriz que guarda el color de cada posición (1 para azul, 0 para blanco)
  colorMatriz BYTE 1, 0, 1, 0, 1, 0, 1, 0   ; Fila 1
               BYTE 0, 1, 0, 1, 0, 1, 0, 1   ; Fila 2
               BYTE 1, 0, 1, 0, 1, 0, 1, 0   ; Fila 3
               BYTE 0, 1, 0, 1, 0, 1, 0, 1   ; Fila 4
               BYTE 1, 0, 1, 0, 1, 0, 1, 0   ; Fila 5
               BYTE 0, 1, 0, 1, 0, 1, 0, 1   ; Fila 6
               BYTE 1, 0, 1, 0, 1, 0, 1, 0   ; Fila 7
               BYTE 0, 1, 0, 1, 0, 1, 0, 1   ; Fila 8

 ; Matriz que guarda los colores de las letras (1 para rojo, 0 para blanco)
    colorLetraMatriz BYTE 0, 0, 0, 0, 0, 0, 0, 0   ; Fila 1 (Las T en posiciones 0 y 7)
                    BYTE 0, 0, 0, 0, 0, 0, 0, 0   ; Fila 2
                    BYTE 0, 0, 0, 0, 0, 0, 0, 0   ; Fila 3
                    BYTE 0, 0, 0, 0, 0, 0, 0, 0   ; Fila 4
                    BYTE 0, 0, 0, 0, 0, 0, 0, 0   ; Fila 5
                    BYTE 0, 0, 0, 0, 0, 0, 0, 0   ; Fila 6
                    BYTE 1, 1, 1, 1, 1, 1, 1, 1   ; Fila 7
                    BYTE 1, 1, 1, 1, 1, 1, 1, 1   ; Fila 8 (Las T en posiciones 0 y 7)


    ; Mensajes y variables
    mensaje BYTE "Matriz de 8x8:", 0
    espacio BYTE " ", 0
    resultado BYTE "Pieza seleccionada: ", 0
    fila1 BYTE "1 ", 0
    fila2 BYTE "2 ", 0
    fila3 BYTE "3 ", 0
    fila4 BYTE "4 ", 0
    fila5 BYTE "5 ", 0
    fila6 BYTE "6 ", 0
    fila7 BYTE "7 ", 0
    fila8 BYTE "8 ", 0
    columnas BYTE "                    1  2  3  4  5  6  7  8", 0
    seleccion_fila BYTE ?, 0
    seleccion_columna BYTE ?, 0
    nueva_fila BYTE ?, 0
    nueva_columna BYTE ?, 0
    pieza BYTE ?, 0  ; Variable para guardar la pieza seleccionada

    fin1 BYTE "| ", 0
    fin2 BYTE "| ", 0
    fin3 BYTE "| ", 0
    fin4 BYTE "| ", 0
    fin5 BYTE "| ", 0
    fin6 BYTE "| ", 0
    fin7 BYTE "| ", 0
    fin8 BYTE "| ", 0

    
    ; Bandera para saber si el peón ya se movió (1 si se movió, 0 si no)
    peon_movido BYTE 8 DUP(0)  ; Un valor por cada columna de peones en la fila 2

    ; Variables para el mouse
    inputRecord DWORD 0
    numRead DWORD ?
    consoleHandle DWORD ?
    mouseX WORD ?
    mouseY WORD ?
    clickDetected BYTE 0


.code
main PROC
    call crlf
    call crlf
    ;call imprimir_matriz2
    call Crlf
    call crlf
    call crlf
    call crlf


    call crlf 
    mWrite "Para mover las piezas ingrese coordenadas de origen y destino"
    call crlf
    mWrite "Formato: fila columna (ejemplo: 2 3 para fila 2, columna 3)"
    call Crlf
    call crlf
    call crlf
    call crlf
    mWrite "Ajedrez"
    call crlf
    call crlf


cicloMovimiento:

    ; Imprimir la matriz inicial
    call imprimir_matriz
    call Crlf

    ; Detectar posicion de casilla
    call detectar_casilla
    
    ; Verificar que la selección está dentro de los rangos válidos
    cmp seleccion_fila, 1
    jb mostrar_error_fuera_rango
    cmp seleccion_fila, 8
    ja mostrar_error_fuera_rango

    cmp seleccion_columna, 1
    jb mostrar_error_fuera_rango
    cmp seleccion_columna, 8
    ja mostrar_error_fuera_rango

    ; Calcular índice en la matriz para la selección
    mov al, seleccion_fila
    sub al, 1            ; Convertir a índice basado en 0 (fila - 1)
    mov bl, al           ; Guardar el índice de la fila en BL

    mov al, seleccion_columna
    sub al, 1            ; Convertir a índice basado en 0 (columna - 1)

    mov bh, 8            ; Tamaño de cada fila es 8
    mov ah, 0            ; Asegurar que AH esté en 0 para evitar errores
    mul bh               ; fila * 8
    add al, bl           ; sumar la columna al resultado (AL contiene el índice correcto)
    mov esi, eax         ; Guardar el índice de la pieza seleccionada en ESI

    ; Guardar la pieza seleccionada
    mov al, matriz[esi]  ; Cargar la pieza seleccionada de la matriz
    mov pieza, al        ; Guardar la pieza en la variable 'pieza'

    ; Validar que la casilla de origen no esté vacía
    cmp pieza, ' '
    jne origen_no_vacio
    call Crlf
    mWrite "Error: La casilla de origen esta vacia. Intente nuevamente."
    call Crlf
    jmp cicloMovimiento

origen_no_vacio:

    ; Mostrar la pieza seleccionada
    mWrite "                                                                       Seleccion --> "
    mov al, pieza
    call WriteChar
    call Crlf

    mWrite "Seleccione posicion de destino (fila columna): "

    ; Leer coordenadas de destino
    call detectar_casilla_destino
    
    ; Verificar que la selección de destino está dentro de los rangos válidos
    cmp nueva_fila, 1
    jb mostrar_error_fuera_rango
    cmp nueva_fila, 8
    ja mostrar_error_fuera_rango

    cmp nueva_columna, 1
    jb mostrar_error_fuera_rango
    cmp nueva_columna, 8
    ja mostrar_error_fuera_rango

    ; Validar el movimiento de la pieza "P" (si es una "P")
    cmp pieza, 'P'
    je validar_movimiento_P
    cmp pieza, 'p'
    je validar_movimiento_p_min

    ; Salto en caso de no cumplir las condiciones
    jmp realizar_movimiento

mostrar_error_fuera_rango:
    call Crlf
    mWrite "Error: Coordenada fuera del rango permitido. Intente nuevamente."
    call Crlf
jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

; VALIDACION DE MOVIMIENTOS PARA LAS PIEZAS EN MAYÚSCULA

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


validar_movimiento_P:
    ; Validar movimiento del peón "P" (blancas)
    ; Regla: solo columna hacia arriba; diagonal solo para capturar

    ; Debe moverse hacia arriba (nueva_fila < seleccion_fila)
    mov al, nueva_fila
    cmp al, seleccion_fila
    jge error_movimiento_peon

    ; Comparar columnas
    mov al, nueva_columna
    cmp al, seleccion_columna
    je p_blanca_recto

    ; Si columnas distintas, verificar captura diagonal exacta (deltaCol == 1 y deltaFila == 1)
    ; deltaFila = seleccion_fila - nueva_fila debe ser 1
    mov al, seleccion_fila
    sub al, nueva_fila
    cmp al, 1
    jne error_movimiento_peon
    ; deltaCol debe ser 1 (nueva_columna = seleccion_columna +/- 1)
    mov al, nueva_columna
    mov bl, seleccion_columna
    cmp al, bl
    ja p_blanca_diag_derecha
    ; izquierda: bl - al == 1
    mov dl, bl
    sub dl, al
    cmp dl, 1
    jne error_movimiento_peon
    jmp p_blanca_verificar_captura

p_blanca_diag_derecha:
    ; derecha: al - bl == 1
    mov dl, al
    sub dl, bl
    cmp dl, 1
    jne error_movimiento_peon

p_blanca_verificar_captura:
    ; Verificar que en destino haya pieza enemiga (minúscula)
    ; Calcular índice destino en EDI
    mov al, nueva_fila
    sub al, 1
    mov bl, al
    mov al, nueva_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    je error_movimiento_peon
    cmp al, 'p'
    je movimiento_valido
    cmp al, 't'
    je movimiento_valido
    cmp al, 'a'
    je movimiento_valido
    cmp al, 'c'
    je movimiento_valido
    cmp al, 'r'
    je movimiento_valido
    cmp al, 'k'
    je movimiento_valido
    jmp error_movimiento_peon

p_blanca_recto:
    ; Movimiento vertical: misma columna
    ; deltaFila = seleccion_fila - nueva_fila (1 o 2 desde fila 2)
    mov al, seleccion_fila
    sub al, nueva_fila
    cmp al, 1
    je p_blanca_recto_1
    cmp al, 2
    je p_blanca_recto_2
    jmp error_movimiento_peon

p_blanca_recto_1:
    ; Destino debe estar vacío
    mov al, nueva_fila
    sub al, 1
    mov bl, al
    mov al, nueva_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    jne error_movimiento_peon
    jmp movimiento_valido

p_blanca_recto_2:
    ; Solo desde fila inicial 2 y camino libre (intermedia y destino vacíos)
    cmp seleccion_fila, 2
    jne error_movimiento_peon
    ; Verificar casilla intermedia (fila 1 más arriba: seleccion_fila - 1)
    mov al, seleccion_fila
    sub al, 1
    mov bl, al
    mov al, seleccion_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    jne error_movimiento_peon
    ; Verificar destino vacío
    mov al, nueva_fila
    sub al, 1
    mov bl, al
    mov al, nueva_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    jne error_movimiento_peon
    jmp movimiento_valido

error_movimiento_peon:
    call crlf
    mWrite "Error: Movimiento no valido para el peon"
    call Crlf
    jmp cicloMovimiento
validar_movimiento_p_min:
    ; Validar movimiento del peón "p" (negras)
    ; Regla: solo columna hacia abajo; diagonal solo para capturar

    ; Debe moverse hacia abajo (nueva_fila > seleccion_fila)
    mov al, nueva_fila
    cmp al, seleccion_fila
    jle error_movimiento_peon_min

    ; Comparar columnas
    mov al, nueva_columna
    cmp al, seleccion_columna
    je p_negra_recto

    ; Si columnas distintas, verificar captura diagonal exacta (deltaCol == 1 y deltaFila == 1)
    ; deltaFila = nueva_fila - seleccion_fila debe ser 1
    mov al, nueva_fila
    sub al, seleccion_fila
    cmp al, 1
    jne error_movimiento_peon_min
    ; deltaCol debe ser 1 (nueva_columna = seleccion_columna +/- 1)
    mov al, nueva_columna
    mov bl, seleccion_columna
    cmp al, bl
    ja p_negra_diag_derecha
    ; izquierda: bl - al == 1
    mov dl, bl
    sub dl, al
    cmp dl, 1
    jne error_movimiento_peon_min
    jmp p_negra_verificar_captura

p_negra_diag_derecha:
    ; derecha: al - bl == 1
    mov dl, al
    sub dl, bl
    cmp dl, 1
    jne error_movimiento_peon_min

p_negra_verificar_captura:
    ; Verificar que en destino haya pieza enemiga (MAYÚSCULA)
    ; Calcular índice destino en EDI
    mov al, nueva_fila
    sub al, 1
    mov bl, al
    mov al, nueva_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    je error_movimiento_peon_min
    cmp al, 'P'
    je movimiento_valido
    cmp al, 'T'
    je movimiento_valido
    cmp al, 'A'
    je movimiento_valido
    cmp al, 'C'
    je movimiento_valido
    cmp al, 'R'
    je movimiento_valido
    cmp al, 'K'
    je movimiento_valido
    jmp error_movimiento_peon_min

p_negra_recto:
    ; Movimiento vertical: misma columna
    ; deltaFila = nueva_fila - seleccion_fila (1 o 2 desde fila 7)
    mov al, nueva_fila
    sub al, seleccion_fila
    cmp al, 1
    je p_negra_recto_1
    cmp al, 2
    je p_negra_recto_2
    jmp error_movimiento_peon_min

p_negra_recto_1:
    ; Destino debe estar vacío
    mov al, nueva_fila
    sub al, 1
    mov bl, al
    mov al, nueva_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    jne error_movimiento_peon_min
    jmp movimiento_valido

p_negra_recto_2:
    ; Solo desde fila inicial 7 y camino libre (intermedia y destino vacíos)
    cmp seleccion_fila, 7
    jne error_movimiento_peon_min
    ; Verificar casilla intermedia (fila 1 más abajo: seleccion_fila + 1)
    mov al, seleccion_fila
    add al, 1
    mov bl, al
    mov al, seleccion_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    jne error_movimiento_peon_min
    ; Verificar destino vacío
    mov al, nueva_fila
    sub al, 1
    mov bl, al
    mov al, nueva_columna
    sub al, 1
    mov bh, 8
    mul bh
    add al, bl
    mov edi, eax
    mov al, matriz[edi]
    cmp al, ' '
    jne error_movimiento_peon_min
    jmp movimiento_valido

error_movimiento_peon_min:
    call crlf
    mWrite "Error: Movimiento no valido para el peon"
    call Crlf
    jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

;Verificar que el destino no sean piezas mayúsculas o del mismo bando
verificar_letra_destino:
    ; Calcular el índice de la nueva posición
    mov al, nueva_fila
    sub al, 1            ; Convertir a índice basado en 0
    mov bl, al           ; Guardar el índice de la fila en BL

    mov al, nueva_columna
    sub al, 1            ; Convertir a índice basado en 0

    mov bh, 8            ; Tamaño de cada fila es 8
    mul bh               ; fila * 8
    add al, bl           ; Sumar la columna al resultado (AL contiene el índice correcto)
    mov edi, eax         ; Guardar el índice de la nueva posición en EDI

    ; Cargar la letra en la posición de destino
    mov al, matriz[edi]

    ; Verificar si la letra en destino es una de las prohibidas (P, T, A, C, R, K)
    cmp al, 'P'
    je mostrar_error_M
    cmp al, 'T'
    je mostrar_error_M
    cmp al, 'A'
    je mostrar_error_M
    cmp al, 'C'
    je mostrar_error_M
    cmp al, 'R'
    je mostrar_error_M
    cmp al, 'K'
    je mostrar_error_M

    ; Si no es ninguna de las letras prohibidas, permitir el movimiento
    jmp movimiento_valido

mostrar_error_M:
    ; Mostrar error y reiniciar el ciclo
    call crlf
    mWrite "Error: Movimiento no valido. No puede eliminar piezas del mismo bando"
    call crlf
    jmp cicloMovimiento


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&




;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
movimiento_valido:
    ; Realizar el movimiento si es válido
    jmp realizar_movimiento


realizar_movimiento:
    ; Calcular la nueva posición en la matriz
    mov al, nueva_fila
    sub al, 1            ; Convertir a índice basado en 0
    mov bl, al           ; Guardar el índice de la fila en BL

    mov al, nueva_columna
    sub al, 1            ; Convertir a índice basado en 0

    mov bh, 8            ; Tamaño de cada fila es 8
    mul bh               ; fila * 8
    add al, bl           ; sumar la columna al resultado (AL contiene el índice correcto)
    mov edi, eax         ; Guardar el índice de la nueva posición en EDI

    ; Verificar si se va a eliminar un rey ('K' o 'k')
    mov al, matriz[edi]  ; Cargar la pieza en la nueva posición
    cmp al, 'K'
    je mostrar_victoria
    cmp al, 'k'
    je mostrar_victoria

    ; Mover la pieza seleccionada a la nueva posición
    mov al, pieza        ; Cargar la pieza desde la variable 'pieza'
    mov matriz[edi], al  ; Colocar la pieza en la nueva posición

    ; Limpiar la posición original después de validar el movimiento
    mov matriz[esi], ' '  ; Dejar en blanco la posición original

    ; Mover el color de la letra a la nueva posición
    mov al, colorLetraMatriz[esi]  ; Cargar el color de la pieza seleccionada
    mov colorLetraMatriz[edi], al  ; Colocar el color en la nueva posición
    call Crlf
    call Crlf
    jmp cicloMovimiento  ; Regresar al ciclo de movimiento

mostrar_victoria:
    ; Mostrar el mensaje de victoria y terminar el juego
    call crlf
    mWrite "Has ganado! El rey ha sido eliminado."
    call crlf
    jmp finalizar  ; Terminar el juego


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finalizar:
    exit
main ENDP


imprimir_matriz PROC
    ; Fila 8
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila8    ; Imprimir el número de la fila
    call WriteString
    mov esi, 56              ; Índice para la fila 8 (T, C, A, R, K, A, C, T)
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin8      ; Imprimir la etiqueta "fin8" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin8
    call Crlf
    

    ; Fila 7
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila7    ; Imprimir el número de la fila
    call WriteString
    mov esi, 48              ; Índice para la fila 7 (P, P, P, P, P, P, P, P)
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin7      ; Imprimir la etiqueta "fin7" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin7
    call Crlf

    ; Fila 6
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila6    ; Imprimir el número de la fila
    call WriteString
    mov esi, 40              ; Índice para la fila 6
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin6      ; Imprimir la etiqueta "fin6" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin6
    call Crlf

    ; Fila 5
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila5    ; Imprimir el número de la fila
    call WriteString
    mov esi, 32              ; Índice para la fila 5
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin5      ; Imprimir la etiqueta "fin5" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin5
    call Crlf

    ; Fila 4
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila4    ; Imprimir el número de la fila
    call WriteString
    mov esi, 24              ; Índice para la fila 4
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin4      ; Imprimir la etiqueta "fin4" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin4
    call Crlf

    ; Fila 3
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila3    ; Imprimir el número de la fila
    call WriteString
    mov esi, 16              ; Índice para la fila 3
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin3      ; Imprimir la etiqueta "fin3" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin3
    call Crlf

    ; Fila 2
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila2    ; Imprimir el número de la fila
    call WriteString
    mov esi, 8               ; Índice para la fila 2
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin2      ; Imprimir la etiqueta "fin2" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin2
    call Crlf

    ; Fila 1
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del índice es blanco
    call SetTextColor
    mov edx, OFFSET fila1    ; Imprimir el número de la fila
    call WriteString
    mov esi, 0               ; Índice para la fila 1
    call imprimir_letra       ; Imprimir letras de la fila
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra
    call imprimir_letra

    ; Cambiar el color a negro (texto negro sobre fondo negro) antes de la etiqueta
    mov eax, 00h              ; Texto negro sobre fondo negro
    call SetTextColor
    mov edx, OFFSET fin1      ; Imprimir la etiqueta "fin1" en negro
    call WriteString
    call imprimir_espacios_negros ; Imprimir espacios negros al lado de fin1
    call Crlf

    ; Imprimir los números de las columnas
    mov eax, 15              ; Asegurar que el color de las columnas sea blanco
    call SetTextColor
    mov edx, OFFSET columnas
    call WriteString
    call Crlf

    ret
imprimir_matriz ENDP

imprimir_espacios_negros PROC
    ; Imprimir algunos espacios negros a la derecha del finX
    mov ecx, 10              ; Número de espacios a imprimir (ajustable)
ciclo_espacios:
    mov edx, OFFSET espacio
    call WriteString
    loop ciclo_espacios
    ret
imprimir_espacios_negros ENDP

imprimir_letra PROC
    ; Verificar el color correspondiente en colorMatriz para el fondo
    mov al, colorMatriz[esi]
    cmp al, 1
    je fondo_negro

    ; Imprimir con fondo blanco (texto negro, fondo blanco)
    mov eax, 70h              ; Texto negro sobre fondo blanco
    call SetTextColor
    jmp verificar_color_letra

fondo_negro:
    ; Imprimir con fondo negro (texto blanco, fondo negro)
    mov eax, 07h              ; Texto blanco sobre fondo negro
    call SetTextColor

verificar_color_letra:
mWrite " "                          ; Espacio antes de la letra para que sea vea centrado
    ; Verificar si la letra debe ser roja (valor 1 en colorLetraMatriz)
    mov al, colorLetraMatriz[esi]
    cmp al, 1
    jne imprimir_caracter      ; Si no es especial, seguir con la impresión normal

    ; Si es una letra especial, cambiar el color del texto a rojo
    mov ah, al                ; Guardar el carácter en AH para preservarlo
    mov eax, 0                ; Limpiar eax
    call GetTextColor         ; Obtener el color actual de la consola
    and eax, 0F0h             ; Mantener los 4 bits superiores (color de fondo)
    or eax,2h                ; Cambiar solo el color del texto a rojo (4), 2 verde, 1 azul, 3 celeste, 5 morado, 6 moztaza, 7 blanco, 8 gris 
    call SetTextColor           ; 12 azul, blanco y texto verde

imprimir_caracter:
    ; Imprimir la letra correspondiente
    mov al, matriz[esi]
    call WriteChar

    ;mWrite " "       ; Espacio para cambiar el ancho          <···················################################·····················
    ; Restaurar el color del texto a blanco si fue modificado
    cmp al, 'T'
    jne continuar
    ; Restaurar el color del texto a blanco después de la 'T'
    mov al, colorMatriz[esi]
    cmp al, 1
    je fondo_negro_restaurar
    mov eax, 70h              ; Texto negro sobre fondo blanco
    call SetTextColor
    jmp continuar

fondo_negro_restaurar:
    ; Restaurar texto blanco sobre fondo negro
    mov eax, 07h
    call SetTextColor

continuar:
    ; Espacio despues de la letra
    mWrite " "

    ; Incrementar el índice de la matriz
    add esi, 1
    ret
imprimir_letra ENDP

; Función para detectar clic del mouse (simulado con teclado)
detectar_casilla PROC
    push eax
    push ebx
    push ecx
    push edx
    
    mWrite "Ingrese coordenadas de la pieza (fila columna): "
    call Crlf
    
    ; Leer fila
    call ReadInt
    mov seleccion_fila, al
    
    ; Leer columna
    call ReadInt
    mov seleccion_columna, al
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
detectar_casilla ENDP

; Función para detectar coordenadas de destino
detectar_casilla_destino PROC
    push eax
    push ebx
    push ecx
    push edx
    
    mWrite "Ingrese coordenadas de destino (fila columna): "
    call Crlf
    
    ; Leer fila de destino
    call ReadInt
    mov nueva_fila, al
    
    ; Leer columna de destino
    call ReadInt
    mov nueva_columna, al
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
detectar_casilla_destino ENDP

END main