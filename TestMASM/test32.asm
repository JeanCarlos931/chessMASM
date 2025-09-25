; ===================================================================
; JUEGO DE AJEDREZ SIMPLE - VERSI�N CORREGIDA
; ===================================================================
; Versi�n simplificada que funciona correctamente
; ===================================================================

INCLUDE Irvine32.inc
include Macros.inc 

; Macro: Actualiza partida.json con estado/turn/fen y espera turno 'b'
mActualizarPartidaYEsperarB MACRO
    call EscribirJSONTurnFenW
    mov edx, OFFSET esperando_jugada
    call WriteString
    call Crlf
    call EsperarJugadaB
ENDM

.data
    ; ===================================================================
    ; MENSAJES DE INTERFAZ
    ; ===================================================================
    titulo          BYTE "=== JUEGO DE AJEDREZ SIMPLE ===", 0
    seleccion_rol   BYTE "Seleccione rol: A o B", 0
    opcion_a        BYTE "A - Jugador A (Inicia partida)", 0
    opcion_b        BYTE "B - Jugador B (Espera invitacion)", 0
    entrada_invalida BYTE "Opcion invalida. Intente nuevamente.", 0
    
    ; ===================================================================
    ; MENSAJES DE ESTADO
    ; ===================================================================
    esperando_b     BYTE "Esperando confirmacion del Jugador B...", 0
    esperando_a     BYTE "Esperando invitacion del Jugador A...", 0
    partida_iniciada BYTE "Partida iniciada! Es tu turno.", 0
    turno_jugador   BYTE "Turno del Jugador A. Ingresa tu jugada: ", 0
    turno_jugador_b BYTE "Turno del Jugador B. Ingresa tu jugada: ", 0
    esperando_jugada BYTE "Esperando jugada del oponente...", 0
    
    ; ===================================================================
    ; NOMBRES DE ARCHIVOS
    ; ===================================================================
    archivo_partida BYTE "data/partida.json", 0
    
    ; ===================================================================
    ; BUFFERS PARA MANEJO DE ARCHIVOS
    ; ===================================================================
    buffer_json     BYTE 1024 DUP(0)    ; Buffer para leer/escribir JSON
    buffer_entrada  BYTE 256 DUP(0)     ; Buffer para entrada del usuario
    
    ; ===================================================================
    ; VARIABLES DE CONTROL
    ; ===================================================================
    rol_seleccionado BYTE ?             ; 'A' o 'B'
    handle_archivo   DWORD ?            ; Handle del archivo
    bytes_leidos     DWORD ?            ; Bytes le�dos del archivo
    bytes_escritos   DWORD ?            ; Bytes escritos al archivo
    confirmacion_recibida BYTE 0        ; Bandera para confirmaci�n de Jugador B

    ; ===================================================================
    ; PLANTILLAS JSON
    ; ===================================================================
    json_iniciada    BYTE '{"estado": "iniciada"}', 0
    json_recibida    BYTE '{"estado": "recibida"}', 0
    json_jugador_a   BYTE '{"jugadorA": "', 0
    json_jugador_b   BYTE '{"jugadorB": "', 0
    json_cierre      BYTE '"}', 0
    
    ; JSON completo requerido tras jugada de A
    json_estado_turn_fen_w BYTE '{"estado": "recibida", "turn": "w", "fen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"}', 0
    
    ; Buffers y plantillas para construir FEN dinámico y JSON
    fen_suffix BYTE " w KQkq - 0 1", 0
    json_estado_turn_fen_prefix BYTE '{"estado": "recibida", "turn": "w", "fen": "', 0
    buffer_fen     BYTE 128 DUP(0)
    
    ; ===================================================================
    ; MENSAJES DE ERROR
    ; ===================================================================
    error_crear      BYTE "Error al crear archivo partida.json", 0
    error_abrir      BYTE "Error al abrir archivo partida.json", 0
    error_escribir   BYTE "Error al escribir en archivo", 0
    error_leer       BYTE "Error al leer archivo", 0
    error_bando_msg BYTE "Error: Solo puedes mover piezas min�sculas (bando B).", 0
    
    ; ===================================================================
    ; MENSAJES DE DEPURACI�N
    ; ===================================================================
    mensaje_debug    BYTE "DEBUG: Contenido del archivo: ", 0
    mensaje_encontrado BYTE "DEBUG: Palabra 'iniciada' encontrada!", 0
    mensaje_no_encontrado BYTE "DEBUG: Palabra 'iniciada' NO encontrada, continuando...", 0
    mensaje_encontrado_recibida BYTE "DEBUG: Palabra 'recibida' encontrada!", 0
    mensaje_debug_jugada_a BYTE "DEBUG: Escribiendo jugada de Jugador A: ", 0
    
    ; Mensajes de jugada
    mensaje_jugada_a BYTE "Jugada A: ", 0
    flecha           BYTE " -> ", 0

    ; ===================================================================
    ; Datos del tablero de ajedrez
    ; ===================================================================
    ; Matriz original de 8x8
    matriz BYTE 'T', 'C', 'A', 'R', 'K', 'A', 'C', 'T'  ; Fila 1
    m2       BYTE 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'  ; Fila 2
    m3       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 3
    m4       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 4
    m5       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 5
    m6       BYTE ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '  ; Fila 6
    m7       BYTE 'p', 'p', 'p', 'p', 'p', 'p', 'p', 'p'  ; Fila 7
    m8       BYTE 't', 'c', 'a', 'k', 'r', 'a', 'c', 't'  ; Fila 8

    ; Matriz que guarda el color de cada posici�n (1 para azul, 0 para blanco)
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



.code
main PROC
    ; ===================================================================
    ; INICIO DEL PROGRAMA PRINCIPAL
    ; ===================================================================
    call Clrscr                    ; Limpiar pantalla
    
    ; Mostrar t�tulo
    mov edx, OFFSET titulo
    call WriteString
    call Crlf
    call Crlf
    
    ; Mostrar men� de selecci�n de rol
    call MostrarMenuRol
    
    ; Procesar selecci�n seg�n el rol elegido
    cmp rol_seleccionado, 'A'
    je JugadorA
    cmp rol_seleccionado, 'B'
    je JugadorB
    
    ; Si llegamos aqu�, hay un error
    jmp Salir
    
JugadorA:
    ; ===================================================================
    ; L�GICA DEL JUGADOR A (INICIA LA PARTIDA)
    ; ===================================================================
    call IniciarPartidaA
    jmp Salir
    
JugadorB:
    ; ===================================================================
    ; L�GICA DEL JUGADOR B (ESPERA INVITACI�N)
    ; ===================================================================
    call EsperarInvitacionB
    jmp Salir
    
