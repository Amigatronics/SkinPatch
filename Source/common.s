; common.s - rutinas compartidas por SkinPatch y SkinPrefs
; (C) Amigatronics
;
; Convencion: las rutinas "hoja" (marcadas LEAF) solo tocan d0/d1/a0/a1.
; El resto guarda d2-d7/a2-a6.

	.macro LVO off
	.short 0x4EAE,(\off)&0xFFFF
	.endm
	; movem.l d2-d7/a2-a6,-(sp) codificado a mano (LLVM invierte la mascara)
	.macro SAVEALL
	.short 0x48E7,0x3F3E
	.endm
	.macro RESTALL
	movem.l (%sp)+,%d2-%d7/%a2-%a6
	.endm

	.set NUM_SKIN, 19
	.set IDX_BAR, 11
	.set IDX_LEFT, 5
	.set IDX_FRAMEH, 12
	.set IDX_FRAMEV, 13
	.set IDX_KNOBV, 14
	.set IDX_KNOBH, 15
	.set IDX_TROUGHV, 16
	.set IDX_TROUGHH, 17
	.set IDX_ICONIFY, 18
	.set BE_DTO, 0
	.set BE_BM, 4
	.set BE_FW, 8
	.set BE_FH, 10
	.set BE_SIZE, 12
	.set BK_LUM, BE_SIZE*NUM_SKIN     ; brillo medio de bar.iff (0..255)
	.set BK_LUMI, BE_SIZE*NUM_SKIN+4  ; idem, ventana inactiva
	.set BANK_SIZE, BE_SIZE*NUM_SKIN+8

	.set PR_MAGIC, 0
	.set PR_HEIGHT, 4
	.set PR_ALL, 8
	.set PR_NAME, 12                  ; 60 bytes
	.set PR_BORDER, 72                ; grosor del marco (0 = por defecto)
	.set PR_SIZE, 76
	.set PR_MAGICVAL, 0x534B5031      ; 'SKP1'

	.set PM_CMD, 20                   ; mensaje al puerto de SkinPatch
	.set PM_ALL, 24
	.set PM_PATH, 28
	.set PM_SIZE, 28+256
	.set CMD_RELOAD, 1
	.set CMD_QUIT, 2
	.set CMD_STATS, 3

	.set BIGSTACK, 65536

	.text
; ---------------------------------------------------------------------------
; RunWithBigStack: ejecuta Main con una pila propia de 64 KB (los datatypes
; necesitan mucha pila; la del icono o la Shell puede ser de solo 4 KB).
; -> d0 = codigo de retorno de Main
RunWithBigStack:
	SAVEALL
	move.l SysBase,%a6
	move.l #BIGSTACK,%d0
	move.l #1,%d1                 ; MEMF_PUBLIC
	LVO -684                      ; AllocVec
	move.l %d0,StackMem
	bne .Lbs_swap
	jsr Main                      ; sin memoria: con la pila que haya
	bra .Lbs_ret
.Lbs_swap:
	lea StackSSS,%a0
	move.l %d0,(%a0)              ; stk_Lower
	add.l #BIGSTACK,%d0
	move.l %d0,(4,%a0)            ; stk_Upper
	move.l %d0,(8,%a0)            ; stk_Pointer
	LVO -732                      ; StackSwap
	jsr Main
	move.l %d0,%d2
	move.l SysBase,%a6
	lea StackSSS,%a0
	LVO -732                      ; StackSwap (vuelta a la pila original)
	move.l StackMem,%a1
	LVO -690                      ; FreeVec
	move.l %d2,%d0
.Lbs_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; DoMethodA(a0 = objeto BOOPSI, a1 = mensaje) -> d0   (como el de amiga.lib)
DoMethodA:
	SAVEALL
	move.l %a0,%a2                ; objeto
	move.l (-4,%a2),%a0           ; OCLASS(objeto) = gancho del dispatcher
	move.l (8,%a0),%a3            ; h_Entry
	jsr (%a3)
	RESTALL
	rts

; ---------------------------------------------------------------------------
; StrCpy(a0 = origen, a1 = destino, d0 = tamano maximo con el 0)   LEAF
StrCpy:
	sub.l #1,%d0
.Lsc_loop:
	cmpi.l #0,%d0
	beq .Lsc_term
	move.b (%a0)+,%d1
	move.b %d1,(%a1)+
	beq .Lsc_done
	sub.l #1,%d0
	bra .Lsc_loop
.Lsc_term:
	move.b #0,(%a1)
.Lsc_done:
	rts

