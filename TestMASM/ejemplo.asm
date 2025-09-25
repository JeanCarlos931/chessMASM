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
    mWrite "Para mover las piezas elija origen y destino"
    call crlf
    mWrite "Ejemplo --> '12' = fila 1, columna 2"
    call Crlf
    call crlf
    call crlf
    call crlf
    mWrite "Ajedrez"
    call crlf
    call crlf


BuclePrincipalA:

    ; Imprimir la matriz inicial
    call imprimir_matriz
    call Crlf
    mWrite "Seleccione una pieza: "

    ; Leer el número completo de la posición (ejemplo: 12)
    call ReadInt
    cmp eax, 0
    je mostrar_error_fuera_rango    ; Si se ingresa un 0 o un valor inválido, mostrar error

    ; Separar fila y columna del número ingresado
    mov ebx, 10            ; Divisor para separar los dígitos (fila y columna)
    mov edx, 0             ; Asegurarse de que EDX esté limpio antes de dividir
    div ebx                ; EAX contiene la fila, EDX contiene la columna

    ; Guardar fila y columna
    mov seleccion_fila, al   ; EAX tiene la fila
    mov seleccion_columna, dl ; EDX tiene la columna


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

    ; Mostrar la pieza seleccionada
    mWrite "                                                                       Seleccion --> "
    mov al, pieza
    call WriteChar
    call Crlf

    mWrite "Seleccione nueva posicion para mover la pieza: "

    ; Leer la nueva fila
    call ReadChar
    call WriteChar
    sub al, '0'
    mov nueva_fila, al

    ; Leer la nueva columna
    call ReadChar
    call WriteChar
    sub al, '0'
    mov nueva_columna, al

    ; Verificar que la selección está dentro de los rangos válidos
    cmp nueva_fila, 1
    jb mostrar_error_fuera_rango
    cmp nueva_fila, 8
    ja mostrar_error_fuera_rango

    cmp nueva_columna, 1
    jb mostrar_error_fuera_rango
    cmp nueva_columna, 8
    ja mostrar_error_fuera_rango

    ; Validar el movimiento de la pieza "T" (si es una "T")
    cmp pieza, 'T'
    je validar_movimiento_T
    cmp pieza, 't'
    je validar_movimiento_tmin

    ; Validar el movimiento de la pieza "A" (si es una "A")
    cmp pieza, 'A'
    je validar_movimiento_A
     cmp pieza, 'a'
    je validar_movimiento_a_min

    ; Validar el movimiento de la pieza "R" (si es una "R")
    cmp pieza, 'R'
    je validar_movimiento_R
    cmp pieza, 'r'
    je validar_movimiento_r_min

    ; Validar el movimiento de la pieza "C" (si es una "C")
    cmp pieza, 'C'
    je validar_movimiento_C
     cmp pieza, 'c'
    je validar_movimiento_c_min

    ; Validar el movimiento de la pieza "K" (si es una "K")
    cmp pieza, 'K'
    je validar_movimiento_K
    cmp pieza, 'k'
    je validar_movimiento_k_min

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


validar_movimiento_T:
    ; Validar movimiento en línea recta para la pieza "T"
    ; Movimiento válido si la fila es la misma o la columna es la misma

    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino  ; Si las filas son iguales, pasar a verificar la letra del destino

    ; Verificar si la columna es la misma
    mov al, seleccion_columna
    cmp al, nueva_columna
    je verificar_letra_destino  ; Si las columnas son iguales, pasar a verificar la letra del destino

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. La torre solo puede moverse de forma horizontal y vertical."
    call crlf
    jmp cicloMovimiento


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

validar_movimiento_A:
    ; Validar movimiento en diagonal para la pieza "A"
    ; Movimiento válido si la diferencia absoluta entre fila y columna es la misma

    ; Calcular diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila       ; seleccion_fila - nueva_fila
    mov bl, al               ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa
    neg bl                   ; Si es negativa, convertirla a positiva

fila_no_negativa:

    ; Calcular diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna    ; seleccion_columna - nueva_columna
    mov bh, al               ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa
    neg bh                   ; Si es negativa, convertirla a positiva

columna_no_negativa:

    ; Comparar diferencias absolutas
    cmp bl, bh               ; Si |diferencia filas| == |diferencia columnas|, es un movimiento válido
    je verificar_letra_destino

    ; Si no se cumple la condición, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. El alfil solo puede moverse en diagonal."
    call Crlf
    jmp cicloMovimiento