Salir:
    call Crlf
    call WaitMsg
    exit
main ENDP

; ===================================================================
; PROCEDIMIENTO: MostrarMenuRol
; Descripci�n: Muestra el men� para seleccionar rol y captura la entrada
; ===================================================================
MostrarMenuRol PROC
    pushad
    
    ; Mostrar opciones
    mov edx, OFFSET seleccion_rol
    call WriteString
    call Crlf
    
    mov edx, OFFSET opcion_a
    call WriteString
    call Crlf

    mov edx, OFFSET opcion_b
    call WriteString
    call Crlf
    call Crlf
    
    ; Capturar entrada del usuario
CapturarEntrada:
    mov edx, OFFSET buffer_entrada
    mov ecx, SIZEOF buffer_entrada
    call ReadString
    
    ; Validar entrada
    cmp eax, 1
    jne EntradaInvalida
    
    mov al, buffer_entrada[0]
    cmp al, 'A'
    je EntradaValida
    cmp al, 'a'
    je EntradaValida
    cmp al, 'B'
    je EntradaValida
    cmp al, 'b'
    je EntradaValida
    
EntradaInvalida:
    mov edx, OFFSET entrada_invalida
    call WriteString
    call Crlf
    jmp CapturarEntrada
    
EntradaValida:
    ; Convertir a may�scula y guardar
    and al, 11011111b    ; Convertir a may�scula
    mov rol_seleccionado, al
    
    popad
    ret
MostrarMenuRol ENDP

; ===================================================================
; PROCEDIMIENTO: IniciarPartidaA
; Descripci�n: L�gica del Jugador A - crea partida y espera confirmaci�n
; ===================================================================
IniciarPartidaA PROC
    pushad

    ; Crear archivo partida.json con estado "iniciada"
    call CrearArchivoPartida
    cmp eax, 0
    je ErrorCrearArchivo
    
    ; Escribir JSON inicial
    call EscribirJSONIniciada
    cmp eax, 0
    je ErrorEscribirJSON
    
    ; Cerrar archivo
    call CerrarArchivo
    
    ; Mostrar mensaje de espera
    mov edx, OFFSET esperando_b
    call WriteString
    call Crlf
    
    ; Esperar confirmaci�n del Jugador B
    call EsperarConfirmacionB
    
    ; Iniciar bucle de jugadas
    call BucleJugadasA
    
    popad
    ret
    
ErrorCrearArchivo:
    mov edx, OFFSET error_crear
    call WriteString
    call Crlf
    popad
    ret
    
ErrorEscribirJSON:
    mov edx, OFFSET error_escribir
    call WriteString
    call Crlf
    popad
    ret
IniciarPartidaA ENDP

; ===================================================================
; PROCEDIMIENTO: EsperarInvitacionB
; Descripci�n: L�gica del Jugador B - espera invitaci�n y confirma
; ===================================================================
EsperarInvitacionB PROC
    pushad
    
    ; Mostrar mensaje de espera
    mov edx, OFFSET esperando_a
    call WriteString
    call Crlf
    call Crlf
    
    ; Esperar a que exista el archivo con estado "iniciada"
    call EsperarArchivoIniciada
    
    ; Modificar archivo a estado "recibida"
    call ConfirmarInvitacion
    
    ; Mostrar mensaje de partida iniciada
    mov edx, OFFSET partida_iniciada
    call WriteString
    call Crlf
    
    ; Iniciar bucle de jugadas
    call BucleJugadasB
    
    popad
    ret
EsperarInvitacionB ENDP

; ===================================================================
; PROCEDIMIENTO: EscribirJSONIniciada
; Descripci�n: Escribe el JSON inicial con estado "iniciada"
; Retorna: EAX = 0 si error, 1 si �xito
; ===================================================================
EscribirJSONIniciada PROC
    pushad
    
    ; Escribir JSON al archivo
    mov eax, handle_archivo
    mov edx, OFFSET json_iniciada
    mov ecx, LENGTHOF json_iniciada - 1
    call WriteToFile
    mov bytes_escritos, eax
    
    ; Verificar si se escribi� correctamente
    cmp eax, 0
    je ErrorEscribir
    
    mov eax, 1
    jmp FinEscribir
    
ErrorEscribir:
    mov eax, 0
    
FinEscribir:
    popad
    ret
EscribirJSONIniciada ENDP

; ===================================================================
; PROCEDIMIENTO: CerrarArchivo
; Descripci�n: Cierra el archivo abierto
; ===================================================================
CerrarArchivo PROC
    pushad
    
    mov eax, handle_archivo
    call CloseFile
    
    popad
    ret
CerrarArchivo ENDP

; ===================================================================
; PROCEDIMIENTO: EsperarConfirmacionB
; Descripci�n: Espera a que el Jugador B confirme la invitaci�n
; ===================================================================
EsperarConfirmacionB PROC
    pushad
    
BucleEspera:
    ; Abrir archivo para lectura
    mov edx, OFFSET archivo_partida
    call OpenInputFile
    mov handle_archivo, eax

    cmp eax, INVALID_HANDLE_VALUE
    je ContinuarEspera

    ; Leer contenido del archivo
    mov eax, handle_archivo
    mov edx, OFFSET buffer_json
    mov ecx, SIZEOF buffer_json
    call ReadFromFile
    mov bytes_leidos, eax

    ; Cerrar archivo
    call CerrarArchivo

    ; Verificar si el JSON es igual a json_recibida
    call VerificarJSONRecibida
    cmp byte ptr confirmacion_recibida, 1
    je ConfirmacionRecibida

ContinuarEspera:
    ; Esperar un poco antes de volver a verificar
    mov eax, 1000
    call Delay
    jmp BucleEspera

ConfirmacionRecibida:
    popad
    ret
EsperarConfirmacionB ENDP

; ===================================================================
; PROCEDIMIENTO: CrearArchivoPartida
; Descripci�n: Crea el archivo partida.json
; Retorna: EAX = 0 si error, 1 si �xito
; ===================================================================
CrearArchivoPartida PROC
    pushad
    
    ; Crear archivo
    mov edx, OFFSET archivo_partida
    call CreateOutputFile
    mov handle_archivo, eax
    
    ; Verificar si se cre� correctamente
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorCrear
    
    mov eax, 1
    jmp FinCrear
    
ErrorCrear:
    mov eax, 0
    
FinCrear:
    popad
    ret
CrearArchivoPartida ENDP

