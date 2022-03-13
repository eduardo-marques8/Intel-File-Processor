;====================================================================
;	Trabalho de Programação INTEL
;	por Eduardo Luís Marques. Número de Matrícula: 00323594	
;====================================================================

; início do módulo principal
	.model		small ; diretiva do modelo de memória definido como small: 1 segmento de código (NEAR) e 1 segmento de dados (NEAR)
	.stack ; cria e encerra um segmento de pilha com 1K byte

; declaração de constantes
CR		equ		0dh ; constante igual ao valor hexadecimal na tabela ascii da tecla Carriage Return
LF		equ		0ah ; constante igual ao valor hexadecimal na tabela ascii da tecla Line Feed
PONTO	equ		2eh ; constante igual ao valor hexadecimal na tabela ascii da tecla .

; declaração de variáveis
	.data ; declara o segmento default de dados
FileNameSrc		db		256 dup (?) ; string do nome do arquivo .txt de origem		
FileNameDst		db		256 dup (?)	; string do nome do arquivo .res de destino
FileBuffer		db		10 dup (?) ; buffer com o valor lido no arquivo origem
FileHandleSrc	dw		0 ; handle do arquivo de origem
FileHandleDst	dw		0 ; handle do arquivo de destino
FileNameBuffer	db		150 dup (?) ; buffer pra copiar o nome do arquivo de origem para o nome do destino
TamanhoSrc		db		0 ; tamanho do nome do arquivo de origem
InvalidLine		db		0 ; flag que indica se uma linha lida é inválida
InvalidNumber	db		0 ; flag que indica se um número inválido foi lido
DecBuffer		db		30 dup (?) ; buffer do dado decimal lido do arquivo
FracBuffer		db		30 dup (?) ; buffer do dado fracionário lido do arquivo
index_dec		db		0 ; index do buffer decimal
index_frac		db		0 ; index do buffer fracional
FracFlag		db		0 ; flag que indica a leitura de dados fracionários
CRLFFlag		db		0 ; flag que indica que foi lido o caractere CR ou LF
VPFlag			db		0 ; flag que indica se foi lida uma vírgula ou um ponto
Decimal			dw		0 ; dado no buffer decimal convertido para valor numérico
Fracional		dw		0 ; dado no buffer fracionário convertido para valor numérico
Paridades		db		0 ; variável que conta o número de "1"s no número binário
ParidadeDec		db		0 ; valor da paridade do número decimal
ParidadeFrac	db		0 ; valor da paridade do número fracionário
SomaDec			dw		0 ; soma dos números decimais
SomaFrac		dw		0 ; soma dos números fracionários
Tam				dw		0 ; variável usada para calcular o tamanho de strings durante o código
QntNmrs			db		0 ; quantidade de números lidos
Quociente		dw		0 ; quociente da divisão da soma dos números com a quantidade (usada para calcular a média)
Cem_flag		db		0 ; flag que indica se foi lido cem números
Divide			db		0 ; resto da divisão da quantidade de números por 2
VarMul			dw		2 dup (?) ; variável de 32 bits para guardar a multiplicação por 100 da soma
String			db		10 dup (?) ; string usada para colocar os números, em ascii, no arquivo
sw_n			dw		0 ; número inteiro de 16 bits que será convertido para String
sw_f			db		0 ; flag que indica se há zeros a esquerda do número
sw_m			dw		0 ; variável para dividir o número sw_n
Par_ou_Impar	db		0 ; flag que indica se a quantidade de números é par ou ímpar (1 é par 0 é ímpar)

; declaração de strings constantes
MsgPedeArquivo		db	"Nome do arquivo: ", 0 ; mensagem aparece na tela para pedir o nome do arquivo origem
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0 ; mensagem aparece na tela se houve erro para abrir o arquivo
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0 ; mensagem aparece na tela se houve erro para ler o arquivo
MsgCRLF				db	CR, LF, 0 ; começa uma nova linha na tela
MsgErroCreateFile	db	"Erro na criacao do arquivo.", CR, LF, 0 ; mensagem aparece na tela se houve erro para criar o arquivo
MsgSucesso			db	" criado com sucesso.", CR, LF, 0 ; mensagem de sucesso com o nome do arquivo destino aparece na tela se não houve erros
MsgHifen			db	" - " ; caractere - em ascii
MsgSoma				db	"Soma: " ; mensagem de indicação da soma no arquivo destino
MsgMedia			db	"Media: " ; mensagem de indicação da média no arquivo destino
Cnt					db	"0","0","1" ; contador dos números lidos (começa em 001, em ascii)
Space				db	" " ; tecla space em ascii
CRLF				db	CR, LF ; começa uma nova linha no arquivo destino
Comma				db	"," ; caractere , em ascii
Zero				db	"0" ; número zero em ascii

; declaração do segmento de código
	.code ; início
	.startup ; ponto de entrada do programa

	call	GetFileName ; chama a subrotina que pega o nome do arquivo de origem
	
	mov		al,0 ; zera registrador A low pra poder usar a interrupção em A high
	lea		dx,FileNameSrc ; pega o nome do arquivo origem
	call	fopen ; abre esse arquivo
	mov		FileHandleSrc,ax ; move o handle gerado para a variável de origem
	jnc		Cria_Destino ; se não deu carry (ou seja, conseguiu abrir), pula para a criação do arquivo destino
	jmp		Erro_abertura ; se sim, informa o erro de abertura
	
Cria_Destino:	
	lea		dx,FileNameDst ; pega o nome do arquivo destino
	call	fcreate ; cria um arquivo com esse nome
	mov		FileHandleDst,ax ; move o handle gerado para a variável de destino
	jnc		Loop_Copia_Dados ; se não deu carry, pula para a leitura dos dados no arquivo origem

	mov		bx,FileHandleSrc ; se sim, pega o handle do arquivo origem
	call	fclose ; fecha esse arquivo
	jmp		Erro_criar ; informa o erro de criação

Loop_Copia_Dados:
	cmp		Cem_flag,1 ; confere se a flag de leitura de 100 números foi ativada
	jne		Continua_Copia ; se não, continua a leitura
	mov		ax,0 ; se sim, ativa o indicar de fim de arquivo
	jmp		Checa_Fim_Arquivo ; e encerra o programa

Continua_Copia:
	mov		bx,FileHandleSrc ; pega o handle do arquivo origem
	lea		dx,FileBuffer ; define FileBuffer como o local onde será salvo os dados lidos
	mov		cx,1 ; seta a quantidade de bytes que serão lidos como 1
	call	fread ; faz a leitura do arquivo
	jnc		Checa_Fim_Arquivo ; se não houve erro, checa se chegou no fim do arquivo
	jmp		Erro_leitura ; se houve, informa o erro de leitura