; StrLen(a0) -> d0   LEAF
StrLen:
	move.l #0,%d0
.Lsl_loop:
	move.b (%a0)+,%d1
	beq .Lsl_done
	add.l #1,%d0
	bra .Lsl_loop
.Lsl_done:
	rts

; StrEq(a0, a1) -> d0 = 1 si son iguales (sin distinguir mayusculas)  LEAF
StrEq:
.Lse_loop:
	move.b (%a0)+,%d0
	move.b (%a1)+,%d1
	cmpi.b #0x61,%d0
	blt .Lse_a
	cmpi.b #0x7B,%d0
	bge .Lse_a
	sub.b #0x20,%d0
.Lse_a:
	cmpi.b #0x61,%d1
	blt .Lse_b
	cmpi.b #0x7B,%d1
	bge .Lse_b
	sub.b #0x20,%d1
.Lse_b:
	cmp.b %d1,%d0
	bne .Lse_no
	cmpi.b #0,%d0
	bne .Lse_loop
	move.l #1,%d0
	rts
.Lse_no:
	move.l #0,%d0
	rts

; ParseNum(a0 = texto) -> d0 = numero (1..999) o 0 si no es un numero  LEAF
ParseNum:
	move.l #0,%d0
	move.l #0,%d1
.Lpn_loop:
	move.b (%a0)+,%d1
	beq .Lpn_end
	cmpi.b #0x30,%d1
	blt .Lpn_bad
	cmpi.b #0x3A,%d1
	bge .Lpn_bad
	and.l #0xFF,%d1
	sub.l #0x30,%d1
	move.l %d0,%a1
	lsl.l #3,%d0                  ; d0*8
	add.l %a1,%d0                 ; +d0
	add.l %a1,%d0                 ; +d0 = d0*10
	add.l %d1,%d0
	cmpi.l #1000,%d0
	bge .Lpn_bad
	bra .Lpn_loop
.Lpn_end:
	rts
.Lpn_bad:
	move.l #0,%d0
	rts

; NumToStr(d0 = numero 0..9999, a1 = destino)   LEAF
NumToStr:
	lea NumTmp+8,%a0
	move.b #0,-(%a0)
.Lns_loop:
	and.l #0xFFFF,%d0
	.short 0x80FC,0x000A          ; divu.w #10,d0  (resto en la palabra alta)
	move.l %d0,%d1
	lsr.l #8,%d1
	lsr.l #8,%d1
	add.b #0x30,%d1
	move.b %d1,-(%a0)
	and.l #0xFFFF,%d0
	cmpi.l #0,%d0
	bne .Lns_loop
.Lns_copy:
	move.b (%a0)+,%d1
	move.b %d1,(%a1)+
	bne .Lns_copy
	rts

; AutoHeight(a0 = pantalla) -> d0 = alto de la barra de titulo de ventana  LEAF
AutoHeight:
	move.l #0,%d0
	move.b (35,%a0),%d0           ; WBorTop
	move.l (40,%a0),%a1           ; Font (TextAttr)
	move.w (4,%a1),%d1            ; ta_YSize
	and.l #0xFFFF,%d1
	add.l %d1,%d0
	add.l #1,%d0
	rts

; ---------------------------------------------------------------------------
; ResolveSkinDir(a0 = nombre de la skin, d0 = altura deseada)
; Deja en PathBuf la carpeta a usar: SYS:Prefs/Skins/<nombre>[/<altura>]
; Elige la subcarpeta numerica mas alta <= altura (o la menor si todas
; son mayores). Si no hay subcarpetas numericas, usa la carpeta de la skin.
; -> d0 = 1 si la carpeta existe
ResolveSkinDir:
	SAVEALL
	move.l %d0,%d7                ; altura deseada
	move.l %a0,%a2
	lea SkinsRoot,%a0
	lea PathBuf,%a1
	move.l #256,%d0
	jsr StrCpy
	move.l DOSBase,%a6
	move.l #PathBuf,%d1
	move.l %a2,%d2
	move.l #256,%d3
	LVO -882                      ; AddPart
	cmpi.l #0,%d0
	beq .Lrd_fail
	move.l #PathBuf,%d1
	move.l #-2,%d2                ; ACCESS_READ
	LVO -84                       ; Lock
	move.l %d0,%d6
	beq .Lrd_fail
	move.l #0,%d4                 ; mejor <= altura
	move.l #0x7FFFFFFF,%d5        ; menor > altura
	move.l %d6,%d1
	move.l #Fib,%d2
	LVO -102                      ; Examine
	cmpi.l #0,%d0
	beq .Lrd_unlock
