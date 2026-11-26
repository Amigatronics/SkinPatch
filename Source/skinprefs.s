; SkinPrefs 1.0 - preferences editor for SkinPatch
; AmigaOS 3.x, GadTools.  Isra Ortuno - Amigatronics

	.include "common.s"

	.set MAXSKINS, 64
	.set NAMELEN, 32
	.set ID_LIST, 1
	.set ID_HEIGHT, 2
	.set ID_ALL, 3
	.set ID_SAVE, 4
	.set ID_USE, 5
	.set ID_TEST, 6
	.set ID_CANCEL, 7
	.set ID_BORDER, 8
	.set ID_ENABLED, 9
	.set ID_UPDATE, 10
	.set NUMBORDERS, 8
	.set NUMHEIGHTS, 7
	.set X1, 10
	.set LW, 200
	.set X2, X1+LW+14
	.set RW, 190
	.set IW, X2+RW+10
	.set PH, 72
	.set LOGOBW, 68               ; marco del logo
	.set LOGOBH, 76
	.set BW, (X2+RW-X1-3*8)/4

	.text
	.globl _start
_start:
	SAVEALL
	move.l $4,%a6
	move.l %a6,SysBase
	.short 0x93C9                 ; suba.l a1,a1
	LVO -294                      ; FindTask(NULL)
	move.l %d0,%a4
	move.l #0,WBMsg
	move.l (172,%a4),%d0          ; pr_CLI
	bne .Lcli
	lea (92,%a4),%a0
	LVO -384                      ; WaitPort
	lea (92,%a4),%a0
	LVO -372                      ; GetMsg
	move.l %d0,WBMsg
.Lcli:
	jsr RunWithBigStack
	move.l %d0,%d2
	move.l WBMsg,%d0
	beq .Lend
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l WBMsg,%a1
	LVO -378                      ; ReplyMsg
.Lend:
	move.l %d2,%d0
	RESTALL
	rts

; ---------------------------------------------------------------------------
Main:
	SAVEALL
	move.l #20,%d7
	move.l SysBase,%a6
	lea DosName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,DOSBase
	lea IntuiName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,IntuitionBase
	lea GfxName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,GfxBase
	lea GTName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,GadToolsBase
	lea DTName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,DataTypesBase
	move.l DOSBase,%d0
	beq .Lm_close
	move.l IntuitionBase,%d0
	beq .Lm_close
	move.l GfxBase,%d0
	beq .Lm_close
	move.l GadToolsBase,%d0
	beq .Lm_close
	move.l DataTypesBase,%d0
	beq .Lm_close

	jsr LocInit
	move.l SysBase,%a6
	LVO -666                      ; CreateMsgPort
	move.l %d0,ReplyPort
	beq .Lm_close

	; preferencias actuales
	lea OrigPrefs,%a0
	jsr ReadPrefs
	lea OrigPrefs,%a0
	lea CurPrefs,%a1
	move.l #PR_SIZE/4,%d0
.Lm_cp:
	move.l (%a0)+,(%a1)+
	sub.l #1,%d0
	bne .Lm_cp

	; pantalla
	move.l IntuitionBase,%a6
	move.l #0,%a0
	LVO -510                      ; LockPubScreen(NULL)
	move.l %d0,Screen
	beq .Lm_close
	move.l %d0,RemapScreen
	move.l GadToolsBase,%a6
	move.l %d0,%a0
	move.l #0,%a1
	LVO -126                      ; GetVisualInfoA
	move.l %d0,VisInfo
	beq .Lm_unlock

	jsr CalcLayout
	jsr ScanSkins
	jsr InitSelection
	jsr CreateGads
	cmpi.l #0,%d0
	beq .Lm_freegads
	jsr OpenWin
	cmpi.l #0,%d0
	beq .Lm_freegads

	move.l GadToolsBase,%a6
	move.l Window,%a0
	move.l #0,%a1
	LVO -84                       ; GT_RefreshWindow
	jsr LoadPreview
	jsr LoadLogo
	jsr DrawAll

	jsr EventLoop
	move.l #0,%d7

	move.l IntuitionBase,%a6
	move.l Window,%a0
	LVO -72                       ; CloseWindow
.Lm_freegads:
	move.l GadToolsBase,%a6
	move.l GList,%a0
	LVO -36                       ; FreeGadgets (acepta NULL)
	lea BankP,%a2
	jsr FreeBank
	lea LogoBank,%a2
	jsr FreeBank
	move.l GadToolsBase,%a6
	move.l VisInfo,%a0
	LVO -132                      ; FreeVisualInfo
.Lm_unlock:
	move.l IntuitionBase,%a6
	move.l #0,%a0
	move.l Screen,%a1
	LVO -516                      ; UnlockPubScreen
.Lm_close:
	move.l SysBase,%a6
	move.l ReplyPort,%d0
	beq .Lm_noport
	move.l %d0,%a0
	LVO -672                      ; DeleteMsgPort
.Lm_noport:
	move.l Catalog,%d0
	beq .Lm_nocat
	move.l LocaleBase,%a6
	move.l %d0,%a0
	LVO -36                       ; CloseCatalog
	move.l SysBase,%a6
.Lm_nocat:
	lea LibList,%a2
.Lm_cl:
	move.l (%a2)+,%d0
	beq .Lm_ret
	move.l %d0,%a0
	move.l (%a0),%d0
	beq .Lm_cl
	move.l %d0,%a1
	LVO -414
	bra .Lm_cl
.Lm_ret:
	move.l %d7,%d0
	RESTALL
	rts

; ---------------------------------------------------------------------------
; Calculo de la disposicion segun la fuente de la pantalla
CalcLayout:
	SAVEALL
	move.l Screen,%a0
	jsr AutoHeight
	move.l %d0,AutoH
	move.l %d0,BTv                ; WBorTop + fuente + 1
	move.l #0,%d0
	move.b (36,%a0),%d0           ; WBorLeft
	move.l %d0,BLv
	move.l (40,%a0),%a1
	move.l #0,%d1
	move.w (4,%a1),%d1            ; alto de la fuente
	move.l %d1,Fv
	move.l %d1,%d0
	add.l #6,%d0
	move.l %d0,Gv                 ; alto de gadget
	; lista
	move.l %d1,%d0
	add.l #8,%d0
	move.l %d0,LYv
	move.l %d1,%d0
	add.l #2,%d0
	lsl.l #3,%d0
	add.l #4,%d0
	move.l %d0,LHv
	; checkbox
	move.l LYv,%d0
	add.l (Gv,%pc),%d0
	add.l #8,%d0
	move.l %d0,KYv
	; activado
	add.l #12+6,%d0
	move.l %d0,EYv
	; ancho del marco
	add.l #12+8,%d0
	move.l %d0,FYv
	add.l (Gv,%pc),%d0
	; vista previa
	add.l #8,%d0
	add.l %d1,%d0
	move.l %d0,PLYv               ; linea base del rotulo
	add.l #4,%d0
	move.l %d0,PYv
	; fila de botones
	add.l #PH,%d0                 ; PY+PH
	add.l #6,%d0
	move.l %d0,UYv                ; boton de buscar actualizaciones
	add.l (Gv,%pc),%d0
	move.l LYv,%d2
	add.l (LHv,%pc),%d2                 ; LY+LH
	add.l #6,%d2
	move.l %d2,LogoYv             ; logo debajo de la lista
	add.l #LOGOBH,%d2
	cmp.l %d2,%d0
	bge .Lcl_a
	move.l %d2,%d0
