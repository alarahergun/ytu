;====================================================================
; Main.asm file generated by New Project wizard
;
; Created:   Per Şub 11 2016
; Processor: 8086
; Compiler:  MASM32
;
; Before starting simulation set Internal Memory Size 
; in the 8086 model properties to 0x10000
;====================================================================

CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS: DATA,   SS:STAK
 
STAK SEGMENT PARA STACK   'STACK'
        DW 20 DUP(?)
STAK  ENDS
 
 ;data segmentte dizi halinde tuşları tutacağım bu şekilde her seferinde bu tuşsa değer şudur sıkıntısından kurtuluyoruz 
 
DATA   SEGMENT PARA   'DATA'
CALC DB  0AH,  0EH, 00H, 0FH, 0BH, 03H, 02H, 01H, 0CH, 06H, 05H, 04H, 0DH, 09H, 08H, 07H ;burada keypadde neyin nereye geldiği tutuluyor
; + -> A, -  -> B, x -> C, / -> D, = -> E, C\ON -> F

DIGITS DB 00H, 00H, 00H ; işlem yapacağımız elemanlar tutuluyor
ONLUK DB 0
BIRLIK DB 0
DATA  ENDS

START: ;2. 8255le bu noktada bir bağlantımız yok, işlem sonunda aktileştireceğimiz için start içine yazmadık
	 
	 mov ax, data
	 mov ds, ax
	 
	mov dx, 206h
	mov al, 09h ; c4=1
	out dx, al
	mov al, 05h; c2=1
	out dx, al
	mov al, 0BCh ;control word için programlama a input, b output, c upper input c lower output
	out dx, al
	
	xor si, si
	
ENDLESS:

	 xor ax, ax ;herhangi bir değer kaldıysa tekrar bu bloğa gelindiğinde sorun yaşanmasın
	 xor dx, dx
    
BASLANGIC:

	mov dx, 204h; c portu okunuyor
        in al, dx ; pc3 intra tutar
	and al, 08h ; pc3 maskelenir 
	cmp al, 00 ; intra kontrolu
	je BASLANGIC ;onay gelmediği sürece tekrar kontrol

	mov dx, 200h ; intra = 1 ise a portundan değer okunuyor
	in ax, dx ; tuş okundu, kontrol etmeden pozitif olduğunu kabul ediyoruz
	
	SUB AX, 0F0H
	
	MOV DI, AX
	MOV AL, CALC[DI] ;burada sayı değeri alındı yukarıdaki diziden
	
	;şimdi basılanın sayı veya operatör olduğunu kontrol edeceğiz
	
	CMP SI, 00H
	JE SAYI
	CMP SI, 01H
	JE OPERAT
	 
SAYI: ;basılan şey sayı

	CMP AL, 009H
	JA ENDLESS
	
	MOV DIGITS[SI], AL
	JMP YEDI_SEG

OPERAT: ;basılan şey operatör

	CMP AL, 009H
	JBE ENDLESS
	
	MOV DIGITS[SI], AL
	JMP YEDI_SEG

YEDI_SEG: ;burası led'e değer yaktırma label'ı

	CMP SI, 00H ; BIR SAYI GOSTER
	JNE OPERATOR 

	MOV BL, 00100000B
	ADD AL, BL

	PUSH AX
	
tekrarla: ;burası handshake için 

	mov dx, 204h
	in al, dx ; pc0 intrb tutar
	and al, 01h ; pc0 maskelenir
	cmp al, 00 ; intrb kontrolü
	je tekrarla
	POP AX
	
	MOV DX, 0202H ; intrb = 1 ise yazma yapılır
	OUT DX, AL ; ILK SAYI YAZDIRILDI
	INC SI	
	JMP ENDLESS

OPERATOR:

	CMP SI, 001H
	JNE SONUC
	
	XOR AL, AL
	MOV BL, 00100000B
	ADD AL, BL
	PUSH AX
	
tekrarla2: ;handshake kısımları

	mov dx, 204h
	in al, dx ; pc0 intrb tutar
	and al, 01h ; pc0 maskelenir
	cmp al, 00h ; intrb kontrolü
	je tekrarla2	
	
	POP AX
	MOV DX, 0202H
	OUT DX, AL
	INC SI
	JMP ENDLESS