.Lrd_next:
	move.l %d6,%d1
	move.l #Fib,%d2
	LVO -108                      ; ExNext
	cmpi.l #0,%d0
	beq .Lrd_unlock
	move.l Fib+4,%d0              ; fib_DirEntryType
	cmpi.l #0,%d0
	ble .Lrd_next
	lea Fib+8,%a0
	jsr ParseNum
	cmpi.l #0,%d0
	beq .Lrd_next
	cmp.l %d7,%d0
	bgt .Lrd_gt
	cmp.l %d4,%d0
	ble .Lrd_next
	move.l %d0,%d4
	bra .Lrd_next
.Lrd_gt:
	cmp.l %d5,%d0
	bge .Lrd_next
	move.l %d0,%d5
	bra .Lrd_next
.Lrd_unlock:
	move.l %d6,%d1
	LVO -90                       ; UnLock
	move.l %d4,%d0
	bne .Lrd_add
	move.l %d5,%d0
	cmpi.l #0x7FFFFFFF,%d0
	beq .Lrd_ok
.Lrd_add:
	lea NumBuf,%a1
	jsr NumToStr
	move.l #PathBuf,%d1
	move.l #NumBuf,%d2
	move.l #256,%d3
	LVO -882                      ; AddPart
.Lrd_ok:
	move.l #1,%d0
	bra .Lrd_ret
.Lrd_fail:
	move.l #0,%d0
.Lrd_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; ReadPrefs(a0 = buffer PR_SIZE) -> d0 = 1 si se leyo bien (si no, buffer a 0)
ReadPrefs:
	SAVEALL
	move.l %a0,%a2
	move.l #PR_SIZE/4,%d0
	move.l %a2,%a0
.Lrp_clr:
	move.l #0,(%a0)+
	sub.l #1,%d0
	bne .Lrp_clr
	move.l DOSBase,%a6
	move.l #PrefsEnv,%d1
	move.l #1005,%d2              ; MODE_OLDFILE
	LVO -30                       ; Open
	move.l %d0,%d6
	beq .Lrp_fail
	move.l %d6,%d1
	move.l %a2,%d2
	move.l #PR_SIZE,%d3
	LVO -42                       ; Read
	move.l %d0,%d5
	move.l %d6,%d1
	LVO -36                       ; Close
	cmpi.l #PR_SIZE,%d5
	bne .Lrp_bad
	move.l (PR_MAGIC,%a2),%d0
	cmpi.l #PR_MAGICVAL,%d0
	bne .Lrp_bad
	move.b #0,(PR_NAME+59,%a2)    ; asegurar el final del nombre
	move.l #1,%d0
	bra .Lrp_ret
.Lrp_bad:
	move.l #PR_SIZE/4,%d0
	move.l %a2,%a0
.Lrp_clr2:
	move.l #0,(%a0)+
	sub.l #1,%d0
	bne .Lrp_clr2
.Lrp_fail:
	move.l #0,%d0
.Lrp_ret:
	RESTALL
	rts

; WritePrefs(a0 = buffer, a1 = nombre del fichero) -> d0 = 1 si ok
WritePrefs:
	SAVEALL
	move.l %a0,%a2
	move.l #PR_MAGICVAL,(PR_MAGIC,%a2)
	move.l DOSBase,%a6
	move.l %a1,%d1
	move.l #1006,%d2              ; MODE_NEWFILE
	LVO -30
	move.l %d0,%d6
	beq .Lwp_fail
	move.l %d6,%d1
	move.l %a2,%d2
	move.l #PR_SIZE,%d3
	LVO -48                       ; Write
	move.l %d0,%d5
	move.l %d6,%d1
	LVO -36
	cmpi.l #PR_SIZE,%d5
	bne .Lwp_fail
	move.l #1,%d0
	bra .Lwp_ret
.Lwp_fail:
	move.l #0,%d0
.Lwp_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; LoadBank(a0 = carpeta, a2 = banco, d0 = cuantas imagenes (desde la 0))
; -> d0 = imagenes cargadas.  Usa RemapScreen para el remapeado.
LoadBank:
	SAVEALL
	move.l #255,(BK_LUM,%a2)      ; sin barra: se considera clara
	move.l #255,(BK_LUMI,%a2)
	move.l %d0,%d6
	move.l %a0,%a4                ; carpeta
	move.l #0,%d7                 ; indice
	move.l #0,%d4                 ; cargadas