.Lcl_a:
	add.l #10,%d0
	move.l %d0,BYv
	add.l (Gv,%pc),%d0
	add.l #8,%d0
	add.l %d1,%d0
	move.l %d0,CRYv               ; linea base de los creditos
	add.l #6,%d0
	move.l %d0,IHv
	RESTALL
	rts


; ---------------------------------------------------------------------------
; Lista de skins: "(none)" + carpetas de SYS:Prefs/Skins, ordenadas
ScanSkins:
	SAVEALL
	; leer nombres en NameBuf
	move.l #0,NumNames
	move.l DOSBase,%a6
	move.l #SkinsRoot,%d1
	move.l #-2,%d2
	LVO -84                       ; Lock
	move.l %d0,%d6
	beq .Lss_build
	move.l %d6,%d1
	move.l #Fib,%d2
	LVO -102                      ; Examine
	cmpi.l #0,%d0
	beq .Lss_unlock
.Lss_next:
	move.l %d6,%d1
	move.l #Fib,%d2
	LVO -108                      ; ExNext
	cmpi.l #0,%d0
	beq .Lss_unlock
	move.l Fib+4,%d0
	cmpi.l #0,%d0
	ble .Lss_next
	move.l NumNames,%d0
	cmpi.l #MAXSKINS-1,%d0
	bge .Lss_unlock
	lsl.l #5,%d0                  ; *32
	lea NameBuf,%a1
	adda.l %d0,%a1
	lea Fib+8,%a0
	move.l #NAMELEN,%d0
	jsr StrCpy
	move.l NumNames,%d0
	add.l #1,%d0
	move.l %d0,NumNames
	bra .Lss_next
.Lss_unlock:
	move.l %d6,%d1
	LVO -90                       ; UnLock
.Lss_build:
	; punteros y ordenacion (burbuja, sin distinguir mayusculas)
	move.l NumNames,%d6
	lea NamePtrs,%a2
	lea NameBuf,%a3
	move.l #0,%d0
.Lss_ptr:
	cmp.l %d6,%d0
	bge .Lss_sort
	move.l %a3,(%a2)+
	lea (NAMELEN,%a3),%a3
	add.l #1,%d0
	bra .Lss_ptr
.Lss_sort:
	cmpi.l #2,%d6
	blt .Lss_list
	move.l %d6,%d5
	sub.l #1,%d5                  ; pasadas
.Lss_pass:
	lea NamePtrs,%a2
	move.l %d5,%d4
	move.l #0,%d3                 ; hubo cambios
.Lss_cmp:
	move.l (%a2),%a0
	move.l (4,%a2),%a1
	jsr StrCmpI
	cmpi.l #0,%d0
	ble .Lss_noswap
	move.l (%a2),%d0
	move.l (4,%a2),%d1
	move.l %d1,(%a2)
	move.l %d0,(4,%a2)
	move.l #1,%d3
.Lss_noswap:
	lea (4,%a2),%a2
	sub.l #1,%d4
	bne .Lss_cmp
	cmpi.l #0,%d3
	beq .Lss_list
	sub.l #1,%d5
	bne .Lss_pass
.Lss_list:
	; lista Exec
	lea SkinList,%a0
	lea (4,%a0),%a1
	move.l %a1,(%a0)              ; lh_Head = &lh_Tail
	move.l #0,(4,%a0)             ; lh_Tail
	move.l %a0,(8,%a0)            ; lh_TailPred = &lh_Head
	move.l SysBase,%a6
	lea Nodes,%a3
	move.l #NoneName,(10,%a3)
	lea SkinList,%a0
	move.l %a3,%a1
	LVO -246                      ; AddTail
	lea NamePtrs,%a2
	move.l #0,%d4
.Lss_add:
	cmp.l %d6,%d4
	bge .Lss_done
	lea (16,%a3),%a3
	move.l (%a2)+,%d0
	move.l %d0,(10,%a3)           ; ln_Name
	lea SkinList,%a0
	move.l %a3,%a1
	LVO -246
	add.l #1,%d4
	bra .Lss_add
.Lss_done:
	RESTALL
	rts

; StrCmpI(a0, a1) -> d0 <0, 0, >0   LEAF
StrCmpI:
.Lci_loop:
	move.b (%a0)+,%d0
	move.b (%a1)+,%d1
	cmpi.b #0x61,%d0
	blt .Lci_a
	cmpi.b #0x7B,%d0
	bge .Lci_a
	sub.b #0x20,%d0
.Lci_a:
	cmpi.b #0x61,%d1
	blt .Lci_b
	cmpi.b #0x7B,%d1
	bge .Lci_b
	sub.b #0x20,%d1
.Lci_b:
	and.l #0xFF,%d0
	and.l #0xFF,%d1
	sub.l %d1,%d0
	bne .Lci_ret
	cmpi.l #0,%d1
	bne .Lci_loop
.Lci_ret:
	rts

; NodeName(d0 = indice) -> a0 = nombre   (guarda el resto)
NodeName:
	move.l SkinList,%a0
.Lnn_loop:
	cmpi.l #0,%d0
	beq .Lnn_done
	move.l (%a0),%a0
	sub.l #1,%d0
	bra .Lnn_loop
.Lnn_done:
	move.l (10,%a0),%a0
	rts

; Seleccion inicial a partir de CurPrefs
InitSelection:
	SAVEALL
	move.l #0,SelIdx
	move.b CurPrefs+PR_NAME,%d0
	beq .Lis_h
	move.l #1,%d6
.Lis_loop:
	move.l NumNames,%d0
	cmp.l %d0,%d6
	bgt .Lis_h
	move.l %d6,%d0
	jsr NodeName
	lea CurPrefs+PR_NAME,%a1
	jsr StrEq
	cmpi.l #0,%d0
	bne .Lis_found
	add.l #1,%d6
	bra .Lis_loop
.Lis_found:
	move.l %d6,SelIdx
.Lis_h:
	move.l #0,HeightIdx
	move.l CurPrefs+PR_HEIGHT,%d1
	lea HeightVals,%a0
	move.l #0,%d0
.Lis_hl:
	cmpi.l #NUMHEIGHTS,%d0
	bge .Lis_all
	cmp.l (0,%a0),%d1
	beq .Lis_hf
	lea (4,%a0),%a0
	add.l #1,%d0
	bra .Lis_hl
.Lis_hf:
	move.l %d0,HeightIdx