Checa_Fim_Arquivo:
	cmp		ax,0 ; checa a quantidade de bytes lidos (0 se chegou no fim do arquivo)
	jg		Checa_Dados ; se for maior que 0, checa os dados lidos

	cmp		VPFlag,1 ; se não, checa se a flag de vírgula ou ponto foi ativada (verifica se o último valor lido é válido para escrever no arquivo destino)
	jne		Nao_Escreve_Fim ; se não foi, o valor não é válido e não escreve no arquivo destino
	call	Escreve_Dados ; se sim, chama a subrotina de escrever no arquivo destino

Nao_Escreve_Fim:
	call	Escreve_Soma_Media ; escreve a soma e a média dos valores lidos no arquivo destino
	jmp		Fecha_Encerra ; pula para o fim do programa

Checa_Dados:
	mov		bl,FileBuffer ; move o dado lido para o registrador BL
	cmp		bl,CR ; checa se foi lido o CR
	je		Trata_CRLF ; se sim, pula para o tratamento do CR/LF
	cmp		bl,LF ; checa se foi lido o LF
	je		Trata_CRLF ; se sim, pula para o tratamento do CR/LF
	mov		bl,InvalidLine ; checa a flag de linha inválida
	cmp		bl,0 ; se estiver ativada
	jne		Loop_Copia_Dados ; pula para a leitura de outro dado no arquivo origem
	mov		bl,FileBuffer ; se não, checa de novo o dado lido
	cmp		bl,',' ; se foi uma vírgula
	je		Trata_Virgula_Ponto ; faz o tratamento pra vírgula e ponto
	cmp		bl,'.' ; se foi um ponto
	je		Trata_Virgula_Ponto ; faz o tratamento pra vírgula e ponto
	cmp		bl,09h ; se foi um tab
	je		Loop_Copia_Dados ; lê o próximo dado
	cmp		bl,20h ; se foi a tecla space
	je		Loop_Copia_Dados ; lê o próximo dado

Checa_Numero:
	cmp		bl,'0' ; se o dado lido for menor que o número 0 na tabela ascii
	jb		Invalida_Linha ; invalida toda a linha
	je		Trata_Zero ; se for igual a zero, faz o tratamento específico desse caso
	cmp		bl,'9' ; se for menor ou igual ao número 9
	jbe		Salva_Numero ; salva o número lido

Invalida_Linha:
	mov		bl,1 ; seta pra 1
	mov		InvalidLine,bl ; a flag de linha inválida
	mov		VPFlag,0 ; zera a flag de vírgula/ponto
	mov		index_dec,0 ; zera o index dos decimais
	mov		index_frac,0 ; zera o index dos fracionários
	jmp		Loop_Copia_Dados ; e lê o próximo dado

Trata_CRLF:
	mov		bl,InvalidLine ; checa a flag de linha inválida
	cmp		bl,1 ; se estivar ativada
	je		PulaLinha ; desconsidera essa linha
	mov		bl,0 ; se não
	mov		InvalidLine,bl ; zera a flag
	mov		FracFlag,bl ; zera a flag de leitura fracionária (caso seja uma linha válida, o CR/LF indica o fim da leitura dessa linha)
	mov		bl,CRLFFlag ; checa a flag de CRLF (utilizada pra não ler os dois juntos)
	cmp		bl,1 ; se estiver ativada
	je		Loop_Copia_Dados ; lê o próximo dado
	mov		bl,1 ; se não
	mov		CRLFFlag,bl ; seta a flag de CRLF
	cmp		VPFlag,1 ; checa a flag de vírgula/ponto (como o CR ou o LF estarão no fim de linhas inválidas ou não, checa se o número lido possui vírgula ou ponto, o que é um dos requisitos pra torná-lo válido)
	jne		Nao_Escreve ; se não estiver ativada, não escreve os dados no arquivo destino
	mov		bl,0 ; zera
	mov		VPFlag,bl ; a flag de vírgula/ponto
	call	Escreve_Dados ; escreve os dados no arquivo destino
	jmp		Loop_Copia_Dados ; lê o próximo dado

Nao_Escreve:
	mov		index_dec,0 ; zera o index do buffer de valores decimais
	mov		index_frac,0 ; zera o index do buffer de valores decimais
	jmp		Loop_Copia_Dados ; lê o próximo dado

PulaLinha:
	mov		bl,0 ; zera
	mov		InvalidLine,bl ; a flag de linha inválida
	mov		bl,1 ; ativa
	mov		CRLFFlag,bl ; a flag de CRLF
	jmp		Loop_Copia_Dados ; lê o próximo dado

Trata_Virgula_Ponto:
	cmp		VPFlag,0 ; checa se já foi escrita uma vírgula/ponto
	jne		Invalida_Linha ; se sim, invalida a linha
	cmp		index_dec,0 ; checa se foi escrito algum dado na parte decimal
	jne		Continua_VP ; se foi, continua o tratamento normalmente
	mov		bl,0 ; se não, zera
	mov		CRLFFlag,bl ; a flag de CRLF
	mov		bl,index_dec ; lê o index dos decimais salvo
	mov		bh,0 ; zera o BH porque não precisa
	mov		al,30h ; move o valor 0 em ascii (hexadecimal) para o registrador al
	mov		[DecBuffer+bx],al ; move o zero para o buffer dos decimais na posição inicial
	inc		index_dec ; incrementa o valor de index_dec, para indicar que um dado foi lido

Continua_VP:
	mov		bl,1 ; ativa
	mov		FracFlag,bl ; a flag de números fracionários
	mov		VPFlag,bl ; a flag de vírgula/ponto
	jmp 	Loop_Copia_Dados ; lê o próximo dado

Trata_Zero:
	cmp		FracFlag,1 ; se a flag de leitura dos fracionários estiver ligada
	je		Salva_Numero_Frac ; lê o número fracionário
	cmp		index_dec,0 ; se não, checa se já foi lido algum dado anterior a esse zero
	jne		Salva_Numero ; se foi, escreve o zero no arquivo
	jmp		Loop_Copia_Dados ; se não, lê o próximo dado

Salva_Numero:
	mov		bl,0 ; zera
	mov		CRLFFlag,bl ; a flag de CRLF
	cmp		FracFlag,1 ; checa a flag de números fracionários
	je		Salva_Numero_Frac ; se estiver ligada, salva o número no buffer dos fracionários
	mov		bl,index_dec ; se não, lê o index dos decimais salvo
	mov		bh,0 ; zera o BH porque não precisa
	mov		al,FileBuffer ; move o dado lido pro registrador AL
	mov		[DecBuffer+bx],al ; move esse dado para o buffer dos decimais deslocado de index_dec
	inc		index_dec ; incrementa o valor de index_dec, para o próximo dado
	jmp 	Loop_Copia_Dados ; lê o próximo dado

