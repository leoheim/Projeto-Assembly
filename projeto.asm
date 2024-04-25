.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib
include \masm32\macros\macros.asm

.data
    teste db "testando", 0
    teste_len equ $ - teste
    
    message db "Digite o nome do arquivo de entrada: ", 0
    message_len equ $ - message
    
    message1 db "Digite o nome do arquivo de saida: ", 0
    message1_len equ $ - message1
    
    message2 db "Digite uma chave numerica de 8 caracteres entre '0' e '7': ", 0
    message2_len equ $ - message2
    
    multiLineMessage db "--Opcoes:--", 13, 10, "1. Criptografar", 13, 10, "2. Descriptografar", 13, 10, "3. Sair", 13, 10, 0
    multiLineMessage_len equ $ - multiLineMessage  ; comprimento da msg
    
    newline db 13, 10, 0  ; nova linha
    
    message3 db "Escolha sua opcao: ", 0
    message3_len equ $ - message3

    message4 db "Sua opcao foi: 1", 0
    message4_len equ $ - message4
    
    message5 db "Sua opcao foi: 2", 0
    message5_len equ $ - message5
    
    message6 db "Sua opcao foi: 3", 0
    message6_len equ $ - message6

    ; buffers para guardar as variaveis providas pelo usuario
    buffer1 BYTE 128 DUP (0)
    buffer2 BYTE 128 DUP (0)
    buffer3 BYTE 128 DUP (0)
    buffer4 BYTE 128 DUP (0)
    palavra_char db 0   ; buffer para cada caractere da palavra
    chave_char db 0 ; buffer para cada caractere da chave
    buffer_palavra BYTE 128 DUP(0)
    MAX_BUFFER_SIZE equ 256 ;
    indice_chave dd 0

    console_handle_out DWORD 0
    console_handle_in DWORD 0
    
    ; numero de caracteres lidos
    chars_read DWORD 0

    fileHandle_entrada DWORD 0  ;
    fileHandle_saida DWORD 0  ;

    fileBuffer BYTE 8 DUP (0)

    transposed_key BYTE 8 DUP (0)  ; Armazenar a chave convertida para índices
    temp_buffer BYTE 8 DUP (0)
    contador dd 0
    