; ===================================================================
; PROCEDIMIENTO: VerificarJSONRecibida
; Descripci�n: Compara buffer_json con json_recibida y muestra mensajes debug
; Retorna: EAX = 1 si son iguales, 0 si no
; ===================================================================
VerificarJSONRecibida PROC
    pushad

    mov esi, OFFSET buffer_json      ; buffer le�do del archivo
    mov edi, OFFSET json_recibida    ; cadena esperada
    mov ecx, LENGTHOF json_recibida - 1  ; longitud real (sin terminador)
    mov ebx, 0                       ; bandera de diferencia

CompararLoop:
    cmp ecx, 0
    je FinComparar

    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne Diferente

    inc esi
    inc edi
    dec ecx
    jmp CompararLoop

Diferente:
    mov ebx, 1
    jmp FinComparar

FinComparar:
    cmp ebx, 0
    je SonIguales
    mov eax, 0
    mov edx, OFFSET mensaje_debug
    call WriteString
    mov edx, OFFSET buffer_json
    call WriteString
    call Crlf
    mov edx, OFFSET error_leer
    call WriteString
    call Crlf
    jmp FinVerificar

SonIguales:
    mov eax, 1
    mov edx, OFFSET mensaje_debug
    call WriteString
    mov edx, OFFSET buffer_json
    call WriteString
    call Crlf
    mov edx, OFFSET mensaje_encontrado_recibida
    call WriteString
    call Crlf
    mov confirmacion_recibida, 1

FinVerificar:
    popad
    ret
VerificarJSONRecibida ENDP

; ===================================================================
; PROCEDIMIENTO: BuscarPalabraRecibida
; Descripci�n: Busca la palabra "recibida" en el buffer
; Par�metros: EDX = offset del buffer
; Retorna: EAX = 1 si encuentra, 0 si no
; ===================================================================
BuscarPalabraRecibida PROC
    pushad
    
    mov esi, edx
    mov ecx, bytes_leidos
    sub ecx, 7  ; Tama�o m�nimo para contener "recibida"
    
BuscarLoop:
    cmp ecx, 0
    jle NoEncontrado
    
    ; Verificar si los siguientes 8 caracteres son "recibida"
    mov al, [esi]
    cmp al, 'r'
    jne Siguiente
    
    ; Encontrado
    mov eax, 1
    jmp FinBuscar
    
Siguiente:
    inc esi
    dec ecx
    jmp BuscarLoop
    
NoEncontrado:
    mov eax, 0
    
FinBuscar:
    popad
    ret
BuscarPalabraRecibida ENDP

; ===================================================================
; PROCEDIMIENTO: EsperarArchivoIniciada
; Descripci�n: Espera a que exista el archivo con estado "iniciada"
; ===================================================================
EsperarArchivoIniciada PROC
    pushad
    
BucleEsperaArchivo:
    ; Intentar abrir archivo
    mov edx, OFFSET archivo_partida
    call OpenInputFile
    mov handle_archivo, eax
    
    cmp eax, INVALID_HANDLE_VALUE
    je ContinuarEsperaArchivo
    
    ; Leer contenido
    mov eax, handle_archivo
    mov edx, OFFSET buffer_json
    mov ecx, SIZEOF buffer_json
    call ReadFromFile
    mov bytes_leidos, eax
    
    ; Cerrar archivo
    call CerrarArchivo
    
    ; Verificar que se ley� algo
    cmp bytes_leidos, 0
    je ContinuarEsperaArchivo
    
    ; Mostrar contenido le�do para depuraci�n
    mov edx, OFFSET mensaje_debug
    call WriteString
    mov edx, OFFSET buffer_json
    call WriteString
    call Crlf

    jmp ArchivoEncontrado
    
ContinuarEsperaArchivo:
    ; Mostrar punto de espera
    mov al, '.'
    call WriteChar
    ; Esperar un poco
    mov eax, 1000
    call Delay
    jmp BucleEsperaArchivo
    
ArchivoEncontrado:
    call Crlf
    mov edx, OFFSET mensaje_encontrado
    call WriteString
    call Crlf
    popad
    ret
EsperarArchivoIniciada ENDP

; ===================================================================
; PROCEDIMIENTO: BuscarPalabraIniciada
; Descripci�n: Busca la palabra "iniciada" en el buffer
; Par�metros: EDX = offset del buffer
; Retorna: EAX = 1 si encuentra, 0 si no
; ===================================================================
BuscarPalabraIniciada PROC
    pushad
    
    mov esi, edx
    mov ecx, bytes_leidos
    sub ecx, 7  ; Tama�o m�nimo para contener "iniciada" (8 caracteres)
    
    ; Verificar que tenemos suficientes caracteres
    cmp ecx, 0
    jle NoEncontradoIniciada
    
BuscarIniciadaLoop:
    cmp ecx, 0
    jle NoEncontradoIniciada
    
    ; Verificar si los siguientes 8 caracteres son "iniciada"
    mov al, [esi]
    cmp al, 'i'
    jne SiguienteIniciada
    
    mov al, [esi+1]
    cmp al, 'n'
    jne SiguienteIniciada
    
    mov al, [esi+2]
    cmp al, 'i'
    jne SiguienteIniciada
    
    mov al, [esi+3]
    cmp al, 'c'
    jne SiguienteIniciada
    
    mov al, [esi+4]
    cmp al, 'i'
    jne SiguienteIniciada
    
    mov al, [esi+5]
    cmp al, 'a'
    jne SiguienteIniciada
    
    mov al, [esi+6]
    cmp al, 'd'
    jne SiguienteIniciada
    
    mov al, [esi+7]
    cmp al, 'a'
    jne SiguienteIniciada
    
    ; Encontrado
    mov eax, 1
    jmp FinBuscarIniciada
    
SiguienteIniciada:
    inc esi
    dec ecx
    jmp BuscarIniciadaLoop
    
NoEncontradoIniciada:
    mov eax, 0
    
FinBuscarIniciada:
    popad
    ret
BuscarPalabraIniciada ENDP

; ===================================================================
; PROCEDIMIENTO: ConfirmarInvitacion
; Descripci�n: Modifica el archivo a estado "recibida"
; ===================================================================
ConfirmarInvitacion PROC
    pushad
    
    ; Abrir archivo para escritura
    mov edx, OFFSET archivo_partida
    call CreateOutputFile
    mov handle_archivo, eax
    
    ; Escribir JSON con estado "recibida"
    mov eax, handle_archivo
    mov edx, OFFSET json_recibida
    mov ecx, LENGTHOF json_recibida - 1
    call WriteToFile
    
    ; Cerrar archivo
    call CerrarArchivo
    
    popad
    ret