Salva_Numero_Frac:
	mov		bl,index_frac ; lê o index dos fracionários
	mov		bh,0 ; zera o BH porque não precisa
	mov		al,FileBuffer ; move o dado lido pro registrador AL
	mov		[FracBuffer+bx],al ; move esse dado para o buffer dos fracionários deslocado de index_frac
	inc		index_frac ; incrementa o valor de index_frac, para o próximo dado
	jmp 	Loop_Copia_Dados ; lê o próximo dado

;====================================================================
;	DECLARAÇÃO DE SUBROTINAS
;====================================================================
;----------------------------------------------------------------------------------------
;====================================================================
;	GetFileName:
;	- Função para ler o nome do arquivo de origem digitado pelo usuário (com ou sem o tipo) e
;	  transformar em um arquivo destino .res com o mesmo nome;
;	- Nome digitado pode ter até no máximo 8 caracteres.
;====================================================================

GetFileName	proc	near ; opcode NEAR
	lea		bx,MsgPedeArquivo ; copia o endereço efetivo de MsgPedeArquivo pro registrador BX
	call	printf_s ; chama a subrotina para imprimir a mensagem na tela

	lea		dx,FileNameBuffer ; copia o endereço efetivo do buffer do nome do arquivo de origem para o registrador DX
	mov		byte ptr FileNameBuffer,100 ; define o número máximo de caracteres lidos como 100
	call	gets ; chama a subrotina para ler a string na tela

	mov		cl,FileNameBuffer+1 ; move o número de caracteres efetivamente lidos (sem considerar o CR) em byte[1] para o registrador CL
	cmp		cl,12 ; compara com o valor 12 (máximo de caracteres do nome + máximo do tipo = 8 + 3 = 11)
	jl		ProcuraPonto ; se for menor, o nome do arquivo é válido e procura foi digitado o tipo
	jmp		Erro_abertura ; se não, mostra o erro de abertura do arquivo

ProcuraPonto:
	lea		di,FileNameBuffer+2 ; copia o endereço efetivo da quantidade de caracteres lidos total
	mov		ax,ds ; ajusta ES
	mov		es,ax ; igual a DS
	mov		al,PONTO ; move o valor ascii de . para o registrador AL
	mov		ah,0 ; zera a parte high do registrador A
	repne	scasb ; enquanto (cx != 0 && Z == 0), procura pelo valor em AL no string e decrementa cx (seta a flag Z se encontrar)
	je		DecTipo ; se Z == 1, pula para decrementar a string de tipo do nome do arquivo

	; se cx == 0
	mov		cl,FileNameBuffer+1 ; move o número de caracteres efetivamente lidos (sem considerar o CR) em byte[1] para o registrador CL
	cmp		cl, 9 ; compara com o valor 9 (máximo de caracteres do nome = 8)
	jge		Erro_abertura ; se for maior ou igual, mostra o erro de abertura do arquivo
	mov		ch,0 ; se não, zera a parte high do registrador C
	mov		TamanhoSrc, cl ; move o valor em registrador cl para a variável de tamanho do nome do arquivo origem
	lea		si,FileNameBuffer+2 ; copia o endereço efetivo de início dos dados lidos no buffer
	lea		di,FileNameSrc ; copia o endereço efetivo do nome do arquivo origem
	call	strcpy ; chama a subrotina para copiar cl caracteres da string em FileNameBuffer para FileNameSrc
	jmp		FimGetFileName ; pula para o fim da subrotina

DecTipo:
	mov		cl,FileNameBuffer+1 ; move o número de caracteres efetivamente lidos (sem considerar o CR) em byte[1] para o registrador CL
	mov		TamanhoSrc, cl ; move o valor em registrador cl para a variável de tamanho do nome do arquivo origem
	sub 	cl, 4 ; subtrai o tamanho reservado para o tipo (no máximo 4 caracteres, contando o ponto)
	mov		ch,0 ; zera a parte high do registrador C
	lea		si,FileNameBuffer+2 ; copia o endereço efetivo de início dos dados lidos no buffer
	lea		di,FileNameDst ; copia o endereço efetivo do nome do arquivo destino
	call	strcpy ; chama a subrotina para copiar cl caracteres da string em FileNameBuffer para FileNameDst
	call	strcat_dst ; concatena o tipo .res no fim do nome do arquivo destino
	mov		cl,TamanhoSrc ; move o tamanho do nome do arquivo de origem para o registrador CL
	lea		si,FileNameBuffer+2 ; copia o endereço efetivo de início dos dados lidos no buffer
	lea		di,FileNameSrc ; copia o endereço efetivo do nome do arquivo origem
	call	strcpy ; chama a subrotina para copiar cl caracteres da string em FileNameSrc para FileNameDst
	ret ; retorna para o endereço na pilha

FimGetFileName:
	mov		cl,TamanhoSrc ; move o tamanho do nome do arquivo de origem para o registrador CL
	lea		si,FileNameSrc ; copia o endereço efetivo da quantidade de caracteres lidos total
	lea		di,FileNameDst ; copia o endereço efetivo do nome do arquivo destino
	call	strcpy ; chama a subrotina para copiar cl caracteres da string em FileNameSrc para FileNameDst
	call	strcat_dst ; concatena o tipo .res no fim do nome do arquivo destino
	ret ; retorna para o endereço na pilha
GetFileName	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Escreve_Dados:
;	- Função para escrever os dados lidos no arquivo de origem no arquivo de destino, dentro
;	  dos parâmetros pedidos.
;====================================================================

Escreve_Dados	proc	near ; opcode NEAR
	call	Check_Invalid ; chama a subrotina para testar se o número lido é válido
	cmp		InvalidNumber,1 ; se for inválido
	je		Invalid_Escreve ; não escreve no arquivo destino

	mov		bl,index_dec ; se não
	mov		bh,0 ; salva o index decimal
	mov		[DecBuffer+bx],0 ; coloca um 0 no fim do buffer decimal para indicar o fim da string
	lea		bx,DecBuffer ; pega o início da string decimal
	call	atoi ; transforma esse string em um número de 16 bits
	mov		Decimal,ax ; salva esse número na variável dos decimais
	mov		bl,index_frac ; salva o index fracionário
	mov		bh,0 ; pra repetir o mesmo processo
	mov		[FracBuffer+bx],0 ; coloca 0 para indicar o fim da string fracionário
	lea		bx,FracBuffer ; copia o início da string
	call	atoi ; transforma a string em um número de 16 bits
	mov		Fracional,ax ; salva esse número na variável dos fracionários

	call	Escreve_Cnt ; escreve o contador no arquivo destino
	cmp		index_dec,2 ; checa se a número decimal tem 2 dígitos
	jg		EscreveDec_Normal ; se tem mais, escreve normalmente
	jl		EscreveDec_Um ; se tem menos, coloca espaços antes do número para alinhar as vírgulas
	mov		bx,FileHandleDst ; se tem exatamente 2, copia o handle do arquivo destino
	lea		dx,Space ; copia o caractere space
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o space no arquivo
	lea		dx,DecBuffer ; copia o início da string decimal
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o primeiro dígito no arquivo
	lea		dx,DecBuffer+1 ; copia o próximo dígito
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o segundo dígito no arquivo
	call	Calc_Soma_Dec ; calcula a soma dos números decimais
	jmp		Escreve_Frac ; escreve o número fracionário

