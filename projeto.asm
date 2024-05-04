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

    ; Parte em que as mensagens que vão aparecer para o usuario sao declaradas
    
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

    newline db 13, 10, 0  ; nova linha ; Nova linha em branco para usar como espaco entre linhas
    
    message3 db "Escolha sua opcao: ", 0
    message3_len equ $ - message3

    message4 db "Sua opcao foi: 1", 0
    message4_len equ $ - message4
    
    message5 db "Sua opcao foi: 2", 0
    message5_len equ $ - message5
    
    message6 db "Sua opcao foi: 3", 0
    message6_len equ $ - message6

    ; Buffers para guardar as variaveis providas pelo usuario
    
    buffer1 BYTE 128 DUP (0)    ; arquivo de entrada
    buffer2 BYTE 128 DUP (0)    ; arquivo de saida
    buffer3 BYTE 128 DUP (0)    ; chave de 7 numeros
    buffer4 BYTE 128 DUP (0)    ; opçao do usuario   
    
    numeros_chave DWORD 8 dup(0)        ; array de inteiros que armazena as chaves

    console_handle_out DWORD 0          ; handle para WriteConsole
    console_handle_in DWORD 0           ; handle para ReadConsole
    
    ; numero de caracteres lidos
    chars_read dd 0
    chars_read_saida dd 0       ; para o arquivo de said
    chars_read_entrada dd 0     ; para o arquivo de entrada

    fileHandle_entrada DWORD 0                  ; fileHandle para arquivo de entrada
    fileHandle_saida DWORD 0                    ; fileHandle para arquivo de saida

    fileBuffer BYTE 8 DUP (0)             ; variavel que recebe a string do arquivo
    fileBuffer_len equ $ - fileBuffer           ; tamanho de fileBuffer
    buffer_palavra BYTE 8 DUP(0)          ; variavel que vai receber a string com a chave aplicada
    buffer_palavra_len equ $ - buffer_palavra   ; tamanho de buffer_palavra
    
.code

; FUNCAO QUE APLICA A CHAVE EM fileBuffer E PASSA PARA buffer_palavra
funcao_cripto PROC
    push ebp
    mov ebp, esp

    mov edi, [ebp + 8]  ; apontar para o endereco da string (fileBuffer)
    mov esi, [ebp + 12] ; apontar para o endereco da chave (numeros_chave)
    mov ebx, [ebp + 16] ; apontar para o endereco da nova string (buffer_palavra) 

    mov ecx, 0
               
    _loop_chave2:    
        cmp ecx, 7
        jg _saida_cripto

        mov eax, [esi + ecx * 4] ; pegar digito da chave

        mov edi, [ebp + 8] ; apontar para o endereco da string
        add edi, ecx ; avancar no indice de fileBuffer
                        
        mov ebx, [ebp + 16]     
        add ebx, eax ; pegar a posicao em buffer_palavra onde edi vai ser inserido

        mov al, [edi] ; pegar o valor no indice de fileBuffer

        cmp al, 0
        je _caracter_nulo
                        
        mov [ebx], al  ; inserir elemento em nova string                                        

        inc ecx
        jmp _loop_chave2

                    
    ; No caso dos 8 bytes nao estarem completamente preenchidos, os que estiverem faltando sao completados com ' '
    _caracter_nulo:
    mov al, ' '
    mov [ebx], al  ; inserir elemento em nova string  
    inc ecx
    jmp _loop_chave2

    _saida_cripto:
        pop ebp
        ret 12 ; limpar 12 bytes dos parametros
funcao_cripto Endp

; FUNCAO RETIRA A CHAVE DE fileBuffer E PASSA PARA buffer_palavra
funcao_descripto PROC
    push ebp
    mov ebp, esp

    mov edi, [ebp + 8]  ; apontar para o endereco da string (fileBuffer)
    mov esi, [ebp + 12] ; apontar para o endereco da chave (numeros_chave)
    mov ebx, [ebp + 16] ; apontar para o endereco da nova string (buffer_palavra) 

    mov ecx, 0
               
    _decripto_loop_chave:    
                    
        cmp ecx, 7
        jg _saida_descripto

        mov eax, [esi + ecx * 4] ; pegar digito da chave

        mov al, [edi + eax] ; pegar digito correspondente a chave

        mov ebx, [ebp + 16]  
        add ebx, ecx  ; pegar indice atual de buffer_palavra


        mov [ebx], al ; inserir no indice atual de buffer_palavra o caracter retirado de fileBuffer
                        
        inc ecx
        jmp _decripto_loop_chave


    _saida_descripto:
        pop ebp
        ret 12