.Lis_all:
	move.l #0,BorderIdx
	move.l CurPrefs+PR_BORDER,%d1
	lea BorderVals,%a0
	move.l #0,%d0
.Lis_bl:
	cmpi.l #NUMBORDERS,%d0
	bge .Lis_all2
	cmp.l (0,%a0),%d1
	beq .Lis_bf
	lea (4,%a0),%a0
	add.l #1,%d0
	bra .Lis_bl
.Lis_bf:
	move.l %d0,BorderIdx
.Lis_all2:
	move.l CurPrefs+PR_ALL,%d0
	move.l #1,EnabledFlag
	move.l %d0,%d1
	and.l #2,%d1                  ; bit 1: desactivado
	beq .Lis_en
	move.l #0,EnabledFlag
.Lis_en:
	and.l #1,%d0
	move.l %d0,AllFlag
	RESTALL
	rts

; ---------------------------------------------------------------------------
; MkGad(d0 tipo, d1 x, d2 y, d3 ancho, d4 alto, a0 texto, d5 id, d6 flags, a1 tags)
MkGad:
	SAVEALL
	lea NG,%a2
	add.l (BLv,%pc),%d1
	move.w %d1,(%a2)
	add.l (BTv,%pc),%d2
	move.w %d2,(2,%a2)
	move.w %d3,(4,%a2)
	move.w %d4,(6,%a2)
	move.l %a0,(8,%a2)
	move.l Screen,%a3
	move.l (40,%a3),%d7
	move.l %d7,(12,%a2)           ; ng_TextAttr = fuente de la pantalla
	move.w %d5,(16,%a2)
	move.l %d6,(18,%a2)
	move.l VisInfo,%d7
	move.l %d7,(22,%a2)
	move.l #0,(26,%a2)
	move.l %a1,%a3
	move.l GadPrev,%a0
	move.l %a2,%a1
	move.l %a3,%a2
	move.l GadToolsBase,%a6
	LVO -30                       ; CreateGadgetA
	move.l %d0,GadPrev
	RESTALL
	rts

; CreateGads -> d0 = 1 si todos se crearon
CreateGads:
	SAVEALL
	move.l GadToolsBase,%a6
	lea GList,%a0
	move.l #0,(%a0)
	LVO -114                      ; CreateContext
	move.l %d0,GadPrev
	beq .Lcg_fail

	; lista de skins
	lea TagList,%a1
	move.l #0x80080006,(%a1)      ; GTLV_Labels
	move.l #SkinList,(4,%a1)
	move.l #0x80080035,(8,%a1)    ; GTLV_ShowSelected
	move.l #0,(12,%a1)
	move.l #0x80080036,(16,%a1)   ; GTLV_Selected
	move.l SelIdx,%d0
	move.l %d0,(20,%a1)
	move.l #0x80080005,(24,%a1)   ; GTLV_Top
	sub.l #3,%d0
	bge .Lcg_top
	move.l #0,%d0
.Lcg_top:
	move.l %d0,(28,%a1)
	move.l #0,(32,%a1)
	move.l #4,%d0                 ; LISTVIEW_KIND
	move.l #X1,%d1
	move.l LYv,%d2
	move.l #LW,%d3
	move.l LHv,%d4
	move.l SSkins,%a0
	move.l #ID_LIST,%d5
	move.l #0x24,%d6              ; PLACETEXT_ABOVE|NG_HIGHLABEL
	jsr MkGad

	; altura
	lea TagCyc,%a1
	move.l #0x8008000E,(%a1)      ; GTCY_Labels
	move.l #HeightLabels,(4,%a1)
	move.l #0x8008000F,(8,%a1)    ; GTCY_Active
	move.l HeightIdx,%d0
	move.l %d0,(12,%a1)
	move.l #0,(16,%a1)
	move.l #7,%d0                 ; CYCLE_KIND
	move.l #X2,%d1
	move.l LYv,%d2
	move.l #RW,%d3
	move.l Gv,%d4
	move.l SHeight,%a0
	move.l #ID_HEIGHT,%d5
	move.l #0x24,%d6
	jsr MkGad

	; todas las pantallas
	lea TagChk,%a1
	move.l #0x80080004,(%a1)      ; GTCB_Checked
	move.l AllFlag,%d0
	move.l %d0,(4,%a1)
	move.l #0,(8,%a1)
	move.l #2,%d0                 ; CHECKBOX_KIND
	move.l #X2,%d1
	move.l KYv,%d2
	move.l #26,%d3
	move.l #11,%d4
	move.l SAll,%a0
	move.l #ID_ALL,%d5
	move.l #2,%d6                 ; PLACETEXT_RIGHT
	jsr MkGad

	; activado
	lea TagChk,%a1
	move.l #0x80080004,(%a1)      ; GTCB_Checked
	move.l EnabledFlag,%d0
	move.l %d0,(4,%a1)
	move.l #0,(8,%a1)
	move.l #2,%d0                 ; CHECKBOX_KIND
	move.l #X2,%d1
	move.l EYv,%d2
	move.l #26,%d3
	move.l #11,%d4
	move.l SEnabled,%a0
	move.l #ID_ENABLED,%d5
	move.l #2,%d6                 ; PLACETEXT_RIGHT
	jsr MkGad

	; ancho del marco
	lea TagCyc,%a1
	move.l #0x8008000E,(%a1)      ; GTCY_Labels
	move.l #BorderLabels,(4,%a1)
	move.l #0x8008000F,(8,%a1)    ; GTCY_Active
	move.l BorderIdx,%d0
	move.l %d0,(12,%a1)
	move.l #0,(16,%a1)
	move.l #7,%d0                 ; CYCLE_KIND
	move.l #X2,%d1
	move.l FYv,%d2
	move.l #RW,%d3
	move.l Gv,%d4
	move.l #0,%a0
	move.l #ID_BORDER,%d5
	move.l #0,%d6
	jsr MkGad

	; buscar actualizaciones
	move.l #1,%d0                 ; BUTTON_KIND
	move.l #X2,%d1
	move.l UYv,%d2
	move.l #RW,%d3
	move.l Gv,%d4
	move.l SUpdate,%a0
	move.l #ID_UPDATE,%d5
	move.l #0x10,%d6
	move.l #0,%a1
	jsr MkGad

	; botones
	move.l #X1,%d7
	lea BtnTable,%a3
.Lcg_btn:
	move.l (%a3)+,%d5             ; id
	beq .Lcg_check
	move.l (%a3)+,%a0             ; texto
	move.l #1,%d0                 ; BUTTON_KIND
	move.l %d7,%d1
	move.l BYv,%d2
	move.l #BW,%d3
	move.l Gv,%d4
	move.l #0x10,%d6              ; PLACETEXT_IN
	move.l #0,%a1
	jsr MkGad
	add.l #BW+8,%d7
	bra .Lcg_btn
.Lcg_check:
	move.l GadPrev,%d0
	beq .Lcg_fail
	move.l #1,%d0
	bra .Lcg_ret
.Lcg_fail:
	move.l #0,%d0