EscreveDec_Um:
	mov		bx,FileHandleDst ; copia o handle do arquivo destino
	lea		dx,Space ; copia o caractere space
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o space no arquivo
	lea		dx,Space ; copia o caractere space
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve mais um space no arquivo
	lea		dx,DecBuffer ; copia o início da string decimal
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o único dígito decimal no arquivo
	call	Calc_Soma_Dec ; calcula a soma dos números decimais
	jmp		Escreve_Frac ; escreve o número fracionário

EscreveDec_Normal:
	mov		bx,FileHandleDst ; copia o handle do arquivo destino
	lea		dx,DecBuffer ; copia o início da string decimal
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o primeiro dígito decimal
	lea		dx,DecBuffer+1 ; copia o segundo dígito decimal
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o segundo dígito decimal
	lea		dx,DecBuffer+2 ; copia o terceiro digito decimal
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	Calc_Soma_Dec ; calcula a soma dos números decimais
	call	fwrite ; escreve o terceiro digito decimal

Escreve_Frac:
	mov		bx,FileHandleDst ; copia o handle do arquivo destino
	lea		dx,Comma ; copia o caractere ','
	call	fwrite ; escreve a vírgula no arquivo

	cmp		index_frac,1 ; checa se o número fracionário lido tem 1 digito
	jg		EscreveFrac_Normal ; se tiver mais, escreve o número normalmente
	mov		bx,FileHandleDst ; se não, copia o handle do arquivo destino
	lea		dx,FracBuffer ; copia o início da string fracionária
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o único digito fracionário no arquivo
	lea		dx,Zero ; copia o valor zero em ascii
	call	fwrite ; escreve o zero no arquivo, depois do primeiro dígito fracionário
	call	Calc_Soma_Frac ; calcula a soma dos números fracionários
	jmp		Fim_Escreve ; pula para o fim da rotina de escrita

EscreveFrac_Normal:
	mov		bx,FileHandleDst ; copia o handle do arquivo destino
	lea		dx,FracBuffer ; copia o início da string fracionária
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o primeiro dígito no arquivo
	lea		dx,FracBuffer+1 ; copia o segundo digito do número fracionário
	mov		cx,1 ; seta a quantidade de bytes a serem escritos como 1
	call	fwrite ; escreve o segundo digito
	call	Calc_Soma_Frac ; calcula a soma dos números fracionários

Fim_Escreve:
	mov		cx,3 ; define 3 como o tamanho de bytes a serem escritos
	lea		dx,MsgHifen ; copia a mensagem do hífen
	call	fwrite ; escreve no arquivo
	call	Escreve_Paridade ; escreve a paridade dos números lidos
	lea		dx,CRLF ; copia os caracteres CRLF
	mov		cx,2 ; define o tamanho de bytes a serem escrtios como 2
	call	fwrite ; escreve eles no arquivo

Invalid_Escreve:
	mov		index_dec,0 ; zera o índice do buffer decimal
	mov		index_frac,0 ; zera o índice do buffer fracionário
	ret ; retorna para o endereço na pilha
Escreve_Dados	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Escreve_Paridade:
;	- Função para escrever a paridade par da parte inteira e fracionária do número lido e escrito no arquivo.
;	- A paridade par é 1 quando o número de bits de valor '1' for ímpar e 0 quando for par.
;====================================================================

Escreve_Paridade	proc	near ; opcode NEAR
	cmp		Decimal,0 ; checa se a parte decimal é igual a 0
	je		Continua_Paridade1 ; se for, continua o cálculo de paridade
	shl		Decimal,1 ; se não, faz um shift left na parte decimal
	jnc		Escreve_Paridade ; se não deu carry (ou seja, o bit que sofreu o shift é 0), checa o próximo bit
	inc		Paridades ; se deu, incrementa a quantidade de bits iguais a 1
	jmp		Escreve_Paridade ; checa o próximo bit

Continua_Paridade1:
	mov		bl,2 ; divide por 2
	mov		al,Paridades ; a quantidade de bits iguais a 1 calculada
	mov		ah,0 ; (não usa a parte high do registrador a)
	div		bl ; (2 salvo em bl)
	mov		Paridades,0 ; zera a variável de paridades para o próximo cálculo
	cmp		ah,0 ; compara se o quociente deu igual a 0 (ou seja, um número par de 1s)
	jne		Ativa_ParidadeD ; se não deu, ativa a paridade da parte decimal
	mov		al,0 ; se deu, desativa
	mov		ParidadeDec,al ; a paridade da parte decimal
	jmp		TestaP_Frac ; e pula para o teste da paridade fracionária

Ativa_ParidadeD:
	mov		al,1 ; ativa
	mov		ParidadeDec,al ; a paridade da parte decimal

TestaP_Frac:
	cmp		Fracional,0 ; checa se a parte fracionária é igual a 0
	je		Continua_Paridade2 ; se for, continua o cálcula de paridade
	shl		Fracional,1 ; se não, faz um shift left na parte fracionária
	jnc		TestaP_Frac ; se não deu carry, checa o próximo bit
	inc		Paridades ; se deu, incrementa a quantidade de bits iguais a 1
	jmp		TestaP_Frac ; checa o próximo bit

Continua_Paridade2:
	mov		bl,2 ; divide
	mov		al,Paridades ; a quantidade de bits iguais a 1 calculada
	mov		ah,0 ; (não usa a parte high do registrador a)
	div		bl ; por 2
	mov		Paridades,0 ; zera a variável de paridades para o próximo cálculo
	cmp		ah,0 ; compara se o quociente deu igual a 0
	jne		Ativa_ParidadeF ; se não deu, ativa a paridade da parte fracionária
	mov		al,0 ; se deu, zera
	mov		ParidadeFrac,al ; a partidade da parte fracionária
	jmp		Fim_Paridade ; e pula para o fim da escrita de paridade

Ativa_ParidadeF:
	mov		al,1 ; ativa
	mov		ParidadeFrac,al ; a paridade da parte fracionária