ConfirmarInvitacion ENDP

; ===================================================================
; PROCEDIMIENTO: BucleJugadasA
; Descripci�n: Bucle principal de jugadas para el Jugador A
; ===================================================================
BucleJugadasA PROC
    pushad
    
BuclePrincipalA:

;Limpiar pantalla
    ;call Clrscr
    ; Mostrar mensaje de inicio
    mov edx, OFFSET titulo
    call WriteString
    call Crlf
    call Crlf

    ; Imprimir la matriz inicial
    call imprimir_matriz
    call Crlf

    ; Mostrar turno del jugador A
    mov edx, OFFSET turno_jugador
    call WriteString

    ; Leer el n�mero completo de la posici�n (ejemplo: 12)
    call ReadInt
    cmp eax, 0
    je mostrar_error_fuera_rango    ; Si se ingresa un 0 o un valor inv�lido, mostrar error

    ; Separar fila y columna del n�mero ingresado
    mov ebx, 10            ; Divisor para separar los d�gitos (fila y columna)
    mov edx, 0             ; Asegurarse de que EDX est� limpio antes de dividir
    div ebx                ; EAX contiene la fila, EDX contiene la columna

    ; Guardar fila y columna
    mov seleccion_fila, al   ; EAX tiene la fila
    mov seleccion_columna, dl ; EDX tiene la columna


     ; Verificar que la selecci�n est� dentro de los rangos v�lidos
    cmp seleccion_fila, 1
    jb mostrar_error_fuera_rango
    cmp seleccion_fila, 8
    ja mostrar_error_fuera_rango

    cmp seleccion_columna, 1
    jb mostrar_error_fuera_rango
    cmp seleccion_columna, 8
    ja mostrar_error_fuera_rango

    ; Calcular �ndice en la matriz para la selecci�n
    mov al, seleccion_fila
    sub al, 1            ; Convertir a �ndice basado en 0 (fila - 1)
    mov bl, al           ; Guardar el �ndice de la fila en BL

    mov al, seleccion_columna
    sub al, 1            ; Convertir a �ndice basado en 0 (columna - 1)

    mov bh, 8            ; Tama�o de cada fila es 8
    mov ah, 0            ; Asegurar que AH est� en 0 para evitar errores
    mul bh               ; fila * 8
    add al, bl           ; sumar la columna al resultado (AL contiene el �ndice correcto)
    mov esi, eax         ; Guardar el �ndice de la pieza seleccionada en ESI

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

    ; Verificar que la selecci�n est� dentro de los rangos v�lidos
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
    je error_bando_equivocado
    cmp pieza, 't'
    je validar_movimiento_tmin

    ; Validar el movimiento de la pieza "A" (si es una "A")
    cmp pieza, 'A'
    je error_bando_equivocado
     cmp pieza, 'a'
    je validar_movimiento_a_min

    ; Validar el movimiento de la pieza "R" (si es una "R")
    cmp pieza, 'R'
    je error_bando_equivocado
    cmp pieza, 'r'
    je validar_movimiento_r_min

    ; Validar el movimiento de la pieza "C" (si es una "C")
    cmp pieza, 'C'
    je error_bando_equivocado
     cmp pieza, 'c'
    je validar_movimiento_c_min

    ; Validar el movimiento de la pieza "K" (si es una "K")
    cmp pieza, 'K'
    je error_bando_equivocado
    cmp pieza, 'k'
    je validar_movimiento_k_min

    ; Validar el movimiento de la pieza "P" (si es una "P")
    cmp pieza, 'P'
    je error_bando_equivocado
    cmp pieza, 'p'
    je validar_movimiento_p_min

    ; Salto en caso de no cumplir las condiciones
    jmp realizar_movimiento
error_bando_equivocado:
    call Crlf
    mov edx, OFFSET error_bando_msg
    call WriteString
    call Crlf
    jmp BuclePrincipalA

mostrar_error_fuera_rango:
    call Crlf
    mWrite "Error: Coordenada fuera del rango permitido. Intente nuevamente."
    call Crlf
    jmp BuclePrincipalA

; ===================================================================


; VALIDACION DE MOVIMIENTOS PARA LAS PIEZAS EN MIN�SCULA


; ===================================================================

validar_movimiento_tmin:
    ; Validar movimiento en l�nea recta para la pieza "t"
    ; Movimiento v�lido si la fila es la misma o la columna es la misma

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
    jmp BuclePrincipalA


; ===================================================================

validar_movimiento_a_min:
    ; Validar movimiento en diagonal para la pieza "a"
    ; Movimiento v�lido si la diferencia absoluta entre fila y columna es la misma

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
    cmp bl, bh               ; Si |diferencia filas| == |diferencia columnas|, es un movimiento v�lido
    je verificar_letra_destino_min

    ; Si no se cumple la condici�n, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. El alfil solo puede moverse en diagonal."
    call Crlf
    jmp BuclePrincipalA

; ===================================================================

validar_movimiento_r_min:
    ; Validar movimiento en l�nea recta (como la torre) o en diagonal (como el alfil)

    ; Primero, validar si se est� moviendo como la torre (en l�nea recta)
    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino_min      ; Si las filas son iguales, el movimiento es v�lido como torre

    ; Verificar si la columna es la misma
    mov al, seleccion_columna
    cmp al, nueva_columna
    je verificar_letra_destino_min     ; Si las columnas son iguales, el movimiento es v�lido como torre

    ; Si no se mueve en l�nea recta, validar si se est� moviendo como el alfil (en diagonal)

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
    cmp bl, bh               ; Si |diferencia filas| == |diferencia columnas|, es un movimiento v�lido como alfil
    je verificar_letra_destino_min

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. La reina solo puede moverse como torre o alfil."
    call Crlf
    jmp BuclePrincipalA

; ===================================================================

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
    ; Movimiento v�lido si (|fila| = 2 y |columna| = 1) o (|fila| = 1 y |columna| = 2)

    cmp bl, 2
    je verificar_columna_1_min    ; Si la diferencia de filas es 2, verificar que la diferencia de columnas sea 1
    cmp bl, 1
    je verificar_columna_2_min    ; Si la diferencia de filas es 1, verificar que la diferencia de columnas sea 2
    jmp movimiento_invalido_min    ; Si no se cumple ninguna de las condiciones, el movimiento es inv�lido

verificar_columna_1_min:
    cmp bh, 1
    je verificar_letra_destino_min       ; Si la diferencia de columnas es 1, el movimiento es v�lido
    jmp movimiento_invalido_min