.Lcg_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; LocInit: abre locale.library y skinprefs.catalog en el idioma guardado en
; ENV:SkinPatch.language (lo pone el instalador) o, si no hay, en el del
; sistema; cambia los textos de StrTab. Sin catalogo todo sigue en ingles.
LocInit:
	SAVEALL
	move.l SysBase,%a6
	lea LocaleName,%a1
	move.l #38,%d0
	LVO -552
	move.l %d0,LocaleBase
	beq .Lli_ret
	lea CatTags,%a2
	move.l DOSBase,%a6
	move.l #LangVar,%d1
	move.l #LangBuf,%d2
	move.l #39,%d3
	move.l #0x100,%d4             ; GVF_GLOBAL_ONLY
	LVO -906                      ; GetVar
	cmpi.l #0,%d0
	ble .Lli_tags
	lea LangBuf,%a0               ; quitar salto de linea y espacios del final
	adda.l %d0,%a0
.Lli_trim:
	move.l %a0,%d1
	cmpi.l #LangBuf,%d1
	beq .Lli_tags
	move.b -(%a0),%d1
	cmpi.b #0x20,%d1
	bhi .Lli_ok
	move.b #0,(%a0)
	bra .Lli_trim
.Lli_ok:
	move.l #0x80090004,(%a2)+     ; OC_Language
	move.l #LangBuf,(%a2)+
.Lli_tags:
	move.l #0x80090001,(%a2)+     ; OC_BuiltInLanguage
	move.l #English,(%a2)+
	move.l #0,(%a2)+
	move.l LocaleBase,%a6
	move.l #0,%a0
	lea CatName,%a1
	lea CatTags,%a2
	LVO -150                      ; OpenCatalogA
	move.l %d0,Catalog
	beq .Lli_ret
	lea StrTab,%a3
.Lli_s:
	move.l (%a3)+,%d0             ; numero
	beq .Lli_ret
	move.l (%a3)+,%a4             ; ranura
	move.l Catalog,%a0
	move.l (%a4),%a1              ; texto por defecto
	LVO -72                       ; GetCatalogStr
	move.l %d0,(%a4)
	bra .Lli_s
.Lli_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; CheckUpdate: lee por http el readme de SkinPatch en Aminet, saca la linea
; "Version:" y la compara con la nuestra. Necesita una pila TCP/IP en marcha.
CheckUpdate:
	SAVEALL
	move.l #0,BsdBase
	move.l #0,NetPtr
	move.l #-1,%d7                ; socket
	move.l #0,VerBuf
	move.l SysBase,%a6
	lea BsdName,%a1
	move.l #4,%d0
	LVO -552
	move.l %d0,BsdBase
	beq .Lcu_fail
	move.l %d0,%a6
	lea AminetHost,%a0
	LVO -210                      ; gethostbyname
	cmpi.l #0,%d0
	beq .Lcu_fail
	move.l %d0,%a0
	move.l (16,%a0),%a0           ; h_addr_list
	move.l (%a0),%d0
	beq .Lcu_fail
	move.l %d0,%a0
	lea SockAddr,%a1
	move.l #0,(%a1)
	move.l #0,(8,%a1)
	move.l #0,(12,%a1)
	move.b #16,(%a1)              ; sin_len
	move.b #2,(1,%a1)             ; AF_INET
	move.w #80,(2,%a1)            ; puerto
	move.l (%a0),(4,%a1)          ; direccion
	move.l #2,%d0                 ; AF_INET
	move.l #1,%d1                 ; SOCK_STREAM
	move.l #0,%d2
	LVO -30                       ; socket
	move.l %d0,%d7
	cmpi.l #0,%d7
	blt .Lcu_fail
	move.l %d7,%d0
	lea SockAddr,%a0
	move.l #16,%d1
	LVO -54                       ; connect
	cmpi.l #0,%d0
	bne .Lcu_fail
	move.l %d7,%d0
	lea HttpReq,%a0
	move.l #HttpReqEnd-HttpReq,%d1
	move.l #0,%d2
	LVO -66                       ; send
	cmpi.l #0,%d0
	ble .Lcu_fail
	move.l SysBase,%a6            ; bufer de 8 KB
	move.l #8192,%d0
	move.l #0x10000,%d1           ; MEMF_CLEAR
	LVO -684                      ; AllocVec
	move.l %d0,NetPtr
	beq .Lcu_fail
	move.l BsdBase,%a6
	move.l %d0,%a4                ; recibir hasta que se cierre o se llene
.Lcu_rx:
	move.l NetPtr,%d1
	add.l #8191,%d1
	sub.l %a4,%d1
	ble .Lcu_rxend
	move.l %d7,%d0
	move.l %a4,%a0
	move.l #0,%d2
	LVO -78                       ; recv
	cmpi.l #0,%d0
	ble .Lcu_rxend
	adda.l %d0,%a4
	bra .Lcu_rx
.Lcu_rxend:
	move.b #0,(%a4)
	; respuesta "HTTP/1.x 200"
	move.l NetPtr,%a0
	cmpi.b #0x48,(%a0)            ; 'H'
	bne .Lcu_fail
	move.b (9,%a0),%d0
	cmpi.b #0x32,%d0              ; '2'
	bne .Lcu_fail
	; buscar "Version:" al principio de una linea
	move.l NetPtr,%a0
.Lcu_find:
	move.b (%a0)+,%d0
	beq .Lcu_fail
	cmpi.b #10,%d0
	bne .Lcu_find
	lea VerKey,%a1
	move.l %a0,%a2
.Lcu_cmp:
	move.b (%a1)+,%d1
	beq .Lcu_hit
	move.b (%a2)+,%d0
	cmp.b %d0,%d1
	beq .Lcu_cmp
	bra .Lcu_find
.Lcu_hit:
	move.b (%a2)+,%d0             ; saltar espacios
	cmpi.b #0x20,%d0
	beq .Lcu_hit
	cmpi.b #9,%d0
	beq .Lcu_hit
	suba.l #1,%a2
	lea VerBuf,%a1
	move.l #30,%d1
.Lcu_cp:
	move.b (%a2)+,%d0
	cmpi.b #0x20,%d0
	bls .Lcu_cpend
	move.b %d0,(%a1)+
	sub.l #1,%d1
	bne .Lcu_cp
.Lcu_cpend:
	move.b #0,(%a1)
	cmpi.b #0,VerBuf
	beq .Lcu_fail
	; comparar "mayor.menor"
	lea VerBuf,%a0
	jsr ParseVer
	move.l %d0,%d5
	lea MyVersion,%a0
	jsr ParseVer
	cmp.l %d0,%d5
	bhi .Lcu_new
	; al dia (o la de Aminet es mas antigua): mostrar la nuestra
	move.l #MyVersion,ReqArgs
	move.l SUpLatest,%d0
	bra .Lcu_show
.Lcu_new:
	move.l #VerBuf,ReqArgs
	move.l #MyVersion,ReqArgs+4
	move.l SUpNew,%d0
	bra .Lcu_show