Fim_Paridade:
	mov		bx,FileHandleDst ; copia o handle do arquivo destino
	add		ParidadeDec,48 ; soma 48 para chegar no valor ascii da paridade decimal calculada (0 = 48 ou 1 = 49)
	mov		cx,1 ; quantidade de bytes a serem escritos igual a 1
	lea		dx,ParidadeDec ; copia o valor da paridade decimal
	call	fwrite ; escreve no arquivo
	add		ParidadeFrac,48 ; soma 48 para chegar no valor ascii da paridade fracionária calculada
	mov		cx,1 ; quantidade de bytes a serem escritos igual a 1
	lea		dx,ParidadeFrac ; copia o valor da paridade fracionária
	call	fwrite ; escreve no arquivo
	mov		Decimal,0 ; zera a variável para o número decimal lido
	mov		Fracional,0 ; zera a variável para o número fracionário lido
	ret ; retorna da subrotina
Escreve_Paridade	endp ; fim

;----------------------------------------------------------------------------------------
;====================================================================
;	Check_Invalid:
;	- Função para checar se o número lido está dentro dos limites pré-estabelecidos e
;	  indicar se deve ser escrito no arquivo destino.
;====================================================================

Check_Invalid	proc	near ; opcode NEAR
	cmp		DecBuffer,':' ; checa se o valor lido é menor que : em ascii (um valor a mais que o número 9)
	jl		Check_Lim ; se sim, checa o outro limite
	mov		bl,1 ; se não
	mov		InvalidNumber,bl ; ativa a flag de número inválido
	ret ; retorna para o endereço na pilha

Check_Lim:
	cmp		DecBuffer,'/' ; checa se o valor lido é maior que / em ascii (um valor abaixo que o número 0)
	jg		Check_Write ; se sim, verifica se foi lido parte decimal e fracionária
	mov		bl,1 ; se não
	mov		InvalidNumber,bl ; ativa a flag de número inválido
	ret ; retorna para o endereço na pilha

Check_Write:
	cmp		index_dec,0 ; checa se houve leitura de números na parte decimal
	jne		Check_Write_Frac ; se sim, checa a parte fracionária
	mov		bl,1 ; se não
	mov		InvalidNumber,bl ; ativa a flag de número inválido
	ret ; retorna para o endereço na pilha

Check_Write_Frac:
	cmp		index_frac,0 ; checa se houve leitura de números na parte fracionária
	jne		Check_Nmr ; se sim, checa os números lidos
	mov		bl,1 ; se não
	mov		InvalidNumber,bl ; ativa a flag de número inválido
	ret ; retorna para o endereço na pilha

Check_Nmr:
	cmp		index_dec,4 ; checa se o index de decimais é maior que 4 (ou seja, se foi lido um número maior que 999)
	jl		Continua_Check ; se não, checa outro limite
	mov		bl,1 ; se sim
	mov		InvalidNumber,bl ; ativa a flag de número inválido
	ret ; retorna para o endereço na pilha

Continua_Check:
	cmp		index_dec,2 ; checa se o index dos decimais é maior que 2 (ou seja, se foi lido um número maior que 99)
	jng		Checa_Frac ; se não, checa os fracionários
	cmp		DecBuffer,'5' ; se sim, verifica se o primeiro dígito desse número é maior que 5 em ascii (ou seja, o número é maior que 499)
	jl		Checa_Frac ; se não for maior, checa os fracionários
	mov		bl,1 ; se for
	mov		InvalidNumber,bl ; ativa a flag de número inválido
	ret ; retorna para o endereço na pilha

Checa_Frac:
	cmp		index_frac,2 ; checa se o index dos fracionários é maior que 2 (ou seja, se foi lido um número maior que 99)
	jg		Invalida_Frac ; se sim, invalida todo o número
	jmp		Fim_Check ; se não, o número é válido

Invalida_Frac:
	mov		bl,1 ; ativa
	mov		InvalidNumber,bl ; a flag de número inválido
	ret ; retorna para o endereço na pilha

Fim_Check:
	mov		bl,0 ; desativa
	mov		InvalidNumber,bl ; a flag de número inválido
	ret ; retorna para o endereço na pilha
Check_Invalid	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Escreve_Cnt:
;	- Função para escrever o contador no arquivo destino.
;====================================================================

Escreve_Cnt		proc	near ; opcode NEAR
	mov		bx,FileHandleDst ; copia o handle do arquivo destino
	lea		dx,Cnt ; salva a string Cnt (inicialmente em 001)
	mov		cx,3 ; define o número de bytes a serem escritos como 3
	call	fwrite ; escreve a string Cnt no arquivo destino
	lea		dx,MsgHifen ; salva o hífen " - "
	call	fwrite ; escreve no arquivo destino pra separar dos números
	call	Calc_Cnt ; calcula o próximo valor de Cnt
	inc		QntNmrs ; incrementa a quantidade de números lidos

	ret ; retorna para o endereço na pilha
Escreve_Cnt		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Escreve_Soma_Media:
;	- Função para escrever as mensagens de "Soma: " e "Media: " no fim do arquivo e seus respectivos valores calculados.
;====================================================================

Escreve_Soma_Media		proc	near ; opcode NEAR
	mov		bx,FileHandleDst ; salva o handle do arquivo destino
	lea		dx,MsgSoma ; copia a string "Soma: "
	mov		cx,6 ; quantidade de bytes a serem escritos = tamanho da string "Soma: "
	call	fwrite ; escreve a string no arquivo
	call	Print_Soma ; escreve a soma dos números lidos no arquivo
	mov		bx,FileHandleDst ; salva o handle do arquivo destino
	lea		dx,CRLF ; copia a mensagem de nova linha
	mov		cx,2 ; quantidade de bytes = 2
	call	fwrite ; pula uma linha no arquivo
	lea		dx,MsgMedia ; copia a string "Media: "
	mov		cx,7 ; quantidade de bytes a serem escritos = tamanho da string "Media: "
	call	fwrite ; escreve a string no arquivo
	call	Print_Media ; escreve a média calculada dos números lidos no arquivo

	ret ; retorna da subrotina
Escreve_Soma_Media		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Print_Soma:
;	- Função para escrever no arquivo a soma calculada dos números lidos.
;====================================================================