verificar_columna_2_min:
    cmp bh, 2
    je verificar_letra_destino_min        ; Si la diferencia de columnas es 2, el movimiento es v�lido
    jmp movimiento_invalido_min

movimiento_invalido_min:
    call crlf
    mWrite "Error: Movimiento no valido. El caballo solo puede moverse en forma de L."
    call Crlf
    jmp BuclePrincipalA

; ===================================================================


validar_movimiento_k_min:
    ; Validar movimiento en cualquier direcci�n para la pieza "K"
    ; El movimiento es v�lido si la diferencia en filas y columnas es de 1 o menos

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

    ; El movimiento es v�lido si la diferencia en filas y en columnas es 1 o menos
    cmp bl, 1
    ja movimiento_no_valido_k_min ; Si la diferencia en filas es mayor a 1, movimiento no v�lido

    cmp bh, 1
    ja movimiento_no_valido_k_min ; Si la diferencia en columnas es mayor a 1, movimiento no v�lido

    ; Si las diferencias son v�lidas, verificar la letra en la posici�n de destino
    jmp verificar_letra_destino_k_min

movimiento_no_valido_k_min:
    ; Si no se cumple la condici�n, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. El rey solo puede moverse una casilla en cualquier direccion."
    call crlf
    jmp BuclePrincipalA

verificar_letra_destino_k_min:
    ; Calcular el �ndice de la nueva posici�n
    mov al, nueva_fila
    sub al, 1            ; Convertir a �ndice basado en 0
    mov bl, al           ; Guardar el �ndice de la fila en BL

    mov al, nueva_columna
    sub al, 1            ; Convertir a �ndice basado en 0

    mov bh, 8            ; Tama�o de cada fila es 8
    mul bh               ; fila * 8
    add al, bl           ; Sumar la columna al resultado (AL contiene el �ndice correcto)
    mov edi, eax         ; Guardar el �ndice de la nueva posici�n en EDI

    ; Cargar la letra en la posici�n de destino
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
    jmp BuclePrincipalA

movimiento_valido_k_min:
    ; Realizar el movimiento si es v�lido
    jmp realizar_movimiento


; ===================================================================


validar_movimiento_p_min:
    ; Validar movimiento en l�nea recta para la pieza "P"
    ; Movimiento v�lido si la fila es la misma o la columna es la misma

    ; Verificar si la fila es la misma
    mov al, seleccion_fila
    cmp al, nueva_fila
    je verificar_letra_destino_min

    ; Si no se cumple ninguna de las dos condiciones, mostrar error
    call crlf
    mWrite "Error: Movimiento no valido. Los peones solo puede moverse de forma vertical"
    call Crlf
    jmp BuclePrincipalA


; ===================================================================

;Verificar que el destino no sean piezas min�sculas o del mismo bando
verificar_letra_destino_min:
    ; Calcular el �ndice de la nueva posici�n
    mov al, nueva_fila
    sub al, 1            ; Convertir a �ndice basado en 0
    mov bl, al           ; Guardar el �ndice de la fila en BL

    mov al, nueva_columna
    sub al, 1            ; Convertir a �ndice basado en 0

    mov bh, 8            ; Tama�o de cada fila es 8
    mul bh               ; fila * 8
    add al, bl           ; Sumar la columna al resultado (AL contiene el �ndice correcto)
    mov edi, eax         ; Guardar el �ndice de la nueva posici�n en EDI

    ; Cargar la letra en la posici�n de destino
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
    jmp BuclePrincipalA


; ===================================================================

; ===================================================================
movimiento_valido:
    ; Realizar el movimiento si es v�lido
    jmp realizar_movimiento


realizar_movimiento:
    ; Calcular la nueva posici�n en la matriz
    mov al, nueva_fila
    sub al, 1            ; Convertir a �ndice en base 0
    mov bl, al           ; Guardar el �ndice de la fila en BL

    mov al, nueva_columna
    sub al, 1            ; Convertir a �ndice en base 0

    mov bh, 8            ; Tama�o de cada fila es 8
    mul bh               ; fila * 8
    add al, bl           ; sumar la columna al resultado (AL contiene el �ndice correcto)
    mov edi, eax         ; Guardar el �ndice de la nueva posici�n en EDI

    ; Verificar si se va a eliminar un rey ('K' o 'k')
    mov al, matriz[edi]  ; Cargar la pieza en la nueva posici�n
    cmp al, 'K'
    je mostrar_victoria
    cmp al, 'k'
    je mostrar_victoria

    ; Mover la pieza seleccionada a la nueva posici�n
    mov al, pieza        ; Cargar la pieza desde la variable 'pieza'
    mov matriz[edi], al  ; Colocar la pieza en la nueva posici�n

    ; Limpiar la posici�n original despu�s de validar el movimiento
    mov matriz[esi], ' '  ; Dejar en blanco la posici�n original

    ; Mover el color de la letra a la nueva posici�n
    mov al, colorLetraMatriz[esi]  ; Cargar el color de la pieza seleccionada
    mov colorLetraMatriz[edi], al  ; Colocar el color en la nueva posici�n
    call Crlf
    
    ; Mostrar jugada textual: "Jugada A: <pieza> <fi><co> -> <fi><co>"
    mov edx, OFFSET mensaje_jugada_a
    call WriteString
    mov al, pieza
    call WriteChar
    mWrite " "
    mov al, seleccion_fila
    add al, '0'
    call WriteChar
    mov al, seleccion_columna
    add al, '0'
    call WriteChar
    mov edx, OFFSET flecha
    call WriteString
    mov al, nueva_fila
    add al, '0'
    call WriteChar
    mov al, nueva_columna
    add al, '0'
    call WriteChar
    call Crlf
    call Crlf
    
    ; Reimprimir visualmente el tablero actualizado
    call imprimir_matriz
    call Crlf

    ; Actualizar archivo con estado/turn/fen y esperar turno 'b'
    mActualizarPartidaYEsperarB

    jmp BuclePrincipalA  ; Regresar al ciclo de movimiento tras respuesta de B

mostrar_victoria:
    ; Mostrar el mensaje de victoria y terminar el juego
    call crlf
    mWrite "Has ganado! El rey ha sido eliminado."
    call crlf
    jmp finalizar  ; Terminar el juego










    finalizar:
    exit

    ; Capturar jugada del usuario
    ;mov edx, OFFSET buffer_entrada
    ;mov ecx, SIZEOF buffer_entrada
    ;call ReadString
    ;mov bytes_escritos, eax ; Guardar cantidad de caracteres le�dos




    ; Escribir jugada en JSON
    call EscribirJugadaA

    ; Verificar si la partida debe terminar
    call VerificarFinPartida
    cmp eax, 1
    je FinPartidaA

    ; Esperar jugada del Jugador B
    mov edx, OFFSET esperando_jugada
    call WriteString
    call Crlf

    call EsperarJugadaB

    ; Verificar si la partida debe terminar
    call VerificarFinPartida
    cmp eax, 1
    je FinPartidaA

    jmp BuclePrincipalA