funcao_descripto Endp

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

        ; Loop para converter a chave que esta armazenada em formato de string em buffer 3 e passar em array de inteiros para numeros_chave

        mov esi, OFFSET buffer3
        mov edi, OFFSET numeros_chave
        mov ecx, 0
    
        _converter_chave:
            mov al, [esi + ecx]  ; Obter cada caractere da string
            sub al, '0'          ; Converter para número
            movzx eax, al        ; Expandir para DWORD para armazenamento
            mov [edi + ecx * 4], eax  ; Armazenar no array de inteiros
        
            inc ecx
            cmp ecx, 8
            jl _converter_chave


        invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia
        invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia

        ; multiline msg
        invoke WriteConsole, console_handle_out, addr multiLineMessage, multiLineMessage_len, NULL, NULL
        invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL  ; linha vazia

    
        ; message3
        invoke WriteConsole, console_handle_out, addr message3, message3_len, NULL, NULL
        invoke ReadConsole, console_handle_in, ADDR buffer4, sizeof buffer4, ADDR chars_read, 0

        ; codigo a seguir provido pelo professor que retira os caracteres desnecessarios de uma string, nesse caso do buffer4, que seria a escolha do usuario
        mov esi, offset buffer4 ; Armazenar apontador da string em esi
        _proximo4:
            mov al, [esi] ; Mover caractere atual para al
            inc esi ; Apontar para o proximo caractere
            cmp al, 13 ; Verificar se eh o caractere ASCII CR FINALIZAR
            jne _proximo4
            dec esi ; Apontar para caractere anterior
            xor al, al ; ASCII 0
            mov [esi], al ; Inserir ASCII 0 no lugar do ASCII CR

        ; Escolha do usuario a seguir:

        cmp buffer4, '1'
        je _cripto
    
        cmp buffer4, '2'
        je _descripto
    
        cmp buffer4, '3'
        je _sair

        ; Parte do codigo que aplica a chave de 8 em 8 bytes do arquivo de entrada

        _cripto:
            ; Mensagem na tela mostrando sua escolha
            invoke WriteConsole, console_handle_out, addr message4, message4_len, NULL, NULL
            invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia

            ; Abre o arquivo de entrada pré-existente
            invoke CreateFile, addr buffer1, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_entrada, eax

            ; No caso da abertura do arquivo der errado:
            cmp fileHandle_entrada, INVALID_HANDLE_VALUE
            je _erro_abrir_arquivo

            ; Abre o arquivo de saida
            invoke CreateFile, addr buffer2, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_saida, eax


            ; Limpar os buffers a seguir

            _zerar_Buffer_1:
                xor eax, eax


            _1_loop:
                cmp eax, 8
                jle _zerar_Buffer_2
                mov [fileBuffer + eax], 0
                add eax, 1

            _zerar_Buffer_2:
                xor eax, eax
                          
            _2_loop:
                cmp eax, 8
                jle _chave2
                mov [buffer_palavra + eax], 0
                add eax, 1
                
                
            _chave2:
                ; Ler 8 bytes do arquivo de entrada
                invoke ReadFile, fileHandle_entrada, addr fileBuffer, 8, addr chars_read_entrada, NULL ; 

                ; Aplicar a chave nesses 8 bytes e guardar em buffer_palavra

                ; mover os parametros para a pilha e aplicar a funcao que aplica a chave em fileBuffer e passa para buffer_palavra

                push OFFSET buffer_palavra
                push OFFSET numeros_chave
                push OFFSET fileBuffer

                call funcao_cripto

            _saida2:

                ; Se fileBuffer(onde estao armazenaodos os 8 bytes que a chave vai ser aplicada) for menor que 1, fecha os arquivos 
                cmp chars_read_entrada, 1
                jl _fechar_arquivos

                ; Escrever no arquivo de saida os 8 bytes
                
                invoke WriteFile, fileHandle_saida, addr buffer_palavra, 8, addr chars_read_saida, NULL ;
                
                jmp _zerar_Buffer_1
                 
            _fechar_arquivos:    
            
                invoke CloseHandle, fileHandle_saida

                invoke CloseHandle, fileHandle_entrada

                ; Fechar arquivos e voltar ao inicio do codigo

                jmp _Corpo

        ; Parte do codigo que retira a chave aplicada na string do arquivo
            
        _descripto:
        
            ; Mensagem mostrando a escolha do usuario
            invoke WriteConsole, console_handle_out, addr message5, message5_len, NULL, NULL
            invoke WriteConsole, console_handle_out, addr newline, 2, NULL, NULL ; linha vazia

            ; Abre o arquivo de entrada pré-existente
            invoke CreateFile, addr buffer1, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_entrada, eax

            ; No caso do arquivo nao abrir
            cmp fileHandle_entrada, INVALID_HANDLE_VALUE
            je _erro_abrir_arquivo

            ; abre o arquivo de saida
            invoke CreateFile, addr buffer2, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
            mov fileHandle_saida, eax
            

            ; Zerar os buffers a seguir:
            
            _decripto_zerar_Buffer_1:
                xor eax, eax


            _decripto_1_loop:
                cmp eax, 8
                jle _decripto_zerar_Buffer_2
                mov [fileBuffer + eax], 0
                add eax, 1

            _decripto_zerar_Buffer_2:
                xor eax, eax
                          
            _decripto_2_loop:
                cmp eax, 8
                jle _decripto_chave
                mov [buffer_palavra + eax], 0
                add eax, 1
                
                
            _decripto_chave:

                ; Ler 8 bytes do arquivo de entrada
                invoke ReadFile, fileHandle_entrada, addr fileBuffer, 8, addr chars_read_entrada, NULL ; 

                ; Retirar a chave aplicada em fileBuffer aqui e passar para buffer_palavra

                ; mover os parametros para a pilha e aplicar a funcao que retira a chave de fileBuffer e passa para buffer_palavra

                push OFFSET buffer_palavra
                push OFFSET numeros_chave
                push OFFSET fileBuffer

                call funcao_descripto
          

            _decripto_saida:

                ; Se o tamanho de fileBuffer nao for 8, fechar os arquivos
                cmp chars_read_entrada, 8
                jne _decripto_fechar_arquivos

                ; escrever no arquivo de saida os 8 bytes
                
                invoke WriteFile, fileHandle_saida, addr buffer_palavra, 8, addr chars_read_saida, NULL ;
                    
                jmp _decripto_zerar_Buffer_1
                 
            _decripto_fechar_arquivos:    

                ; Voltar ao inicio e fechar os arquivos
                
                invoke CloseHandle, fileHandle_saida

                invoke CloseHandle, fileHandle_entrada

                jmp _Corpo

            
        _sair:  

            ; Caso se o usuario decidir escolher 3, para sair do programa
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