.Lcu_fail:
	move.l SUpFail,%d0
.Lcu_show:
	move.l %d0,%d6
	; cerrar la red antes de mostrar nada
	move.l BsdBase,%d0
	beq .Lcu_nb
	cmpi.l #0,%d7
	blt .Lcu_nosock
	move.l %d0,%a6
	move.l %d7,%d0
	LVO -120                      ; CloseSocket
.Lcu_nosock:
	move.l SysBase,%a6
	move.l BsdBase,%a1
	LVO -414
.Lcu_nb:
	move.l NetPtr,%d0
	beq .Lcu_nofree
	move.l SysBase,%a6
	move.l %d0,%a1
	LVO -690                      ; FreeVec
.Lcu_nofree:
	lea Easy,%a1
	move.l #20,(%a1)
	move.l #0,(4,%a1)
	move.l #ReqTitle,(8,%a1)
	move.l %d6,(12,%a1)
	move.l SUpOK,(16,%a1)
	move.l IntuitionBase,%a6
	move.l Window,%a0
	move.l #0,%a2
	lea ReqArgs,%a3
	LVO -588                      ; EasyRequestArgs
	RESTALL
	rts

; ParseVer(a0 = "1.2") -> d0 = mayor*65536 + menor   LEAF
ParseVer:
	; "1.3" -> 0x010300, "1.3.1" -> 0x010301
	move.l %d1,-(%sp)
	move.l %d2,-(%sp)
	move.l %d3,-(%sp)
	move.l #0,%d0                 ; numero en curso
	move.l #0,%d2                 ; acumulado
	move.l #3,%d3                 ; partes que quedan
.Lpv_n:
	move.b (%a0)+,%d1
	cmpi.b #0x30,%d1
	blt .Lpv_part
	cmpi.b #0x39,%d1
	bgt .Lpv_part
	and.l #0x0F,%d1
	.short 0xC0FC,10              ; mulu.w #10,d0
	add.l %d1,%d0
	bra .Lpv_n
.Lpv_part:
	and.l #0xFF,%d0
	lsl.l #8,%d2
	or.l %d0,%d2
	move.l #0,%d0
	sub.l #1,%d3
	beq .Lpv_end
	cmpi.b #0x2E,%d1              ; '.' -> otra parte
	beq .Lpv_n
.Lpv_fill:
	lsl.l #8,%d2
	sub.l #1,%d3
	bne .Lpv_fill
.Lpv_end:
	move.l %d2,%d0
	move.l (%sp)+,%d3
	move.l (%sp)+,%d2
	move.l (%sp)+,%d1
	rts

; OpenWin -> d0 = ventana o 0
OpenWin:
	SAVEALL
	lea WinTags,%a0
	move.l #0x80000064,(%a0)+     ; WA_Left
	move.l #40,(%a0)+
	move.l #0x80000065,(%a0)+     ; WA_Top
	move.l #30,(%a0)+
	move.l #0x80000076,(%a0)+     ; WA_InnerWidth
	move.l #IW,(%a0)+
	move.l #0x80000077,(%a0)+     ; WA_InnerHeight
	move.l IHv,%d0
	move.l %d0,(%a0)+
	move.l #0x80000079,(%a0)+     ; WA_PubScreen
	move.l Screen,%d0
	move.l %d0,(%a0)+
	move.l #0x8000006E,(%a0)+     ; WA_Title
	move.l #WinTitle,(%a0)+
	move.l #0x8000006F,(%a0)+     ; WA_ScreenTitle
	move.l #ScrTitle,(%a0)+
	move.l #0x8000006C,(%a0)+     ; WA_Gadgets
	move.l GList,%d0
	move.l %d0,(%a0)+
	move.l #0x8000006A,(%a0)+     ; WA_IDCMP
	move.l #0x0040027C,(%a0)+     ; CLOSEWINDOW|REFRESHWINDOW|LISTVIEWIDCMP|BUTTONIDCMP
	move.l #0x80000082,(%a0)+     ; WA_DragBar
	move.l #1,(%a0)+
	move.l #0x80000083,(%a0)+     ; WA_DepthGadget
	move.l #1,(%a0)+
	move.l #0x80000084,(%a0)+     ; WA_CloseGadget
	move.l #1,(%a0)+
	move.l #0x80000089,(%a0)+     ; WA_Activate
	move.l #1,(%a0)+
	move.l #0x8000008D,(%a0)+     ; WA_SmartRefresh
	move.l #1,(%a0)+
	move.l #0x80000090,(%a0)+     ; WA_AutoAdjust
	move.l #1,(%a0)+
	move.l #0,(%a0)+
	move.l #0,(%a0)+
	move.l IntuitionBase,%a6
	move.l #0,%a0
	lea WinTags,%a1
	LVO -606                      ; OpenWindowTagList
	move.l %d0,Window
	beq .Low_ret
	move.l %d0,%a0
	move.l (50,%a0),%d1
	move.l %d1,WinRP
.Low_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; Dibujo de los adornos: marco y rotulo de la vista previa y los creditos
DrawAll:
	SAVEALL
	lea TagBevel,%a1
	move.l #0x80080034,(%a1)      ; GT_VisualInfo
	move.l VisInfo,%d0
	move.l %d0,(4,%a1)
	move.l #0x80080033,(8,%a1)    ; GTBB_Recessed
	move.l #1,(12,%a1)
	move.l #0,(16,%a1)
	move.l GadToolsBase,%a6
	move.l WinRP,%a0
	move.l #X2,%d0
	add.l (BLv,%pc),%d0
	move.l PYv,%d1
	add.l (BTv,%pc),%d1
	move.l #RW,%d2
	move.l #PH,%d3
	LVO -120                      ; DrawBevelBoxA
	; textos
	move.l #X2,%d0
	move.l PLYv,%d1
	move.l SPreview,%a0
	jsr TextAt
	move.l #X1,%d0
	move.l CRYv,%d1
	lea TxtCredit,%a0
	jsr TextAt
	jsr DrawLogo
	jsr DrawPreview
	RESTALL
	rts

; LoadLogo: carga SYS:Prefs/Skins/SkinPatch.logo (si no esta, no pasa nada)
LoadLogo:
	SAVEALL
	lea LogoDir,%a4
	lea LogoName,%a3
	lea LogoBank,%a5
	jsr LoadOne
	RESTALL
	rts

; DrawLogo: el logo centrado debajo de la lista
DrawLogo:
	SAVEALL
	move.l LogoBank+BE_BM,%d0
	beq .Ldl_ret
	; sin marco: el logo directamente sobre el fondo de la ventana
	move.l #0,%d4
	move.w LogoBank+BE_FW,%d4     ; ancho de un fotograma
	cmpi.l #LOGOBW-4,%d4
	ble .Ldl_w
	move.l #LOGOBW-4,%d4
.Ldl_w:
	move.l #0,%d5
	move.w LogoBank+BE_FH,%d5
	cmpi.l #LOGOBH-4,%d5
	ble .Ldl_h
	move.l #LOGOBH-4,%d5