FinPartidaA:
    popad
    ret
BucleJugadasA ENDP

; ===================================================================
; PROCEDIMIENTO: BucleJugadasB
; Descripci�n: Bucle principal de jugadas para el Jugador B
; ===================================================================
BucleJugadasB PROC
    pushad
    
BuclePrincipalB:
    ; Esperar jugada del Jugador A
    mov edx, OFFSET esperando_jugada
    call WriteString
    call Crlf
    
    call EsperarJugadaA
    
    ; Verificar si la partida debe terminar
    call VerificarFinPartida
    cmp eax, 1
    je FinPartidaB
    
    ; Mostrar turno del jugador B
    mov edx, OFFSET turno_jugador_b
    call WriteString
    
    ; Capturar jugada del usuario
    mov edx, OFFSET buffer_entrada
    mov ecx, SIZEOF buffer_entrada
    call ReadString
    
    ; Escribir jugada en JSON
    call EscribirJugadaB
    
    ; Verificar si la partida debe terminar
    call VerificarFinPartida
    cmp eax, 1
    je FinPartidaB
    
    jmp BuclePrincipalB
    
FinPartidaB:
    popad
    ret
BucleJugadasB ENDP

; ===================================================================
; PROCEDIMIENTO: EscribirJugadaA
; Descripci�n: Escribe la jugada del Jugador A en el archivo JSON
; ===================================================================
EscribirJugadaA PROC
    pushad

    ; Abrir archivo para escritura
    mov edx, OFFSET archivo_partida
    call CreateOutputFile
    mov handle_archivo, eax

    ; DEBUG: Mostrar jugada que se va a escribir
    mov edx, OFFSET mensaje_debug_jugada_a
    call WriteString
    mov edx, OFFSET buffer_entrada
    call WriteString
    call Crlf

    ; Escribir JSON con jugada del Jugador A
    mov eax, handle_archivo
    mov edx, OFFSET json_jugador_a
    mov ecx, LENGTHOF json_jugador_a - 1
    call WriteToFile

    ; Escribir la jugada (usar longitud real)
    mov eax, handle_archivo
    mov edx, OFFSET buffer_entrada
    mov ecx, bytes_escritos ; Usar la cantidad de caracteres le�dos
    call WriteToFile

    ; Escribir cierre del JSON
    mov eax, handle_archivo
    mov edx, OFFSET json_cierre
    mov ecx, LENGTHOF json_cierre - 1
    call WriteToFile

    ; DEBUG: Confirmar que la jugada fue escrita
    mov edx, OFFSET mensaje_encontrado
    call WriteString
    call Crlf

    ; Cerrar archivo
    call CerrarArchivo

    popad
    ret
EscribirJugadaA ENDP

; ===================================================================
; PROCEDIMIENTO: EscribirJugadaB
; Descripci�n: Escribe la jugada del Jugador B en el archivo JSON
; ===================================================================
EscribirJugadaB PROC
    pushad
    
    ; Abrir archivo para escritura
    mov edx, OFFSET archivo_partida
    call CreateOutputFile
    mov handle_archivo, eax
    
    ; Escribir JSON con jugada del Jugador B
    mov eax, handle_archivo
    mov edx, OFFSET json_jugador_b
    mov ecx, LENGTHOF json_jugador_b - 1
    call WriteToFile
    
    ; Escribir la jugada
    mov eax, handle_archivo
    mov edx, OFFSET buffer_entrada
    mov ecx, eax  ; Tama�o de la cadena le�da
    call WriteToFile
    
    ; Escribir cierre del JSON
    mov eax, handle_archivo
    mov edx, OFFSET json_cierre
    mov ecx, LENGTHOF json_cierre - 1
    call WriteToFile
    
    ; Cerrar archivo
    call CerrarArchivo
    
    popad
    ret
EscribirJugadaB ENDP