;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

validar_movimiento_R:
    ; Validar movimiento en línea recta (como la torre) o en diagonal (como el alfil)

    ; Primero, validar si se está moviendo como la torre (en línea recta)
    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino      ; Si las filas son iguales, el movimiento es válido como torre

    ; Verificar si la columna es la misma
    mov al, seleccion_columna
    cmp al, nueva_columna
    je verificar_letra_destino      ; Si las columnas son iguales, el movimiento es válido como torre

    ; Si no se mueve en línea recta, validar si se está moviendo como el alfil (en diagonal)

    ; Calcular diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila       ; seleccion_fila - nueva_fila
    mov bl, al               ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_R
    neg bl                   ; Si es negativa, convertirla a positiva

fila_no_negativa_R:

    ; Calcular diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna    ; seleccion_columna - nueva_columna
    mov bh, al               ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_R
    neg bh                   ; Si es negativa, convertirla a positiva

columna_no_negativa_R:

    ; Comparar diferencias absolutas
    cmp bl, bh               ; Si |diferencia filas| == |diferencia columnas|, es un movimiento válido como alfil
    je verificar_letra_destino

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. La reina solo puede moverse como torre o alfil."
    call Crlf
    jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


validar_movimiento_C:
    ; Validar movimiento en forma de "L" para la pieza "C" (caballo)

    ; Calcular la diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila        ; seleccion_fila - nueva_fila
    mov bl, al                ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_C
    neg bl                    ; Si es negativa, convertirla a positiva

fila_no_negativa_C:

    ; Calcular la diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna     ; seleccion_columna - nueva_columna
    mov bh, al                ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_C
    neg bh                    ; Si es negativa, convertirla a positiva

columna_no_negativa_C:

    ; Validar los movimientos en "L" del caballo
    ; Movimiento válido si (|fila| = 2 y |columna| = 1) o (|fila| = 1 y |columna| = 2)

    cmp bl, 2
    je verificar_columna_1     ; Si la diferencia de filas es 2, verificar que la diferencia de columnas sea 1
    cmp bl, 1
    je verificar_columna_2     ; Si la diferencia de filas es 1, verificar que la diferencia de columnas sea 2
    jmp movimiento_invalido    ; Si no se cumple ninguna de las condiciones, el movimiento es inválido

verificar_columna_1:
    cmp bh, 1
    je verificar_letra_destino       ; Si la diferencia de columnas es 1, el movimiento es válido
    jmp movimiento_invalido

verificar_columna_2:
    cmp bh, 2
    je verificar_letra_destino        ; Si la diferencia de columnas es 2, el movimiento es válido
    jmp movimiento_invalido

movimiento_invalido:
    call crlf
    mWrite "Error: Movimiento no valido. El caballo solo puede moverse en forma de L."
    call Crlf
    jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

validar_movimiento_K:
    ; Validar movimiento en cualquier dirección para la pieza "K"
    ; El movimiento es válido si la diferencia en filas y columnas es de 1 o menos

    ; Calcular diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila       ; seleccion_fila - nueva_fila
    mov bl, al               ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_K
    neg bl                   ; Si es negativa, convertirla a positiva

fila_no_negativa_K:

    ; Calcular diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna    ; seleccion_columna - nueva_columna
    mov bh, al               ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_K
    neg bh                   ; Si es negativa, convertirla a positiva

columna_no_negativa_K:

    ; El movimiento es válido si la diferencia en filas y en columnas es 1 o menos
    cmp bl, 1
    ja movimiento_no_valido_K ; Si la diferencia en filas es mayor a 1, movimiento no válido

    cmp bh, 1
    ja movimiento_no_valido_K ; Si la diferencia en columnas es mayor a 1, movimiento no válido

    ; Si las diferencias son válidas, verificar la letra en la posición de destino
    jmp verificar_letra_destino_K

movimiento_no_valido_K:
    ; Si no se cumple la condición, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. El rey solo puede moverse una casilla en cualquier direccion."
    call crlf
    jmp cicloMovimiento

verificar_letra_destino_K:
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
    je mostrar_error_K
    cmp al, 'T'
    je mostrar_error_K
    cmp al, 'A'
    je mostrar_error_K
    cmp al, 'C'
    je mostrar_error_K
    cmp al, 'R'
    je mostrar_error_K
    cmp al, 'K'
    je mostrar_error_K

    ; Si no es ninguna de las letras prohibidas, permitir el movimiento
    jmp movimiento_valido_K