Print_Soma	proc	near ; opcode NEAR
	mov		ax,SomaDec ; copia o valor calcula da soma das partes decimais lidas
	lea		bx,String ; copia a variável String
	call	sprintf_w ; transforma o valor da soma decimal em uma string e salva na variável String
	lea		bx,String ; copia esse variável
	call	Calc_Tam ; calcula o tamanho dela
	mov		bx,FileHandleDst ; salva o valor do handle do arquivo destino
	lea		dx,String ; copia o valor de String
	mov		cx,Tam ; quantidade de bytes a serem escritos = tamanho de String
	call	fwrite ; escreve String no arquivo
	lea		dx,Comma ; copia um caractere ','
	mov		cx,1 ; 1 byte a ser escrito
	call	fwrite ; escreve a vírgula no arquivo
	mov		ax,SomaFrac ; copia o valor da soma dos fracionários
	cmp		ax,10 ; se for maior ou igual a 10
	jge		Print_Soma_Normal ; escreve normalmente o valor da soma
	mov		bx,FileHandleDst ; se não, salva o valor do handle do arquivo destino
	lea		dx,Zero ; copia o valor de zero em ascii
	mov		cx,1 ; 1 byte a ser escrito
	call	fwrite ; escreve um '0' no arquivo
	mov		ax,SomaFrac ; copia o valor da soma dos fracionários
	lea		bx,String ; salva a variável String
	call	sprintf_w ; transforma o valor da soma dos fracionários em uma string e salva nessa variável
	mov		bx,FileHandleDst ; salva o valor do handle do arquivo destino
	lea		dx,String ; copia o valor em String
	mov		cx,1 ; 1 byte a ser escrito
	call	fwrite ; escreve o primeiro dígito salvo em String (como já temos um 0 escrito anteriormente, ficamos com um número menor que 10)
	ret ; retorna da subrotina

Print_Soma_Normal:
	lea		bx,String ; salva a variável String
	call	sprintf_w ; transforma o valor da soma dos fracionários em uma string e salva nessa variável
	mov		bx,FileHandleDst ; salva o valor do handle do arquivo destino
	lea		dx,String ; copia o valor em String
	mov		cx,2 ; 2 bytes a serem escritos
	call	fwrite ; escreve o valor completo da soma dos fracionários (2 dígitos) no arquivo

	ret ; retorna da subrotina
Print_Soma	endp ; fim

;----------------------------------------------------------------------------------------
;====================================================================
;	Calc_Tam:
;	- Função para calcular tamanho de strings, quando necessário, e salvar na variável Tam.
;====================================================================

Calc_Tam	proc	near ; opcode NEAR
	mov		dl,[bx] ; copia o valor da string deslocado de acordo com bx
	cmp		dl,0 ; se for 0 (fim da string)
	je		Fim_Calc_Tam ; pula para o fim do cálculo da variável Tam

	inc		Tam ; se não, incrementa o valor da variável
	inc 	bx ; desloca um na string
	jmp		Calc_Tam ; pula para o início da rotina

Fim_Calc_Tam:
	ret ; retorna da rotina
Calc_Tam	endp ; fim

;----------------------------------------------------------------------------------------
;====================================================================
;	Print_Media:
;	- Função para escrever no arquivo a média calculada dos números lidos.
;====================================================================

Print_Media	proc	near ; opcode NEAR
	call	Calc_Media ; calcula o valor da média dos números lidos
	mov		ax,Quociente ; copia o valor calculado da média
	cmp		ax,100 ; checa se o quociente é menor que 100 (ou seja, a média calculada é maior ou igual a 1)
	jae		Continua_Print ; se for maior ou igual, escreve normal
	mov		bx,FileHandleDst ; se não, copia o handle do arquivo
	lea		dx,Zero ; copia o valor ascii do zero
	mov		cx,1 ; define 1 byte a ser escrito
	call	fwrite ; escreve esse zero
	lea		dx,Comma ; copia o valor ascii da vírgula
	mov		cx,1 ; 1 byte a ser escrito
	call	fwrite ; escreve a vírgula no arquivo
	mov		ax,Quociente ; copia o valor calculado da média
	cmp		ax,10 ; checa se o quociente é menor que 10 (ou seja, a média calculada é do tipo 0,0x)
	jae		Zero_X ; se for maior ou igual, imprime como 0,x
	lea		dx,Zero ; se não, copia o valor ascii do zero
	mov		cx,1 ; define 1 byte a ser escrito
	call	fwrite ; escreve esse zero

Zero_X:
	mov		ax,Quociente ; copia o valor calculado da média
	lea		bx,String ; salva a variável String
	call	sprintf_w ; transforma esse valor calculado na variável String
	mov		Tam,0 ; zera a variável Tam
	jmp 	Escreve_Media_Frac ; escreve a parte fracionária da média calculada

Continua_Print:
	mov		ax,Quociente ; copia o valor calculado da média
	lea		bx,String ; salva a variável String
	call	sprintf_w ; transforma esse valor calculado na variável String
	lea		bx,String ; copia o valor
	mov		Tam,0 ; zera a variável Tam
	call	Calc_Tam ; calcula o tamanho da string
	sub		Tam,2 ; subtrai 2 do tamanho pra pegar só a parte decimal da média
	mov		bx,FileHandleDst ; salva o handle do arquivo destino
	lea		dx,String ; copia a variável String
	mov		cx,Tam ; quantidade de bytes a serem escritos = Tam - 2
	call	fwrite ; escreve a parte decimal da média no arquivo
	lea		dx,Comma ; copia o valor ascii da vírgula
	mov		cx,1 ; 1 byte a ser escrito
	call	fwrite ; escreve a vírgula no arquivo

Escreve_Media_Frac:
	mov		ax,Quociente ; copia o valor calculado da média
	mov		bx,Tam ; salva o valor de Tam que é igual ao final da parte decimal da média calculada
	lea		dx,[String+bx] ; salva a parte fracionária da média (que é indicada pelo deslocamento em String a partir de Tam)
	mov		bx,FileHandleDst ; salva o handle do arquivo destino
	mov		cx,2 ; no máximo 2 bytes serão escritos
	call	fwrite ; escreve a parte fracionária da média no arquivo

	ret ; retorna da subrotina
Print_Media	endp ; fim

;----------------------------------------------------------------------------------------
;====================================================================
;	Calc_Media:
;	- Função para calcular a média dos valores lidos.
;====================================================================

Calc_Media	proc	near ; opcode NEAR
	mov		al,QntNmrs ; copia a quantidade de números lidos
	mov		ah,0 ; (número tem no máximo 8 bits)
	mov		bl,2 ; divide por 2
	div		bl ; esse quantidade
	mov		Divide,al ; e salva o quociente na variável Divide (usada para verificar se arredonda o último dígito da média)
	cmp		ah,0 ; checa se a divisão deu resto = 0 (ou seja, o número é par)
	jne		Def_Impar ; se não deu, a quantidade de números é ímpar
	mov		Par_ou_Impar,1 ; se deu, a quantidade é par