.Ldl_h:
	move.l #X1+LW/2,%d2           ; centrado
	move.l %d4,%d0
	lsr.l #1,%d0
	sub.l %d0,%d2
	add.l (BLv,%pc),%d2
	move.l LogoYv,%d3
	add.l #LOGOBH/2,%d3
	move.l %d5,%d0
	lsr.l #1,%d0
	sub.l %d0,%d3
	add.l (BTv,%pc),%d3
	move.l GfxBase,%a6
	move.l LogoBank+BE_BM,%a0
	move.l #0,%d0
	move.l #0,%d1
	move.l WinRP,%a1
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
.Ldl_ret:
	RESTALL
	rts

; TextAt(d0 x, d1 y linea base (interiores), a0 texto) en pluma 1
TextAt:
	SAVEALL
	move.l %a0,%a2
	add.l (BLv,%pc),%d0
	add.l (BTv,%pc),%d1
	move.l %d0,%d4
	move.l %d1,%d5
	move.l GfxBase,%a6
	move.l WinRP,%a1
	move.l #1,%d0
	LVO -342                      ; SetAPen
	move.l WinRP,%a1
	move.l %d4,%d0
	move.l %d5,%d1
	LVO -240                      ; Move
	move.l %a2,%a0
	jsr StrLen
	move.l WinRP,%a1
	move.l %a2,%a0
	LVO -60                       ; Text
	RESTALL
	rts

; DrawPreview: botones activos (fila 1) e inactivos (fila 2)
DrawPreview:
	SAVEALL
	move.l GfxBase,%a6
	move.l WinRP,%a1
	move.l #0,%d0
	LVO -342                      ; SetAPen 0
	move.l WinRP,%a1
	move.l #X2+2,%d0
	add.l (BLv,%pc),%d0
	move.l PYv,%d1
	add.l (BTv,%pc),%d1
	add.l #1,%d1
	move.l #X2+RW-3,%d2
	add.l (BLv,%pc),%d2
	move.l PYv,%d3
	add.l (BTv,%pc),%d3
	add.l #PH-2,%d3
	LVO -306                      ; RectFill
	move.l PrevCount,%d0
	bne .Ldp_imgs
	move.l #X2+8,%d0
	move.l PYv,%d1
	add.l #PH/2+4,%d1
	move.l SNoPreview,%a0
	jsr TextAt
	bra .Ldp_ret
.Ldp_imgs:
	move.l #0,%d7                 ; fila (0 activa, 1 inactiva)
.Ldp_row:
	move.l #X2+4,%d2
	add.l (BLv,%pc),%d2                 ; x
	move.l PYv,%d3
	add.l (BTv,%pc),%d3
	add.l #6,%d3
	cmpi.l #0,%d7
	beq .Ldp_r0
	add.l #32,%d3
.Ldp_r0:
	; fondo: barra de titulo de la skin (si tiene)
	lea BankP+IDX_BAR*BE_SIZE,%a2
	move.l (BE_BM,%a2),%d0
	beq .Ldp_nobar
	move.l %d2,-(%sp)
	move.l #0,%d4
	move.w (BE_FW,%a2),%d4
	move.l #0,%d5
	move.w (BE_FH,%a2),%d5
	cmpi.l #28,%d5
	ble .Ldp_bh
	move.l #28,%d5
.Ldp_bh:
	move.l %d4,%a3                ; fw
.Ldp_bar:
	move.l #X2+RW-4,%d1
	add.l (BLv,%pc),%d1
	sub.l %d2,%d1                 ; sitio que queda
	ble .Ldp_bardone
	move.l %a3,%d4
	cmp.l %d1,%d4
	ble .Ldp_bw
	move.l %d1,%d4
.Ldp_bw:
	move.l #0,%d0
	cmpi.l #0,%d7
	beq .Ldp_bsx
	move.l %a3,%d0
	add.l %d0,%d0
.Ldp_bsx:
	move.l #0,%d1
	move.l (BE_BM,%a2),%a0
	move.l WinRP,%a1
	move.l %d6,-(%sp)
	move.l #0xC0,%d6
	LVO -606
	move.l (%sp)+,%d6
	add.l %d4,%d2
	bra .Ldp_bar
.Ldp_bardone:
	move.l (%sp)+,%d2
.Ldp_nobar:
	lea BankP,%a2
	move.l #3,%d6
.Ldp_img:
	move.l (BE_BM,%a2),%d0
	beq .Ldp_next
	move.l #0,%d4
	move.w (BE_FW,%a2),%d4        ; fw
	move.l #0,%d5
	move.w (BE_FH,%a2),%d5        ; fh
	cmpi.l #28,%d5
	ble .Ldp_h
	move.l #28,%d5
.Ldp_h:
	move.l #X2+RW-6,%d1
	add.l (BLv,%pc),%d1
	sub.l %d2,%d1                 ; sitio que queda
	ble .Ldp_rowdone
	move.l %d4,%a3                ; guardar fw
	cmp.l %d1,%d4
	ble .Ldp_w
	move.l %d1,%d4
.Ldp_w:
	; sx = fotograma * fw (fotograma 0 o 2)
	move.l #0,%d0
	cmpi.l #0,%d7
	beq .Ldp_sx
	move.l %a3,%d0
	add.l %d0,%d0
.Ldp_sx:
	move.l #0,%d1
	move.l (BE_BM,%a2),%a0
	move.l WinRP,%a1
	move.l %d6,-(%sp)
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	move.l (%sp)+,%d6
	add.l %a3,%d2
	add.l #4,%d2
.Ldp_next:
	lea (BE_SIZE,%a2),%a2
	sub.l #1,%d6
	bne .Ldp_img
.Ldp_rowdone:
	add.l #1,%d7
	cmpi.l #2,%d7
	bne .Ldp_row
.Ldp_ret:
	RESTALL
	rts

; LoadPreview: carga las 3 imagenes de la skin elegida a la altura elegida
LoadPreview:
	SAVEALL
	lea BankP,%a2
	jsr FreeBank
	move.l #0,PrevCount
	move.l SelIdx,%d0
	beq .Llp_ret
	jsr NodeName
	move.l %a0,%a3
	move.l HeightIdx,%d0
	lsl.l #2,%d0
	lea HeightVals,%a0
	move.l (0,%a0,%d0),%d0
	bne .Llp_h
	move.l AutoH,%d0
.Llp_h:
	move.l %a3,%a0
	jsr ResolveSkinDir
	cmpi.l #0,%d0
	beq .Llp_ret
	lea PathBuf,%a0
	lea BankP,%a2
	move.l #NUM_SKIN,%d0
	jsr LoadBank
	move.l %d0,PrevCount
.Llp_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; Bucle de eventos
EventLoop:
	SAVEALL
.Lev_wait:
	move.l Window,%a0
	move.l (86,%a0),%a0           ; UserPort
	move.l SysBase,%a6
	LVO -384                      ; WaitPort