mostrar_error_K:
    ; Mostrar error y reiniciar el ciclo
    call crlf
    mWrite "Error: Movimiento no valido. No puede eliminar piezas del mismo bando"
    call crlf
    jmp cicloMovimiento

movimiento_valido_K:
    ; Realizar el movimiento si es válido
    jmp realizar_movimiento


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


validar_movimiento_P:
    ; Validar movimiento en línea recta para la pieza "P"
    ; Movimiento válido si la fila es la misma o la columna es la misma

    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. Los peones solo puede moverse de forma vertical"
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



; VALIDACION DE MOVIMIENTOS PARA LAS PIEZAS EN MINÚSCULA CON COLOR


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
validar_movimiento_tmin:
    ; Validar movimiento en línea recta para la pieza "t"
    ; Movimiento válido si la fila es la misma o la columna es la misma

    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino_min  ; Si las filas son iguales, pasar a verificar la letra del destino

    ; Verificar si la columna es la misma
    mov al, seleccion_columna
    cmp al, nueva_columna
    je verificar_letra_destino_min  ; Si las columnas son iguales, pasar a verificar la letra del destino

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. La torre solo puede moverse de forma horizontal y vertical."
    call crlf
    jmp cicloMovimiento


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

validar_movimiento_a_min:
    ; Validar movimiento en diagonal para la pieza "a"
    ; Movimiento válido si la diferencia absoluta entre fila y columna es la misma

    ; Calcular diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila       ; seleccion_fila - nueva_fila
    mov bl, al               ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_a_min
    neg bl                   ; Si es negativa, convertirla a positiva

fila_no_negativa_a_min:

    ; Calcular diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna    ; seleccion_columna - nueva_columna
    mov bh, al               ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_a_min
    neg bh                   ; Si es negativa, convertirla a positiva

columna_no_negativa_a_min:

    ; Comparar diferencias absolutas
    cmp bl, bh               ; Si |diferencia filas| == |diferencia columnas|, es un movimiento válido
    je verificar_letra_destino_min

    ; Si no se cumple la condición, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. El alfil solo puede moverse en diagonal."
    call Crlf
    jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

validar_movimiento_r_min:
    ; Validar movimiento en línea recta (como la torre) o en diagonal (como el alfil)

    ; Primero, validar si se está moviendo como la torre (en línea recta)
    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino_min      ; Si las filas son iguales, el movimiento es válido como torre

    ; Verificar si la columna es la misma
    mov al, seleccion_columna
    cmp al, nueva_columna
    je verificar_letra_destino_min     ; Si las columnas son iguales, el movimiento es válido como torre

    ; Si no se mueve en línea recta, validar si se está moviendo como el alfil (en diagonal)

    ; Calcular diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila       ; seleccion_fila - nueva_fila
    mov bl, al               ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_r_min
    neg bl                   ; Si es negativa, convertirla a positiva

fila_no_negativa_r_min:

    ; Calcular diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna    ; seleccion_columna - nueva_columna
    mov bh, al               ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_r_min
    neg bh                   ; Si es negativa, convertirla a positiva

columna_no_negativa_r_min:

    ; Comparar diferencias absolutas
    cmp bl, bh               ; Si |diferencia filas| == |diferencia columnas|, es un movimiento válido como alfil
    je verificar_letra_destino_min

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. La reina solo puede moverse como torre o alfil."
    call Crlf
    jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

validar_movimiento_c_min:
    ; Validar movimiento en forma de "L" para la pieza "C" (caballo)

    ; Calcular la diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila        ; seleccion_fila - nueva_fila
    mov bl, al                ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_c_min
    neg bl                    ; Si es negativa, convertirla a positiva

fila_no_negativa_c_min:

    ; Calcular la diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna     ; seleccion_columna - nueva_columna
    mov bh, al                ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_c_min
    neg bh                    ; Si es negativa, convertirla a positiva

columna_no_negativa_c_min:

    ; Validar los movimientos en "L" del caballo
    ; Movimiento válido si (|fila| = 2 y |columna| = 1) o (|fila| = 1 y |columna| = 2)

    cmp bl, 2
    je verificar_columna_1_min    ; Si la diferencia de filas es 2, verificar que la diferencia de columnas sea 1
    cmp bl, 1
    je verificar_columna_2_min    ; Si la diferencia de filas es 1, verificar que la diferencia de columnas sea 2
    jmp movimiento_invalido_min    ; Si no se cumple ninguna de las condiciones, el movimiento es inválido