.Llb_loop:
	cmp.l %d6,%d7
	bge .Llb_done
	lea FileNames,%a0
	move.l %d7,%d0
	lsl.l #2,%d0
	move.l (0,%a0,%d0),%a3        ; nombre del fichero
	move.l %d7,%d0
	lsl.l #2,%d0
	move.l %d0,%d1
	add.l %d0,%d0
	add.l %d1,%d0                 ; d0 = idx*12
	lea (0,%a2,%d0),%a5           ; entrada del banco
	jsr LoadOne
	cmpi.l #IDX_BAR,%d7
	bne .Llb_nolum
	cmpi.l #0,%d0
	beq .Llb_nolum
	move.l ILLum,(BK_LUM,%a2)
	move.l ILLumI,(BK_LUMI,%a2)
.Llb_nolum:
	add.l %d0,%d4
	add.l #1,%d7
	bra .Llb_loop
.Llb_done:
	move.l %d4,%d0
	RESTALL
	rts

; LoadOne(a4 = carpeta, a3 = fichero, a5 = entrada del banco) -> d0 = 1/0
; Lector propio de IFF ILBM (sin datatypes): lee el fichero, adapta los
; colores a la pantalla (ObtainBestPen) y crea un bitmap amigo de la pantalla.
; En la entrada: BE_BM = bitmap, BE_DTO = registro de plumas (para liberarlas).
	.set FILEBUF, 65536
LoadOne:
	SAVEALL
	move.l #0,(BE_DTO,%a5)
	move.l #0,(BE_BM,%a5)
	move.l #0,ILFile
	move.l #0,ILChunky
	move.l #0,ILPens
	move.l %a4,%a0
	lea PathBuf2,%a1
	move.l #256,%d0
	jsr StrCpy
	move.l DOSBase,%a6
	move.l #PathBuf2,%d1
	move.l %a3,%d2
	move.l #256,%d3
	LVO -882                      ; AddPart
	cmpi.l #0,%d0
	beq .Llo_fail
	; leer el fichero entero
	move.l SysBase,%a6
	move.l #FILEBUF,%d0
	move.l #1,%d1                 ; MEMF_PUBLIC
	LVO -684                      ; AllocVec
	move.l %d0,ILFile
	beq .Llo_fail
	move.l DOSBase,%a6
	move.l #PathBuf2,%d1
	move.l #1005,%d2
	LVO -30                       ; Open
	move.l %d0,%d6
	beq .Llo_bad
	move.l %d6,%d1
	move.l ILFile,%d2
	move.l #FILEBUF,%d3
	LVO -42                       ; Read
	move.l %d0,%d5
	move.l %d6,%d1
	LVO -36                       ; Close
	cmpi.l #12,%d5
	blt .Llo_bad
	; cabecera FORM ILBM
	move.l ILFile,%a0
	cmpi.l #0x464F524D,(%a0)      ; 'FORM'
	bne .Llo_bad
	cmpi.l #0x494C424D,(8,%a0)    ; 'ILBM'
	bne .Llo_bad
	move.l %a0,%d0
	add.l %d5,%d0
	move.l %d0,ILEnd               ; fin de los datos leidos
	move.l #0,ILBmhd
	move.l #0,ILCmap
	move.l #0,ILCmapN
	move.l #0,ILBody
	lea (12,%a0),%a1
.Llo_chunk:
	move.l %a1,%d0
	add.l #8,%d0
	move.l ILEnd,%d1
	cmp.l %d1,%d0
	bhi .Llo_parsed
	move.l (%a1),%d3              ; tipo
	move.l (4,%a1),%d2            ; longitud
	lea (8,%a1),%a2               ; datos
	move.l %a2,%d0
	add.l %d2,%d0
	cmp.l %d1,%d0
	bls .Llo_lenok
	move.l %d1,%d2
	sub.l %a2,%d2                 ; recortar al final del fichero
.Llo_lenok:
	cmpi.l #0x424D4844,%d3        ; 'BMHD'
	bne .Llo_c1
	move.l %a2,ILBmhd
.Llo_c1:
	cmpi.l #0x434D4150,%d3        ; 'CMAP'
	bne .Llo_c2
	move.l %a2,ILCmap
	move.l %d2,%d0
	.short 0x80FC,0x0003          ; divu.w #3,d0
	and.l #0xFFFF,%d0
	move.l %d0,ILCmapN
.Llo_c2:
	cmpi.l #0x424F4459,%d3        ; 'BODY'
	bne .Llo_c3
	move.l %a2,ILBody
	move.l %a2,%d0
	add.l %d2,%d0
	move.l %d0,ILBodyEnd