.code
start:
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov console_handle_out, eax  ; armazenar o handle para saidas

    invoke GetStdHandle, STD_INPUT_HANDLE
    mov console_handle_in, eax  ; armazenar o handle para entradas

    _Corpo:
         invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia
         
        ; message
        invoke WriteConsole, console_handle_out, addr message, message_len, NULL, NULL
        invoke ReadConsole, console_handle_in, ADDR buffer1, sizeof buffer1, ADDR chars_read, 0

        ; codigo a seguir provido pelo professor que retira os caracteres desnecessarios de uma string, nesse caso do buffer1
        mov esi, offset buffer1 ; Armazenar apontador da string em esi
        _proximo1:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR FINALIZAR
            jne _proximo1
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR

      
        ; message1
        invoke WriteConsole, console_handle_out, addr message1, message1_len, NULL, NULL
        invoke ReadConsole, console_handle_in, ADDR buffer2, sizeof buffer2, ADDR chars_read, 0

        ; codigo a seguir provido pelo professor que retira os caracteres desnecessarios de uma string, nesse caso do buffer2
        mov esi, offset buffer2 ; Armazenar apontador da string em esi
        _proximo2:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR FINALIZAR
            jne _proximo2
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR

    
        ;message 2
        invoke WriteConsole, console_handle_out, addr message2, message2_len, NULL, NULL
        invoke ReadConsole, console_handle_in, ADDR buffer3, sizeof buffer3, ADDR chars_read, 0

        ; codigo a seguir provido pelo professor que retira os caracteres desnecessarios de uma string, nesse caso do buffer3
        mov esi, offset buffer3 ; Armazenar apontador da string em esi
        _proximo3:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR FINALIZAR
            jne _proximo3
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR

    
        invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia
        invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia

        ; multiline msg
        invoke WriteConsole, console_handle_out, addr multiLineMessage, multiLineMessage_len, NULL, NULL
        invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL  ; linha vazia

    
        ; message3
        invoke WriteConsole, console_handle_out, addr message3, message3_len, NULL, NULL
        invoke ReadConsole, console_handle_in, ADDR buffer4, sizeof buffer4, ADDR chars_read, 0

        ; codigo a seguir provido pelo professor que retira os caracteres desnecessarios de uma string, nesse caso do buffer4
        mov esi, offset buffer4 ; Armazenar apontador da string em esi
        _proximo4:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR FINALIZAR
            jne _proximo4
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR

        cmp buffer4, '1'
        je _cripto
    
        cmp buffer4, '2'
        je _descripto
    
        cmp buffer4, '3'
        je _sair
    

        _cripto:
            invoke WriteConsole, console_handle_out, addr message4, message4_len, NULL, NULL
            invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia

            ; Abre o arquivo de entrada pré-existente
            invoke CreateFile, addr buffer1, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_entrada, eax

            cmp fileHandle_entrada, INVALID_HANDLE_VALUE
            je _erro_abrir_arquivo

            invoke ReadFile, fileHandle_entrada, addr fileBuffer, 10, addr chars_read, NULL ; Lê 10 bytes do arquivo
            
            invoke CloseHandle, fileHandle_entrada 

            mov esi, OFFSET fileBuffer ; ponteiro para o início do buffer de origem
            mov edi, OFFSET buffer_palavra ; ponteiro para o início do buffer de destino
            mov ecx, 0 ; contador para o loop

            _copy_loop:
                ; copiar o caractere do buffer de origem para o buffer de destino
                mov al, [esi + ecx] ; obter o caractere atual da origem
                mov [edi + ecx], al ; copiar para o destino
    
                ; verificar se o caractere é nulo
                cmp al, 0
                je _chave ; se for nulo, terminamos de copiar
    
                ; incrementar o contador para o próximo caractere
                inc ecx
    
                ; evitar overflow no buffer de destino
                cmp ecx, MAX_BUFFER_SIZE
                jge _chave
    
                ; voltar para o início do loop
                jmp _copy_loop
            
            _chave:

                
                ; Aplicar a chave em fileBuffer aqui

                mov edi, OFFSET fileBuffer ; apontar para o endereco da string
                mov esi, OFFSET buffer3 ; apontar para o endereco da chave
                mov eax, OFFSET buffer_palavra
                
                mov ecx, 0 ; zera o contador
                mov contador, 0

                _loop:
                    invoke WriteConsole, console_handle_out, teste, teste_len, NULL, NULL
                    ; problema no loop so esta rodando uma vez
                    cmp contador, 7
                    jg _saida
                    invoke WriteConsole, console_handle_out, teste, teste_len, NULL, NULL

                    mov ecx, contador
                                        
                    mov dl, [esi + ecx] ; obter o caractere da chave
                    sub dl, '0' ; transformar o char da chave em inteiro

                    movzx ebx, dl
                        
                    mov al, [eax + ebx] ; pega o valor de buffer_palavra no indice da chave(ebx no caso)
                    
                    ; alterar o valor no indice atual de fileBuffer para o valor no indice inicial de buffer_palavra + dl
                    mov [edi + ecx], al

                    invoke WriteConsole, console_handle_out, addr fileBuffer, 8, NULL, NULL
                    
                    add contador, 1
                
                    jmp _loop

                
            _saida:
                
                ;arquivo de saida
                
                invoke CreateFile, addr buffer2, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                mov fileHandle_saida, eax

                invoke WriteFile, fileHandle_saida, addr fileBuffer, 10, addr chars_read, NULL ; Escreve 10 bytes do arquivo

                invoke CloseHandle, fileHandle_saida

                jmp _Corpo  ; Volta para o inicio

            
        _descripto:
            invoke WriteConsole, console_handle_out, addr message5, message5_len, NULL, NULL
            invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia


            ; Abre o arquivo de entrada pré-existente
            invoke CreateFile, addr buffer1, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_entrada, eax

            cmp fileHandle_entrada, INVALID_HANDLE_VALUE
            je _erro_abrir_arquivo

            invoke ReadFile, fileHandle_entrada, addr fileBuffer, 10, addr chars_read, NULL ; Le 10 bytes do arquivo

            invoke CloseHandle, fileHandle_entrada 

            ;arquivo de saida
                
            invoke CreateFile, addr buffer2, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_saida, eax

            invoke WriteFile, fileHandle_saida, addr fileBuffer, 10, addr chars_read, NULL ; Escreve 10 bytes do arquivo

            invoke CloseHandle, fileHandle_saida


            jmp _Corpo
            
        _sair:  
            invoke WriteConsole, console_handle_out, addr message6, message6_len, NULL, NULL
            invoke WriteConsole, console_handle_out, addr newline, 3, NULL, NULL ; linha vazia
            jmp _FimDoPrograma

        _erro_abrir_arquivo:
            invoke WriteConsole, console_handle_out, addr message1, message1_len, NULL, NULL
            jmp _FimDoPrograma

    
    ; Finalizar o programa
    _FimDoPrograma:
        invoke ExitProcess, 0
    
end start