.Lev_get:
	move.l Window,%a0
	move.l (86,%a0),%a0
	move.l GadToolsBase,%a6
	LVO -72                       ; GT_GetIMsg
	cmpi.l #0,%d0
	beq .Lev_wait
	move.l %d0,%a1
	move.l (20,%a1),%d2           ; Class
	move.l #0,%d3
	move.w (24,%a1),%d3           ; Code
	move.l (28,%a1),%d4           ; IAddress
	LVO -78                       ; GT_ReplyIMsg
	cmpi.l #0x200,%d2             ; IDCMP_CLOSEWINDOW
	beq .Lev_cancel
	cmpi.l #0x4,%d2               ; IDCMP_REFRESHWINDOW
	beq .Lev_refresh
	cmpi.l #0x40,%d2              ; IDCMP_GADGETUP
	bne .Lev_get
	move.l %d4,%a0
	move.l #0,%d0
	move.w (38,%a0),%d0           ; GadgetID
	cmpi.l #ID_LIST,%d0
	beq .Lev_list
	cmpi.l #ID_HEIGHT,%d0
	beq .Lev_height
	cmpi.l #ID_ALL,%d0
	beq .Lev_all
	cmpi.l #ID_SAVE,%d0
	beq .Lev_save
	cmpi.l #ID_USE,%d0
	beq .Lev_use
	cmpi.l #ID_TEST,%d0
	beq .Lev_test
	cmpi.l #ID_CANCEL,%d0
	beq .Lev_cancel
	cmpi.l #ID_BORDER,%d0
	beq .Lev_border
	cmpi.l #ID_ENABLED,%d0
	beq .Lev_en
	cmpi.l #ID_UPDATE,%d0
	bne .Lev_get
	jsr CheckUpdate
	bra .Lev_get
.Lev_en:
	move.l #0,%d0
	move.w (12,%a0),%d0
	and.l #0x80,%d0               ; GFLG_SELECTED
	beq .Lev_en0
	move.l #1,%d0
.Lev_en0:
	move.l %d0,EnabledFlag
	bra .Lev_get
.Lev_border:
	move.l %d3,BorderIdx
	bra .Lev_get
.Lev_refresh:
	move.l GadToolsBase,%a6
	move.l Window,%a0
	LVO -90                       ; GT_BeginRefresh
	jsr DrawAll
	move.l GadToolsBase,%a6
	move.l Window,%a0
	move.l #1,%d0
	LVO -96                       ; GT_EndRefresh
	bra .Lev_get
.Lev_list:
	move.l %d3,SelIdx
	jsr LoadPreview
	jsr DrawPreview
	bra .Lev_get
.Lev_height:
	move.l %d3,HeightIdx
	jsr LoadPreview
	jsr DrawPreview
	bra .Lev_get
.Lev_all:
	move.l #0,%d0
	move.w (12,%a0),%d0           ; Flags
	and.l #0x80,%d0               ; GFLG_SELECTED
	beq .Lev_all0
	move.l #1,%d0
.Lev_all0:
	move.l %d0,AllFlag
	bra .Lev_get
.Lev_test:
	jsr FillPrefs
	lea CurPrefs,%a0
	lea PrefsEnv,%a1
	jsr WritePrefs
	jsr Notify
	move.l #1,Tested
	bra .Lev_get
.Lev_save:
	jsr FillPrefs
	lea CurPrefs,%a0
	lea PrefsArc,%a1
	jsr WritePrefs
.Lev_use:
	jsr FillPrefs
	lea CurPrefs,%a0
	lea PrefsEnv,%a1
	jsr WritePrefs
	jsr Notify
	bra .Lev_ret
.Lev_cancel:
	move.l Tested,%d0
	beq .Lev_ret
	lea OrigPrefs,%a0
	lea PrefsEnv,%a1
	jsr WritePrefs
	lea OrigPrefs,%a0
	lea CurPrefs,%a1
	move.l #PR_SIZE/4,%d0
.Lev_cp:
	move.l (%a0)+,(%a1)+
	sub.l #1,%d0
	bne .Lev_cp
	jsr Notify
.Lev_ret:
	RESTALL
	rts

; FillPrefs: CurPrefs a partir de lo elegido en la ventana
FillPrefs:
	SAVEALL
	lea CurPrefs,%a2
	move.l #PR_MAGICVAL,(PR_MAGIC,%a2)
	move.l HeightIdx,%d0
	lsl.l #2,%d0
	lea HeightVals,%a0
	move.l (0,%a0,%d0),%d0
	move.l %d0,(PR_HEIGHT,%a2)
	move.l AllFlag,%d0
	move.l EnabledFlag,%d1
	bne .Lfp_en
	or.l #2,%d0                   ; desactivado
.Lfp_en:
	move.l %d0,(PR_ALL,%a2)
	move.l BorderIdx,%d0
	lsl.l #2,%d0
	lea BorderVals,%a0
	move.l (0,%a0,%d0),%d0
	move.l %d0,(PR_BORDER,%a2)
	lea (PR_NAME,%a2),%a1
	move.l #15,%d0
.Lfp_clr:
	move.l #0,(%a1)+
	sub.l #1,%d0
	bne .Lfp_clr
	move.l SelIdx,%d0
	beq .Lfp_ret
	jsr NodeName
	lea (PR_NAME,%a2),%a1
	move.l #60,%d0
	jsr StrCpy
.Lfp_ret:
	RESTALL
	rts

; Notify: avisa a SkinPatch (o lo arranca si no esta en marcha)
Notify:
	SAVEALL
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	lea PortName,%a1
	LVO -390                      ; FindPort
	cmpi.l #0,%d0
	beq .Lno_start
	move.l %d0,%a0
	lea NotifyMsg,%a1
	move.b #5,(8,%a1)             ; NT_MESSAGE
	move.l ReplyPort,%d1
	move.l %d1,(14,%a1)
	move.w #PM_SIZE,(18,%a1)
	move.l #CMD_RELOAD,(PM_CMD,%a1)
	move.l #0,(PM_ALL,%a1)
	move.b #0,(PM_PATH,%a1)
	LVO -366                      ; PutMsg
	LVO -138                      ; Permit
	move.l ReplyPort,%a0
	LVO -384                      ; WaitPort
	move.l ReplyPort,%a0
	LVO -372                      ; GetMsg
	bra .Lno_ret
.Lno_start:
	LVO -138                      ; Permit
	move.b CurPrefs+PR_NAME,%d0
	beq .Lno_ret
	move.l DOSBase,%a6
	move.l #NilName,%d1
	move.l #1006,%d2
	LVO -30                       ; Open("NIL:")
	move.l %d0,%d6
	lea TagSys,%a0
	move.l #0x80000021,(%a0)      ; SYS_Input
	move.l %d6,(4,%a0)
	move.l #0x80000022,(8,%a0)    ; SYS_Output
	move.l #0,(12,%a0)
	move.l #0,(16,%a0)
	move.l #RunCmd,%d1
	move.l #TagSys,%d2
	LVO -606                      ; SystemTagList
	cmpi.l #0,%d6
	beq .Lno_ret
	move.l %d6,%d1
	LVO -36                       ; Close