.Llo_c3:
	add.l #1,%d2
	and.l #-2,%d2                 ; relleno a par
	lea (0,%a2,%d2),%a1
	bra .Llo_chunk
.Llo_parsed:
	move.l ILBmhd,%d0
	beq .Llo_bad
	move.l ILBody,%d0
	beq .Llo_bad
	move.l ILBmhd,%a0
	move.l #0,%d0
	move.w (%a0),%d0
	move.l %d0,ILW
	move.w (2,%a0),%d0
	move.l %d0,ILH
	move.b (8,%a0),%d0
	and.l #0xFF,%d0
	move.l %d0,ILPl
	move.b (9,%a0),%d0
	and.l #0xFF,%d0
	move.l %d0,ILMask
	move.b (10,%a0),%d0
	and.l #0xFF,%d0
	move.l %d0,ILComp
	move.l ILW,%d0
	cmpi.l #3,%d0
	blt .Llo_bad
	move.l ILH,%d0
	cmpi.l #1,%d0
	blt .Llo_bad
	move.l ILPl,%d0
	cmpi.l #1,%d0
	blt .Llo_bad
	cmpi.l #8,%d0
	bgt .Llo_bad
	move.l ILComp,%d0
	cmpi.l #1,%d0
	bhi .Llo_bad
	move.l ILW,%d0
	add.l #15,%d0
	lsr.l #4,%d0
	add.l %d0,%d0
	move.l %d0,ILRB                ; bytes por fila de un plano
	cmpi.l #256,%d0
	bgt .Llo_bad

	; ---- plumas
	move.l SysBase,%a6
	move.l #8+256,%d0
	move.l #0x10001,%d1           ; MEMF_PUBLIC|MEMF_CLEAR
	LVO -684
	move.l %d0,ILPens
	beq .Llo_bad
	move.l %d0,%a2
	move.l RemapScreen,%a0
	move.l (48,%a0),%d0           ; Screen->ViewPort.ColorMap
	move.l %d0,(%a2)
	move.l #1,%d4
	move.l ILPl,%d0
	lsl.l %d0,%d4                 ; colores posibles = 1 << planos
	move.l ILCmapN,%d0
	cmp.l %d4,%d0
	bge .Llo_ncok
	move.l %d0,%d4
.Llo_ncok:
	move.l #0,%d7                 ; indice de color
	move.l GfxBase,%a6
.Llo_pen:
	cmp.l %d4,%d7
	bge .Llo_pendone
	move.l ILCmap,%a3
	move.l %d7,%d0
	add.l %d0,%d0
	add.l %d7,%d0                 ; i*3
	lea (0,%a3,%d0),%a3
	move.b (%a3)+,%d0
	jsr Rep32
	move.l %d0,%d5                ; rojo
	move.b (%a3)+,%d0
	jsr Rep32
	move.l %d0,%d6                ; verde
	move.b (%a3)+,%d0
	jsr Rep32
	move.l %d0,%d3                ; azul
	move.l %d5,%d1
	move.l %d6,%d2
	move.l (%a2),%a0              ; ColorMap
	lea PenTags,%a1
	LVO -840                      ; ObtainBestPenA
	cmpi.l #0,%d0
	bge .Llo_penok
	move.l #1,%d0                 ; sin pluma: usar la 1
	bra .Llo_penstore
.Llo_penok:
	move.l (4,%a2),%d1
	add.l #1,%d1
	move.l %d1,(4,%a2)            ; plumas obtenidas (para liberarlas)
.Llo_penstore:
	move.b %d0,(8,%a2,%d7)
	add.l #1,%d7
	bra .Llo_pen
.Llo_pendone:

	; ---- imagen en "chunky" (un byte por pixel)
	move.l ILW,%d0
	move.l ILH,%d1
	.short 0xC0C1                 ; mulu.w d1,d0
	move.l %d0,ILSize
	move.l SysBase,%a6
	move.l #0x10001,%d1
	LVO -684
	move.l %d0,ILChunky
	beq .Llo_bad
	move.l ILBody,%a3              ; origen
	move.l ILChunky,%a4            ; destino: fila actual
	move.l #0,%d7                 ; y
.Llo_row:
	cmp.l (ILH,%pc),%d7
	bge .Llo_decoded
	move.l #0,%d6                 ; plano