; ===================================================================
; PROCEDIMIENTO: EscribirJSONTurnFenW
; Descripción: Escribe el JSON requerido con estado/turn/fen tras jugada de A
; ===================================================================
EscribirJSONTurnFenW PROC
    pushad

    ; Construir FEN desde la matriz actual en buffer_fen
    call BuildFenFromMatriz

    ; Abrir/crear archivo para escritura
    mov edx, OFFSET archivo_partida
    call CreateOutputFile
    mov handle_archivo, eax

    ; Escribir prefijo JSON {"estado":..., "turn": "w", "fen": "
    mov eax, handle_archivo
    mov edx, OFFSET json_estado_turn_fen_prefix
    mov ecx, LENGTHOF json_estado_turn_fen_prefix - 1
    call WriteToFile

    ; Escribir FEN dinámico
    ; Calcular longitud del buffer_fen (hasta 0)
    mov esi, OFFSET buffer_fen
    xor ecx, ecx
@@
    ; loop para contar longitud
FenLenLoop:
    mov al, [esi+ecx]
    cmp al, 0
    je FenLenDone
    inc ecx
    jmp FenLenLoop
FenLenDone:
    mov eax, handle_archivo
    mov edx, OFFSET buffer_fen
    call WriteToFile

    ; Escribir cierre "}
    mov eax, handle_archivo
    mov edx, OFFSET json_cierre
    mov ecx, LENGTHOF json_cierre - 1
    call WriteToFile

    ; Cerrar archivo
    call CerrarArchivo

    popad
    ret
EscribirJSONTurnFenW ENDP

; ===================================================================
; PROCEDIMIENTO: BuildFenFromMatriz
; Descripción: Construye en buffer_fen el FEN del tablero actual
;              a partir de la matriz (fila 8 a 1). Agrega sufijo
;              " w KQkq - 0 1" al final.
; ===================================================================
BuildFenFromMatriz PROC
    pushad

    ; EDI -> donde escribir FEN
    mov edi, OFFSET buffer_fen
    ; limpiar buffer (opcional, escribimos terminador al final)

    ; EBP = índice de fila (7..0)
    mov ebp, 7

FilaLoop:
    ; DL = contador de espacios vacíos consecutivos en la fila
    xor edx, edx

    ; ESI = base de la fila (fila*8)
    mov esi, ebp
    imul esi, 8

    ; ECX = 8 columnas
    mov ecx, 8

ColLoop:
    mov al, matriz[esi]
    cmp al, ' '
    je CeldaVacia

    ; Si había vacíos pendientes, emitir dígito
    cmp dl, 0
    je NoVaciosPend
    mov bl, dl
    add bl, '0'
    mov [edi], bl
    inc edi
    xor dl, dl
NoVaciosPend:

    ; Mapear pieza local (T,C,A,R,K,P / t,c,a,r,k,p) a FEN estándar
    ; minusculas (negras)
    cmp al, 't'
    jne chk_c_min
    mov al, 'r'
    jmp EmitPieza
chk_c_min:
    cmp al, 'c'
    jne chk_a_min
    mov al, 'n'
    jmp EmitPieza
chk_a_min:
    cmp al, 'a'
    jne chk_r_min
    mov al, 'b'
    jmp EmitPieza
chk_r_min:
    cmp al, 'r'
    jne chk_k_min
    mov al, 'q'
    jmp EmitPieza
chk_k_min:
    cmp al, 'k'
    jne chk_p_min
    mov al, 'k'
    jmp EmitPieza
chk_p_min:
    cmp al, 'p'
    jne chk_T_may
    mov al, 'p'
    jmp EmitPieza

    ; mayúsculas (blancas)
chk_T_may:
    cmp al, 'T'
    jne chk_C_may
    mov al, 'R'
    jmp EmitPieza
chk_C_may:
    cmp al, 'C'
    jne chk_A_may
    mov al, 'N'
    jmp EmitPieza
chk_A_may:
    cmp al, 'A'
    jne chk_R_may
    mov al, 'B'
    jmp EmitPieza
chk_R_may:
    cmp al, 'R'
    jne chk_K_may
    mov al, 'Q'
    jmp EmitPieza
chk_K_may:
    cmp al, 'K'
    jne chk_P_may
    mov al, 'K'
    jmp EmitPieza
chk_P_may:
    cmp al, 'P'
    jne EmitPieza
    mov al, 'P'

EmitPieza:
    mov [edi], al
    inc edi
    jmp SiguienteCol

CeldaVacia:
    inc dl

SiguienteCol:
    inc esi
    loop ColLoop

    ; Al finalizar la fila, si quedan vacíos, emitir dígito
    cmp dl, 0
    je NoVaciosFinFila
    mov bl, dl
    add bl, '0'
    mov [edi], bl
    inc edi
    xor dl, dl
NoVaciosFinFila:

    ; Agregar '/' entre filas excepto después de la última (fila 0)
    cmp ebp, 0
    je UltimaFila
    mov byte ptr [edi], '/'
    inc edi
UltimaFila:

    dec ebp
    cmp ebp, -1
    jne FilaLoop

    ; Agregar sufijo de FEN
    mov esi, OFFSET fen_suffix
AddSufLoop:
    lodsb
    cmp al, 0
    je FinFen
    stosb
    jmp AddSufLoop

FinFen:
    ; Terminar con 0
    mov byte ptr [edi], 0

    popad
    ret
BuildFenFromMatriz ENDP

; ===================================================================
; PROCEDIMIENTO: EsperarJugadaA
; Descripci�n: Espera a que el Jugador A haga su jugada
; ===================================================================
EsperarJugadaA PROC
    pushad
    
BucleEsperaJugadaA:
    ; Abrir archivo para lectura
    mov edx, OFFSET archivo_partida
    call OpenInputFile
    mov handle_archivo, eax
    
    cmp eax, INVALID_HANDLE_VALUE
    je ContinuarEsperaJugadaA
    
    ; Leer contenido
    mov eax, handle_archivo
    mov edx, OFFSET buffer_json
    mov ecx, SIZEOF buffer_json
    call ReadFromFile
    mov bytes_leidos, eax
    
    ; Cerrar archivo
    call CerrarArchivo
    
    ; Buscar "jugadorA" en el buffer
    mov edx, OFFSET buffer_json
    call BuscarJugadorA
    cmp eax, 1
    je JugadaRecibidaA
    
ContinuarEsperaJugadaA:
    ; Esperar un poco
    mov eax, 1000
    call Delay
    jmp BucleEsperaJugadaA
    
JugadaRecibidaA:
    popad
    ret
EsperarJugadaA ENDP

; ===================================================================
; PROCEDIMIENTO: EsperarJugadaB
; Descripci�n: Espera a que el Jugador B haga su jugada
; ===================================================================
EsperarJugadaB PROC
    pushad
    
BucleEsperaJugadaB:
    ; Abrir archivo para lectura
    mov edx, OFFSET archivo_partida
    call OpenInputFile
    mov handle_archivo, eax
    
    cmp eax, INVALID_HANDLE_VALUE
    je ContinuarEsperaJugadaB
    
    ; Leer contenido
    mov eax, handle_archivo
    mov edx, OFFSET buffer_json
    mov ecx, SIZEOF buffer_json
    call ReadFromFile
    mov bytes_leidos, eax
    
    ; Cerrar archivo
    call CerrarArchivo
    
    ; Buscar cambio de turno a 'b' en el buffer
    mov edx, OFFSET buffer_json
    call BuscarTurnoB
    cmp eax, 1
    je JugadaRecibidaB
    
ContinuarEsperaJugadaB:
    ; Esperar un poco
    mov eax, 1000
    call Delay
    jmp BucleEsperaJugadaB
    
JugadaRecibidaB:
    popad
    ret
EsperarJugadaB ENDP

; ===================================================================
; PROCEDIMIENTO: BuscarJugadorA
; Descripci�n: Busca "jugadorA" en el buffer
; Par�metros: EDX = offset del buffer
; Retorna: EAX = 1 si encuentra, 0 si no
; ===================================================================
BuscarJugadorA PROC
    pushad
    
    mov esi, edx
    mov ecx, bytes_leidos
    sub ecx, 7  ; Tama�o m�nimo para contener "jugadorA"
    
BuscarJugadorALoop:
    cmp ecx, 0
    jle NoEncontradoJugadorA
    
    ; Verificar si los siguientes 8 caracteres son "jugadorA"
    mov al, [esi]
    cmp al, 'j'
    jne SiguienteJugadorA
    
    mov al, [esi+1]
    cmp al, 'u'
    jne SiguienteJugadorA
    
    mov al, [esi+2]
    cmp al, 'g'
    jne SiguienteJugadorA
    
    mov al, [esi+3]
    cmp al, 'a'
    jne SiguienteJugadorA
    
    mov al, [esi+4]
    cmp al, 'd'
    jne SiguienteJugadorA
    
    mov al, [esi+5]
    cmp al, 'o'
    jne SiguienteJugadorA
    
    mov al, [esi+6]
    cmp al, 'r'
    jne SiguienteJugadorA
    
    mov al, [esi+7]
    cmp al, 'A'
    jne SiguienteJugadorA
    
    ; Encontrado
    mov eax, 1
    jmp FinBuscarJugadorA
    
SiguienteJugadorA:
    inc esi
    dec ecx
    jmp BuscarJugadorALoop
    
NoEncontradoJugadorA:
    mov eax, 0
    
FinBuscarJugadorA:
    popad
    ret
BuscarJugadorA ENDP

; ===================================================================
; PROCEDIMIENTO: BuscarJugadorB
; Descripci�n: Busca "jugadorB" en el buffer
; Par�metros: EDX = offset del buffer
; Retorna: EAX = 1 si encuentra, 0 si no
; ===================================================================
BuscarJugadorB PROC
    pushad
    
    mov esi, edx
    mov ecx, bytes_leidos
    sub ecx, 7  ; Tama�o m�nimo para contener "jugadorB"
    
BuscarJugadorBLoop:
    cmp ecx, 0
    jle NoEncontradoJugadorB
    
    ; Verificar si los siguientes 8 caracteres son "jugadorB"
    mov al, [esi]
    cmp al, 'B'
    jne SiguienteJugadorB
    
    
    ; Encontrado
    mov eax, 1
    jmp FinBuscarJugadorB
    
SiguienteJugadorB:
    inc esi
    dec ecx
    jmp BuscarJugadorBLoop
    
NoEncontradoJugadorB:
    mov eax, 0
    
FinBuscarJugadorB:
    popad
    ret
BuscarJugadorB ENDP

; ===================================================================
; PROCEDIMIENTO: BuscarTurnoB
; Descripción: Busca la secuencia 'turn": "b' en el buffer
; Parámetros: EDX = offset del buffer
; Retorna: EAX = 1 si encuentra, 0 si no
; ===================================================================
BuscarTurnoB PROC
    pushad
    mov esi, edx
    mov ecx, bytes_leidos
    sub ecx, 9

BuscarTurnoBLoop:
    cmp ecx, 0
    jle NoEncontradoTurnoB

    mov al, [esi]
    cmp al, 't'
    jne SiguienteTurnoB
    mov al, [esi+1]
    cmp al, 'u'
    jne SiguienteTurnoB
    mov al, [esi+2]
    cmp al, 'r'
    jne SiguienteTurnoB
    mov al, [esi+3]
    cmp al, 'n'
    jne SiguienteTurnoB
    mov al, [esi+4]
    cmp al, '"'
    jne SiguienteTurnoB
    mov al, [esi+5]
    cmp al, ':'
    jne SiguienteTurnoB
    mov al, [esi+6]
    cmp al, ' '
    jne SiguienteTurnoB
    mov al, [esi+7]
    cmp al, '"'
    jne SiguienteTurnoB
    mov al, [esi+8]
    cmp al, 'b'
    jne SiguienteTurnoB
    mov eax, 1
    jmp FinBuscarTurnoB

SiguienteTurnoB:
    inc esi
    dec ecx
    jmp BuscarTurnoBLoop

NoEncontradoTurnoB:
    mov eax, 0

FinBuscarTurnoB:
    popad
    ret
BuscarTurnoB ENDP

; ===================================================================
; PROCEDIMIENTO: VerificarFinPartida
; Descripci�n: Verifica si la partida debe terminar
; Retorna: EAX = 1 si debe terminar, 0 si contin�a
; ===================================================================
VerificarFinPartida PROC
    pushad
    
    ; Por simplicidad, en esta implementaci�n b�sica
    ; la partida contin�a hasta que el usuario presione 'q' para salir
    ; En una implementaci�n completa, aqu� se verificar�an condiciones
    ; como jaque mate, tablas, etc.
    
    ; Por ahora, siempre retornamos 0 (continuar)
    mov eax, 0
    
    popad
    ret
VerificarFinPartida ENDP

; ===================================================================
; PROCEDIMIENTO: Procesos Para el juego
; Descripci�n: Diferentes procesos para manejar la jugabilidad
; ===================================================================
imprimir_matriz PROC
    ; Fila 8
    mWrite "                 "
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila8    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 56              ; �ndice para la fila 8 (T, C, A, R, K, A, C, T)
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila7    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 48              ; �ndice para la fila 7 (P, P, P, P, P, P, P, P)
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila6    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 40              ; �ndice para la fila 6
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila5    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 32              ; �ndice para la fila 5
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila4    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 24              ; �ndice para la fila 4
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila3    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 16              ; �ndice para la fila 3
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila2    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 8               ; �ndice para la fila 2
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
    mov eax, 15             ; Asegurar que el color del �ndice es blanco
    call SetTextColor
    mov edx, OFFSET fila1    ; Imprimir el n�mero de la fila
    call WriteString
    mov esi, 0               ; �ndice para la fila 1
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

    ; Imprimir los n�meros de las columnas
    mov eax, 15              ; Asegurar que el color de las columnas sea blanco
    call SetTextColor
    mov edx, OFFSET columnas
    call WriteString
    call Crlf

    ret
imprimir_matriz ENDP

imprimir_espacios_negros PROC
    ; Imprimir algunos espacios negros a la derecha del finX
    mov ecx, 10              ; N�mero de espacios a imprimir (ajustable)
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
    jne imprimir_caracter      ; Si no es especial, seguir con la impresi�n normal

    ; Si es una letra especial, cambiar el color del texto a rojo
    mov ah, al                ; Guardar el car�cter en AH para preservarlo
    mov eax, 0                ; Limpiar eax
    call GetTextColor         ; Obtener el color actual de la consola
    and eax, 0F0h             ; Mantener los 4 bits superiores (color de fondo)
    or eax,2h                ; Cambiar solo el color del texto a rojo (4), 2 verde, 1 azul, 3 celeste, 5 morado, 6 moztaza, 7 blanco, 8 gris 
    call SetTextColor           ; 12 azul, blanco y texto verde

imprimir_caracter:
    ; Imprimir la letra correspondiente
    mov al, matriz[esi]
    call WriteChar

    ;mWrite " "       ; Espacio para cambiar el ancho          <�������������������################################���������������������
    ; Restaurar el color del texto a blanco si fue modificado
    cmp al, 'T'
    jne continuar
    ; Restaurar el color del texto a blanco despu�s de la 'T'
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

    ; Incrementar el �ndice de la matriz
    add esi, 1
    ret
imprimir_letra ENDP
END main