Def_Impar:
	mov		ax,100 ; multiplica por 100
	mul		SomaDec ; a soma dos números decimais (pra poder adicionar a soma dos fracionários que nunca vai passar de 99 e dividir pela quantidade de números)
	mov		VarMul,ax ; salva o valor em uma variável de 32 bits (o número pode passar de 65535)
	mov		VarMul+2,dx ; no formato little endian
	mov		bx,SomaFrac ; copia o valor da soma dos fracionários
	add		VarMul,bx ; adiciona na forma little endian ao valor achado na multiplicação
	mov		bl,QntNmrs ; salva a quantidade de números lidos
	mov		bh,0 ; (número de no máximo 8 bits)
	mov		ax,VarMul ; faz uma divisão
	mov		dx,VarMul+2 ; de 32 bits
	div		bx ; por um número de 16 bits
	mov		Quociente,ax ; salva o quociente
	mov		bl,Divide ; salva a variável divide
	mov		bh,0 ; (não passa de 8 bits)
	cmp		Par_ou_Impar,1 ; checa a flag de par ou ímpar sobre a quantidade de números
	jne		Eh_Impar ; se não estiver ativada, pula para o tratamento de números ímpares
	cmp		dx,bx ; se estiver, compara o resto da divisão acima com a variável divide
	jl		Fim_Media ; se o resto deu menor que a metade da quantidade de números, pula para o fim da rotina
	inc		Quociente ; se deu maior ou igual, arredonda pra cima o último dígito da média
	jmp		Fim_Media ; pula para o fim da rotina

Eh_Impar:
	cmp		dx,bx ; compara o resto da divisão acima com a variável divide
	jle		Fim_Media ; se o resto deu menor ou igual a metade da quantidade de números (por exemplo, 3/2 = 1.5, que no INTEL seria 1. Nesse caso, o resto teria que ser maior que 1), pula para o fim da rotina
	inc		Quociente ; arredonda pra cima o último dígito da média

Fim_Media:
	ret ; retorna da subrotina
Calc_Media	endp

;----------------------------------------------------------------------------------------
;====================================================================
;	Calc_Soma_Dec:
;	- Função para calcular a soma dos valores decimais lidos.
;====================================================================

Calc_Soma_Dec	proc	near ; opcode NEAR
	mov		ax,Decimal ; salva o valor decimal lido no registrador ax
	add		SomaDec,ax ; soma com o valor salvo em SomaDec

	ret ; retorna para o endereço na pilha
Calc_Soma_Dec	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Calc_Soma_Frac:
;	- Função para calcular a soma dos valores fracionários lidos.
;====================================================================

Calc_Soma_Frac	proc	near ; opcode NEAR
	call	Check_Frac ; ajusta o valor fracionário lido

	add		SomaFrac,ax ; soma o valor fracional calculado (no registrador ax) à variável SomaFrac
	cmp		SomaFrac,100 ; checa se a soma passou de 99
	jge		Soma1_dec ; se sim, soma 1 na soma decimal
	ret ; se não, retorna da subrotina

Soma1_dec:
	add		SomaDec,1 ; soma um à soma decimal
	sub		SomaFrac,100 ; subtrai 100 da soma fracionário (para ajustar esse +1 na soma decimal)

	ret ; retorna da subrotina
Calc_Soma_Frac	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Check_Frac:
;	- Função para checar se o número fracionário lido é do tipo ,x ou ,0x e ajustar.
;====================================================================

Check_Frac	proc	near ; opcode NEAR
	cmp		FracBuffer,0 ; checa se foi lido um primeiro dígito fracionário
	je		Fim_Check_Frac ; se não, pula para o fim da rotina
	cmp		FracBuffer+1,0 ; se sim, checa se foi lido um segundo digito (no caso de número do tipo ,x checa se possui mais algum valor depois do x)
	jne		Fim_Check_Frac ; se foi (ou seja, um número entre 0 e 9 em ascii), pula para o fim da rotina
	cmp		Fracional,10 ; se não, confere se o valor fracionário calculado é maior ou igual a 10
	jge		Fim_Check_Frac ; se for, pula para o fim da subrotina
	mov		ax,10 ; se não for, multiplica por 10 (para ajustar em números do tipo ,x)
	mul		Fracional ; o valor fracionário calculado
	mov		Fracional,ax ; e salva esse novo valor

Fim_Check_Frac:
	mov		ax,Fracional ; move o valor fracionário calculado para o registrador ax
	ret ; retorna para o endereço na pilha
Check_Frac	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	Calc_Cnt:
;	- Função para calcular o valor na string Cnt.
;====================================================================

Calc_Cnt		proc	near ; opcode NEAR
	inc		Cnt+2 ; incrementa o terceiro dígito de Cnt
	cmp		Cnt,'1' ; se não chegou em 100
	jne		Continua_CalcCnt ; continua incrementando
	mov		Cem_flag,1 ; se não, ativa a flag de que chegou em 100 números lidos

Continua_CalcCnt:
	cmp		Cnt+2,':' ; checa se o terceiro dígito é maior que 9 em ascii
	je		Zera_3 ; se for, faz o próximo passo
	ret ; se não, retorna para o endereço na pilha

Zera_3:
	mov		Cnt+2,'0' ; zera o terceiro dígito
	inc		Cnt+1 ; incrementa o segundo
	cmp		Cnt+1,':' ; checa se o segundo dígito é maior que 9 em ascii
	je		Zera_2 ; se for, faz o próximo passo
	ret ; se não, retorna para o endereço na pilha

Zera_2:
	mov		Cnt+1,'0' ; zera o segundo dígito
	inc		Cnt ; incrementa o primeiro
	ret ; retorna para o endereço na pilha
Calc_Cnt		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	gets:
;	- Função para ler uma string digitada no console.
;====================================================================

gets		proc	near ; opcode NEAR
	mov		ah,0ah ; define o código da interrupção 21h do sistema como 0ah, que representa a leitura de uma string do teclado
	int		21h ; chama a interrupção

	ret ; retorna para o endereço na pilha
gets		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	strcpy:
;	- Função para copiar o conteúdo de uma string em outra.
;====================================================================

strcpy		proc	near ; opcode NEAR
	mov		ax,ds ; ajusta ES				
	mov		es,ax ; igual a DS
	rep 	movsb ; copia CX caracteres do string iniciado em [DS:SI] para o string iniciado em [ES:DI]

	ret ; retorna para o endereço na pilha
strcpy		endp

;----------------------------------------------------------------------------------------
;====================================================================
;	strcat_dst:
;	- Função para concatenar no fim do nome do arquivo de destino a extensão ".res".
;====================================================================

strcat_dst	proc	near ; opcode NEAR
	mov		byte ptr es:[di],'.' ; coloca um . no byte menos significativo em es:[di]
	mov		byte ptr es:[di+1],'r' ; coloca um r no byte menos significativo em es:[di+1]
	mov		byte ptr es:[di+2],'e' ; coloca um e no byte menos significativo em es:[di+2]
	mov		byte ptr es:[di+3],'s' ; coloca um s no byte menos significativo em es:[di+3]
	mov		byte ptr es:[di+4],0 ; coloca um 0 no byte menos significativo em es:[di+4] (indica fim da string)

	ret ; retorna para o endereço na pilha