.Llo_plane:
	move.l ILPl,%d0
	add.l (ILMask,%pc),%d0               ; masking 1 = plano extra de mascara
	cmp.l %d0,%d6
	bge .Llo_rowdone
	; descomprimir una fila de plano en RowBuf
	lea RowBuf,%a1
	move.l ILRB,%d5                ; bytes que faltan
	move.l ILComp,%d0
	bne .Llo_rle
.Llo_raw:
	cmpi.l #0,%d5
	beq .Llo_gotrow
	jsr GetByte
	move.b %d0,(%a1)+
	sub.l #1,%d5
	bra .Llo_raw
.Llo_rle:
	cmpi.l #0,%d5
	ble .Llo_gotrow
	jsr GetByte
	ext.w %d0
	ext.l %d0
	cmpi.l #-128,%d0
	beq .Llo_rle
	cmpi.l #0,%d0
	blt .Llo_rep
	add.l #1,%d0                  ; copiar n+1 bytes
	move.l %d0,%d4
.Llo_lit:
	jsr GetByte
	cmpi.l #0,%d5
	ble .Llo_litskip
	move.b %d0,(%a1)+
.Llo_litskip:
	sub.l #1,%d5
	sub.l #1,%d4
	bne .Llo_lit
	bra .Llo_rle
.Llo_rep:
	neg.l %d0
	add.l #1,%d0                  ; repetir -n+1 veces
	move.l %d0,%d4
	jsr GetByte
.Llo_repl:
	cmpi.l #0,%d5
	ble .Llo_repskip
	move.b %d0,(%a1)+
.Llo_repskip:
	sub.l #1,%d5
	sub.l #1,%d4
	bne .Llo_repl
	bra .Llo_rle
.Llo_gotrow:
	; aplicar el plano (salvo el de mascara)
	cmp.l (ILPl,%pc),%d6
	bge .Llo_nextplane
	move.l #1,%d3
	lsl.l %d6,%d3                 ; bit del plano
	lea RowBuf,%a0
	move.l %a4,%a1
	move.l #0,%d4                 ; x
.Llo_byte:
	cmp.l (ILW,%pc),%d4
	bge .Llo_nextplane
	move.b (%a0)+,%d1
	move.l #8,%d2
.Llo_bit:
	cmp.l (ILW,%pc),%d4
	bge .Llo_nextplane
	move.l %d1,%d0
	and.l #0x80,%d0
	beq .Llo_nobit
	or.b %d3,(%a1)
.Llo_nobit:
	lea (1,%a1),%a1
	lsl.l #1,%d1
	add.l #1,%d4
	sub.l #1,%d2
	bne .Llo_bit
	bra .Llo_byte
.Llo_nextplane:
	add.l #1,%d6
	bra .Llo_plane
.Llo_rowdone:
	adda.l (ILW,%pc),%a4
	add.l #1,%d7
	bra .Llo_row
.Llo_decoded:
	; brillo de la imagen en el centro de los fotogramas 0 (activa) y 2
	; (inactiva), en la fila central: sirve para elegir el color del titulo
	move.l ILH,%d0
	lsr.l #1,%d0
	move.l ILW,%d1
	.short 0xC0C1                 ; mulu.w d1,d0
	move.l ILChunky,%a0
	adda.l %d0,%a0
	move.l ILW,%d1
	.short 0x82FC,0x0003          ; divu.w #3,d1
	and.l #0xFFFF,%d1             ; ancho de fotograma
	move.l %d1,%d2
	lsr.l #1,%d2
	move.l #0,%d0
	move.b (0,%a0,%d2),%d0
	jsr CmapLum
	move.l %d0,ILLum
	add.l %d1,%d2
	add.l %d1,%d2
	move.l #0,%d0
	move.b (0,%a0,%d2),%d0
	jsr CmapLum
	move.l %d0,ILLumI
	; indices -> plumas
	move.l ILChunky,%a0
	move.l ILPens,%a1
	lea (8,%a1),%a1
	move.l ILSize,%d1
.Llo_map:
	cmpi.l #0,%d1
	beq .Llo_mapped
	move.l #0,%d0
	move.b (%a0),%d0
	move.b (0,%a1,%d0),%d0
	move.b %d0,(%a0)+
	sub.l #1,%d1
	bra .Llo_map