verificar_columna_1_min:
    cmp bh, 1
    je verificar_letra_destino_min       ; Si la diferencia de columnas es 1, el movimiento es válido
    jmp movimiento_invalido_min

verificar_columna_2_min:
    cmp bh, 2
    je verificar_letra_destino_min        ; Si la diferencia de columnas es 2, el movimiento es válido
    jmp movimiento_invalido_min

movimiento_invalido_min:
    call crlf
    mWrite "Error: Movimiento no valido. El caballo solo puede moverse en forma de L."
    call Crlf
    jmp cicloMovimiento

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


validar_movimiento_k_min:
    ; Validar movimiento en cualquier dirección para la pieza "K"
    ; El movimiento es válido si la diferencia en filas y columnas es de 1 o menos

    ; Calcular diferencia de filas
    mov al, seleccion_fila
    sub al, nueva_fila       ; seleccion_fila - nueva_fila
    mov bl, al               ; Guardar en BL

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bl, 0
    jge fila_no_negativa_k_min
    neg bl                   ; Si es negativa, convertirla a positiva

fila_no_negativa_k_min:

    ; Calcular diferencia de columnas
    mov al, seleccion_columna
    sub al, nueva_columna    ; seleccion_columna - nueva_columna
    mov bh, al               ; Guardar en BH

    ; Verificar si la diferencia es negativa y convertirla en valor absoluto
    cmp bh, 0
    jge columna_no_negativa_k_min
    neg bh                   ; Si es negativa, convertirla a positiva

columna_no_negativa_k_min:

    ; El movimiento es válido si la diferencia en filas y en columnas es 1 o menos
    cmp bl, 1
    ja movimiento_no_valido_k_min ; Si la diferencia en filas es mayor a 1, movimiento no válido

    cmp bh, 1
    ja movimiento_no_valido_k_min ; Si la diferencia en columnas es mayor a 1, movimiento no válido

    ; Si las diferencias son válidas, verificar la letra en la posición de destino
    jmp verificar_letra_destino_k_min

movimiento_no_valido_k_min:
    ; Si no se cumple la condición, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. El rey solo puede moverse una casilla en cualquier direccion."
    call crlf
    jmp cicloMovimiento

verificar_letra_destino_k_min:
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

    ; Verificar si la letra en destino es una de las prohibidas (p, t, a, c, r, k)
    cmp al, 'p'
    je mostrar_error_k_min
    cmp al, 't'
    je mostrar_error_k_min
    cmp al, 'a'
    je mostrar_error_k_min
    cmp al, 'c'
    je mostrar_error_k_min
    cmp al, 'r'
    je mostrar_error_k_min
    cmp al, 'k'
    je mostrar_error_k_min

    ; Si no es ninguna de las letras prohibidas, permitir el movimiento
    jmp movimiento_valido_k_min

mostrar_error_k_min:
    ; Mostrar error y reiniciar el ciclo
    call crlf
    mWrite "Error: Movimiento no valido. No puede eliminar piezas del mismo bando"
    call crlf
    jmp cicloMovimiento

movimiento_valido_k_min:
    ; Realizar el movimiento si es válido
    jmp realizar_movimiento


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


validar_movimiento_p_min:
    ; Validar movimiento en línea recta para la pieza "P"
    ; Movimiento válido si la fila es la misma o la columna es la misma

    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino_min

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. Los peones solo puede moverse de forma vertical"
    call Crlf
    jmp cicloMovimiento


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

;Verificar que el destino no sean piezas minúsculas o del mismo bando
verificar_letra_destino_min:
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
    cmp al, 'p'
    je mostrar_error_min
    cmp al, 't'
    je mostrar_error_min
    cmp al, 'a'
    je mostrar_error_min
    cmp al, 'c'
    je mostrar_error_min
    cmp al, 'r'
    je mostrar_error_min
    cmp al, 'k'
    je mostrar_error_min

    ; Si no es ninguna de las letras prohibidas, permitir el movimiento
    jmp movimiento_valido

mostrar_error_min:
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
mov edx, OFFSET espacio
    call WriteString
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
    mov edx, OFFSET espacio
    call WriteString

    ; Incrementar el índice de la matriz
    add esi, 1
    ret
imprimir_letra ENDP

END main