strcat_dst	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	printf_s:
;	- Função para colocar o conteúdo de uma string na tela;
;	- Lê a sequência de caracteres e imprime até chegar em 00h (equivalente a '\0').
;	- char *s -> BX
;====================================================================

printf_s	proc	near ; opcode NEAR
;	while (*s!='\0') {
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

;		putchar(*s)
	push	bx
	mov		ah,2
	int		21H
	pop		bx

;		++s;
	inc		bx		

;	}
	jmp		printf_s
		
ps_1:
	ret ; retorna para o endereço na pilha
printf_s	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	atoi:
;	- Função para converter uma string em um número de 16 bits.
;	- Lê a sequência de caracteres em ascii e transforma em número até chegar em 00h (equivalente a '\0').
;	- char *S -> BX
;	- word A -> AX
;====================================================================

atoi	proc near ; opcode NEAR
	; A = 0;
	mov		ax,0 
		
atoi_2:
	; while (*S!='\0') {
	cmp		byte ptr[bx], 0
	jz		atoi_1

	; 	A = 10 * A
	mov		cx,10
	mul		cx

	; 	A = A + *S
	mov		ch,0
	mov		cl,[bx]
	add		ax,cx

	; 	A = A - '0'
	sub		ax,'0'

	; 	++S
	inc		bx

	;}
	jmp		atoi_2

atoi_1:
	ret	; retorna para o endereço na pilha

atoi	endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	sprintf_w:
;	- Função para converter um número de 16 bits em uma string.
;	- word n -> AX e sw_n
;	- char *string -> BX
;	- int k -> CX
;	- word m -> sw_m
;	- int f -> sw_f
;====================================================================

sprintf_w	proc	near ; opcode NEAR

	;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax

	;	k=5;
	mov		cx,5

	;	m=10000;
	mov		sw_m,10000

	;	f=0;
	mov		sw_f,0

;	do {
sw_do:

	;		quociente = n / m : resto = n % m;
	mov		dx,0
	mov		ax,sw_n
	div		sw_m

	;		if (quociente || f) {
	;			*string++ = quociente+'0'
	;			f = 1;
	;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue

sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1

sw_continue:

	;		n = resto;
	mov		sw_n,dx
	
	;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	;		--k;
	dec		cx
	
;	} while(k);
	cmp		cx,0
	jnz		sw_do

	;	if (!f)
	;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx

sw_continua2:

	;	*string = '\0';
	mov		byte ptr[bx],0
	
	;}
	ret
sprintf_w	endp

;----------------------------------------------------------------------------------------
;====================================================================
;	FUNÇÕES DE ARQUIVOS
;====================================================================
;----------------------------------------------------------------------------------------
; INTERRUPÇÃO DO SISTEMA PARA ABRIR ARQUIVOS
fopen		proc	near ; opcode NEAR
	mov		ah,3dh
	int		21h

	ret ; retorna para o endereço na pilha
fopen		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
; INTERRUPÇÃO DO SISTEMA PARA CRIAR ARQUIVOS
fcreate		proc	near ; opcode NEAR
	mov		cx,0
	mov		ah,3ch
	int		21h

	ret ; retorna para o endereço na pilha
fcreate		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
; INTERRUPÇÃO DO SISTEMA PARA FECHAR ARQUIVOS
fclose		proc	near ; opcode NEAR
	mov		ah,3eh
	int		21h

	ret ; retorna para o endereço na pilha
fclose		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
; INTERRUPÇÃO DO SISTEMA PARA LER ARQUIVOS
fread		proc	near ; opcode NEAR
	mov		ah,3fh
	int		21h

	ret ; retorna para o endereço na pilha
fread		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
; INTERRUPÇÃO DO SISTEMA PARA ESCREVER EM ARQUIVOS
fwrite		proc	near ; opcode NEAR
	mov		ah,40h	
	int		21h

	ret ; retorna para o endereço na pilha
fwrite		endp ; fim da subrotina

;----------------------------------------------------------------------------------------
;====================================================================
;	IMPRESSÃO DOS ERROS NA TELA
;====================================================================
;----------------------------------------------------------------------------------------

Erro_abertura:
	lea		bx,MsgCRLF ; copia o endereço efetivo de MsgCRLF para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir uma nova linha na tela
	lea		bx,MsgErroOpenFile ; copia o endereço efetivo de MsgErroOpenFile para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir a mensagem de erro na tela
	
	.exit ; retorna para o S.O.

;----------------------------------------------------------------------------------------

Erro_criar:
	lea		bx,MsgCRLF ; copia o endereço efetivo de MsgCRLF para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir uma nova linha na tela
	lea		bx, MsgErroCreateFile ; copia o endereço efetivo de MsgErroCreateFile para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir a mensagem de erro na tela

	.exit ; retorna para o S.O.

;----------------------------------------------------------------------------------------

Erro_leitura:
	lea		bx,MsgCRLF ; copia o endereço efetivo de MsgCRLF para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir uma nova linha na tela
	lea		bx,MsgErroReadFile ; copia o endereço efetivo de MsgErroReadFile para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir a mensagem de erro na tela
	
	mov		bx,FileHandleSrc ; copia o handle do arquivo origem para o registrador BX	
	mov		ah,3eh ; chama a função para fechar arquivos
	int		21h ; interrupção do sistema
	mov		bx,FileHandleDst ; copia o handle do arquivo destino para o registrador BX		
	mov		ah,3eh ; chama a função para fechar arquivos
	int		21h ; interrupção do sistema

	.exit ; retorna para o S.O.

;----------------------------------------------------------------------------------------
;====================================================================
;	FIM DO PROGRAMA
;====================================================================
;----------------------------------------------------------------------------------------

Fecha_Encerra:
	mov		bx,FileHandleSrc ; copia o handle do arquivo origem para o registrador BX		 
	call	fclose ; chama a função para fechar arquivos
	mov		bx,FileHandleDst ; copia o handle do arquivo destino para o registrador BX	
	call	fclose ; chama a função para fechar arquivos

Final:
	lea		bx,MsgCRLF ; copia o endereço efetivo de MsgCRLF para o registrador BX
	call	printf_s ; chama a função printf_s para imprimir uma nova linha na tela
	lea		bx,FileNameDst ; copia o endereço efetivo do nome do arquivo de origem para o registrador BX
	call	printf_s ; imprime esse nome na tela
	lea		bx,MsgSucesso ; copia o endereço efetivo da mensagem de sucesso para o registrador BX
	call	printf_s ; imprime a mensagem na tela

	.exit ; retorna para o S.O.

;----------------------------------------------------------------------------------------

		end ; final do módulo