.Llo_mapped:
	; ---- bitmap amigo de la pantalla
	move.l GfxBase,%a6
	move.l RemapScreen,%a0
	move.l (88,%a0),%a0           ; Screen->RastPort.BitMap
	move.l %a0,ILFriend
	move.l #4,%d1                 ; BMA_DEPTH
	LVO -960                      ; GetBitMapAttr
	move.l %d0,%d2                ; profundidad
	move.l ILW,%d0
	move.l ILH,%d1
	move.l #1,%d3                 ; BMF_CLEAR
	move.l ILFriend,%a0
	LVO -918                      ; AllocBitMap
	move.l %d0,(BE_BM,%a5)
	beq .Llo_bad
	lea TempRP,%a1
	LVO -198                      ; InitRastPort
	lea TempRP,%a0
	move.l (BE_BM,%a5),%d0
	move.l %d0,(4,%a0)            ; rp->BitMap
	move.l #0,%d0
	move.l #0,%d1
	move.l ILW,%d2
	sub.l #1,%d2
	move.l ILH,%d3
	sub.l #1,%d3
	move.l ILChunky,%a2
	move.l ILW,%d4
	LVO -1056                     ; WriteChunkyPixels
	; listo
	move.l ILPens,%d0
	move.l %d0,(BE_DTO,%a5)
	move.l #0,ILPens
	move.l ILW,%d0
	.short 0x80FC,0x0003          ; divu.w #3,d0
	move.w %d0,(BE_FW,%a5)
	move.l ILH,%d0
	move.w %d0,(BE_FH,%a5)
	move.l #1,%d7
	bra .Llo_clean
.Llo_bad:
	move.l #0,%d7
	move.l GfxBase,%a6
	move.l (BE_BM,%a5),%d0
	beq .Llo_nobm
	LVO -228                      ; WaitBlit
	move.l (BE_BM,%a5),%a0
	LVO -924                      ; FreeBitMap
	move.l #0,(BE_BM,%a5)
.Llo_nobm:
	move.l ILPens,%d0
	beq .Llo_clean
	move.l %d0,%a2
	jsr ReleasePens
	move.l #0,ILPens
.Llo_clean:
	move.l SysBase,%a6
	move.l ILChunky,%d0
	beq .Llo_c_nochunky
	move.l %d0,%a1
	LVO -690                      ; FreeVec
.Llo_c_nochunky:
	move.l ILFile,%d0
	beq .Llo_c_nofile
	move.l %d0,%a1
	LVO -690
.Llo_c_nofile:
	move.l %d7,%d0
	bra .Llo_ret
.Llo_fail:
	move.l #0,%d0
.Llo_ret:
	RESTALL
	rts

; GetByte -> d0 (siguiente byte del BODY, 0 si se acaba)  usa a3   LEAF
GetByte:
	move.l (ILBodyEnd,%pc),%d1
	move.l #0,%d0
	cmp.l %a3,%d1
	bls .Lgb_end
	move.b (%a3)+,%d0
.Lgb_end:
	rts

; CmapLum(d0 = indice de color) -> d0 = brillo (r+g+b)/3 segun el CMAP  (usa d3)
CmapLum:
	move.l %d3,-(%sp)
	cmp.l (ILCmapN,%pc),%d0
	blt .Lcl_ok
	move.l #255,%d0
	bra .Lcl_ret
.Lcl_ok:
	move.l %a0,-(%sp)
	move.l ILCmap,%a0
	move.l %d0,%d3
	add.l %d0,%d0
	add.l %d3,%d0
	adda.l %d0,%a0
	move.l #0,%d0
	move.l #0,%d3
	move.b (%a0)+,%d3
	add.l %d3,%d0
	move.b (%a0)+,%d3
	add.l %d3,%d0
	move.b (%a0)+,%d3
	add.l %d3,%d0
	.short 0x80FC,0x0003          ; divu.w #3,d0
	and.l #0xFFFF,%d0
	move.l (%sp)+,%a0
.Lcl_ret:
	move.l (%sp)+,%d3
	rts

; Rep32(d0.b) -> d0 = byte repetido en los 4 bytes (formato de color de 32 bits)  LEAF
Rep32:
	and.l #0xFF,%d0
	move.l %d0,%d1
	lsl.l #8,%d1
	or.l %d1,%d0
	move.l %d0,%d1
	lsl.l #8,%d1
	lsl.l #8,%d1
	or.l %d1,%d0
	rts

; ReleasePens(a2 = registro de plumas) y lo libera
ReleasePens:
	SAVEALL
	move.l GfxBase,%a6
	move.l (4,%a2),%d6            ; plumas obtenidas
	move.l #0,%d7
.Lrp2_loop:
	cmp.l %d6,%d7
	bge .Lrp2_done
	move.l (%a2),%a0              ; ColorMap
	move.l #0,%d0
	move.b (8,%a2,%d7),%d0
	LVO -948                      ; ReleasePen
	add.l #1,%d7
	bra .Lrp2_loop