.Lno_ret:
	RESTALL
	rts

; ===========================================================================
	.data
	.p2align 2
BorderVals:
	.long 0, 4, 6, 8, 10, 12, 14, 16
BorderLabels:
	.long BL0, BL1, BL2, BL3, BL4, BL5, BL6, BL7, 0
HeightVals:
	.long 0, 11, 13, 15, 17, 20, 24
HeightLabels:
	.long HL0, HL1, HL2, HL3, HL4, HL5, HL6, 0
BtnTable:
	.long ID_SAVE, TxtSave, ID_TEST, TxtTest, ID_USE, TxtUse, ID_CANCEL, TxtCancel, 0
LibList:
	.long DOSBase, IntuitionBase, GfxBase, GadToolsBase, DataTypesBase, LocaleBase, 0
; textos traducibles: ranuras con el texto en ingles (se cambian por los del
; catalogo skinprefs.catalog si lo hay)
SSkins:     .long TxtSkins
SHeight:    .long TxtHeight
SEnabled:   .long TxtEnabled
SAll:       .long TxtAll
SPreview:   .long TxtPreview
SNoPreview: .long TxtNoPreview
SUpdate:    .long TxtUpdate
SUpLatest:  .long TxtUpLatest
SUpNew:     .long TxtUpNew
SUpFail:    .long TxtUpFail
SUpOK:      .long TxtUpOK
; (numero en el catalogo, ranura)
StrTab:
	.long 1, SSkins, 2, SHeight, 3, SEnabled, 4, SAll, 5, SPreview, 6, SNoPreview
	.long 7, BtnTable+4, 8, BtnTable+12, 9, BtnTable+20, 10, BtnTable+28
	.long 11, HeightLabels
	.long 12, BorderLabels, 13, BorderLabels+4, 14, BorderLabels+8, 15, BorderLabels+12
	.long 16, BorderLabels+16, 17, BorderLabels+20, 18, BorderLabels+24, 19, BorderLabels+28
	.long 20, SUpdate, 21, SUpLatest, 22, SUpNew, 23, SUpFail, 24, SUpOK
	.long 0
CatTags:    .long 0, 0, 0, 0, 0, 0
LocaleName: .asciz "locale.library"
CatName:    .asciz "skinprefs.catalog"
LangVar:    .asciz "SkinPatch.language"
English:    .asciz "english"
	.p2align 2
Version:  .asciz "$VER: SkinPrefs 1.4 (23.11.2026) Amigatronics"
GTName:   .asciz "gadtools.library"
NilName:  .asciz "NIL:"
RunCmd:   .asciz "Run >NIL: SkinPatch"
WinTitle: .asciz "SkinPrefs - by Amigatronics"
ScrTitle: .asciz "SkinPrefs 1.4 - Amigatronics"
TxtCredit: .asciz "SkinPatch 1.4 by Amigatronics"
LogoDir:  .asciz "SYS:Prefs/Skins"
LogoName: .asciz "SkinPatch.logo"
TxtUpdate: .asciz "Check for updates"
TxtUpLatest: .asciz "You have the latest version (%s)."
TxtUpNew: .asciz "A new version is available: %s\n(you have %s)\n\nGet it from Aminet (util/wb/SkinPatch.lha)\nor with Hangar."
TxtUpFail: .asciz "Could not check for updates.\n\nIs the Amiga connected to the Internet\n(TCP/IP stack running)?"
TxtUpOK:  .asciz "OK"
MyVersion: .asciz "1.4"
BsdName:  .asciz "bsdsocket.library"
AminetHost: .asciz "aminet.net"
HttpReq:  .ascii "GET /util/wb/SkinPatch.readme HTTP/1.0\r\nHost: aminet.net\r\nUser-Agent: SkinPrefs/1.4 (AmigaOS)\r\nConnection: close\r\n\r\n"
HttpReqEnd:
	.byte 0
VerKey:   .asciz "Version:"
ReqTitle: .asciz "SkinPrefs"
TxtSkins: .asciz "Skins"
TxtHeight: .asciz "Title bar height"
TxtEnabled: .asciz "Enabled"
TxtAll:   .asciz "All screens"
TxtPreview: .asciz "Preview"
TxtNoPreview: .asciz "(no preview)"
TxtSave:  .asciz "Save"
TxtTest:  .asciz "Test"
TxtUse:   .asciz "Use"
TxtCancel: .asciz "Cancel"
NoneName: .asciz "(none)"
HL0: .asciz "Automatic"
BL0: .asciz "Frame: default (8)"
BL1: .asciz "Frame: 4 pixels"
BL2: .asciz "Frame: 6 pixels"
BL3: .asciz "Frame: 8 pixels"
BL4: .asciz "Frame: 10 pixels"
BL5: .asciz "Frame: 12 pixels"
BL6: .asciz "Frame: 14 pixels"
BL7: .asciz "Frame: 16 pixels"
HL1: .asciz "11"
HL2: .asciz "13"
HL3: .asciz "15"
HL4: .asciz "17"
HL5: .asciz "20"
HL6: .asciz "24"

	.bss
	.p2align 2
WBMsg:        .space 4
GadToolsBase: .space 4
LocaleBase:   .space 4
Catalog:      .space 4
LangBuf:      .space 40
UYv:          .space 4
BsdBase:      .space 4
NetPtr:       .space 4
VerBuf:       .space 32
SockAddr:     .space 16
Easy:         .space 20
ReqArgs:      .space 16
ReplyPort:    .space 4
Screen:       .space 4
VisInfo:      .space 4
Window:       .space 4
WinRP:        .space 4
GList:        .space 4
GadPrev:      .space 4
SelIdx:       .space 4
HeightIdx:    .space 4
AllFlag:      .space 4
BorderIdx:    .space 4
EnabledFlag:  .space 4
EYv:          .space 4
FYv:          .space 4
Tested:       .space 4
PrevCount:    .space 4
NumNames:     .space 4
AutoH:        .space 4
BLv:          .space 4
BTv:          .space 4
Fv:           .space 4
Gv:           .space 4
LYv:          .space 4
LHv:          .space 4
KYv:          .space 4
PLYv:         .space 4
PYv:          .space 4
BYv:          .space 4
CRYv:         .space 4
IHv:          .space 4
NG:           .space 32
TagList:      .space 40
TagCyc:       .space 24
TagChk:       .space 16
TagBevel:     .space 24
TagSys:       .space 24
WinTags:      .space 160
OrigPrefs:    .space PR_SIZE
CurPrefs:     .space PR_SIZE
NotifyMsg:    .space PM_SIZE
SkinList:     .space 16
Nodes:        .space 16*MAXSKINS
NamePtrs:     .space 4*MAXSKINS
NameBuf:      .space NAMELEN*MAXSKINS
BankP:        .space BANK_SIZE
LogoBank:     .space BANK_SIZE
LogoYv:       .space 4