SONUC:

	MOV CL, DIGITS[1] ; İŞARET ALINDI
	MOV AL, DIGITS[0] ; SAYI 1
	MOV BL, DIGITS[2] ; SAYI 2
	
	CMP CL, 0AH ; +
	JE TOPLAMA	
	CMP CL, 0BH ; -
	JE CIKARTMA	
	CMP CL, 0CH ; x
	JE CARPMA	
	CMP CL, 0DH ; /
	JE BOLME
	
TOPLAMA:	

	ADD AL, BL
	JMP BITIR
	
CIKARTMA:

	SUB AL, BL
	JMP BITIR
	
CARPMA:

	MUL BL
	JMP BITIR

BOLME:

	DIV BL
	
	 ;AL -> BOLUM AH -> KALAN
	
	CMP AH, 00H
	JNE IKI_BASAMAK
	
	MOV AH, 00h ; KALANLI BÖLME
	
	JMP BITIR
	
BITIR: 
      
	CMP AL, 00H ;eğer bölme harici bir işlem 0dan küçükse hata versin
	JB IKI_BASAMAK
	
	MOV CL, 10
	DIV CL 
	MOV ONLUK, AL
	MOV BIRLIK, AH
	CMP AL, 00H ; BOLUM 0 ISE TEK BASAMAK
	JNE IKI_BASAMAK

TEK_BASAMAK: 

tekrarla3:

	mov dx, 204h
	in al, dx ; pc0 intrb tutar
	and al, 01h ; pc0 maskelenir
	cmp al, 00h ; intrb kontrolü
	je tekrarla3
	
yazdir:

	MOV BL, 00100000B
	MOV AL, BIRLIK
	ADD AL, BL ;elde kalan birliklerin eklenmesi
	MOV DX, 202H
	OUT DX, AL
	
	mov dx, 204h 
	in al, dx ; pc3 intra tutar
	and al, 08h ; pc3 maskelenir 
	cmp al, 00h ; intra kontrolu
	
	mov dx, 200h 
	in ax, dx ; port a'dan tuş okundu
	SUB AX, 0F0H
	

	 MOV AL,80H ;2. 8255'e bağlanılır
	 OUT 66H,AL	 	  
	 

   CALL DELAY
      ;O
     MOV AL, 00H
     OUT 60H,AL
     MOV AL, 0FFH
     OUT 62H,AL
      
      CALL DELAY
     CALL DELAY
           ;N
     MOV AL, 0CDH
     OUT 60H,AL
     MOV AL, 57H
     OUT 62H,AL
      
      CALL DELAY
     CALL DELAY
	    ;A
     MOV AL, 00CH
     OUT 60H,AL
     MOV AL, 0EEH
     OUT 62H,AL
      
      CALL DELAY
     CALL DELAY
     ;Y
     MOV AL, 0FFH
     OUT 60H,AL
     MOV AL, 05BH
     OUT 62H,AL

     JMP ENDLESS
     
	 
IKI_BASAMAK: 

	 MOV AL,80H ;2. 8255'e bağlanılır
	 OUT 66H,AL	
	 
   CALL DELAY
   CALL DELAY
      ;H
     MOV AL, 0CCH
     OUT 60H,AL
     MOV AL, 0EEH
     OUT 62H,AL
     
     CALL DELAY
     CALL DELAY
           ;A
     MOV AL, 0CDH
     OUT 60H,AL
     MOV AL, 0EEH
     OUT 62H,AL
     
      CALL DELAY
     CALL DELAY
	    ;T
     MOV AL, 3FH
     OUT 60H,AL
     MOV AL, 0BBH
     OUT 62H,AL
     
      CALL DELAY
     CALL DELAY
     ;A
     MOV AL, 0CH
     OUT 60H,AL
     MOV AL, 0EEH
     OUT 62H,AL

     JMP ENDLESS
     
     
  DELAY PROC NEAR ;örnekte verilen procedure
	 PUSH CX
	 MOV CX, 05FFFh
	 COUNT:
	 LOOP COUNT
	 POP CX
	 RET
  DELAY ENDP
	
SIFIRLA:
	XOR SI, SI
	MOV DX, 202H
	XOR AL, AL
	OUT DX, AL
	JMP ENDLESS
	 
CODE    ENDS
        END START