.Lrp2_done:
	move.l SysBase,%a6
	move.l %a2,%a1
	LVO -690                      ; FreeVec
	RESTALL
	rts

; FreeBank(a2 = banco)
FreeBank:
	SAVEALL
	move.l #NUM_SKIN,%d6
.Lfb_loop:
	move.l (BE_BM,%a2),%d0
	beq .Lfb_nobm
	move.l GfxBase,%a6
	LVO -228                      ; WaitBlit
	move.l (BE_BM,%a2),%a0
	LVO -924                      ; FreeBitMap
.Lfb_nobm:
	move.l (BE_DTO,%a2),%d0
	beq .Lfb_next
	move.l %a2,-(%sp)
	move.l %d0,%a2
	jsr ReleasePens
	move.l (%sp)+,%a2
.Lfb_next:
	move.l #0,(BE_DTO,%a2)
	move.l #0,(BE_BM,%a2)
	lea (BE_SIZE,%a2),%a2
	sub.l #1,%d6
	bne .Lfb_loop
	RESTALL
	rts

; ===========================================================================
	.data
	.p2align 2
; Orden de las imagenes (indice 0..10). Las 3 primeras se usan en la vista previa.
FileNames:
	.long FnClose, FnDepth, FnZoom, FnSDepth, FnSize
	.long FnLeft, FnRight, FnUp, FnDown, FnCheck, FnMx, FnBar, FnFrH, FnFrV, FnKnV, FnKnH, FnTrV, FnTrH, FnIconify
WhichTab:
	.long 0x03, 0x00, 0x01, 0x05, 0x02
	.long 0x0A, 0x0C, 0x0B, 0x0D, 0x0E, 0x0F, 0x7FFF, 0x7FFF, 0x7FFF, 0x7FFF, 0x7FFF, 0x7FFF, 0x7FFF, 0x12
FnIconify: .asciz "iconify.iff"
FnKnV:    .asciz "knobv.iff"
FnKnH:    .asciz "knobh.iff"
FnTrV:    .asciz "troughv.iff"
FnTrH:    .asciz "troughh.iff"
FnFrH:    .asciz "frameh.iff"
FnFrV:    .asciz "framev.iff"
FnClose:  .asciz "close.iff"
FnDepth:  .asciz "depth.iff"
FnZoom:   .asciz "zoom.iff"
FnSDepth: .asciz "sdepth.iff"
FnSize:   .asciz "size.iff"
FnLeft:   .asciz "left.iff"
FnRight:  .asciz "right.iff"
FnUp:     .asciz "up.iff"
FnDown:   .asciz "down.iff"
FnCheck:  .asciz "check.iff"
FnMx:     .asciz "mx.iff"
FnBar:    .asciz "bar.iff"
SkinsRoot: .asciz "SYS:Prefs/Skins"
PrefsEnv:  .asciz "ENV:SkinPatch.prefs"
PrefsArc:  .asciz "ENVARC:SkinPatch.prefs"
PenTags:   .long 0x84000000, 0, 0, 0     ; OBP_Precision PRECISION_IMAGE
PortName:  .asciz "SkinPatch"
DosName:   .asciz "dos.library"
IntuiName: .asciz "intuition.library"
GfxName:   .asciz "graphics.library"
DTName:    .asciz "datatypes.library"

	.bss
	.p2align 2
SysBase:       .space 4
StackMem:      .space 4
StackSSS:      .space 12
DOSBase:       .space 4
IntuitionBase: .space 4
GfxBase:       .space 4
DataTypesBase: .space 4
RemapScreen:   .space 4
BmhdPtr:       .space 4
BmPtr:         .space 4
LayoutMsg:     .space 12
TagBuf:        .space 96
Fib:           .space 260
NumTmp:        .space 8
NumBuf:        .space 8
PathBuf:       .space 260
PathBuf2:      .space 260
ILFile:         .space 4
ILEnd:          .space 4
ILBmhd:         .space 4
ILCmap:         .space 4
ILLum:         .space 4
ILLumI:        .space 4
ILCmapN:        .space 4
ILBody:         .space 4
ILBodyEnd:      .space 4
ILW:            .space 4
ILH:            .space 4
ILPl:           .space 4
ILMask:         .space 4
ILComp:         .space 4
ILRB:           .space 4
ILSize:         .space 4
ILPens:         .space 4
ILChunky:       .space 4
ILFriend:       .space 4
RowBuf:        .space 260
TempRP:        .space 104
