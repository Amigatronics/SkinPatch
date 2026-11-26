; SkinPatch 0.4 - skins para las imagenes del sistema (sysiclass)
; AmigaOS 3.2, cualquier 68000+.  by Amigatronics
;
; Uso:  SkinPatch [SKIN=<carpeta>] [ALLSCREENS] [QUIT]
;   Sin SKIN usa la configuracion de ENV:SkinPatch.prefs (la de SkinPrefs).
;   Si ya hay un SkinPatch en marcha, le pide que recargue (o que salga
;   con QUIT) y termina.

	.include "common.s"

	.set MAX_OBJ, 1024
	.set SYSIA_Which, 0x8002000D
	.set SYSIA_DrawInfo, 0x80020018

	.text
	.globl _start
_start:
	SAVEALL
	move.l $4,%a6
	move.l %a6,SysBase
	.short 0x93C9                 ; suba.l a1,a1
	LVO -294                      ; FindTask(NULL)
	move.l %d0,%a4
	move.l (172,%a4),%d0          ; pr_CLI
	bne .Lcli
	lea (92,%a4),%a0
	LVO -384                      ; WaitPort
	lea (92,%a4),%a0
	LVO -372                      ; GetMsg
	move.l %d0,%d2
	LVO -132                      ; Forbid
	move.l %d2,%a1
	LVO -378                      ; ReplyMsg
	move.l #20,%d0
	bra .Lend
.Lcli:
	jsr RunWithBigStack
.Lend:
	RESTALL
	rts

; ---------------------------------------------------------------------------
Main:
	SAVEALL
	move.l #20,%d7
	move.l #-1,DirtySig
	move.l #-1,TitlePen                ; codigo de retorno
	move.l #-1,TubePen
	move.l #-1,TitlePenW
	move.l SysBase,%a6
	lea DosName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,DOSBase
	beq .Lm_ret

	lea Banner,%a0
	jsr Puts

	move.l DOSBase,%a6
	move.l #Template,%d1
	move.l #ArgArray,%d2
	move.l #0,%d3
	LVO -798                      ; ReadArgs
	move.l %d0,RDArgs
	bne .Lm_args
	LVO -132                      ; IoErr
	move.l %d0,%d1
	move.l #ProgName,%d2
	LVO -474                      ; PrintFault
	bra .Lm_closedos
.Lm_args:
	; mensaje con la orden (por si hay que mandarlo a otra copia)
	lea CmdMsg,%a2
	move.l #CMD_RELOAD,(PM_CMD,%a2)
	move.l ArgArray+8,%d0         ; QUIT
	beq .Lm_noquit
	move.l #CMD_QUIT,(PM_CMD,%a2)
.Lm_noquit:
	move.l ArgArray+16,%d0        ; STATS=fichero
	beq .Lm_nostats
	move.l #CMD_STATS,(PM_CMD,%a2)
.Lm_nostats:
	move.l ArgArray+4,%d0         ; ALLSCREENS
	move.l %d0,(PM_ALL,%a2)
	move.l ArgArray+12,%d0        ; LOG -> activar el registro
	move.l %d0,LogFlag
	move.b #0,(PM_PATH,%a2)
	move.l ArgArray+16,%d0        ; STATS: la ruta es el fichero
	bne .Lm_haspath
	move.l ArgArray,%d0           ; SKIN
	beq .Lm_nopath
.Lm_haspath:
	move.l %d0,%a0
	lea (PM_PATH,%a2),%a1
	move.l #256,%d0
	jsr StrCpy
.Lm_nopath:
	; ya hay uno en marcha?
	move.l SysBase,%a6
	LVO -666                      ; CreateMsgPort
	move.l %d0,ReplyPort
	beq .Lm_freeargs
	LVO -132                      ; Forbid
	lea PortName,%a1
	LVO -390                      ; FindPort
	cmpi.l #0,%d0
	beq .Lm_first
	move.l %d0,%a0
	lea CmdMsg,%a1
	move.l ReplyPort,%d1
	move.l %d1,(14,%a1)           ; mn_ReplyPort
	move.w #PM_SIZE,(18,%a1)      ; mn_Length
	move.b #5,(8,%a1)             ; NT_MESSAGE
	LVO -366                      ; PutMsg
	LVO -138                      ; Permit
	move.l ReplyPort,%a0
	LVO -384                      ; WaitPort
	move.l ReplyPort,%a0
	LVO -372                      ; GetMsg
	move.l CmdMsg+PM_CMD,%d0
	cmpi.l #-1,%d0
	bne .Lm_sentok
	lea MsgQuitFail,%a0
	jsr Puts
	move.l #10,%d7
	bra .Lm_delreply
.Lm_sentok:
	lea MsgSent,%a0
	jsr Puts
	move.l #0,%d7
	bra .Lm_delreply
.Lm_first:
	LVO -138                      ; Permit
	move.l CmdMsg+PM_CMD,%d0
	cmpi.l #CMD_STATS,%d0
	beq .Lm_notrun
	cmpi.l #CMD_QUIT,%d0
	bne .Lm_start
.Lm_notrun:
	lea MsgNotRunning,%a0
	jsr Puts
	move.l #5,%d7
	bra .Lm_delreply

.Lm_start:
	move.l SysBase,%a6
	lea IntuiName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,IntuitionBase
	lea GfxName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,GfxBase
	lea DTName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,DataTypesBase
	lea LayersName,%a1
	move.l #39,%d0
	LVO -552
	move.l %d0,LayersBase
	beq .Lm_nolibs
	move.l IntuitionBase,%d0
	beq .Lm_nolibs
	move.l GfxBase,%d0
	beq .Lm_nolibs
	move.l DataTypesBase,%d0
	bne .Lm_libsok
.Lm_nolibs:
	lea MsgNoLibs,%a0
	jsr Puts
	bra .Lm_cleanup
.Lm_libsok:
	move.l IntuitionBase,%a6
	lea WBName,%a0
	LVO -510                      ; LockPubScreen
	move.l %d0,WBScreen
	bne .Lm_scrok
	lea MsgNoScreen,%a0
	jsr Puts
	bra .Lm_cleanup
.Lm_scrok:
	move.l %d0,InitLock           ; se suelta al terminar de arrancar
	move.l %d0,RemapScreen
	move.l %d0,%a0
	LVO -690                      ; GetScreenDrawInfo
	move.l %d0,WBDri

	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -558                      ; InitSemaphore
	lea KnSem,%a0
	LVO -558
	move.l #BankA,CurBank
	.short 0x93C9                 ; suba.l a1,a1
	LVO -294                      ; FindTask(NULL)
	move.l %d0,MainTask
	move.l #-1,%d0
	LVO -330                      ; AllocSignal(-1)
	move.l %d0,DirtySig
	bmi .Lm_cleanup
	move.l #1,%d1
	lsl.l %d0,%d1
	move.l %d1,DirtyMask

	; puerto publico
	LVO -666                      ; CreateMsgPort
	move.l %d0,PubPort
	beq .Lm_cleanup
	move.l %d0,%a1
	move.l #PortName,(10,%a1)     ; ln_Name
	move.b #0,(9,%a1)             ; ln_Pri
	LVO -354                      ; AddPort

	; temporizador de 1 s (revision de titulos)
	jsr TimerOpen
	; pluma del titulo: el color mas parecido al negro en esta pantalla
	move.l GfxBase,%a6
	move.l WBScreen,%a0
	move.l (48,%a0),%a0           ; ViewPort.ColorMap
	move.l #0,%d1
	move.l #0,%d2
	move.l #0,%d3
	lea PenTags,%a1
	LVO -840                      ; ObtainBestPenA
	move.l %d0,TitlePen
	; y el mas parecido al blanco (skins oscuras)
	move.l WBScreen,%a0
	move.l (48,%a0),%a0
	move.l #-1,%d1
	move.l #-1,%d2
	move.l #-1,%d3
	lea PenTags,%a1
	LVO -840
	move.l %d0,TitlePenW
	; carga inicial
	lea CmdMsg,%a2
	jsr DoReload

	jsr InstallPatch
	cmpi.l #0,%d0
	bne .Lm_patched
	lea MsgNoClass,%a0
	jsr Puts
	bra .Lm_remport
.Lm_patched:
	lea MsgActive,%a0
	jsr Puts
	; marcos de al menos 6 pixeles en las ventanas nuevas (como AmigaOS 4)
	move.l WBScreen,%a0
	move.b (36,%a0),OrigBor
	move.b (37,%a0),OrigBor+1
	move.b (38,%a0),OrigBor+2
	move.l #1,BorSet
	jsr ApplyBorder
.Lm_bordone:
	; foto de la pantalla y soltarla: si la tenemos bloqueada, Intuition
	; no puede reiniciar el Workbench (cambio de fuente o de modo)
	move.l WBScreen,%a0
	lea SnapCur,%a1
	jsr SnapScr
	move.l IntuitionBase,%a6
	move.l #0,%a0
	move.l InitLock,%a1
	LVO -516                      ; UnlockPubScreen
	move.l #0,InitLock

	; bucle principal
.Lm_wait:
	move.l PubPort,%a0
	move.l #0,%d1
	move.b (15,%a0),%d1           ; mp_SigBit
	move.l #1,%d0
	lsl.l %d1,%d0
	or.l #0x1000,%d0              ; + SIGBREAKF_CTRL_C
	or.l (DirtyMask,%pc),%d0      ; + barras pendientes de repintar
	or.l (TimerMask,%pc),%d0      ; + temporizador
	move.l SysBase,%a6
	LVO -318                      ; Wait
	move.l %d0,%d5
	move.l #0,%d4                 ; salir?
	move.l %d5,%d0
	and.l (TimerMask,%pc),%d0
	beq .Lm_notimer
	jsr TimerTick
.Lm_notimer:
	move.l %d5,%d0
	and.l (DirtyMask,%pc),%d0
	beq .Lm_msgs
	jsr ProcessDirty
.Lm_msgs:
	move.l SysBase,%a6
	move.l PubPort,%a0
	LVO -372                      ; GetMsg
	cmpi.l #0,%d0
	beq .Lm_nomsg
	move.l %d0,%a2
	move.l (PM_CMD,%a2),%d0
	cmpi.l #CMD_STATS,%d0
	bne .Lm_notstats
	jsr WriteStats                ; a2 = mensaje (PM_PATH = fichero)
	bra .Lm_reply
.Lm_notstats:
	cmpi.l #CMD_QUIT,%d0
	bne .Lm_reload
	jsr RemovePatch               ; intentar quitar los parches ya
	cmpi.l #0,%d0
	bne .Lm_qok
	move.l #-1,(PM_CMD,%a2)       ; avisar al que lo pidio: no se pudo
	bra .Lm_reply
.Lm_qok:
	move.l #2,%d4                 ; parches quitados: salir
	bra .Lm_reply
.Lm_reload:
	jsr DoReload                  ; a2 = mensaje
.Lm_reply:
	move.l SysBase,%a6
	move.l %a2,%a1
	LVO -378                      ; ReplyMsg
	bra .Lm_msgs
.Lm_nomsg:
	cmpi.l #2,%d4
	beq .Lm_removed               ; ya se quitaron con QUIT
	and.l #0x1000,%d5
	or.l %d5,%d4
	cmpi.l #0,%d4
	beq .Lm_wait
	jsr RemovePatch
	cmpi.l #0,%d0
	bne .Lm_removed
	lea MsgCantRemove,%a0
	jsr Puts
	bra .Lm_wait
.Lm_removed:
	; LOG=fichero: el informe va tambien a ese fichero
	move.l #0,LogFH
	move.l ArgArray+12,%d1
	beq .Lm_nolog
	move.l DOSBase,%a6
	move.l #1006,%d2
	LVO -30                       ; Open
	move.l %d0,LogFH
	beq .Lm_nolog
	move.l %d0,%d1
	LVO -300                      ; SelectOutput
	move.l %d0,OldOut
	lea Banner,%a0
	jsr Puts
.Lm_nolog:
	lea MsgSizes,%a0
	jsr Puts
	move.l #0,%d6
.Lm_rep:
	lea SeenTab,%a0
	move.l %d6,%d0
	lsl.l #2,%d0
	move.w (0,%a0,%d0),%d1
	beq .Lm_repn
	ext.l %d1
	move.l %d1,PrintArgs+4
	move.w (2,%a0,%d0),%d1
	ext.l %d1
	move.l %d1,PrintArgs+8
	lea FileNames,%a0
	move.l (0,%a0,%d0),%d1
	move.l %d1,PrintArgs
	lea MsgImgLine,%a0
	jsr Printf
.Lm_repn:
	add.l #1,%d6
	cmpi.l #NUM_SKIN,%d6
	bne .Lm_rep
	; diagnostico (solo si se pidio LOG)
	move.l LogFH,%d0
	beq .Lm_nodiag
	move.l SysIClass,%a0
	move.l %a0,PrintArgs
	move.l (28,%a0),%d0           ; cl_ID
	bne .Lm_hasid
	move.l #NoId,%d0
.Lm_hasid:
	move.l %d0,PrintArgs+4
	move.l OrigEntry,%d0
	move.l %d0,PrintArgs+8
	lea MsgDiag1,%a0
	jsr Printf
	move.l CntAll,%d0
	move.l %d0,PrintArgs
	move.l CntNew,%d0
	move.l %d0,PrintArgs+4
	move.l CntTracked,%d0
	move.l %d0,PrintArgs+8
	move.l CntDraw,%d0
	move.l %d0,PrintArgs+12
	lea MsgDiag2,%a0
	jsr Printf
	move.l CntSkinned,%d0
	move.l %d0,PrintArgs
	move.l CntMatched,%d0
	move.l %d0,PrintArgs+4
	lea MsgDiag3,%a0
	jsr Printf
	move.l #0,%d6
.Lm_wc:
	lea WhichCnt,%a0
	move.l %d6,%d0
	lsl.l #2,%d0
	move.l (0,%a0,%d0),%d1
	beq .Lm_wcn
	move.l %d6,PrintArgs
	move.l %d1,PrintArgs+4
	lea MsgDiag4,%a0
	jsr Printf
.Lm_wcn:
	add.l #1,%d6
	cmpi.l #32,%d6
	bne .Lm_wc
	move.l CntTextSkip,%d0
	move.l %d0,PrintArgs
	move.l LogN,%d0
	move.l %d0,PrintArgs+4
	lea MsgLog1,%a0
	jsr Printf
	lea LogBuf,%a3
	move.l LogN,%d6
.Lm_lg:
	cmpi.l #0,%d6
	beq .Lm_nodiag
	move.l (%a3),%d0
	move.l %d0,PrintArgs
	move.w (4,%a3),%d0
	ext.l %d0
	move.l %d0,PrintArgs+4
	move.w (6,%a3),%d0
	ext.l %d0
	move.l %d0,PrintArgs+8
	move.w (8,%a3),%d0
	ext.l %d0
	move.l %d0,PrintArgs+12
	move.l #0,%d0
	move.b (10,%a3),%d0
	move.l %d0,PrintArgs+16
	move.b (11,%a3),%d0
	move.l %d0,PrintArgs+20
	move.b (45,%a3),%d0
	move.l %d0,PrintArgs+24
	move.b (44,%a3),%d0
	move.l %d0,PrintArgs+28
	lea (12,%a3),%a0
	move.l %a0,PrintArgs+32
	lea (28,%a3),%a0
	move.l %a0,PrintArgs+36
	lea MsgLog2,%a0
	jsr Printf
	lea (LOGSZ,%a3),%a3
	sub.l #1,%d6
	bra .Lm_lg
.Lm_nodiag:
	lea MsgBye,%a0
	jsr Puts
	move.l LogFH,%d0
	beq .Lm_nolog2
	move.l DOSBase,%a6
	move.l OldOut,%d1
	LVO -300                      ; SelectOutput (restaurar)
	move.l LogFH,%d1
	LVO -36                       ; Close
	lea MsgLogged,%a0
	jsr Puts
.Lm_nolog2:
	move.l #0,%d7

.Lm_remport:
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l PubPort,%a1
	LVO -360                      ; RemPort
.Lm_drain:
	move.l PubPort,%a0
	LVO -372                      ; GetMsg
	cmpi.l #0,%d0
	beq .Lm_drained
	move.l %d0,%a1
	LVO -378                      ; ReplyMsg
	bra .Lm_drain
.Lm_drained:
	LVO -138                      ; Permit
	move.l PubPort,%a0
	LVO -672                      ; DeleteMsgPort
	move.l #0,PubPort

.Lm_cleanup:
	jsr TimerClose
	jsr ExitScreen                ; bloquear la pantalla, si sigue siendo la nuestra
	move.l TitlePen,%d0
	bmi .Lm_nopen
	move.l WBScreen,%d1
	beq .Lm_nopen
	move.l %d1,%a0
	move.l (48,%a0),%a0
	move.l GfxBase,%a6
	LVO -948                      ; ReleasePen
	move.l #-1,TitlePen
.Lm_nopen:
	move.l TitlePenW,%d0
	bmi .Lm_nopenw
	move.l WBScreen,%d1
	beq .Lm_nopenw
	move.l %d1,%a0
	move.l (48,%a0),%a0
	move.l GfxBase,%a6
	LVO -948
	move.l #-1,TitlePenW
.Lm_nopenw:
	move.l TubePen,%d0
	bmi .Lm_nopent
	move.l WBScreen,%d1
	beq .Lm_nopent
	move.l %d1,%a0
	move.l (48,%a0),%a0
	move.l GfxBase,%a6
	LVO -948
	move.l #-1,TubePen
.Lm_nopent:
	lea BankA,%a2
	jsr FreeBank
	lea BankB,%a2
	jsr FreeBank
	move.l IntuitionBase,%a6
	move.l WBDri,%d0
	beq .Lm_nodri
	move.l WBScreen,%a0
	move.l %d0,%a1
	LVO -696                      ; FreeScreenDrawInfo
.Lm_nodri:
	move.l WBScreen,%d0
	beq .Lm_noscr
	move.l BorSet,%d1
	beq .Lm_nobor
	move.l %d0,%a0
	move.b OrigBor,(36,%a0)
	move.b OrigBor+1,(37,%a0)
	move.b OrigBor+2,(38,%a0)
.Lm_nobor:
.Lm_noscr:
	move.l ExitLock,%d0
	beq .Lm_nounl
	move.l IntuitionBase,%a6
	move.l #0,%a0
	move.l %d0,%a1
	LVO -516                      ; UnlockPubScreen
.Lm_nounl:
	move.l SysBase,%a6
	move.l DirtySig,%d0
	bmi .Lm_nosig
	LVO -336                      ; FreeSignal
.Lm_nosig:
	move.l LayersBase,%d0
	beq .Lm_c0
	move.l %d0,%a1
	LVO -414
.Lm_c0:
	move.l DataTypesBase,%d0
	beq .Lm_c1
	move.l %d0,%a1
	LVO -414
.Lm_c1:
	move.l GfxBase,%d0
	beq .Lm_c2
	move.l %d0,%a1
	LVO -414
.Lm_c2:
	move.l IntuitionBase,%d0
	beq .Lm_delreply
	move.l %d0,%a1
	LVO -414
.Lm_delreply:
	move.l SysBase,%a6
	move.l ReplyPort,%a0
	LVO -672                      ; DeleteMsgPort
.Lm_freeargs:
	move.l DOSBase,%a6
	move.l RDArgs,%d1
	LVO -858                      ; FreeArgs
.Lm_closedos:
	move.l SysBase,%a6
	move.l DOSBase,%a1
	LVO -414
.Lm_ret:
	move.l %d7,%d0
	RESTALL
	rts

; ---------------------------------------------------------------------------
Puts:
	SAVEALL
	move.l DOSBase,%a6
	move.l %a0,%d1
	LVO -948                      ; PutStr
	RESTALL
	rts

Printf:
	SAVEALL
	move.l DOSBase,%a6
	move.l %a0,%d1
	move.l #PrintArgs,%d2
	LVO -954                      ; VPrintf
	RESTALL
	rts

; ---------------------------------------------------------------------------
; DoReload(a2 = mensaje con PM_PATH / PM_ALL)
; Carga la skin nueva en el banco libre y la activa.
DoReload:
	SAVEALL
	move.l (PM_ALL,%a2),%d5       ; todas las pantallas
	move.b (PM_PATH,%a2),%d0
	beq .Lrl_prefs
	lea (PM_PATH,%a2),%a0
	lea DirBuf,%a1
	move.l #256,%d0
	jsr StrCpy
	bra .Lrl_load
.Lrl_prefs:
	move.b #0,DirBuf
	lea PrefsBuf,%a0
	jsr ReadPrefs
	cmpi.l #0,%d0
	beq .Lrl_load
	move.l PrefsBuf+PR_ALL,%d0
	move.l %d0,%d1
	and.l #1,%d0
	or.l %d0,%d5
	move.l PrefsBuf+PR_BORDER,PrefBorder
	move.l #0,Disabled
	and.l #2,%d1                  ; desactivado en SkinPrefs: sin skin
	beq .Lrl_on
	move.l #1,Disabled
	bra .Lrl_load
.Lrl_on:
	move.b PrefsBuf+PR_NAME,%d0
	beq .Lrl_load
	move.l PrefsBuf+PR_HEIGHT,%d0
	bne .Lrl_h
	move.l WBScreen,%a0
	jsr AutoHeight
.Lrl_h:
	lea PrefsBuf+PR_NAME,%a0
	jsr ResolveSkinDir
	cmpi.l #0,%d0
	beq .Lrl_nodir
	lea PathBuf,%a0
	lea DirBuf,%a1
	move.l #256,%d0
	jsr StrCpy
	bra .Lrl_load
.Lrl_nodir:
	lea MsgNoDir,%a0
	jsr Puts
.Lrl_load:
	; banco libre
	lea BankA,%a3
	move.l CurBank,%d0
	cmp.l %a3,%d0
	bne .Lrl_gotbank
	lea BankB,%a3
.Lrl_gotbank:
	move.l %a3,%a2
	jsr FreeBank
	move.l #0,%d4
	move.b DirBuf,%d0
	beq .Lrl_swap
	lea DirBuf,%a0
	move.l %a3,%a2
	move.l #NUM_SKIN,%d0
	jsr LoadBank
	move.l %d0,%d4
	move.l #DirBuf,PrintArgs
	move.l %d4,PrintArgs+4
	lea MsgSkin,%a0
	jsr Printf
.Lrl_swap:
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -564                      ; ObtainSemaphore
	move.l CurBank,%d6            ; banco viejo
	move.l %a3,CurBank
	move.l %d5,AllScreens
	lea ObjSem,%a0
	LVO -570                      ; ReleaseSemaphore
	move.l %d6,%a2
	jsr FreeBank
	jsr ApplyBorder
	jsr TubeColor
	; sin skin (desactivado o sin tiradores): devolver las barras del
	; Workbench al sistema, que si no se quedan en blanco
	move.l Disabled,%d0
	bne .Lrl_kr
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),%d0
	bne .Lrl_end
.Lrl_kr:
	jsr KnReleaseAll
.Lrl_end:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; Reinicio de la pantalla Workbench (cambio de fuente, de modo...).
; No la tenemos bloqueada; cada segundo miramos si sigue siendo la misma
; y, si Intuition la ha cerrado y abierto de nuevo, nos enganchamos a la nueva.

; SnapScr(a0 = pantalla, a1 = foto de 16 bytes)  LEAF
SnapScr:
	move.l %d2,-(%sp)
	move.l %a2,-(%sp)
	move.l %a0,(%a1)              ; direccion
	move.l (12,%a0),(4,%a1)       ; ancho y alto
	move.l #0,%d0
	move.b (30,%a0),%d0           ; BarHeight
	lsl.l #8,%d0
	lsl.l #8,%d0
	move.l #0,%d1                 ; suma del nombre de la fuente
	move.l (40,%a0),%d2           ; Font (TextAttr)
	beq .Lss_put
	move.l %d2,%a2
	move.w (4,%a2),%d0            ; ta_YSize
	move.l (%a2),%d2              ; ta_Name
	beq .Lss_put
	move.l %d2,%a2
	move.l #32,%d2
.Lss_sum:
	move.l #0,%d1
	move.b (%a2)+,%d1
	beq .Lss_put0
	add.l %d1,(12,%a1)
	sub.l #1,%d2
	bne .Lss_sum
.Lss_put0:
	move.l (12,%a1),%d1
.Lss_put:
	move.l %d0,(8,%a1)
	move.l %d1,(12,%a1)
	move.l (%sp)+,%a2
	move.l (%sp)+,%d2
	rts

; ScrCheck: comprueba la pantalla Workbench actual (desde el temporizador)
ScrCheck:
	SAVEALL
	move.l WBScreen,%d0
	beq .Lsc_ret
	move.l IntuitionBase,%a6
	lea WBName,%a0
	LVO -510                      ; LockPubScreen
	move.l %d0,%d7
	beq .Lsc_ret                  ; ahora mismo no hay Workbench
	lea SnapTmp,%a1
	move.l #0,(12,%a1)
	move.l %d7,%a0
	jsr SnapScr
	lea SnapTmp,%a0
	lea SnapCur,%a1
	move.l #4,%d1
.Lsc_cmp:
	move.l (%a0)+,%d0
	move.l (%a1)+,%d2
	cmp.l %d2,%d0
	bne .Lsc_new
	sub.l #1,%d1
	bne .Lsc_cmp
	jsr TubeCheck                 ; misma pantalla: la paleta si puede cambiar
	bra .Lsc_unlock
.Lsc_new:
	move.l %d7,%a3
	jsr Rebind
.Lsc_unlock:
	move.l IntuitionBase,%a6
	move.l #0,%a0
	move.l %d7,%a1
	LVO -516                      ; UnlockPubScreen
.Lsc_ret:
	RESTALL
	rts

; ForgetPens: las plumas de la pantalla vieja ya no existen (se fueron con
; su ColorMap): no liberarlas nunca.
ForgetPens:
	SAVEALL
	move.l #-1,TitlePen
	move.l #-1,TitlePenW
	move.l #-1,TubePen
	move.l #-1,TubeRGB
	lea BankA,%a2
	jsr ForgetBank
	lea BankB,%a2
	jsr ForgetBank
	RESTALL
	rts
ForgetBank:
	move.l #NUM_SKIN,%d1
.Lfgb_l:
	move.l (BE_DTO,%a2),%d0
	beq .Lfgb_n
	move.l %d0,%a0
	move.l #0,(4,%a0)             ; ninguna pluma que liberar
.Lfgb_n:
	lea (BE_SIZE,%a2),%a2
	sub.l #1,%d1
	bne .Lfgb_l
	rts

; Rebind(a3 = pantalla Workbench nueva, bloqueada)
Rebind:
	SAVEALL
	jsr ForgetPens
	move.l %a3,WBScreen
	move.l %a3,RemapScreen
	move.l IntuitionBase,%a6
	move.l %a3,%a0
	LVO -690                      ; GetScreenDrawInfo
	move.l %d0,WBDri
	move.l GfxBase,%a6
	move.l (48,%a3),%a0
	move.l #0,%d1
	move.l #0,%d2
	move.l #0,%d3
	lea PenTags,%a1
	LVO -840                      ; ObtainBestPenA (negro)
	move.l %d0,TitlePen
	move.l (48,%a3),%a0
	move.l #-1,%d1
	move.l #-1,%d2
	move.l #-1,%d3
	lea PenTags,%a1
	LVO -840                      ; (blanco)
	move.l %d0,TitlePenW
	move.b (36,%a3),OrigBor       ; bordes de la pantalla nueva
	move.b (37,%a3),OrigBor+1
	move.b (38,%a3),OrigBor+2
	lea SnapCur,%a1
	move.l #0,(12,%a1)
	move.l %a3,%a0
	jsr SnapScr
	lea CmdMsg,%a2
	jsr DoReload                  ; skin remapeada a la pantalla nueva
	.short 0x52B9
	.long CntRebind
	RESTALL
	rts

; ExitScreen: al salir, ExitLock = pantalla bloqueada para deshacer lo
; nuestro; si ya no es la misma, olvidar todo lo de la vieja.
ExitScreen:
	SAVEALL
	move.l #0,ExitLock
	move.l InitLock,%d0
	beq .Les_cur
	move.l %d0,ExitLock           ; aun no se habia soltado
	move.l #0,InitLock
	bra .Les_ret
.Les_cur:
	move.l WBScreen,%d0
	beq .Les_ret
	move.l IntuitionBase,%a6
	lea WBName,%a0
	LVO -510                      ; LockPubScreen
	move.l %d0,%d7
	beq .Les_gone
	lea SnapTmp,%a1
	move.l #0,(12,%a1)
	move.l %d7,%a0
	jsr SnapScr
	lea SnapTmp,%a0
	lea SnapCur,%a1
	move.l #4,%d1
.Les_cmp:
	move.l (%a0)+,%d0
	move.l (%a1)+,%d2
	cmp.l %d2,%d0
	bne .Les_other
	sub.l #1,%d1
	bne .Les_cmp
	move.l %d7,ExitLock           ; la misma: se deshace y se suelta al final
	bra .Les_ret
.Les_other:
	move.l IntuitionBase,%a6
	move.l #0,%a0
	move.l %d7,%a1
	LVO -516
.Les_gone:
	jsr ForgetPens
	move.l #0,WBScreen
	move.l #0,WBDri
.Les_ret:
	RESTALL
	rts

; TubeColor: pluma del tubo del indicador de disco = color medio del marco
; vertical de la skin, oscurecido a la mitad.
TubeColor:
	; recalcula siempre: el color del marco y la pluma del tubo
	SAVEALL
	move.l #-1,TubeRGB            ; forzar
	jsr TubeCheck
	RESTALL
	rts

; TubeCheck: color del marco ahora (puede cambiar si cambia la paleta, por
; ejemplo al arrancar); si es distinto del ultimo, pluma nueva para el tubo
TubeCheck:
	SAVEALL
	lea (-160,%sp),%sp
	move.l #0,(116,%sp)           ; rojo
	move.l #0,(120,%sp)           ; verde
	move.l #0,(124,%sp)           ; azul
	move.l WBScreen,%d0
	beq .Ltc2_ret
	move.l CurBank,%a2
	move.l (IDX_FRAMEV*BE_SIZE+BE_BM,%a2),%d0
	beq .Ltc2_none
	move.l %d0,%a4                ; bitmap
	move.l #0,%d6
	move.w (IDX_FRAMEV*BE_SIZE+BE_FW,%a2),%d6   ; ancho
	beq .Ltc2_none
	move.l #0,%d7
	move.w (IDX_FRAMEV*BE_SIZE+BE_FH,%a2),%d7
	lsr.l #1,%d7                  ; fila del medio
	move.l GfxBase,%a6
	lea (0,%sp),%a1
	LVO -198                      ; InitRastPort
	move.l %a4,(4,%sp)            ; rp.BitMap
	move.l %a4,DbgFrBM
	move.l %d6,%d0
	lsl.l #8,%d0
	lsl.l #8,%d0
	or.l %d7,%d0
	move.l %d0,DbgFrWH            ; ancho << 16 | fila
	move.l #-1,%d4                ; brillo del color mas claro visto
	move.l #0,%d5                 ; i = 0..7
.Ltc2_px:
	move.l %d6,%d0                ; x = ancho * i / 8
	.short 0xC0C5                 ; mulu.w d5,d0
	lsr.l #3,%d0
	move.l %d7,%d1
	lea (0,%sp),%a1
	LVO -318                      ; ReadPixel
	lea DbgPix,%a0                ; plumas leidas (un byte cada una)
	move.b %d0,(0,%a0,%d5)
	move.l %d0,%d1
	bmi .Ltc2_next
	move.l WBScreen,%a0
	move.l (48,%a0),%a0
	move.l #1,%d1
	lea (104,%sp),%a1
	LVO -900                      ; GetRGB32
	; quedarse con el color mas claro (la cara del marco, no sus bordes)
	move.l #0,%d0
	move.l #0,%d1
	move.b (104,%sp),%d1
	add.l %d1,%d0
	move.b (108,%sp),%d1
	add.l %d1,%d0
	move.b (112,%sp),%d1
	add.l %d1,%d0
	cmp.l %d4,%d0
	ble .Ltc2_dbg
	move.l %d0,%d4
	move.l #0,%d0
	move.b (104,%sp),%d0
	move.l %d0,(116,%sp)
	move.b (108,%sp),%d0
	move.l %d0,(120,%sp)
	move.b (112,%sp),%d0
	move.l %d0,(124,%sp)
.Ltc2_dbg:
	move.l (104,%sp),%d0          ; rgb de la ultima muestra
	lsr.l #8,%d0
	move.b (108,%sp),%d0
	lsl.l #8,%d0
	move.b (112,%sp),%d0
	and.l #0xFFFFFF,%d0
	move.l %d0,DbgRGB
.Ltc2_next:
	add.l #1,%d5
	cmpi.l #8,%d5
	blt .Ltc2_px
	; marco claro: ese color al 70% (* 179 / 256); marco oscuro (skins
	; negras): mezclado con un 35% de blanco, para que el tubo se vea
	move.l #0,%d3
	cmpi.l #240,%d4               ; r+g+b del color mas claro
	bge .Ltc2_light
	move.l #1,%d3
.Ltc2_light:
	lea (116,%sp),%a0
	move.l #3,%d1
.Ltc2_c:
	move.l (%a0),%d0
	cmpi.l #0,%d3
	bne .Ltc2_dk
	.short 0xC0FC,179             ; mulu.w #179,d0
	lsr.l #8,%d0
	bra .Ltc2_rep
.Ltc2_dk:
	move.l #255,%d2
	sub.l %d0,%d2
	.short 0xC4FC,90              ; mulu.w #90,d2
	lsr.l #8,%d2
	add.l %d2,%d0
.Ltc2_rep:
	move.l %d0,%d2
	lsl.l #8,%d2
	or.l %d2,%d0
	move.l %d0,%d2
	lsl.l #8,%d2
	lsl.l #8,%d2
	or.l %d2,%d0
	move.l %d0,(%a0)+
	sub.l #1,%d1
	bne .Ltc2_c
.Ltc2_none:
	; igual que la ultima vez: nada que hacer
	move.l (116,%sp),%d0
	cmp.l (TubeRGB,%pc),%d0
	bne .Ltc2_new
	move.l (120,%sp),%d0
	cmp.l (TubeRGB+4,%pc),%d0
	bne .Ltc2_new
	move.l (124,%sp),%d0
	cmp.l (TubeRGB+8,%pc),%d0
	beq .Ltc2_ret
.Ltc2_new:
	move.l (116,%sp),TubeRGB
	move.l (120,%sp),TubeRGB+4
	move.l (124,%sp),TubeRGB+8
	move.l GfxBase,%a6
	move.l TubePen,%d0
	bmi .Ltc2_get
	move.l WBScreen,%a0
	move.l (48,%a0),%a0
	LVO -948                      ; ReleasePen
	move.l #-1,TubePen
.Ltc2_get:
	move.l CurBank,%a2
	move.l (IDX_FRAMEV*BE_SIZE+BE_BM,%a2),%d0
	beq .Ltc2_ret                 ; skin sin marco: pluma 1
	move.l WBScreen,%a0
	move.l (48,%a0),%a0
	move.l (116,%sp),%d1
	move.l (120,%sp),%d2
	move.l (124,%sp),%d3
	lea PenTags,%a1
	LVO -840                      ; ObtainBestPenA
	move.l %d0,TubePen
	.short 0x52B9
	.long CntTubeNew
.Ltc2_ret:
	lea (160,%sp),%sp
	RESTALL
	rts

; KnReleaseAll: devuelve todas las barras que tenemos (como al cerrar la
; ventana), las redibuja el sistema y libera nuestras imagenes. Con KnSem
; cogido ninguna ventana puede cerrarse a medias (NewCW lo pide antes).
KnReleaseAll:
	SAVEALL
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -564                      ; ObtainSemaphore
	lea KnTab,%a5
	move.l #KN_MAX,%d5
.Lkra_l:
	move.l (4,%a5),%d0
	beq .Lkra_n
	cmpi.l #-1,%d0
	beq .Lkra_n
	move.l (0,%a5),%a2
	move.l %d0,%a3
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	jsr GInList
	cmpi.l #0,%d0
	beq .Lkra_gone
	move.l (8,%a5),(18,%a3)       ; devolver el gadget como estaba
	move.w (18,%a5),(12,%a3)
	move.w (20,%a5),(4,%a3)
	move.w (22,%a5),(8,%a3)
	move.l (34,%a3),%a0
	move.w (16,%a5),(%a0)
	LVO -138                      ; Permit
	move.l IntuitionBase,%a6
	move.l %a2,%a0
	LVO -456                      ; RefreshWindowFrame
	bra .Lkra_disp
.Lkra_gone:
	LVO -138
.Lkra_disp:
	move.l IntuitionBase,%a6
	move.l (12,%a5),%a0
	LVO -642                      ; DisposeObject
	move.l #0,(0,%a5)
	move.l #0,(4,%a5)
	.short 0x53B9
	.long KnCount
.Lkra_n:
	lea (KN_SIZE,%a5),%a5
	sub.l #1,%d5
	bne .Lkra_l
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -570
	RESTALL
	rts

; ApplyBorder: grosor del marco de las ventanas nuevas en la pantalla
; Workbench: BORDER=n, si no el de las preferencias, si no 8 (2..16).
; Nunca menos que el que tenia la pantalla.
ApplyBorder:
	SAVEALL
	move.l BorSet,%d0
	beq .Lab_ret
	move.l #0,%d2                 ; desactivado: marcos originales
	move.l Disabled,%d0
	bne .Lab_c2
	move.l #8,%d2
	move.l PrefBorder,%d0
	beq .Lab_arg
	move.l %d0,%d2
.Lab_arg:
	move.l ArgArray+20,%d0
	beq .Lab_clamp
	move.l %d0,%a1
	move.l (%a1),%d2
.Lab_clamp:
	cmpi.l #2,%d2
	bge .Lab_c1
	move.l #2,%d2
.Lab_c1:
	cmpi.l #16,%d2
	ble .Lab_c2
	move.l #16,%d2
.Lab_c2:
	move.l WBScreen,%a0
	lea (36,%a0),%a0
	lea OrigBor,%a1
	move.l #3,%d1
.Lab_l:
	move.l #0,%d0
	move.b (%a1)+,%d0
	cmp.l %d2,%d0
	bge .Lab_s
	move.l %d2,%d0
.Lab_s:
	move.b %d0,(%a0)+
	sub.l #1,%d1
	bne .Lab_l
.Lab_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
InstallPatch:
	SAVEALL
	lea TagBuf,%a0
	move.l #SYSIA_Which,(%a0)+
	move.l #3,(%a0)+              ; CLOSEIMAGE
	move.l #SYSIA_DrawInfo,(%a0)+
	move.l WBDri,%d0
	move.l %d0,(%a0)+
	move.l #0,(%a0)+
	move.l #0,(%a0)+
	move.l IntuitionBase,%a6
	move.l #0,%a0
	lea SysIName,%a1
	lea TagBuf,%a2
	LVO -636                      ; NewObjectA
	cmpi.l #0,%d0
	beq .Li_ret
	move.l %d0,%a0
	move.l (-4,%a0),%d1           ; OCLASS(o)
	move.l %d1,SysIClass
	LVO -642                      ; DisposeObject(a0)
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l SysIClass,%a0
	move.l (8,%a0),%d0            ; h_Entry
	move.l %d0,OrigEntry
	move.l #DispEntry,(8,%a0)
	LVO -138                      ; Permit
	; SetWindowTitles: para repintar la barra cuando cambia un titulo
	move.l IntuitionBase,%a1
	move.l #-276,%a0
	move.l #NewSWT,%d0
	LVO -420                      ; SetFunction
	move.l %d0,OldSWT
	; CloseWindow, NewModifyProp y ModifyProp (barras deslizantes)
	move.l IntuitionBase,%a1
	move.l #-72,%a0
	move.l #NewCW,%d0
	LVO -420
	move.l %d0,OldCW
	move.l IntuitionBase,%a1
	move.l #-468,%a0
	move.l #NewNMP,%d0
	LVO -420
	move.l %d0,OldNMP
	move.l IntuitionBase,%a1
	move.l #-156,%a0
	move.l #NewMP,%d0
	LVO -420
	move.l %d0,OldMP
	; propgclass: despachador parcheado (barras BOOPSI de las aplicaciones)
	move.l IntuitionBase,%a6
	move.l #0,%a0
	lea PropGName,%a1
	lea KnTags,%a2
	LVO -636                      ; NewObjectA
	cmpi.l #0,%d0
	beq .Li_nopg
	move.l %d0,%a0
	move.l (-4,%a0),PgClass
	LVO -642                      ; DisposeObject
	move.l SysBase,%a6
	LVO -132
	move.l PgClass,%a0
	move.l (8,%a0),OldPgEntry
	move.l #PgEntry,(8,%a0)
	LVO -138
.Li_nopg:
	; clase propia para el tirador
	move.l IntuitionBase,%a6
	move.l #0,%a0
	lea ImageClassName,%a1
	move.l #0,%a2
	move.l #0,%d0
	move.l #0,%d1
	LVO -678                      ; MakeClass
	move.l %d0,KnClass
	beq .Li_nokc
	move.l %d0,%a0
	move.l #KnobEntry,(8,%a0)
.Li_nokc:
	move.l #1,%d0
.Li_ret:
	RESTALL
	rts

RemovePatch:
	SAVEALL
	move.l SysBase,%a6
	LVO -132
	move.l KnCount,%d0            ; barras convertidas: no se puede salir
	bne .Lr_fail
	move.l IntuitionBase,%a1
	move.l (-70,%a1),%d0          ; CloseWindow
	cmpi.l #NewCW,%d0
	bne .Lr_fail
	move.l (-466,%a1),%d0         ; NewModifyProp
	cmpi.l #NewNMP,%d0
	bne .Lr_fail
	move.l (-154,%a1),%d0         ; ModifyProp
	cmpi.l #NewMP,%d0
	bne .Lr_fail
	move.l PgClass,%d0
	beq .Lr_pgok
	move.l %d0,%a0
	move.l (8,%a0),%d0
	cmpi.l #PgEntry,%d0
	bne .Lr_fail
.Lr_pgok:
	move.l GaugeClass,%d0
	beq .Lr_gcok
	move.l %d0,%a0
	move.l (8,%a0),%d0
	cmpi.l #GaugeEntry,%d0
	bne .Lr_fail
.Lr_gcok:
	move.l SysIClass,%a0
	move.l (8,%a0),%d0
	cmpi.l #DispEntry,%d0
	bne .Lr_fail
	; SetWindowTitles: comprobar que nadie lo ha parcheado despues
	move.l IntuitionBase,%a1
	move.l #-276,%a0
	move.l OldSWT,%d0
	LVO -420                      ; SetFunction (devuelve el actual)
	cmpi.l #NewSWT,%d0
	beq .Lr_swtok
	move.l IntuitionBase,%a1      ; no era el nuestro: dejarlo como estaba
	move.l #-276,%a0
	LVO -420
.Lr_fail:
	LVO -138
	move.l #0,%d0
	bra .Lr_ret
.Lr_swtok:
	move.l PgClass,%d0
	beq .Lr_pgdone
	move.l %d0,%a0
	move.l OldPgEntry,(8,%a0)
.Lr_pgdone:
	move.l GaugeClass,%d0
	beq .Lr_gcdone
	move.l %d0,%a0
	move.l OldGaugeEntry,(8,%a0)
.Lr_gcdone:
	move.l IntuitionBase,%a1
	move.l #-72,%a0
	move.l OldCW,%d0
	LVO -420
	move.l IntuitionBase,%a1
	move.l #-468,%a0
	move.l OldNMP,%d0
	LVO -420
	move.l IntuitionBase,%a1
	move.l #-156,%a0
	move.l OldMP,%d0
	LVO -420
	move.l SysIClass,%a0
.Lr_ok:
	move.l OrigEntry,%d0
	move.l %d0,(8,%a0)
	LVO -138
	move.l DOSBase,%a6
.Lr_wait:
	move.l InUse,%d0
	beq .Lr_done
	move.l #5,%d1
	LVO -198                      ; Delay
	bra .Lr_wait
.Lr_done:
	move.l #25,%d1
	LVO -198
	move.l KnClass,%d0
	beq .Lr_nokc
	move.l IntuitionBase,%a6
	move.l %d0,%a0
	LVO -714                      ; FreeClass
	move.l #0,KnClass
.Lr_nokc:
	move.l #1,%d0
.Lr_ret:
	RESTALL
	rts

; NewText: Text(a1 rastport, a0 texto, d0 longitud)
; Si es el titulo de una ventana con skin y se escribe dentro de su barra,
; no se escribe (ya lo ha escrito SkinBar sobre el degradado).
NewText:
	SAVEALL
	.short 0x52B9
	.long InUse
	move.l CurBank,%a2
	move.l (IDX_BAR*BE_SIZE+BE_BM,%a2),%d1
	beq .Lnt_orig
	move.l %a1,%d1
	beq .Lnt_orig
	move.l (%a1),%d1              ; rp->Layer
	beq .Lnt_orig
	move.l %d1,%a2
	move.l (40,%a2),%d1           ; Layer->Window
	beq .Lnt_orig
	move.l %d1,%a2
	move.l #0,%d6
	move.l LogFlag,%d1
	beq .Lnt_nolog
	jsr LogText                   ; -> d1 = entrada del registro (o 0)
	move.l %d1,%d6
.Lnt_nolog:
	move.l (32,%a2),%d1           ; Window->Title
	beq .Lnt_orig
	move.l %d1,%a3
	move.l #0,%d1
	move.b (55,%a2),%d1           ; BorderTop
	move.w (38,%a1),%d2           ; cp_y
	ext.l %d2
	cmp.l %d1,%d2
	bge .Lnt_orig
	; mismo texto que el titulo (los d0 primeros caracteres)?
	move.l %d0,%d3
	beq .Lnt_orig
	move.l %a0,%a4
.Lnt_cmp:
	move.b (%a4)+,%d1
	move.b (%a3)+,%d2
	cmp.b %d1,%d2
	bne .Lnt_orig
	sub.l #1,%d3
	bne .Lnt_cmp
	.short 0x52B9
	.long CntTextSkip
	cmpi.l #0,%d6
	beq .Lnt_out
	move.l %d6,%a4
	move.b #1,(11,%a4)            ; marcado como saltado
	bra .Lnt_out                  ; saltar: el titulo ya esta escrito
.Lnt_orig:
	move.l OldText,%a3
	jsr (%a3)
.Lnt_out:
	.short 0x53B9
	.long InUse
	RESTALL
	rts

; LogText(a0 texto, d0 longitud, a1 rp, a2 ventana) -> d1 = entrada o 0
; Registro de diagnostico: textos escritos en la zona de la barra de titulo.
	.set LOGMAX, 32
	.set LOGSZ, 48
LogText:
	SAVEALL
	move.l #0,%d7
	move.w (38,%a1),%d2           ; cp_y
	ext.l %d2
	move.l #0,%d1
	move.b (55,%a2),%d1           ; BorderTop
	add.l #4,%d1
	cmp.l %d1,%d2
	bge .Llt_ret                  ; lejos de la barra: no interesa
	move.l %a1,%a5
	move.l %a0,%d6
	move.l SysBase,%a6
	LVO -132                      ; Forbid (puede destruir a0/a1)
	move.l %a5,%a1
	move.l %d6,%a0
	move.l LogN,%d3
	cmpi.l #LOGMAX,%d3
	bge .Llt_full
	move.l %d3,%d4
	add.l #1,%d4
	move.l %d4,LogN
	.short 0xC6FC,LOGSZ           ; mulu.w #LOGSZ,d3
	lea LogBuf,%a3
	adda.l %d3,%a3
	move.l %a3,%d7
	move.l %a2,(%a3)              ; ventana
	move.w (38,%a1),(4,%a3)       ; cp_y
	move.l #0,%d1
	move.b (55,%a2),%d1
	move.w %d1,(6,%a3)            ; BorderTop
	move.w %d0,(8,%a3)            ; longitud
	move.b (28,%a1),(10,%a3)      ; DrawMode
	move.b #0,(11,%a3)
	lea (12,%a3),%a4              ; texto (15 car.)
	move.l %d0,%d5
	cmpi.l #15,%d5
	ble .Llt_n
	move.l #15,%d5
.Llt_n:
	cmpi.l #0,%d5
	beq .Llt_t0
.Llt_tc:
	move.b (%a0)+,(%a4)+
	sub.l #1,%d5
	bne .Llt_tc
.Llt_t0:
	move.b #0,(%a4)
	lea (28,%a3),%a4              ; titulo de la ventana (15 car.)
	move.l (32,%a2),%d1
	beq .Llt_tt0
	move.l %d1,%a0
	move.l #15,%d5
.Llt_ttc:
	move.b (%a0)+,%d1
	beq .Llt_tt0
	move.b %d1,(%a4)+
	sub.l #1,%d5
	bne .Llt_ttc
.Llt_tt0:
	move.b #0,(%a4)
	move.b (26,%a1),(44,%a3)      ; BgPen
	move.b (25,%a1),(45,%a3)      ; FgPen
.Llt_full:
	LVO -138                      ; Permit
	move.l %a5,%a1                ; devolver a0/a1 intactos
	move.l %d6,%a0
.Llt_ret:
	move.l %d7,%d1
	RESTALL
	rts

; WriteStats(a2 = mensaje con PM_PATH = fichero): contadores de diagnostico
WriteStats:
	SAVEALL
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),KnImg

	move.l DOSBase,%a6
	lea (PM_PATH,%a2),%a0
	move.l %a0,%d1
	move.l #1006,%d2
	LVO -30                       ; Open
	move.l %d0,%d7
	beq .Lws_ret
	move.l %d7,%d1
	LVO -300                      ; SelectOutput
	move.l %d0,%d6
	lea Banner,%a0
	jsr Puts
	lea StatTab,%a3
.Lws_loop:
	move.l (%a3)+,%d0             ; texto
	beq .Lws_end
	move.l (%a3)+,%a0             ; variable
	move.l (%a0),%d1
	move.l %d1,PrintArgs
	move.l %d0,%a0
	jsr Printf
	bra .Lws_loop
.Lws_end:
	jsr DumpGadgets
	move.l DOSBase,%a6
	move.l %d6,%d1
	LVO -300                      ; SelectOutput (restaurar)
	move.l %d7,%d1
	LVO -36                       ; Close
.Lws_ret:
	RESTALL
	rts

; DumpGadgets: lista los gadgets de la ventana activa (para el diagnostico)
DumpGadgets:
	SAVEALL
	move.l IntuitionBase,%a6
	move.l #0,%d0
	LVO -414                      ; LockIBase
	move.l %d0,%d7
	move.l WBScreen,%d0
	beq .Ldg_end
	move.l %d0,%a0
	move.l (4,%a0),%a4            ; FirstWindow
	move.l #32,%d5
.Ldg_w:
	move.l %a4,%d0
	beq .Ldg_end
	move.l %d0,%a2
	move.l (32,%a2),%d0
	bne .Ldg_t
	move.l #NoId,%d0
.Ldg_t:
	lea PrintArgs,%a1
	move.l %d0,(0,%a1)
	move.w (8,%a2),%d0
	ext.l %d0
	move.l %d0,(4,%a1)
	move.w (10,%a2),%d0
	ext.l %d0
	move.l %d0,(8,%a1)
	move.l #0,%d0
	move.b (54,%a2),%d0
	move.l %d0,(12,%a1)
	move.b (55,%a2),%d0
	move.l %d0,(16,%a1)
	move.b (56,%a2),%d0
	move.l %d0,(20,%a1)
	move.b (57,%a2),%d0
	move.l %d0,(24,%a1)
	move.l (24,%a2),(28,%a1)
	lea MsgDgWin,%a0
	jsr Printf
	move.l (62,%a2),%a3
	move.l #64,%d6
.Ldg_g:
	move.l %a3,%d0
	beq .Ldg_nw
	jsr GadRect
	lea PrintArgs,%a1
	move.l #0,%d4
	move.w (16,%a3),%d4
	move.l %d4,(0,%a1)            ; tipo
	move.l #0,%d4
	move.w (12,%a3),%d4
	move.l %d4,(4,%a1)            ; flags
	move.l #0,%d4
	move.w (14,%a3),%d4
	move.l %d4,(8,%a1)            ; activation
	move.l %d0,(12,%a1)
	move.l %d1,(16,%a1)
	move.l %d2,(20,%a1)
	move.l %d3,(24,%a1)
	; imagen: es de sysiclass?
	move.l #0,(28,%a1)
	move.l (18,%a3),%d0
	beq .Ldg_noimg
	move.l %d0,%a0
	move.l (-4,%a0),%d0
	cmp.l (SysIClass,%pc),%d0
	bne .Ldg_noimg
	move.l #1,(28,%a1)
.Ldg_noimg:
	; clase del gadget si es BOOPSI (GTYP_CUSTOMGADGET)
	move.l #NoId,(32,%a1)
	move.l #0,(36,%a1)
	move.l #0,%d4
	move.w (16,%a3),%d4
	and.l #0x7,%d4
	cmpi.l #5,%d4
	bne .Ldg_pr
	move.l (-4,%a3),%d0           ; OCLASS
	move.l %d0,(36,%a1)
	beq .Ldg_pr
	move.l %d0,%a0
	move.l (28,%a0),%d0           ; cl_ID
	beq .Ldg_pr
	move.l %d0,(32,%a1)
.Ldg_pr:
	lea MsgDgGad,%a0
	jsr Printf
	move.l (%a3),%a3
	sub.l #1,%d6
	bne .Ldg_g
.Ldg_nw:
	move.l (%a4),%a4              ; NextWindow
	sub.l #1,%d5
	bne .Ldg_w
.Ldg_end:
	move.l IntuitionBase,%a6
	move.l %d7,%a0
	LVO -420                      ; UnlockIBase
	RESTALL
	rts

; ---------------------------------------------------------------------------
; Temporizador: cada segundo se revisan los titulos de las ventanas
TimerOpen:
	SAVEALL
	move.l SysBase,%a6
	LVO -666                      ; CreateMsgPort
	move.l %d0,TimerPort
	beq .Lto_ret
	move.l %d0,%a0
	move.l #40,%d0
	LVO -654                      ; CreateIORequest
	move.l %d0,TimerIO
	beq .Lto_ret
	lea TimerName,%a0
	move.l #1,%d0                 ; UNIT_VBLANK
	move.l TimerIO,%a1
	move.l #0,%d1
	LVO -444                      ; OpenDevice
	cmpi.l #0,%d0
	bne .Lto_ret
	move.l #1,TimerOK
	move.l TimerPort,%a0
	move.l #0,%d1
	move.b (15,%a0),%d1
	move.l #1,%d0
	lsl.l %d1,%d0
	move.l %d0,TimerMask
	jsr TimerSend
.Lto_ret:
	RESTALL
	rts

TimerSend:
	SAVEALL
	move.l TimerIO,%a1
	move.w #9,(28,%a1)            ; TR_ADDREQUEST
	move.l #1,(32,%a1)            ; tv_secs
	move.l #0,(36,%a1)            ; tv_micro
	move.l SysBase,%a6
	LVO -462                      ; SendIO
	move.l #1,TimerBusy
	RESTALL
	rts

TimerTick:
	SAVEALL
	move.l SysBase,%a6
	move.l TimerPort,%a0
	LVO -372                      ; GetMsg
	cmpi.l #0,%d0
	beq .Ltt_ret
	move.l #0,TimerBusy
	jsr ScrCheck
	jsr CheckTitles
	jsr TimerSend
.Ltt_ret:
	RESTALL
	rts

TimerClose:
	SAVEALL
	move.l SysBase,%a6
	move.l TimerOK,%d0
	beq .Ltc_io
	move.l TimerBusy,%d0
	beq .Ltc_closedev
	move.l TimerIO,%a1
	LVO -480                      ; AbortIO
	move.l TimerIO,%a1
	LVO -474                      ; WaitIO
.Ltc_closedev:
	move.l TimerIO,%a1
	LVO -450                      ; CloseDevice
	move.l #0,TimerOK
.Ltc_io:
	move.l TimerIO,%d0
	beq .Ltc_port
	move.l %d0,%a0
	LVO -660                      ; DeleteIORequest
	move.l #0,TimerIO
.Ltc_port:
	move.l TimerPort,%d0
	beq .Ltc_ret
	move.l %d0,%a0
	LVO -672                      ; DeleteMsgPort
	move.l #0,TimerPort
.Ltc_ret:
	RESTALL
	rts

; CheckTitles: apunta para repintar la ventana activa y las ventanas cuyo
; titulo ha cambiado (texto o puntero) desde la ultima revision.
	.set TTMAX, 64
CheckTitles:
	SAVEALL
	move.l CurBank,%a0
	move.l (IDX_BAR*BE_SIZE+BE_BM,%a0),%d0
	beq .Lct_ret                  ; skin sin barra
	lea (-64,%sp),%sp
	move.l %sp,%a5                ; ventanas a repintar (16)
	move.l #0,%d6                 ; cuantas
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l IntuitionBase,%a0
	move.l (52,%a0),%d0           ; ActiveWindow
	beq .Lct_scan
	move.l %d0,(%a5)
	move.l #1,%d6
.Lct_scan:
	move.l IntuitionBase,%a0
	move.l (60,%a0),%a2           ; FirstScreen
.Lct_scr:
	move.l %a2,%d0
	beq .Lct_done
	move.l AllScreens,%d0
	bne .Lct_scrok
	move.l %a2,%d0
	cmp.l (WBScreen,%pc),%d0
	bne .Lct_nextscr
.Lct_scrok:
	move.l (4,%a2),%a3            ; FirstWindow
.Lct_win:
	move.l %a3,%d0
	beq .Lct_nextscr
	move.l #0,%d0
	move.b (55,%a3),%d0           ; BorderTop
	cmpi.l #4,%d0
	blt .Lct_nextwin
	; firma del titulo: puntero + suma de los caracteres
	move.l (32,%a3),%d2
	move.l %d2,%d3
	beq .Lct_sig
	move.l %d2,%a0
	move.l #64,%d1
.Lct_sum:
	move.l #0,%d0
	move.b (%a0)+,%d0
	beq .Lct_sig
	lsl.l #1,%d3
	add.l %d0,%d3
	sub.l #1,%d1
	bne .Lct_sum
.Lct_sig:
	; buscar la ventana en la tabla
	lea TitleTab,%a0
	move.l #TTMAX,%d1
	move.l #0,%a1                 ; hueco libre
.Lct_find:
	move.l (%a0),%d0
	cmp.l %a3,%d0
	beq .Lct_found
	cmpi.l #0,%d0
	bne .Lct_fnext
	move.l %a1,%d0
	bne .Lct_fnext
	move.l %a0,%a1
.Lct_fnext:
	lea (8,%a0),%a0
	sub.l #1,%d1
	bne .Lct_find
	; no estaba: guardarla (en un hueco o pisando una al azar)
	move.l %a1,%d0
	bne .Lct_put
	move.l TTNext,%d0
	add.l #1,%d0
	and.l #TTMAX-1,%d0
	move.l %d0,TTNext
	lsl.l #3,%d0
	lea TitleTab,%a1
	adda.l %d0,%a1
.Lct_put:
	move.l %a3,(%a1)
	move.l %d3,(4,%a1)
	bra .Lct_add                  ; nueva: repintar
.Lct_found:
	cmp.l (4,%a0),%d3
	beq .Lct_nextwin
	move.l %d3,(4,%a0)
.Lct_add:
	cmpi.l #16,%d6
	bge .Lct_nextwin
	move.l %d6,%d0
	lsl.l #2,%d0
	move.l %a3,(0,%a5,%d0)
	add.l #1,%d6
.Lct_nextwin:
	move.l (%a3),%a3
	bra .Lct_win
.Lct_nextscr:
	move.l (%a2),%a2
	bra .Lct_scr
.Lct_done:
	LVO -138                      ; Permit
	move.l #0,%d5
.Lct_rp:
	cmp.l %d6,%d5
	bge .Lct_out
	move.l %d5,%d0
	lsl.l #2,%d0
	move.l (0,%a5,%d0),%d0
	jsr RepaintWindow
	.short 0x52B9
	.long CntTick
	add.l #1,%d5
	bra .Lct_rp
.Lct_out:
	lea (64,%sp),%sp
.Lct_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; MarkDirty(d0 = ventana): apuntarla para repintar su barra desde el proceso
; principal, cuando el sistema (y sus parches) hayan terminado de dibujar.
	.set DIRTYMAX, 16
MarkDirty:
	SAVEALL
	move.l %d0,%d7
	beq .Lmd_ret
	.short 0x52B9
	.long CntMarked
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	lea DirtyList,%a0
	move.l DirtyN,%d1
	move.l %d1,%d2
.Lmd_find:
	cmpi.l #0,%d2
	beq .Lmd_add
	move.l (%a0)+,%a1
	cmp.l %a1,%d7
	beq .Lmd_unf
	sub.l #1,%d2
	bra .Lmd_find
.Lmd_add:
	cmpi.l #DIRTYMAX,%d1
	bge .Lmd_unf
	lea DirtyList,%a0
	lsl.l #2,%d1
	move.l %d7,(0,%a0,%d1)
	move.l DirtyN,%d1
	add.l #1,%d1
	move.l %d1,DirtyN
.Lmd_unf:
	LVO -138                      ; Permit
	move.l MainTask,%a1
	move.l DirtyMask,%d0
	LVO -324                      ; Signal
.Lmd_ret:
	RESTALL
	rts

; FramesNow(d0 = ventana, a0 = rp): pinta los marcos en el momento, con una
; pila propia (puede llamarse desde input.device, que tiene poca pila)
FramesNow:
	SAVEALL
	move.l %d0,%d7
	move.l %a0,%d6
	move.l %d7,%a1
	move.l (46,%a1),%d0           ; WScreen
	move.l AllScreens,%d1
	bne .Lfn_scr
	cmp.l (WBScreen,%pc),%d0
	bne .Lfn_ret
.Lfn_scr:
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l (FrBusy,%pc),%d0
	cmpi.l #0,%d0
	bne .Lfn_busy
	move.l #1,FrBusy
	LVO -138                      ; Permit
	lea FrSwap,%a0
	move.l #FrStack,(%a0)
	move.l #FrStack+4096,(4,%a0)
	move.l #FrStack+4096,(8,%a0)
	LVO -732                      ; StackSwap
	move.l %d6,%a0
	move.l %d7,%a1
	jsr SkinFrames
	move.l SysBase,%a6
	lea FrSwap,%a0
	LVO -732                      ; StackSwap (volver)
	.short 0x52B9
	.long CntFrNow
	move.l #0,FrBusy
	bra .Lfn_ret
.Lfn_busy:
	LVO -138
.Lfn_ret:
	RESTALL
	rts

; ProcessDirty: repinta las barras apuntadas (proceso principal) en dos
; pasadas, para llegar despues de cualquier redibujo tardio del sistema.
ProcessDirty:
	SAVEALL
	.short 0x52B9
	.long CntProcess
	lea (-64,%sp),%sp
	move.l %sp,%a5
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l DirtyN,%d6             ; copiar la lista y vaciarla
	move.l #0,DirtyN
	lea DirtyList,%a0
	move.l %a5,%a1
	move.l %d6,%d0
.Lpd_cp:
	cmpi.l #0,%d0
	beq .Lpd_cpd
	move.l (%a0)+,(%a1)+
	sub.l #1,%d0
	bra .Lpd_cp
.Lpd_cpd:
	LVO -138                      ; Permit
	move.l #1,%d5                 ; primera pasada al tick siguiente (20 ms)
	move.l #2,%d4                 ; dos pasadas
.Lpd_pass:
	; esperar d5 ticks de uno en uno; si mientras tanto el sistema vuelve a
	; dibujar (ventana arrastrandose), dejar esta pasada: el bucle principal
	; repintara enseguida con la lista nueva
.Lpd_dl:
	move.l DOSBase,%a6
	move.l #1,%d1
	LVO -198                      ; Delay
	cmpi.l #2,%d4
	beq .Lpd_dn                   ; la primera pasada se hace siempre
	move.l SysBase,%a6
	move.l #0,%d0
	move.l #0,%d1
	LVO -306                      ; SetSignal(0,0)
	and.l (DirtyMask,%pc),%d0
	bne .Lpd_end
.Lpd_dn:
	sub.l #1,%d5
	bne .Lpd_dl
	move.l #0,%d3
.Lpd_win:
	cmp.l %d6,%d3
	bge .Lpd_passdone
	move.l %d3,%d0
	lsl.l #2,%d0
	move.l (0,%a5,%d0),%d0
	jsr RepaintWindow
	cmpi.l #2,%d4
	bne .Lpd_notk
	move.l %d3,%d0
	lsl.l #2,%d0
	move.l (0,%a5,%d0),%d0        ; la ventana otra vez (RepaintWindow cambia d0)
	jsr Takeover
.Lpd_notk:
	add.l #1,%d3
	bra .Lpd_win
.Lpd_passdone:
	move.l #8,%d5                 ; segunda pasada 160 ms despues
	sub.l #1,%d4
	bne .Lpd_pass
.Lpd_end:
	lea (64,%sp),%sp
	RESTALL
	rts

; FindWinScreen(d7 = ventana) -> d0 = su pantalla o 0 (llamar bajo Forbid)  LEAF
FindWinScreen:
	move.l IntuitionBase,%a0
	move.l (60,%a0),%a0           ; FirstScreen
.Lfw_scr:
	move.l %a0,%d0
	beq .Lfw_ret
	move.l (4,%a0),%a1            ; FirstWindow
.Lfw_win:
	move.l %a1,%d1
	beq .Lfw_next
	cmp.l %a1,%d7
	beq .Lfw_ret                  ; d0 = pantalla
	move.l (%a1),%a1
	bra .Lfw_win
.Lfw_next:
	move.l (%a0),%a0
	bra .Lfw_scr
.Lfw_ret:
	rts

; RepaintWindow(d0 = ventana): repinta su barra con la ventana bloqueada
RepaintWindow:
	SAVEALL
	move.l %d0,%d7
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	jsr FindWinScreen
	move.l %d0,%d6
	bne .Lrw_exists
	.short 0x52B9
	.long CntRpGone
	bra .Lrw_permit               ; ya no existe
.Lrw_exists:
	move.l %d6,LastWinScr
	move.l AllScreens,%d0
	bne .Lrw_scrok
	cmp.l (WBScreen,%pc),%d6
	beq .Lrw_scrok
	.short 0x52B9
	.long CntRpScreen
	bra .Lrw_permit
.Lrw_scrok:
	move.l LayersBase,%a6
	move.l %d6,%a0
	lea (224,%a0),%a0             ; Screen->LayerInfo
	LVO -120                      ; LockLayerInfo (puede esperar)
	move.l SysBase,%a6
	LVO -138                      ; Permit
	; con LayerInfo bloqueado la ventana no puede cerrarse: comprobar que sigue
	LVO -132
	jsr FindWinScreen
	LVO -138
	cmp.l %d6,%d0
	bne .Lrw_unlockinfo
	move.l %d7,%a3
	move.l (58,%a3),%d0           ; BorderRPort (ventanas GZZ)
	bne .Lrw_rp
	move.l (50,%a3),%d0           ; RPort
.Lrw_rp:
	cmpi.l #0,%d0
	beq .Lrw_unlockinfo
	move.l %d0,%a4
	move.l (%a4),%d0              ; rp->Layer
	beq .Lrw_unlockinfo
	move.l %d0,%a2
	move.l LayersBase,%a6
	move.l #0,%a0
	move.l %a2,%a1
	LVO -96                       ; LockLayer
	move.l #0,%d0
	cmp.l (WBScreen,%pc),%d6
	bne .Lrw_dri
	move.l WBDri,%d0
.Lrw_dri:
	move.l %a4,%a0
	move.l %d7,%a1
	.short 0x52B9
	.long CntRpOK
	jsr SkinBar
	move.l %a4,%a0
	move.l %d7,%a1
	jsr SkinExtra
	move.l %a4,%a0
	move.l %d7,%a1
	jsr SkinFrames
	move.l %a4,%a0
	move.l %d7,%a1
	jsr KnPaintWin
	move.l %a4,%a0
	move.l %d7,%a1
	jsr PgPaintWin
	move.l %a4,%a0
	move.l %d7,%a1
	jsr GaugePaintWin
	move.l LayersBase,%a6
	move.l %a2,%a0
	LVO -102                      ; UnlockLayer
.Lrw_unlockinfo:
	move.l LayersBase,%a6
	move.l %d6,%a0
	lea (224,%a0),%a0
	LVO -138                      ; UnlockLayerInfo
	bra .Lrw_ret
.Lrw_permit:
	LVO -138                      ; Permit
.Lrw_ret:
	RESTALL
	rts

; NewSWT: SetWindowTitles(a0 ventana, a1 titulo, a2 titulo de pantalla)
NewSWT:
	SAVEALL
	.short 0x52B9                 ; addq.l #1,InUse
	.long InUse
	move.l %a0,%d7
	move.l %a1,%d6
	move.l OldSWT,%a3
	jsr (%a3)
	cmpi.l #-1,%d6                ; el titulo de la ventana no cambia
	beq .Lsw_out
	move.l CurBank,%a0
	move.l (IDX_BAR*BE_SIZE+BE_BM,%a0),%d0
	beq .Lsw_out
	move.l %d7,%d0
	jsr MarkDirty
.Lsw_out:
	.short 0x53B9                 ; subq.l #1,InUse
	.long InUse
	RESTALL
	rts

; ---------------------------------------------------------------------------
; Dispatcher: a0 = clase, a2 = objeto, a1 = mensaje
; d5 = clase, d7 = a6 de entrada, a4 = objeto, a5 = mensaje, d6 = retorno
	.globl DispEntry
DispEntry:
	SAVEALL
	.short 0x52B9                 ; addq.l #1,InUse
	.long InUse
	.short 0x52B9                 ; addq.l #1,CntAll
	.long CntAll
	move.l %a0,%d5
	move.l %a6,%d7
	move.l %a2,%a4
	move.l %a1,%a5
	move.l (%a5),%d0
	cmpi.l #0x101,%d0             ; OM_NEW
	beq .Ld_new
	cmpi.l #0x102,%d0             ; OM_DISPOSE
	beq .Ld_dispose
	cmpi.l #0x202,%d0             ; IM_DRAW
	beq .Ld_draw
	cmpi.l #0x206,%d0             ; IM_DRAWFRAME
	beq .Ld_draw
	jsr CallOrig
	bra .Ld_out
.Ld_new:
	.short 0x52B9
	.long CntNew
	jsr CallOrig
	move.l %d0,%d6
	beq .Ld_ret6
	move.l (4,%a5),%a0            ; ops_AttrList
	jsr GetWhich
	cmpi.l #32,%d0
	bcc .Ld_nowhich
	lea WhichCnt,%a0
	lsl.l #2,%d0
	add.l #1,(0,%a0,%d0)
	lsr.l #2,%d0
.Ld_nowhich:
	jsr FindIdx                   ; -> d0 indice o -1
	cmpi.l #0,%d0
	blt .Ld_ret6
	.short 0x52B9
	.long CntTracked
	jsr AddObj                    ; d6 = objeto, d0 = indice
.Ld_ret6:
	move.l %d6,%d0
	bra .Ld_out
.Ld_dispose:
	jsr RemObj                    ; a4 = objeto
	jsr CallOrig
	bra .Ld_out
.Ld_draw:
	.short 0x52B9
	.long CntDraw
	jsr CallOrig
	move.l %d0,%d6
	jsr DrawIfSkinned
	bra .Ld_ret6
.Ld_out:
	.short 0x53B9                 ; subq.l #1,InUse
	.long InUse
	RESTALL
	rts

CallOrig:
	move.l OrigEntry,%a3
	move.l %d5,%a0
	move.l %a5,%a1
	move.l %a4,%a2
	move.l %d7,%a6
	jsr (%a3)
	rts

; GetWhich(a0 = tags) -> d0 = SYSIA_Which o -1   LEAF
GetWhich:
	move.l #-1,%d0
.Lg_loop:
	move.l %a0,%d1
	beq .Lg_done
	move.l (%a0),%d1
	beq .Lg_done
	cmpi.l #1,%d1
	beq .Lg_next
	cmpi.l #2,%d1
	beq .Lg_more
	cmpi.l #3,%d1
	beq .Lg_skip
	cmpi.l #SYSIA_Which,%d1
	bne .Lg_next
	move.l (4,%a0),%d0
	rts
.Lg_next:
	lea (8,%a0),%a0
	bra .Lg_loop
.Lg_more:
	move.l (4,%a0),%a0
	bra .Lg_loop
.Lg_skip:
	move.l (4,%a0),%d1
	add.l #1,%d1
	lsl.l #3,%d1
	adda.l %d1,%a0
	bra .Lg_loop
.Lg_done:
	rts

; FindIdx(d0 = which) -> d0 = indice 0..10 o -1   LEAF
FindIdx:
	lea WhichTab,%a0
	move.l #0,%d1
.Lfi_loop:
	move.l (%a0)+,%a1
	cmp.l %a1,%d0
	beq .Lfi_found
	add.l #1,%d1
	cmpi.l #NUM_SKIN,%d1
	bne .Lfi_loop
	move.l #-1,%d0
	rts
.Lfi_found:
	move.l %d1,%d0
	rts

; AddObj(d6 = objeto, d0 = indice)
AddObj:
	SAVEALL
	move.l %d0,%d5
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -564                      ; ObtainSemaphore
	lea ObjTab,%a0
	move.l #0,%d0
.La_loop:
	move.l (%a0),%d1
	beq .La_free
	lea (8,%a0),%a0
	add.l #1,%d0
	cmpi.l #MAX_OBJ,%d0
	bne .La_loop
	bra .La_rel
.La_free:
	move.l %d6,(%a0)
	move.l %d5,(4,%a0)
	add.l #1,%d0
	move.l ObjTop,%d1
	cmp.l %d0,%d1
	bge .La_rel
	move.l %d0,ObjTop
.La_rel:
	lea ObjSem,%a0
	LVO -570
	RESTALL
	rts

; RemObj(a4 = objeto)
RemObj:
	SAVEALL
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -564
	lea ObjTab,%a0
	move.l ObjTop,%d0
	beq .Lrm_rel
	move.l %a4,%d2
.Lrm_loop:
	move.l (%a0),%d1
	cmp.l %d2,%d1
	bne .Lrm_next
	move.l #0,(%a0)
	move.l #0,(4,%a0)
	bra .Lrm_rel
.Lrm_next:
	lea (8,%a0),%a0
	sub.l #1,%d0
	bne .Lrm_loop
.Lrm_rel:
	lea ObjSem,%a0
	LVO -570
	RESTALL
	rts

; DrawIfSkinned(a4 = objeto, a5 = impDraw)
; Todo bajo el semaforo compartido: el banco no puede cambiar mientras se dibuja.
DrawIfSkinned:
	SAVEALL
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -678                      ; ObtainSemaphoreShared
	lea ObjTab,%a0
	move.l ObjTop,%d0
	beq .Ldi_scan
	move.l %a4,%d2
.Ldi_loop:
	move.l (%a0),%d1
	cmp.l %d2,%d1
	beq .Ldi_found
	lea (8,%a0),%a0
	sub.l #1,%d0
	bne .Ldi_loop
.Ldi_scan:
	; no se vio su creacion: buscar el boton de ventana que usa esta imagen
	jsr ScanGadgets               ; a4 = objeto -> d0 = indice o -1, d1 = ventana
	cmpi.l #0,%d0
	blt .Ldi_rel
	.short 0x52B9
	.long CntMatched
	move.l %d0,%d3
	move.l %d1,%d4
	bra .Ldi_have
.Ldi_found:
	move.l (4,%a0),%d3            ; indice
	move.l #-1,%d4                ; ventana aun desconocida
.Ldi_have:
	move.l AllScreens,%d0
	bne .Ldi_scrok
	move.l (16,%a5),%d0           ; imp_DrInfo
	move.l WBDri,%d1
	cmp.l %d1,%d0
	bne .Ldi_rel
.Ldi_scrok:
	; barra de titulo: al dibujar cerrar/profundidad/zoom, repintar la barra
	cmpi.l #2,%d3
	bls .Ldi_isbar
	; botones del borde (tamano y flechas): repintar los marcos despues
	cmpi.l #4,%d3
	blt .Ldi_nobar
	cmpi.l #8,%d3
	bhi .Ldi_nobar
	move.l CurBank,%a0
	move.l (IDX_FRAMEH*BE_SIZE+BE_BM,%a0),%d0
	beq .Ldi_nobar
	move.l (4,%a5),%d0            ; imp_RPort
	beq .Ldi_nobar
	move.l %d0,%a0
	move.l (%a0),%d0              ; Layer
	beq .Ldi_nobar
	move.l %d0,%a0
	move.l (40,%a0),%d0           ; Layer->Window
	beq .Ldi_nobar
	; al dibujar el boton de tamano se pintan ya los marcos: mientras se
	; redimensiona, el sistema tiene la pantalla bloqueada y el repintado
	; diferido no llega hasta soltar el raton
	cmpi.l #4,%d3
	bne .Ldi_fm
	move.l (4,%a5),%a0            ; imp_RPort
	jsr FramesNow
.Ldi_fm:
	jsr MarkDirty
	bra .Ldi_nobar
.Ldi_isbar:
	move.l CurBank,%a0
	move.l (IDX_BAR*BE_SIZE+BE_BM,%a0),%d0
	beq .Ldi_nobar
	; la ventana es la duena de la capa donde se dibuja (las imagenes pueden
	; estar compartidas entre ventanas: no fiarse del gadget)
	move.l (4,%a5),%d0            ; imp_RPort
	beq .Ldi_nolayer
	move.l %d0,%a0
	move.l (%a0),%d0              ; rp->Layer
	beq .Ldi_nolayer
	move.l %d0,%a0
	move.l (40,%a0),%d0           ; Layer->Window
	beq .Ldi_nolayer
	move.l %d0,%d4
	bra .Ldi_winok
.Ldi_nolayer:
	cmpi.l #-1,%d4
	bne .Ldi_winok
	jsr ScanGadgets
	move.l %d1,%d4
.Ldi_winok:
	cmpi.l #0,%d4
	beq .Ldi_nobar
	move.l (4,%a5),%d0            ; imp_RPort
	beq .Ldi_nobar
	move.l %d0,%a0
	move.l %d4,%a1
	move.l (16,%a5),%d0           ; imp_DrInfo
	.short 0x52B9
	.long CntBars
	jsr SkinBar
	move.l %d4,%d0
	jsr MarkDirty                 ; y repintarla otra vez cuando acabe el sistema
.Ldi_nobar:
	move.l %d3,%d0
	lsl.l #2,%d0
	move.l %d0,%d1
	add.l %d0,%d0
	add.l %d1,%d0                 ; indice*12
	move.l CurBank,%a2
	lea (0,%a2,%d0),%a2
	move.l (BE_BM,%a2),%d0
	beq .Ldi_rel
	move.l %d3,%d0
	.short 0x52B9
	.long CntSkinned
	jsr DrawSkin
.Ldi_rel:
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -570                      ; ReleaseSemaphore
	RESTALL
	rts

;
; ScanGadgets(a4 = objeto imagen) -> d0 = indice de la skin o -1
; Recorre pantallas -> ventanas -> gadgets del sistema buscando el que
; tiene esta imagen (GadgetRender o SelectRender). Bajo Forbid, sin LockIBase.
ScanGadgets:
	SAVEALL
	move.l #-1,%d7
	move.l #0,%d6                 ; ventana encontrada
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l IntuitionBase,%a0
	move.l (60,%a0),%a1           ; FirstScreen
	move.l #64,%d5                ; limite de pantallas
.Lsg_scr:
	move.l %a1,%d0
	beq .Lsg_done
	move.l (4,%a1),%a2            ; FirstWindow
	move.l #256,%d4               ; limite de ventanas
.Lsg_win:
	move.l %a2,%d0
	beq .Lsg_nextscr
	move.l (62,%a2),%a3           ; FirstGadget
	move.l #256,%d3               ; limite de gadgets
.Lsg_gad:
	move.l %a3,%d0
	beq .Lsg_nextwin
	move.l #0,%d1
	move.w (16,%a3),%d1           ; GadgetType
	move.l %d1,%d0
	and.l #0x8000,%d0             ; GTYP_SYSGADGET
	bne .Lsg_sys
	; gadget de la aplicacion con esta imagen: puede ser una flecha del borde
	move.l %a4,%d0
	cmp.l (18,%a3),%d0
	beq .Lsg_arrow
	cmp.l (22,%a3),%d0
	bne .Lsg_nextgad
.Lsg_arrow:
	jsr ArrowKind                 ; a2 ventana, a3 gadget -> d0
	cmpi.l #0,%d0
	blt .Lsg_nextgad
	move.l %d0,%d7
	move.l %a2,%d6
	bra .Lsg_done
.Lsg_sys:
	move.l %a4,%d0
	cmp.l (18,%a3),%d0            ; GadgetRender
	beq .Lsg_match
	cmp.l (22,%a3),%d0            ; SelectRender
	bne .Lsg_nextgad
.Lsg_match:
	move.l %a2,%d6
	and.l #0xF0,%d1
	cmpi.l #0x80,%d1              ; GTYP_CLOSE
	bne .Lsg_t1
	move.l #0,%d7
	bra .Lsg_done
.Lsg_t1:
	cmpi.l #0x40,%d1              ; GTYP_WDEPTH
	bne .Lsg_t2
	move.l #1,%d7
	bra .Lsg_done
.Lsg_t2:
	cmpi.l #0x60,%d1              ; GTYP_WZOOM
	bne .Lsg_t3
	move.l #2,%d7
	bra .Lsg_done
.Lsg_t3:
	cmpi.l #0x50,%d1              ; GTYP_SDEPTH
	bne .Lsg_t4
	move.l #3,%d7
	bra .Lsg_done
.Lsg_t4:
	cmpi.l #0x10,%d1              ; GTYP_SIZING
	bne .Lsg_t5
	move.l #4,%d7
	bra .Lsg_done
.Lsg_t5:
	cmpi.l #0x90,%d1              ; iconificar (gadget de sistema de OS 3.2.3)
	bne .Lsg_nextgad
	move.l #IDX_ICONIFY,%d7
	bra .Lsg_done
.Lsg_nextgad:
	move.l (%a3),%a3
	sub.l #1,%d3
	bne .Lsg_gad
.Lsg_nextwin:
	move.l (%a2),%a2              ; NextWindow
	sub.l #1,%d4
	bne .Lsg_win
.Lsg_nextscr:
	move.l (%a1),%a1              ; NextScreen
	sub.l #1,%d5
	bne .Lsg_scr
.Lsg_done:
	LVO -138                      ; Permit
	move.l %d7,%d0
	move.l %d6,%d1                ; d1 = ventana (o 0)
	RESTALL
	rts


; GadRect(a3 = gadget, a2 = ventana) -> d0 x0, d1 y0, d2 ancho, d3 alto
GadRect:
	move.l %d4,-(%sp)
	move.l #0,%d4
	move.w (12,%a3),%d4
	move.w (4,%a3),%d0
	ext.l %d0
	move.w (6,%a3),%d1
	ext.l %d1
	move.w (8,%a3),%d2
	ext.l %d2
	move.w (10,%a3),%d3
	ext.l %d3
	move.l %d4,-(%sp)
	and.l #0x10,%d4               ; RELRIGHT
	beq .Lgr_1
	move.w (8,%a2),%d4
	ext.l %d4
	add.l %d4,%d0
	sub.l #1,%d0
.Lgr_1:
	move.l (%sp),%d4
	and.l #0x08,%d4               ; RELBOTTOM
	beq .Lgr_2
	move.w (10,%a2),%d4
	ext.l %d4
	add.l %d4,%d1
	sub.l #1,%d1
.Lgr_2:
	move.l (%sp),%d4
	and.l #0x20,%d4               ; RELWIDTH
	beq .Lgr_3
	move.w (8,%a2),%d4
	ext.l %d4
	add.l %d4,%d2
.Lgr_3:
	move.l (%sp)+,%d4
	and.l #0x40,%d4               ; RELHEIGHT
	beq .Lgr_4
	move.w (10,%a2),%d4
	ext.l %d4
	add.l %d4,%d3
.Lgr_4:
	move.l (%sp)+,%d4
	rts

; ArrowKind(a2 = ventana, a3 = gadget) -> d0 = 5 izq, 6 der, 7 arriba,
; 8 abajo, o -1. Una flecha es un gadget pequeno en el borde derecho o
; inferior; se distingue la pareja mirando si hay otro igual antes.
ArrowKind:
	SAVEALL
	move.l #-1,%d7
	jsr GadRect
	; boton extra en la barra de titulo (iconificar en 3.2 y similares)
	cmpi.l #0,%d1
	bne .Lak_notitle
	move.l #0,%d4
	move.b (55,%a2),%d4           ; BorderTop
	cmpi.l #4,%d4
	blt .Lak_notitle
	add.l #1,%d4
	cmp.l %d4,%d3
	bgt .Lak_notitle
	cmpi.l #2,%d2
	blt .Lak_notitle
	move.l #IDX_ICONIFY,%d7
	bra .Lak_ret
.Lak_notitle:
	cmpi.l #2,%d2
	blt .Lak_ret
	cmpi.l #2,%d3
	blt .Lak_ret
	cmpi.l #40,%d2
	bgt .Lak_ret
	cmpi.l #40,%d3
	bgt .Lak_ret
	move.l %d0,%d4                ; x0
	move.l %d1,%d5                ; y0
	move.l %d2,%a5                ; ancho
	move.l %d3,%d6                ; alto
	; borde derecho?
	move.w (8,%a2),%d0
	ext.l %d0
	move.l #0,%d1
	move.b (56,%a2),%d1           ; BorderRight
	cmpi.l #0,%d1
	beq .Lak_bot
	sub.l %d1,%d0
	cmp.l %d0,%d4
	blt .Lak_bot
	move.l #7,%d7                 ; arriba, salvo que haya otra encima
	move.l #1,%a0                 ; vertical
	bra .Lak_pair
.Lak_bot:
	move.w (10,%a2),%d0
	ext.l %d0
	move.l #0,%d1
	move.b (57,%a2),%d1           ; BorderBottom
	cmpi.l #0,%d1
	beq .Lak_ret
	sub.l %d1,%d0
	cmp.l %d0,%d5
	blt .Lak_ret
	move.l #5,%d7                 ; izquierda, salvo que haya otra antes
	move.l #0,%a0
.Lak_pair:
	move.l %a3,%a4                ; el nuestro
	move.l (62,%a2),%a3
	move.l #256,%d3
.Lak_g:
	move.l %a3,%d0
	beq .Lak_restore
	move.l %a3,%d0
	cmp.l %a4,%d0
	beq .Lak_n
	move.l (18,%a3),%d0           ; con imagen
	beq .Lak_n
	move.l %d3,-(%sp)
	jsr GadRect
	cmp.l %a5,%d2
	bne .Lak_pop
	cmp.l %d6,%d3
	bne .Lak_pop
	move.l %a0,%d2
	cmpi.l #0,%d2
	beq .Lak_h
	cmp.l %d4,%d0                 ; misma x, y anterior y cercana
	bne .Lak_pop
	cmp.l %d5,%d1
	bge .Lak_pop
	move.l %d5,%d2
	sub.l %d6,%d2
	sub.l %d6,%d2
	cmp.l %d2,%d1
	blt .Lak_pop
	move.l #8,%d7
	bra .Lak_pop
.Lak_h:
	cmp.l %d5,%d1                 ; misma y, x anterior y cercana
	bne .Lak_pop
	cmp.l %d4,%d0
	bge .Lak_pop
	move.l %d4,%d2
	sub.l %a5,%d2
	sub.l %a5,%d2
	cmp.l %d2,%d0
	blt .Lak_pop
	move.l #6,%d7
.Lak_pop:
	move.l (%sp)+,%d3
.Lak_n:
	move.l (%a3),%a3
	sub.l #1,%d3
	bne .Lak_g
.Lak_restore:
	move.l %a4,%a3
.Lak_ret:
	move.l %d7,%d0
	RESTALL
	rts

; ---------------------------------------------------------------------------
; SkinBar(a0 = rastport, a1 = ventana, d0 = DrawInfo)
; Pinta la barra de titulo con bar.iff dejando libres los gadgets que hay en
; ella (salvo el de arrastre) y vuelve a escribir el titulo centrado.
; Locales en a5: 0 rp, 4 ventana, 8 fotograma, 12 dri, 16 alto barra (BT),
; 20 ancho ventana, 24 n intervalos, 28 fw, 32 fh, 36 bitmap, 40 mejor inicio,
; 44 mejor fin, 48 pluma, 49 modo, 50 cpx, 52 cpy, 56.. intervalos (16 x 8)
	.set SB_LOCALS, 184
SkinBar:
	SAVEALL
	lea (-296,%sp),%sp
	move.l %sp,%a5
	move.l %a0,(0,%a5)
	move.l %a1,(4,%a5)
	move.l %d0,(12,%a5)
	move.l CurBank,%a2
	lea (IDX_BAR*BE_SIZE,%a2),%a2
	move.l (BE_BM,%a2),%d0
	beq .Lsb_out
	move.l %d0,(36,%a5)
	move.l #0,%d0
	move.w (BE_FW,%a2),%d0
	move.l %d0,(28,%a5)
	move.w (BE_FH,%a2),%d0
	move.l %d0,(32,%a5)
	move.l (4,%a5),%a3            ; ventana
	move.l #0,%d0
	move.b (55,%a3),%d0           ; BorderTop
	cmpi.l #4,%d0
	blt .Lsb_out
	move.l %d0,(16,%a5)
	move.w (8,%a3),%d0            ; Width
	ext.l %d0
	cmpi.l #8,%d0
	blt .Lsb_out
	move.l %d0,(20,%a5)
	move.l #2,(8,%a5)             ; fotograma inactivo
	move.l (24,%a3),%d0           ; Flags
	and.l #0x2000,%d0             ; WFLG_WINDOWACTIVE
	beq .Lsb_inact
	move.l #0,(8,%a5)
.Lsb_inact:
	; --- huecos ocupados por gadgets en la barra
	move.l #0,(24,%a5)
	move.l (62,%a3),%a4           ; FirstGadget
	move.l #256,%d7
.Lsb_g:
	move.l %a4,%d0
	beq .Lsb_gdone
	move.l #0,%d1
	move.w (16,%a4),%d1           ; GadgetType
	move.l %d1,%d0
	and.l #0x8000,%d0
	beq .Lsb_ns
	move.l %d1,%d0
	and.l #0xF0,%d0
	cmpi.l #0x20,%d0              ; GTYP_WDRAGGING: no cuenta
	beq .Lsb_gnext
.Lsb_ns:
	move.l #0,%d5
	move.w (12,%a4),%d5           ; Flags del gadget
	move.w (6,%a4),%d2            ; TopEdge
	ext.l %d2
	move.l %d5,%d0
	and.l #0x0008,%d0             ; GFLG_RELBOTTOM
	beq .Lsb_y
	move.w (10,%a3),%d1
	ext.l %d1
	add.l %d1,%d2
	sub.l #1,%d2
.Lsb_y:
	cmp.l (16,%a5),%d2
	bge .Lsb_gnext                ; empieza por debajo de la barra
	move.w (4,%a4),%d2            ; LeftEdge
	ext.l %d2
	move.l %d5,%d0
	and.l #0x0010,%d0             ; GFLG_RELRIGHT
	beq .Lsb_x
	add.l (20,%a5),%d2
	sub.l #1,%d2
.Lsb_x:
	move.w (8,%a4),%d3            ; Width
	ext.l %d3
	move.l %d5,%d0
	and.l #0x0020,%d0             ; GFLG_RELWIDTH
	beq .Lsb_w
	add.l (20,%a5),%d3
.Lsb_w:
	cmpi.l #0,%d3
	ble .Lsb_gnext
	move.l %d2,%d4
	add.l %d3,%d4
	sub.l #1,%d4                  ; x1
	move.l (24,%a5),%d0
	cmpi.l #16,%d0
	bge .Lsb_gnext
	lsl.l #3,%d0
	lea (56,%a5),%a0
	move.l %d2,(0,%a0,%d0)
	move.l %d4,(4,%a0,%d0)
	move.l (24,%a5),%d0
	add.l #1,%d0
	move.l %d0,(24,%a5)
.Lsb_gnext:
	move.l (%a4),%a4
	sub.l #1,%d7
	bne .Lsb_g
.Lsb_gdone:
	; --- ordenar por x0 (insercion)
	move.l #1,%d6                 ; i
.Lsb_si:
	cmp.l (24,%a5),%d6
	bge .Lsb_sorted
	lea (56,%a5),%a0
	move.l %d6,%d0
	lsl.l #3,%d0
	move.l (0,%a0,%d0),%d2        ; clave x0
	move.l (4,%a0,%d0),%d3        ; clave x1
	move.l %d6,%d5
	sub.l #1,%d5                  ; j
.Lsb_sj:
	cmpi.l #0,%d5
	blt .Lsb_sput
	move.l %d5,%d0
	lsl.l #3,%d0
	move.l (0,%a0,%d0),%d1
	cmp.l %d2,%d1
	ble .Lsb_sput
	move.l (0,%a0,%d0),%d1
	move.l %d1,(8,%a0,%d0)
	move.l (4,%a0,%d0),%d1
	move.l %d1,(12,%a0,%d0)
	sub.l #1,%d5
	bra .Lsb_sj
.Lsb_sput:
	move.l %d5,%d0
	add.l #1,%d0
	lsl.l #3,%d0
	move.l %d2,(0,%a0,%d0)
	move.l %d3,(4,%a0,%d0)
	add.l #1,%d6
	bra .Lsb_si
.Lsb_sorted:
	; --- pintar los tramos libres
	move.l #0,(40,%a5)
	move.l #-1,(44,%a5)
	move.l #0,%d5                 ; cur
	move.l #0,%d6                 ; i
.Lsb_p:
	cmp.l (24,%a5),%d6
	bge .Lsb_plast
	lea (56,%a5),%a0
	move.l %d6,%d0
	lsl.l #3,%d0
	move.l (0,%a0,%d0),%d2        ; x0
	move.l (4,%a0,%d0),%d4        ; x1
	cmp.l %d5,%d2
	ble .Lsb_pskip
	move.l %d2,%d3
	sub.l #1,%d3
	move.l %d5,%d2
	jsr SkinBarSeg                ; d2..d3
.Lsb_pskip:
	add.l #1,%d4
	cmp.l %d5,%d4
	ble .Lsb_pnext
	move.l %d4,%d5
.Lsb_pnext:
	add.l #1,%d6
	bra .Lsb_p
.Lsb_plast:
	move.l (20,%a5),%d3
	sub.l #1,%d3
	cmp.l %d3,%d5
	bgt .Lsb_title
	move.l %d5,%d2
	jsr SkinBarSeg
.Lsb_title:
	; --- titulo
	move.l (4,%a5),%a3
	move.l (32,%a3),%d0           ; Title
	beq .Lsb_out
	move.l %d0,%a2
	move.l (44,%a5),%d7
	sub.l (40,%a5),%d7
	add.l #1,%d7                  ; ancho del tramo
	cmpi.l #24,%d7
	blt .Lsb_out
	move.l (0,%a5),%a1            ; rp
	move.l (52,%a1),%d0           ; Font
	beq .Lsb_out
	move.l %d0,%a4
	move.b (25,%a1),(48,%a5)      ; FgPen
	move.b (28,%a1),(49,%a5)      ; DrawMode
	move.w (36,%a1),(50,%a5)      ; cp_x
	move.w (38,%a1),(52,%a5)      ; cp_y
	move.l GfxBase,%a6
	move.l #1,%d0                 ; pluma por defecto
	move.l (12,%a5),%d1           ; DrawInfo
	beq .Lsb_pen
	move.l %d1,%a0
	move.l (4,%a0),%d1            ; dri_Pens
	beq .Lsb_pen
	move.l %d1,%a0
	move.l #0,%d0
	move.w (8,%a0),%d0            ; SHADOWPEN (la mas oscura: buen contraste sobre la barra)
.Lsb_pen:
	move.l TitlePen,%d1
	move.l CurBank,%a0
	move.l (BK_LUM,%a0),%d2
	cmpi.l #0,(8,%a5)             ; fotograma de la barra: 0 activa, 2 inactiva
	beq .Lsb_lum
	move.l (BK_LUMI,%a0),%d2
.Lsb_lum:
	cmpi.l #110,%d2               ; barra oscura: titulo en blanco
	bge .Lsb_pen1
	move.l TitlePenW,%d1
.Lsb_pen1:
	cmpi.l #0,%d1
	blt .Lsb_pen2
	move.l %d1,%d0                ; negro o blanco de verdad (ObtainBestPen)
.Lsb_pen2:
	move.l %d0,LastPen
	move.l (12,%a5),%d1
	move.l %d1,LastDri
	.short 0x52B9
	.long CntTitles
	LVO -342                      ; SetAPen (a1 = rp)
	move.l (0,%a5),%a1
	move.l #0,%d0                 ; JAM1
	LVO -354                      ; SetDrMd
	move.l %a2,%a0
	jsr StrLen
	move.l %d0,%d6                ; caracteres
	sub.l #8,%d7                  ; margen
.Lsb_fit:
	cmpi.l #0,%d6
	ble .Lsb_restore
	move.l (0,%a5),%a1
	move.l %a2,%a0
	move.l %d6,%d0
	LVO -54                       ; TextLength
	cmp.l %d7,%d0
	ble .Lsb_fits
	sub.l #1,%d6
	bra .Lsb_fit
.Lsb_fits:
	; x = inicio + (ancho - texto)/2 ; y sup = (BT - alto)/2
	move.l %d0,(284,%a5)          ; ancho del texto
	add.l #8,%d7
	sub.l %d0,%d7
	asr.l #1,%d7
	add.l (40,%a5),%d7
	move.l %d7,%d4                ; x
	move.l #0,%d1
	move.w (20,%a4),%d1           ; tf_YSize
	move.l (16,%a5),%d5
	sub.l %d1,%d5
	asr.l #1,%d5                  ; y superior
	; componer el texto en un mapa de 1 plano propio y estamparlo con
	; BltTemplate: asi ningun parche de Text() de otros programas lo cambia
	move.l (284,%a5),%d0
	add.l #16,%d0
	move.l #0,%d1
	move.w (20,%a4),%d1
	move.l #1,%d2
	move.l #1,%d3                 ; BMF_CLEAR
	move.l #0,%a0
	LVO -918                      ; AllocBitMap
	move.l %d0,(288,%a5)
	beq .Lsb_direct
	lea (184,%a5),%a1
	LVO -198                      ; InitRastPort
	lea (184,%a5),%a1
	move.l (288,%a5),(4,%a1)      ; rp.BitMap
	move.l %a4,%a0
	LVO -66                       ; SetFont
	lea (184,%a5),%a1
	move.l #1,%d0
	LVO -342                      ; SetAPen
	lea (184,%a5),%a1
	move.l #0,%d0
	LVO -354                      ; SetDrMd JAM1
	lea (184,%a5),%a1
	move.l #0,%d0
	move.l #0,%d1
	move.w (26,%a4),%d1           ; tf_Baseline
	LVO -240                      ; Move
	lea (184,%a5),%a1
	move.l %a2,%a0
	move.l %d6,%d0
	LVO -60                       ; Text (en nuestro mapa)
	LVO -228                      ; WaitBlit
	move.l (288,%a5),%a0
	move.l #0,%d1
	move.w (%a0),%d1              ; BytesPerRow
	move.l (8,%a0),%a0            ; Planes[0]
	move.l #0,%d0
	move.l (0,%a5),%a1            ; rp de la ventana (pluma y JAM1 ya puestos)
	move.l %d4,%d2
	move.l %d5,%d3
	move.l (284,%a5),%d4
	move.l #0,%d5
	move.w (20,%a4),%d5
	LVO -36                       ; BltTemplate
	LVO -228                      ; WaitBlit
	move.l (288,%a5),%a0
	LVO -924                      ; FreeBitMap
	bra .Lsb_restore
.Lsb_direct:
	move.l #0,%d1
	move.w (26,%a4),%d1
	add.l %d5,%d1
	move.l (0,%a5),%a1
	move.l %d4,%d0
	LVO -240                      ; Move
	move.l (0,%a5),%a1
	move.l %a2,%a0
	move.l %d6,%d0
	LVO -60                       ; Text
.Lsb_restore:
	move.l (0,%a5),%a1
	move.l #0,%d0
	move.b (48,%a5),%d0
	LVO -342                      ; SetAPen
	move.l (0,%a5),%a1
	move.l #0,%d0
	move.b (49,%a5),%d0
	LVO -354                      ; SetDrMd
	move.l (0,%a5),%a1
	move.w (50,%a5),%d0
	ext.l %d0
	move.w (52,%a5),%d1
	ext.l %d1
	LVO -240                      ; Move
.Lsb_out:
	lea (296,%sp),%sp
	RESTALL
	rts

; SkinBarSeg(d2 = x inicio, d3 = x fin, a5 = locales de SkinBar)
SkinBarSeg:
	SAVEALL
	cmpi.l #0,%d2
	bge .Lss_a
	move.l #0,%d2
.Lss_a:
	move.l (20,%a5),%d0
	sub.l #1,%d0
	cmp.l %d0,%d3
	ble .Lss_b
	move.l %d0,%d3
.Lss_b:
	cmp.l %d2,%d3
	blt .Lss_ret
	; recordar el tramo mas ancho (para el titulo)
	move.l %d3,%d0
	sub.l %d2,%d0
	move.l (44,%a5),%d1
	sub.l (40,%a5),%d1
	cmp.l %d1,%d0
	ble .Lss_c
	move.l %d2,(40,%a5)
	move.l %d3,(44,%a5)
.Lss_c:
	move.l GfxBase,%a6
	move.l (32,%a5),%d5           ; alto = min(fh, BT)
	cmp.l (16,%a5),%d5
	ble .Lss_h
	move.l (16,%a5),%d5
.Lss_h:
	move.l %d5,%a4                ; alto
	move.l %d3,%a3                ; x fin
	move.l %d2,%d7                ; x
.Lss_loop:
	move.l %a3,%d0
	cmp.l %d0,%d7
	bgt .Lss_ret
	move.l %a3,%d4
	sub.l %d7,%d4
	add.l #1,%d4                  ; quedan
	cmp.l (28,%a5),%d4
	ble .Lss_w
	move.l (28,%a5),%d4
.Lss_w:
	move.l #0,%d0
	move.l (8,%a5),%d1            ; fotograma (0 o 2)
	cmpi.l #0,%d1
	beq .Lss_sx
	move.l (28,%a5),%d0
	add.l %d0,%d0                 ; 2*fw
.Lss_sx:
	move.l #0,%d1
	move.l (36,%a5),%a0
	move.l (0,%a5),%a1
	move.l %d7,%d2
	move.l #0,%d3
	move.l %a4,%d5
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	add.l %d4,%d7
	bra .Lss_loop
.Lss_ret:
	RESTALL
	rts

; ---------------------------------------------------------------------------
; SkinFrames(a0 = rp, a1 = ventana): pinta los marcos izquierdo, derecho e
; inferior con frameh.iff (inferior) y framev.iff (laterales), escalando el
; perfil al grosor del borde y sin tocar los gadgets que haya en ellos.
; Locales (a5): 0 rp, 4 win, 8 fotograma, 12 W, 16 H, 20 BL, 24 BT, 28 BR,
; 32 BB, 36 hBM, 40 hFW, 44 hFH, 48 vBM, 52 vFW, 56 vFH, 60 n rects,
; 64 x0, 68 y0, 72 x1, 76 y1, 80 orientacion, 84 segA, 88 segB, 92 grosor,
; 96 base x, 100 tmp, 128.. rects (x0,y0,x1,y1)
	.set FR_LOC, 128+32*16
	.globl SkinFrames
SkinFrames:
	SAVEALL
	lea (-640,%sp),%sp
	move.l %sp,%a5
	move.l %a0,(0,%a5)
	move.l %a1,(4,%a5)
	move.l CurBank,%a2
	lea (IDX_FRAMEH*BE_SIZE,%a2),%a0
	move.l (BE_BM,%a0),%d0
	beq .Lsf_out
	move.l %d0,(36,%a5)
	move.l #0,%d0
	move.w (BE_FW,%a0),%d0
	move.l %d0,(40,%a5)
	move.w (BE_FH,%a0),%d0
	move.l %d0,(44,%a5)
	lea (IDX_FRAMEV*BE_SIZE,%a2),%a0
	move.l (BE_BM,%a0),%d0
	beq .Lsf_out
	move.l %d0,(48,%a5)
	move.l #0,%d0
	move.w (BE_FW,%a0),%d0
	move.l %d0,(52,%a5)
	move.w (BE_FH,%a0),%d0
	move.l %d0,(56,%a5)
	cmpi.l #2,(40,%a5)
	blt .Lsf_out
	cmpi.l #2,(44,%a5)
	blt .Lsf_out
	cmpi.l #2,(52,%a5)
	blt .Lsf_out
	cmpi.l #2,(56,%a5)
	blt .Lsf_out
	move.l (4,%a5),%a3
	move.w (8,%a3),%d0
	ext.l %d0
	move.l %d0,(12,%a5)
	cmpi.l #8,%d0
	blt .Lsf_out
	move.w (10,%a3),%d0
	ext.l %d0
	move.l %d0,(16,%a5)
	cmpi.l #8,%d0
	blt .Lsf_out
	move.l #0,%d0
	move.b (54,%a3),%d0
	move.l %d0,(20,%a5)
	move.b (55,%a3),%d0
	move.l %d0,(24,%a5)
	move.b (56,%a3),%d0
	move.l %d0,(28,%a5)
	move.b (57,%a3),%d0
	move.l %d0,(32,%a5)
	move.l #2,(8,%a5)
	move.l (24,%a3),%d0
	and.l #0x2000,%d0
	beq .Lsf_in
	move.l #0,(8,%a5)
.Lsf_in:
	; --- rectangulos de los gadgets
	move.l #0,(60,%a5)
	move.l (62,%a3),%a4
	move.l #256,%d7
.Lsf_g:
	move.l %a4,%d0
	beq .Lsf_gdone
	move.l #0,%d1
	move.w (16,%a4),%d1
	move.l %d1,%d0
	and.l #0x8000,%d0
	beq .Lsf_ns
	move.l %d1,%d0
	and.l #0xF0,%d0
	cmpi.l #0x20,%d0              ; arrastre: no cuenta
	beq .Lsf_gnext
.Lsf_ns:
	move.l #0,%d5
	move.w (12,%a4),%d5
	move.w (4,%a4),%d0
	ext.l %d0
	move.l %d5,%d4
	and.l #0x10,%d4
	beq .Lsf_1
	add.l (12,%a5),%d0
	sub.l #1,%d0
.Lsf_1:
	move.w (6,%a4),%d1
	ext.l %d1
	move.l %d5,%d4
	and.l #0x08,%d4
	beq .Lsf_2
	add.l (16,%a5),%d1
	sub.l #1,%d1
.Lsf_2:
	move.w (8,%a4),%d2
	ext.l %d2
	move.l %d5,%d4
	and.l #0x20,%d4
	beq .Lsf_3
	add.l (12,%a5),%d2
.Lsf_3:
	move.w (10,%a4),%d3
	ext.l %d3
	move.l %d5,%d4
	and.l #0x40,%d4
	beq .Lsf_4
	add.l (16,%a5),%d3
.Lsf_4:
	; botones (BOOL o de sistema) con imagen: solo tapa su dibujo
	move.l (18,%a4),%d4
	beq .Lsf_5
	move.l #0,%d5
	move.w (16,%a4),%d5
	move.l %d5,%d6
	and.l #0x7,%d6
	cmpi.l #3,%d6                 ; barras: rectangulo entero
	beq .Lsf_5
	cmpi.l #1,%d6
	beq .Lsf_img
	and.l #0x8000,%d5
	beq .Lsf_5
.Lsf_img:
	move.l %d4,%a0
	move.w (0,%a0),%d4
	ext.l %d4
	add.l %d4,%d0
	move.w (2,%a0),%d4
	ext.l %d4
	add.l %d4,%d1
	move.w (4,%a0),%d2
	ext.l %d2
	move.w (6,%a0),%d3
	ext.l %d3
.Lsf_5:
	cmpi.l #0,%d2
	ble .Lsf_gnext
	cmpi.l #0,%d3
	ble .Lsf_gnext
	add.l %d0,%d2
	sub.l #1,%d2
	add.l %d1,%d3
	sub.l #1,%d3
	move.l (60,%a5),%d4
	cmpi.l #32,%d4
	bge .Lsf_gnext
	lsl.l #4,%d4
	lea (128,%a5),%a0
	adda.l %d4,%a0
	move.l %d0,(0,%a0)
	move.l %d1,(4,%a0)
	move.l %d2,(8,%a0)
	move.l %d3,(12,%a0)
	move.l (60,%a5),%d4
	add.l #1,%d4
	move.l %d4,(60,%a5)
.Lsf_gnext:
	move.l (%a4),%a4
	sub.l #1,%d7
	bne .Lsf_g
.Lsf_gdone:
	; --- inferior
	move.l (32,%a5),%d0
	beq .Lsf_left
	move.l #0,(64,%a5)
	move.l (12,%a5),%d1
	sub.l #1,%d1
	move.l %d1,(72,%a5)
	move.l (16,%a5),%d1
	sub.l #1,%d1
	move.l %d1,(76,%a5)
	sub.l %d0,%d1
	add.l #1,%d1
	move.l %d1,(68,%a5)
	jsr FrWBLine
	move.l (68,%a5),%d1
	sub.l %d0,%d1
	move.l %d1,(68,%a5)
	move.l #0,(80,%a5)
	jsr FrStrip
.Lsf_left:
	; --- laterales: y de BT a H-BB-1
	move.l (16,%a5),%d1
	sub.l (32,%a5),%d1
	sub.l #1,%d1
	move.l %d1,(76,%a5)
	move.l (24,%a5),(68,%a5)
	move.l #1,(80,%a5)
	move.l (20,%a5),%d0
	beq .Lsf_right
	move.l #0,(64,%a5)
	sub.l #1,%d0
	move.l %d0,(72,%a5)
	jsr FrStrip
.Lsf_right:
	move.l (28,%a5),%d0
	beq .Lsf_ring
	move.l (12,%a5),%d1
	sub.l #1,%d1
	move.l %d1,(72,%a5)
	sub.l %d0,%d1
	add.l #1,%d1
	move.l %d1,(64,%a5)
	jsr FrWBLine
	move.l (64,%a5),%d1
	sub.l %d0,%d1
	move.l %d1,(64,%a5)
	jsr FrStrip
.Lsf_ring:
	; --- contorno de 1 pixel alrededor de toda la ventana (tapa las lineas
	; del sistema que quedan entre el borde y los botones con skin)
	cmpi.l #4,(24,%a5)
	blt .Lsf_out
	cmpi.l #0,(20,%a5)
	beq .Lsf_out
	cmpi.l #0,(28,%a5)
	beq .Lsf_out
	cmpi.l #0,(32,%a5)
	beq .Lsf_out
	move.l GfxBase,%a6
	move.l (44,%a5),%d7
	sub.l #1,%d7                  ; ultima fila del perfil
	move.l #0,%d4                 ; arriba: fila 0
	move.l #0,%d1
	jsr FrLineH
	move.l (24,%a5),%d4           ; bajo la barra: fila BT-1
	sub.l #1,%d4
	move.l %d7,%d1
	jsr FrLineH
	move.l (16,%a5),%d4           ; abajo del todo
	sub.l #1,%d4
	move.l %d7,%d1
	jsr FrLineH
	move.l #0,%d2                 ; izquierda: columna 0 del perfil
	move.l #0,%d1
	jsr FrLineV
	move.l (12,%a5),%d2           ; derecha: ultima columna
	sub.l #1,%d2
	move.l (52,%a5),%d1
	sub.l #1,%d1
	jsr FrLineV
.Lsf_out:
	lea (640,%sp),%sp
	RESTALL
	rts

; FrWBLine -> d0 = 1 en ventanas del Workbench (el marco cubre tambien la
; linea interior que pinta el sistema junto al contenido), si no 0  (a5 locales)
FrWBLine:
	; (desactivado: esa linea esta en la zona del contenido y dejaba rastros
	; al agrandar la ventana)
.Lwl_0:
	move.l #0,%d0
	rts

; FrLineH(d4 = y, d1 = fila origen): linea horizontal de ancho W con frameh
FrLineH:
	SAVEALL
	move.l %d1,%a4
	move.l #0,%d0
	cmpi.l #0,(8,%a5)
	beq .Llh_b
	move.l (40,%a5),%d0
	add.l %d0,%d0
.Llh_b:
	move.l %d0,%a3                ; x origen
	move.l %d4,%d3
	move.l #0,%d7                 ; x
.Llh_x:
	cmp.l (12,%a5),%d7
	bge .Llh_ret
	move.l (12,%a5),%d4
	sub.l %d7,%d4
	cmp.l (40,%a5),%d4
	ble .Llh_w
	move.l (40,%a5),%d4
.Llh_w:
	move.l (36,%a5),%a0
	move.l %a3,%d0
	move.l %a4,%d1
	move.l (0,%a5),%a1
	move.l %d7,%d2
	move.l #1,%d5
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	add.l %d4,%d7
	bra .Llh_x
.Llh_ret:
	RESTALL
	rts

; FrLineV(d2 = x, d1 = columna origen): linea vertical de alto H con framev
FrLineV:
	SAVEALL
	move.l #0,%d0
	cmpi.l #0,(8,%a5)
	beq .Llv_b
	move.l (52,%a5),%d0
	add.l %d0,%d0
.Llv_b:
	add.l %d1,%d0
	move.l %d0,%a3                ; x origen
	move.l %d2,%a4                ; x destino
	move.l #0,%d7                 ; y
.Llv_y:
	cmp.l (16,%a5),%d7
	bge .Llv_ret
	move.l (16,%a5),%d5
	sub.l %d7,%d5
	cmp.l (56,%a5),%d5
	ble .Llv_h
	move.l (56,%a5),%d5
.Llv_h:
	move.l (48,%a5),%a0
	move.l %a3,%d0
	move.l #0,%d1
	move.l (0,%a5),%a1
	move.l %a4,%d2
	move.l %d7,%d3
	move.l #1,%d4
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	add.l %d5,%d7
	bra .Llv_y
.Llv_ret:
	RESTALL
	rts

; FrStrip: pinta el rectangulo (64..76) salvo donde haya gadgets, linea a
; linea a lo ancho del borde (104..108 = linea actual en el eje corto)
FrStrip:
	SAVEALL
	move.l (64,%a5),%d6
	move.l (72,%a5),%d7
	cmpi.l #0,(80,%a5)
	bne .Lfx_o
	move.l (68,%a5),%d6
	move.l (76,%a5),%d7
.Lfx_o:
	cmp.l %d7,%d6
	bgt .Lfx_ret
	move.l %d6,(104,%a5)
	move.l %d6,(108,%a5)
	jsr FrStrip1
	add.l #1,%d6
	bra .Lfx_o
.Lfx_ret:
	RESTALL
	rts

FrStrip1:
	SAVEALL
	move.l (72,%a5),%d0
	cmp.l (64,%a5),%d0
	blt .Lfs_ret
	move.l (76,%a5),%d0
	cmp.l (68,%a5),%d0
	blt .Lfs_ret
	move.l (64,%a5),%d6           ; pos
	move.l (72,%a5),%d7           ; fin
	move.l #0,%d4                 ; desplazamiento del eje largo en el rect
	move.l #8,%d3                 ; fin
	cmpi.l #0,(80,%a5)
	beq .Lfs_o
	move.l (68,%a5),%d6
	move.l (76,%a5),%d7
	move.l #4,%d4
	move.l #12,%d3
.Lfs_o:
.Lfs_loop:
	cmp.l %d7,%d6
	bgt .Lfs_ret
	move.l %d7,%d5
	add.l #1,%d5                  ; siguiente bloqueo
	move.l (60,%a5),%d2
	lea (128,%a5),%a0
.Lfs_r:
	cmpi.l #0,%d2
	beq .Lfs_paint
	; solape en el eje corto
	cmpi.l #0,(80,%a5)
	bne .Lfs_cv
	move.l (12,%a0),%d0           ; ry1 >= c0
	cmp.l (104,%a5),%d0
	blt .Lfs_rn
	move.l (4,%a0),%d0            ; ry0 <= c1
	cmp.l (108,%a5),%d0
	bgt .Lfs_rn
	bra .Lfs_al
.Lfs_cv:
	move.l (8,%a0),%d0
	cmp.l (104,%a5),%d0
	blt .Lfs_rn
	move.l (0,%a0),%d0
	cmp.l (108,%a5),%d0
	bgt .Lfs_rn
.Lfs_al:
	move.l (0,%a0,%d4),%d0        ; ra0
	move.l (0,%a0,%d3),%d1        ; ra1
	cmp.l %d6,%d0
	bgt .Lfs_after
	cmp.l %d6,%d1
	blt .Lfs_rn
	move.l %d1,%d6                ; dentro: saltar el gadget
	add.l #1,%d6
	bra .Lfs_loop
.Lfs_after:
	cmp.l %d5,%d0
	bge .Lfs_rn
	move.l %d0,%d5
.Lfs_rn:
	lea (16,%a0),%a0
	sub.l #1,%d2
	bra .Lfs_r
.Lfs_paint:
	move.l %d6,(84,%a5)
	move.l %d5,%d0
	sub.l #1,%d0
	move.l %d0,(88,%a5)
	cmpi.l #0,(80,%a5)
	bne .Lfs_pv
	jsr FrPaintH
	bra .Lfs_pd
.Lfs_pv:
	jsr FrPaintV
.Lfs_pd:
	move.l %d5,%d6
	bra .Lfs_loop
.Lfs_ret:
	RESTALL
	rts

; FrScale(d0 = i, d1 = tam origen, d2 = grosor) -> d0 = fila/columna origen
FrScale:
	cmpi.l #1,%d2
	bgt .Lfc_n
	move.l %d1,%d0
	lsr.l #1,%d0
	rts
.Lfc_n:
	sub.l #1,%d1
	sub.l #1,%d2
	.short 0xC0C1                 ; mulu.w d1,d0
	.short 0x80C2                 ; divu.w d2,d0
	and.l #0xFFFF,%d0
	rts

; FrScaleC: como FrScale pero limitando el indice a 0..grosor-1
FrScaleC:
	cmpi.l #0,%d0
	bge .Lfsc_1
	move.l #0,%d0
.Lfsc_1:
	cmp.l %d2,%d0
	blt .Lfsc_2
	move.l %d2,%d0
	sub.l #1,%d0
.Lfsc_2:
	bra FrScale

; FrPaintH: inferior, x de segA a segB, filas y0..y1
FrPaintH:
	SAVEALL
	move.l GfxBase,%a6
	move.l (76,%a5),%d0
	sub.l (68,%a5),%d0
	add.l #1,%d0
	move.l %d0,(92,%a5)           ; grosor
	move.l #0,%d0
	cmpi.l #0,(8,%a5)
	beq .Lph_b
	move.l (40,%a5),%d0
	add.l %d0,%d0
.Lph_b:
	move.l %d0,(96,%a5)
	move.l (104,%a5),%d0
	sub.l (68,%a5),%d0
	move.l %d0,%a2                ; fila
.Lph_row:
	move.l %a2,%d0
	add.l (68,%a5),%d0
	cmp.l (108,%a5),%d0
	bgt .Lph_ret
	move.l #1,%a4                 ; filas de esta pasada
	move.l %a2,%d0
	move.l (92,%a5),%d2
	cmp.l (44,%a5),%d2
	beq .Lph_sy                   ; mismo grosor: fila = fila
.Lph_sc:
	move.l (44,%a5),%d1
	jsr FrScale
.Lph_sy:
	move.l %d0,(100,%a5)          ; fila origen
	move.l (84,%a5),%a3           ; x
.Lph_x:
	move.l %a3,%d0
	cmp.l (88,%a5),%d0
	bgt .Lph_nx
	move.l (88,%a5),%d4
	sub.l %a3,%d4
	add.l #1,%d4
	cmp.l (40,%a5),%d4
	ble .Lph_w
	move.l (40,%a5),%d4
.Lph_w:
	move.l (36,%a5),%a0
	move.l (96,%a5),%d0
	move.l (100,%a5),%d1
	move.l (0,%a5),%a1
	move.l %a3,%d2
	move.l (68,%a5),%d3
	add.l %a2,%d3
	move.l %a4,%d5
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	adda.l %d4,%a3
	bra .Lph_x
.Lph_nx:
	adda.l %a4,%a2
	bra .Lph_row
.Lph_ret:
	RESTALL
	rts

; FrPaintV: lateral, y de segA a segB, columnas x0..x1
FrPaintV:
	SAVEALL
	move.l GfxBase,%a6
	move.l (72,%a5),%d0
	sub.l (64,%a5),%d0
	add.l #1,%d0
	move.l %d0,(92,%a5)
	move.l #0,%d0
	cmpi.l #0,(8,%a5)
	beq .Lpv_b
	move.l (52,%a5),%d0
	add.l %d0,%d0
.Lpv_b:
	move.l %d0,(96,%a5)
	move.l (104,%a5),%d0
	sub.l (64,%a5),%d0
	move.l %d0,%a2                ; columna
.Lpv_col:
	move.l %a2,%d0
	add.l (64,%a5),%d0
	cmp.l (108,%a5),%d0
	bgt .Lpv_ret
	move.l #1,%a4
	move.l %a2,%d0
	move.l (92,%a5),%d2
	cmp.l (52,%a5),%d2
	beq .Lpv_sx
.Lpv_sc:
	move.l (52,%a5),%d1
	jsr FrScale
.Lpv_sx:
	add.l (96,%a5),%d0
	move.l %d0,(100,%a5)          ; columna origen
	move.l (84,%a5),%a3           ; y
.Lpv_y:
	move.l %a3,%d0
	cmp.l (88,%a5),%d0
	bgt .Lpv_nc
	move.l (88,%a5),%d5
	sub.l %a3,%d5
	add.l #1,%d5
	cmp.l (56,%a5),%d5
	ble .Lpv_h
	move.l (56,%a5),%d5
.Lpv_h:
	move.l (48,%a5),%a0
	move.l (100,%a5),%d0
	move.l #0,%d1
	move.l (0,%a5),%a1
	move.l (64,%a5),%d2
	add.l %a2,%d2
	move.l %a3,%d3
	move.l %a4,%d4
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	adda.l %d5,%a3
	bra .Lpv_y
.Lpv_nc:
	adda.l %a4,%a2
	bra .Lpv_col
.Lpv_ret:
	RESTALL
	rts

; ===========================================================================
; Barras deslizantes con skin (ventanas del Workbench).
; Las barras del Workbench son PROPGADGET antiguos con AUTOKNOB: Intuition
; dibuja el tirador por dentro. Para poder pintarlo, SkinPatch les quita
; AUTOKNOB y les pone como tirador una imagen BOOPSI propia (KnClass), que
; pinta el canal y el tirador con la skin cada vez que Intuition lo dibuja.
; Al cerrar la ventana (CloseWindow parcheado) se deja todo como estaba.
	.set KN_MAX, 32
	.set KN_SIZE, 24              ; 0 ventana, 4 gadget, 8 render original,
	                              ; 12 objeto, 16 flags PropInfo, 18 flags gadget

; KnFind(d0 = gadget) -> a0 = entrada o 0   (llamar bajo Forbid)  LEAF
KnFind:
	lea KnTab,%a0
	move.l #KN_MAX,%d1
.Lkf_l:
	cmp.l (4,%a0),%d0
	beq .Lkf_ok
	lea (KN_SIZE,%a0),%a0
	sub.l #1,%d1
	bne .Lkf_l
	move.l #0,%a0
.Lkf_ok:
	rts

; KnFindObj(d0 = objeto) -> a0 = entrada o 0   (bajo Forbid)  LEAF
KnFindObj:
	lea KnTab,%a0
	move.l #KN_MAX,%d1
.Lko_l:
	move.l (4,%a0),%d2
	beq .Lko_n
	cmp.l (12,%a0),%d0
	beq .Lko_ok
.Lko_n:
	lea (KN_SIZE,%a0),%a0
	sub.l #1,%d1
	bne .Lko_l
	move.l #0,%a0
.Lko_ok:
	rts

; KnSize(a2 = ventana, a3 = gadget, a4 = objeto, d3 = HorizBody, d4 = VertBody)
; Calcula el tamano del tirador (Width/Height de la imagen)
KnSize:
	SAVEALL
	and.l #0xFFFF,%d3
	and.l #0xFFFF,%d4
	move.l %d3,%d6
	move.l %d4,%d7
	jsr GadRect                   ; d2 ancho, d3 alto
	cmpi.l #1,%d2
	bge .Lks_1
	move.l #1,%d2
.Lks_1:
	cmpi.l #1,%d3
	bge .Lks_2
	move.l #1,%d3
.Lks_2:
	move.l (34,%a3),%a0           ; PropInfo
	move.l #0,%d0
	move.w (%a0),%d0
	and.l #4,%d0                  ; FREEVERT
	beq .Lks_h
	; vertical: ancho = canal, alto = canal * VertBody
	move.w %d2,(4,%a4)
	move.l %d3,%d0
	move.l %d7,%d1
	.short 0xC0C1                 ; mulu.w d1,d0
	lsr.l #8,%d0
	lsr.l #8,%d0
	cmpi.l #8,%d0
	bge .Lks_v1
	move.l #8,%d0
.Lks_v1:
	cmp.l %d3,%d0
	ble .Lks_v2
	move.l %d3,%d0
.Lks_v2:
	move.w %d0,(6,%a4)
	bra .Lks_ret
.Lks_h:
	move.w %d3,(6,%a4)
	move.l %d2,%d0
	move.l %d6,%d1
	.short 0xC0C1                 ; mulu.w d1,d0
	lsr.l #8,%d0
	lsr.l #8,%d0
	cmpi.l #8,%d0
	bge .Lks_h1
	move.l #8,%d0
.Lks_h1:
	cmp.l %d2,%d0
	ble .Lks_h2
	move.l %d2,%d0
.Lks_h2:
	move.w %d0,(4,%a4)
.Lks_ret:
	RESTALL
	rts

; Takeover(d0 = ventana): convierte sus barras AUTOKNOB del borde
	.globl Takeover
Takeover:
	SAVEALL
	.short 0x52B9
	.long CntTkCall
	move.l %d0,%d7
	beq .Lto2_ret
	move.l KnClass,%d0
	beq .Lto2_ret
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),%d0
	beq .Lto2_ret
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -564                      ; ObtainSemaphore
	LVO -132                      ; Forbid
	jsr FindWinScreen
	LVO -138                      ; Permit
	cmpi.l #0,%d0
	beq .Lto2_rel
	move.l %d7,%a2
	; solo ventanas del Workbench (WFLG_WBENCHWINDOW)
	move.l (24,%a2),%d0
	move.l %d0,LastSigTask
	and.l #0x02000000,%d0
	beq .Lto2_rel
	.short 0x52B9
	.long CntTkWB
	move.l (62,%a2),%a3
	move.l #64,%d6
.Lto2_g:
	move.l %a3,%d0
	beq .Lto2_rel
	move.l #0,%d0
	move.w (16,%a3),%d0
	cmpi.l #3,%d0                 ; GTYP_PROPGADGET (no de sistema)
	bne .Lto2_n
	move.l #0,%d0
	move.w (14,%a3),%d0           ; Activation
	and.l #0x90,%d0               ; RIGHTBORDER | BOTTOMBORDER
	beq .Lto2_n
	move.l (34,%a3),%d0
	beq .Lto2_n
	.short 0x52B9
	.long CntTkProp
	move.l %d0,%a0
	move.l #0,%d0
	move.w (%a0),%d0
	move.l %d0,LastPFlags
	and.l #1,%d0                  ; AUTOKNOB
	beq .Lto2_n
	.short 0x52B9
	.long CntTkAuto
	jsr TakeOne
.Lto2_n:
	move.l (%a3),%a3
	sub.l #1,%d6
	bne .Lto2_g
.Lto2_rel:
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -570                      ; ReleaseSemaphore
.Lto2_ret:
	RESTALL
	rts

; TakeOne(a2 = ventana, a3 = gadget)
TakeOne:
	SAVEALL
	move.l SysBase,%a6
	LVO -132
	move.l %a3,%d0
	jsr KnFind
	move.l %a0,%d0
	bne .Lt1_permit               ; ya es nuestra
	move.l #0,%d0
	jsr KnFind                    ; hueco libre
	move.l %a0,%d0
	beq .Lt1_permit
	move.l %a0,%a5
	move.l #-1,(4,%a5)            ; reservada
	LVO -138
	move.l IntuitionBase,%a6
	move.l KnClass,%a0
	move.l #0,%a1
	lea KnTags,%a2
	LVO -636                      ; NewObjectA
	move.l %d7,%a2                ; (d7 = ventana desde Takeover)
	move.l %d0,%a4
	cmpi.l #0,%d0
	beq .Lt1_free
	move.l %a2,%a0
	move.l %a3,%a1
	LVO -228                      ; RemoveGadget -> d0 posicion
	move.l %d0,%d5
	move.l %a2,(0,%a5)
	move.l (18,%a3),(8,%a5)
	move.l %a4,(12,%a5)
	move.l (34,%a3),%a0
	move.w (%a0),(16,%a5)
	move.w (12,%a3),(18,%a5)
	; tirador propio: sin AUTOKNOB, sin marco, sin resaltado
	move.l #0,%d0
	move.w (%a0),%d0
	and.l #0xFFFE,%d0
	or.l #8,%d0                   ; PROPBORDERLESS
	move.w %d0,(%a0)
	move.l #0,%d0
	move.w (12,%a3),%d0
	or.l #3,%d0                   ; GADGHNONE
	move.w %d0,(12,%a3)
	move.l %a4,(18,%a3)
	move.w (4,%a3),(20,%a5)       ; posicion y ancho originales
	move.w (8,%a3),(22,%a5)
	; barra horizontal: que empiece donde acaba el marco izquierdo
	move.l #0,%d0
	move.w (%a0),%d0
	and.l #4,%d0                  ; FREEVERT
	bne .Lt1_geo
	move.l #0,%d0
	move.b (54,%a2),%d0           ; BorderLeft
	move.w (4,%a3),%d1
	ext.l %d1
	sub.l %d1,%d0                 ; cuanto se mete en el marco
	ble .Lt1_geo
	add.w %d0,(4,%a3)
	sub.w %d0,(8,%a3)
.Lt1_geo:
	move.l #0,%d3
	move.w (6,%a0),%d3            ; HorizBody
	move.l #0,%d4
	move.w (8,%a0),%d4            ; VertBody
	jsr KnSize
	move.l %a3,(4,%a5)            ; entrada activa
	.short 0x52B9
	.long KnCount
	move.l IntuitionBase,%a6
	move.l %a2,%a0
	move.l %a3,%a1
	move.l %d5,%d0
	LVO -42                       ; AddGadget
	move.l %a3,%a0
	move.l %a2,%a1
	move.l #0,%a2
	move.l #1,%d0
	LVO -432                      ; RefreshGList
	bra .Lt1_ret
.Lt1_free:
	move.l #0,(4,%a5)
	bra .Lt1_ret
.Lt1_permit:
	LVO -138
.Lt1_ret:
	RESTALL
	rts

; KnRefresh(d0 = ventana): vuelve a dibujar sus barras con tirador propio
	.globl KnRefresh
KnRefresh:
	SAVEALL
	move.l %d0,%d7
	beq .Lkr_ret
	move.l KnCount,%d0
	beq .Lkr_ret
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -564
	LVO -132
	jsr FindWinScreen
	LVO -138
	cmpi.l #0,%d0
	beq .Lkr_rel
	lea KnTab,%a5
	move.l #KN_MAX,%d5
.Lkr_l:
	move.l (4,%a5),%d0
	beq .Lkr_n
	cmpi.l #-1,%d0
	beq .Lkr_n
	cmp.l (0,%a5),%d7
	bne .Lkr_n
	move.l %d7,%a2
	move.l %d0,%a3
	jsr GInList
	cmpi.l #0,%d0
	beq .Lkr_n
	move.l IntuitionBase,%a6
	move.l %a3,%a0
	move.l %d7,%a1
	move.l #0,%a2
	move.l #1,%d0
	LVO -432                      ; RefreshGList
	move.l SysBase,%a6
.Lkr_n:
	lea (KN_SIZE,%a5),%a5
	sub.l #1,%d5
	bne .Lkr_l
.Lkr_rel:
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -570
.Lkr_ret:
	RESTALL
	rts

; KnPaintWin(a0 = rp, a1 = ventana): repinta (proceso principal, con la capa
; bloqueada) las barras con tirador propio de la ventana, colocando el tirador
; segun los valores de la barra. Asi lo que Intuition borre al arrastrar
; se corrige enseguida.
KnPaintWin:
	SAVEALL
	lea (-24,%sp),%sp
	move.l %sp,%a5                ; mensaje IM_DRAW propio
	move.l #0x202,(0,%a5)
	move.l %a0,(4,%a5)
	move.l #0,(12,%a5)
	move.l #0,(16,%a5)
	move.l #0,(20,%a5)
	move.l %a1,%d6                ; ventana
	move.l KnCount,%d0
	beq .Lpw_out
	lea KnTab,%a3
	move.l #KN_MAX,%d5
.Lpw_l:
	move.l (4,%a3),%d0
	beq .Lpw_n
	cmpi.l #-1,%d0
	beq .Lpw_n
	cmp.l (0,%a3),%d6
	bne .Lpw_n
	move.l %d0,%d7                ; gadget
	.short 0x48E7,0x0410           ; movem.l d5/a3,-(sp)
	move.l %d6,%a2
	move.l %d7,%a3
	jsr GInList
	cmpi.l #0,%d0
	beq .Lpw_skip
	move.l (18,%a3),%a4           ; nuestro objeto (sigue puesto?)
	move.l (34,%a3),%a0
	move.l #0,%d3
	move.w (6,%a0),%d3
	move.l #0,%d4
	move.w (8,%a0),%d4
	jsr KnSize
	jsr GadRect                   ; d0 x0 d1 y0 d2 w d3 h
	move.l (34,%a3),%a0
	move.l #0,%d4
	move.w (%a0),%d4
	and.l #4,%d4                  ; FREEVERT
	beq .Lpw_h
	move.l #0,%d4
	move.w (6,%a4),%d4            ; kh
	sub.l %d4,%d3
	ble .Lpw_set
	move.l #0,%d4
	move.w (4,%a0),%d4            ; VertPot
	move.l %d0,-(%sp)
	move.l %d3,%d0
	move.l %d4,%d2
	.short 0xC0C2                 ; mulu.w d2,d0
	lsr.l #8,%d0
	lsr.l #8,%d0
	add.l %d0,%d1
	move.l (%sp)+,%d0
	bra .Lpw_set
.Lpw_h:
	move.l #0,%d4
	move.w (4,%a4),%d4            ; kw
	sub.l %d4,%d2
	ble .Lpw_set
	move.l #0,%d4
	move.w (2,%a0),%d4            ; HorizPot
	move.l %d1,-(%sp)
	move.l %d2,%d1
	move.l %d4,%d2
	.short 0xC2C2                 ; mulu.w d2,d1
	lsr.l #8,%d1
	lsr.l #8,%d1
	add.l %d1,%d0
	move.l (%sp)+,%d1
.Lpw_set:
	; desplazamiento = posicion - LeftEdge/TopEdge de la imagen
	move.w (0,%a4),%d2
	ext.l %d2
	sub.l %d2,%d0
	move.w (2,%a4),%d2
	ext.l %d2
	sub.l %d2,%d1
	move.w %d0,(8,%a5)
	move.w %d1,(10,%a5)
	move.l %d6,%d0
	move.l %d7,%d1
	.short 0x48E7,0x0300           ; movem.l d6-d7,-(sp)
	jsr KnPaint                   ; a4 objeto, a5 mensaje, d6 ventana, d7 gadget
	movem.l (%sp)+,%d6-%d7
.Lpw_skip:
	movem.l (%sp)+,%d5/%a3
.Lpw_n:
	lea (KN_SIZE,%a3),%a3
	sub.l #1,%d5
	bne .Lpw_l
.Lpw_out:
	lea (24,%sp),%sp
	RESTALL
	rts

; ===========================================================================
; Botones extra de la barra de titulo que no usan imagenes de sysiclass
; (por ejemplo el de iconificar de AmigaOS 3.2, un buttongclass con su propia
; imagen): se pintan encima con iconify.iff al repintar la barra.
; SkinExtra(a0 = rp, a1 = ventana)
SkinExtra:
	SAVEALL
	lea (-48,%sp),%sp
	move.l %sp,%a5                ; 0..23 mensaje IM_DRAW, 24..43 imagen
	move.l #0x202,(0,%a5)
	move.l %a0,(4,%a5)            ; rp
	move.l #0,(16,%a5)
	move.l #0,(20,%a5)
	move.l #0,(24,%a5)
	move.l #0,(28,%a5)
	move.l #0,(32,%a5)
	move.l %a1,%a2                ; ventana
	move.l CurBank,%a0
	lea (IDX_ICONIFY*BE_SIZE,%a0),%a0
	move.l (BE_BM,%a0),%d0
	beq .Lse_out
	move.l %a0,%d6                ; entrada del banco
	move.l (62,%a2),%a3
	move.l #64,%d5
.Lse_g:
	move.l %a3,%d0
	beq .Lse_out
	move.l #0,%d0
	move.w (16,%a3),%d0
	move.l %d0,%d1
	and.l #0x8000,%d1             ; de sistema: ya tienen skin
	bne .Lse_n
	and.l #7,%d0
	cmpi.l #5,%d0                 ; BOOPSI
	bne .Lse_n
	move.l (18,%a3),%d0           ; con imagen
	beq .Lse_n
	move.l %d0,%a0
	move.l (-4,%a0),%d0
	cmp.l (SysIClass,%pc),%d0     ; las de sysiclass ya se pintan con skin
	beq .Lse_n
	move.l (-4,%a3),%d0           ; clase del gadget: buttongclass
	beq .Lse_n
	move.l %d0,%a0
	move.l (28,%a0),%d0
	beq .Lse_n
	move.l %d0,%a0
	move.l %a0,-(%sp)
	lea ButtonGName,%a1
	jsr StrEq
	move.l (%sp)+,%a0
	cmpi.l #0,%d0
	bne .Lse_cls
	lea DopusButtonGName,%a1      ; Directory Opus: su propia clase de boton
	jsr StrEq
	cmpi.l #0,%d0
	beq .Lse_n
.Lse_cls:
	jsr GadRect
	cmpi.l #0,%d1                 ; arriba del todo
	bne .Lse_n
	move.l #0,%d4
	move.b (55,%a2),%d4
	cmpi.l #4,%d4
	blt .Lse_n
	add.l #1,%d4
	cmp.l %d4,%d3
	bgt .Lse_n
	cmpi.l #8,%d2
	blt .Lse_n
	; imagen falsa del tamano del gadget y mensaje IM_DRAW
	move.w #0,(24,%a5)
	move.w #0,(26,%a5)
	move.w %d2,(28,%a5)
	move.w %d3,(30,%a5)
	move.w %d0,(8,%a5)
	move.w %d1,(10,%a5)
	move.l #0,(12,%a5)            ; IDS_NORMAL
	move.l (24,%a2),%d0
	and.l #0x2000,%d0             ; ventana activa?
	bne .Lse_act
	move.l #5,(12,%a5)            ; IDS_INACTIVENORMAL
	bra .Lse_draw
.Lse_act:
	move.l #0,%d0
	move.w (12,%a3),%d0
	and.l #0x80,%d0               ; GFLG_SELECTED
	beq .Lse_draw
	move.l #1,(12,%a5)
.Lse_draw:
	.short 0x48E7,0x003C           ; movem.l a2-a5,-(sp)
	move.l %d6,%a2
	lea (24,%a5),%a4
	move.l #IDX_ICONIFY,%d0
	.short 0x52B9
	.long CntExtra
	jsr DrawSkin
	movem.l (%sp)+,%a2-%a5
.Lse_n:
	move.l (%a3),%a3
	sub.l #1,%d5
	bne .Lse_g
.Lse_out:
	lea (48,%sp),%sp
	RESTALL
	rts

; ===========================================================================
; Barras deslizantes BOOPSI (propgclass) de las aplicaciones: se parchea el
; despachador de la clase; tras su GM_RENDER se pinta encima el canal y el
; tirador con la skin (solo barras del borde de la ventana).
	.globl PgEntry
PgEntry:
	move.l (%a1),%d0
	cmpi.l #1,%d0                 ; GM_RENDER
	beq .Lpg_r
	move.l OldPgEntry,-(%sp)
	rts
.Lpg_r:
	SAVEALL
	.short 0x52B9
	.long CntPg
	move.l %a1,%a5
	move.l %a2,%a3
	move.l OldPgEntry,%a4
	jsr (%a4)
	move.l %d0,%d7
	.short 0x52B9
	.long InUse
	move.l Disabled,%d0
	bne .Lpg_out
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),%d0
	beq .Lpg_out
	move.l (4,%a5),%d0            ; gpr_GInfo
	beq .Lpg_out
	move.l %d0,%a0
	move.l (8,%a0),%d0            ; gi_Requester
	bne .Lpg_out
	move.l (4,%a0),%d0            ; gi_Window
	beq .Lpg_out
	move.l %d0,%a2
	move.l (8,%a5),%d0            ; gpr_RPort
	beq .Lpg_out
	move.l %d0,%d6
	move.l AllScreens,%d0
	bne .Lpg_scr
	move.l (46,%a2),%d0           ; WScreen
	cmp.l (WBScreen,%pc),%d0
	bne .Lpg_out
.Lpg_scr:
	jsr InBorder
	cmpi.l #0,%d0
	beq .Lpg_out
	move.l (34,%a3),%d0           ; PropInfo
	beq .Lpg_out
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -678                      ; ObtainSemaphoreShared
	move.l %d6,%a0
	move.l %a2,%a1
	.short 0x52B9
	.long CntPgPaint
	jsr PgPaint
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -570
.Lpg_out:
	.short 0x53B9
	.long InUse
	move.l %d7,%d0
	RESTALL
	rts

; PgPaint(a0 = rp, a1 = ventana, a3 = gadget): canal y tirador con la skin
PgPaint:
	SAVEALL
	lea (-48,%sp),%sp
	move.l %sp,%a5                ; mensaje IM_DRAW propio
	lea (24,%sp),%a4              ; imagen falsa (tamano del tirador)
	move.l #0x202,(0,%a5)
	move.l %a0,(4,%a5)
	move.l #0,(12,%a5)
	move.l #0,(16,%a5)
	move.l #0,(20,%a5)
	move.l #0,(0,%a4)
	move.l #0,(4,%a4)
	move.l %a1,%d6
	move.l %a3,%d7
	move.l %a1,%a2
	move.l (34,%a3),%a0
	move.l #0,%d3
	move.w (6,%a0),%d3
	move.l #0,%d4
	move.w (8,%a0),%d4
	jsr KnSize
	jsr GadRect                   ; d0 x0 d1 y0 d2 w d3 h
	move.l (34,%a3),%a0
	move.l #0,%d4
	move.w (%a0),%d4
	and.l #4,%d4                  ; FREEVERT
	beq .Lpp_h
	move.l #0,%d4
	move.w (6,%a4),%d4
	sub.l %d4,%d3
	ble .Lpp_set
	move.l #0,%d4
	move.w (4,%a0),%d4            ; VertPot
	move.l %d0,-(%sp)
	move.l %d3,%d0
	move.l %d4,%d2
	.short 0xC0C2                 ; mulu.w d2,d0
	lsr.l #8,%d0
	lsr.l #8,%d0
	add.l %d0,%d1
	move.l (%sp)+,%d0
	bra .Lpp_set
.Lpp_h:
	move.l #0,%d4
	move.w (4,%a4),%d4
	sub.l %d4,%d2
	ble .Lpp_set
	move.l #0,%d4
	move.w (2,%a0),%d4            ; HorizPot
	move.l %d1,-(%sp)
	move.l %d2,%d1
	move.l %d4,%d2
	.short 0xC2C2                 ; mulu.w d2,d1
	lsr.l #8,%d1
	lsr.l #8,%d1
	add.l %d1,%d0
	move.l (%sp)+,%d1
.Lpp_set:
	move.w %d0,(8,%a5)
	move.w %d1,(10,%a5)
	jsr KnPaint                   ; a4 imagen, a5 mensaje, d6 ventana, d7 gadget
	lea (48,%sp),%sp
	RESTALL
	rts

; PgPaintWin(a0 = rp, a1 = ventana): repinta las barras propgclass del borde
; (tras mover o activar la ventana el sistema las redibuja por dentro)
PgPaintWin:
	SAVEALL
	move.l %a0,%d6
	move.l %a1,%a2
	move.l PgClass,%d7
	beq .Lpw2_out
	move.l Disabled,%d0
	bne .Lpw2_out
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),%d0
	beq .Lpw2_out
	move.l (62,%a2),%a3
	move.l #64,%d5
.Lpw2_g:
	move.l %a3,%d0
	beq .Lpw2_out
	move.l #0,%d0
	move.w (16,%a3),%d0
	and.l #7,%d0
	cmpi.l #5,%d0
	bne .Lpw2_n
	move.l (-4,%a3),%d0
	cmp.l %d7,%d0
	bne .Lpw2_n
	jsr InBorder
	cmpi.l #0,%d0
	beq .Lpw2_n
	move.l (34,%a3),%d0
	beq .Lpw2_n
	.short 0x52B9
	.long CntPgPaint
	move.l %d6,%a0
	move.l %a2,%a1
	jsr PgPaint
.Lpw2_n:
	move.l (%a3),%a3
	sub.l #1,%d5
	bne .Lpw2_g
.Lpw2_out:
	RESTALL
	rts

; ===========================================================================
; Indicador de llenado del disco (ventanas raiz de un volumen del Workbench):
; gadget de una clase privada del Workbench en el borde izquierdo, que se
; dibuja solo. Se parchea su despachador (como propgclass) y, tras su
; GM_RENDER, se pinta encima con la skin: canal (marco) arriba y tirador
; abajo, con la altura del porcentaje que pone el titulo de la ventana.

; IsGauge(a2 = ventana, a3 = gadget) -> d0 = clase si es el indicador, si no 0
IsGauge:
	.short 0x48E7,0x60C0          ; movem.l d1-d2/a0-a1,-(sp)
	move.l (24,%a2),%d0
	and.l #0x02000000,%d0         ; WFLG_WBENCHWINDOW
	beq .Lig_no
	move.l #0,%d0
	move.w (16,%a3),%d0
	and.l #7,%d0
	cmpi.l #5,%d0                 ; GTYP_CUSTOMGADGET
	bne .Lig_no
	move.w (14,%a3),%d0
	and.l #0x20,%d0               ; GACT_LEFTBORDER
	beq .Lig_no
	move.l (18,%a3),%d0           ; sin imagen
	bne .Lig_no
	move.l (-4,%a3),%d0           ; clase
	beq .Lig_no
	move.l %d0,%a0
	move.l (28,%a0),%d1           ; privada (sin nombre)
	bne .Lig_no
	move.l (24,%a0),%d1           ; superclase
	beq .Lig_no
	move.l %d1,%a1
	move.l (28,%a1),%d1
	beq .Lig_no
	move.l %d1,%a1
	lea GadgetClassName,%a0
.Lig_c:
	move.b (%a0)+,%d1
	move.b (%a1)+,%d2
	cmp.b %d1,%d2
	bne .Lig_no
	cmpi.b #0,%d1
	bne .Lig_c
	move.l (-4,%a3),%d0
	bra .Lig_ret
.Lig_no:
	move.l #0,%d0
.Lig_ret:
	movem.l (%sp)+,%d1-%d2/%a0-%a1
	rts

; TitlePct(a0 = titulo) -> d0 = numero delante del primer '%' (0..100) o -1
TitlePct:
	.short 0x48E7,0x7000          ; movem.l d1-d3,-(sp)
	move.l %a0,%d3                ; inicio
.Ltp_f:
	move.b (%a0)+,%d0
	beq .Ltp_no
	cmpi.b #0x25,%d0              ; '%'
	bne .Ltp_f
	suba.l #1,%a0                 ; a0 en '%'
	move.l #0,%d0
	move.l #1,%d1
	move.l #0,%d2                 ; cifras
.Ltp_b:
	cmp.l %a0,%d3
	beq .Ltp_end
	move.b -(%a0),%d2
	cmpi.b #0x30,%d2
	blt .Ltp_end2
	cmpi.b #0x39,%d2
	bgt .Ltp_end2
	and.l #0x0F,%d2
	move.l %d1,-(%sp)
	.short 0xC4C1                 ; mulu.w d1,d2
	move.l (%sp)+,%d1
	add.l %d2,%d0
	move.l %d1,%d2
	lsl.l #2,%d1
	add.l %d2,%d1
	add.l %d1,%d1                 ; *10
	cmpi.l #1000,%d1
	bgt .Ltp_end
	bra .Ltp_b
.Ltp_end2:
.Ltp_end:
	cmpi.l #1,%d1                 ; ninguna cifra
	beq .Ltp_no
	cmpi.l #100,%d0
	ble .Ltp_ret
	move.l #100,%d0
	bra .Ltp_ret
.Ltp_no:
	move.l #-1,%d0
.Ltp_ret:
	movem.l (%sp)+,%d1-%d3
	rts

; GaugePaint(a2 = ventana, a3 = gadget, d6 = rp)
; Bloque (a3): campos de SkinRect + 72 ancho tubo, 76 alto tubo, 80 lleno,
; 84 porcentaje, 88 x tubo, 92 y tubo
GaugePaint:
	SAVEALL
	lea (-128,%sp),%sp
	move.l (32,%a2),%d0           ; titulo
	beq .Lgp_out
	move.l %d0,%a0
	jsr TitlePct
	cmpi.l #0,%d0
	blt .Lgp_out
	move.l %d0,%d5                ; porcentaje
	jsr GadRect                   ; d0 x0, d1 y0, d2 w, d3 h
	cmpi.l #8,%d2
	blt .Lgp_out
	cmpi.l #12,%d3
	blt .Lgp_out
	move.l %a2,%a5                ; ventana
	move.l %sp,%a3                ; bloque
	move.l %d5,(84,%a3)
	move.l %d6,(16,%a3)
	move.l %d0,%d4                ; x0
	move.l %d1,%d7                ; y0
	move.l %d2,(72,%a3)
	move.l %d3,(76,%a3)
	move.l #2,(104,%a3)           ; inactiva
	move.l (24,%a5),%d0
	and.l #0x2000,%d0
	beq .Lgp_fr
	move.l #0,(104,%a3)
.Lgp_fr:
	; 1) todo el gadget con el marco izquierdo
	move.l CurBank,%a2
	move.l #IDX_FRAMEV,%d0
	jsr KnSetImg
	cmpi.l #0,%d0
	beq .Lgp_in
	move.l %d4,(20,%a3)
	move.l %d7,(24,%a3)
	move.l (72,%a3),(28,%a3)
	move.l (76,%a3),(32,%a3)
	move.l #1,(36,%a3)
	move.l #0,(40,%a3)
	move.l #0,(44,%a3)
	move.l #0,%d0
	move.b (54,%a5),%d0           ; BorderLeft
	move.l %d0,(112,%a3)
	move.l %d4,(116,%a3)
	jsr SkinRect
.Lgp_in:
	move.l #0,(112,%a3)
	; 2) tubo: margen lateral ancho/4 (2..4), 3 arriba y abajo
	move.l (72,%a3),%d0
	move.l %d0,%d1
	lsr.l #2,%d1
	cmpi.l #2,%d1
	bge .Lgp_m1
	move.l #2,%d1
.Lgp_m1:
	cmpi.l #4,%d1
	ble .Lgp_m2
	move.l #4,%d1
.Lgp_m2:
	add.l %d1,%d4
	sub.l %d1,%d0
	sub.l %d1,%d0
	move.l %d0,(72,%a3)
	move.l %d4,(88,%a3)
	add.l #3,%d7
	move.l %d7,(92,%a3)
	move.l (76,%a3),%d0
	sub.l #6,%d0
	move.l %d0,(76,%a3)
	; lleno = alto * pct / 100, minimo 4 si hay algo
	move.l %d0,%d1
	move.l (84,%a3),%d2
	.short 0xC2C2                 ; mulu.w d2,d1
	.short 0x82FC,100             ; divu.w #100,d1
	and.l #0xFFFF,%d1
	move.l %d1,%d5
	cmpi.l #0,(84,%a3)
	beq .Lgp_f2
	cmpi.l #4,%d5
	bge .Lgp_f2
	move.l #4,%d5
.Lgp_f2:
	cmp.l (76,%a3),%d5
	ble .Lgp_f3
	move.l (76,%a3),%d5
.Lgp_f3:
	move.l %d5,(80,%a3)
	; 3) tubo hundido: fondo oscuro (el marco de la skin oscurecido, o la
	; pluma 1 si no hay) y luz abajo y a la derecha
	move.l GfxBase,%a6
	move.l (16,%a3),%a1
	move.l TubePen,%d0
	bpl .Lgp_tpen
	move.l #1,%d0
.Lgp_tpen:
	LVO -342                      ; SetAPen
	move.l (16,%a3),%a1
	move.l (88,%a3),%d0
	move.l (92,%a3),%d1
	move.l %d0,%d2
	add.l (72,%a3),%d2
	sub.l #1,%d2
	move.l %d1,%d3
	add.l (76,%a3),%d3
	sub.l #1,%d3
	LVO -306                      ; RectFill
	move.l (16,%a3),%a1
	move.l TitlePenW,%d0
	cmpi.l #0,%d0
	bge .Lgp_wp
	move.l #2,%d0
.Lgp_wp:
	LVO -342
	move.l (16,%a3),%a1           ; linea de abajo
	move.l (88,%a3),%d0
	move.l (92,%a3),%d1
	add.l (76,%a3),%d1
	LVO -240                      ; Move
	move.l (16,%a3),%a1
	move.l (88,%a3),%d0
	add.l (72,%a3),%d0
	move.l (92,%a3),%d1
	add.l (76,%a3),%d1
	LVO -246                      ; Draw
	move.l (16,%a3),%a1           ; y la de la derecha, hacia arriba
	move.l (88,%a3),%d0
	add.l (72,%a3),%d0
	move.l (92,%a3),%d1
	LVO -246
.Lgp_knob:
	; 4) lleno: tirador
	cmpi.l #0,(80,%a3)
	ble .Lgp_ticks
	move.l CurBank,%a2
	move.l #IDX_KNOBV,%d0
	jsr KnSetImg
	cmpi.l #0,%d0
	beq .Lgp_ticks
	move.l (88,%a3),(20,%a3)
	move.l (92,%a3),%d0
	add.l (76,%a3),%d0
	sub.l (80,%a3),%d0
	move.l %d0,(24,%a3)
	move.l (72,%a3),(28,%a3)
	move.l (80,%a3),(32,%a3)
	move.l #1,(36,%a3)
	move.l #1,(40,%a3)
	move.l #1,(44,%a3)
	jsr SkinRect
.Lgp_ticks:
	; 5) rayitas cada 10% (la del 50% mas larga), en blanco
	move.l GfxBase,%a6
	move.l (16,%a3),%a1
	move.l TitlePenW,%d0
	cmpi.l #0,%d0
	bge .Lgp_tp
	move.l #2,%d0
.Lgp_tp:
	LVO -342                      ; SetAPen
	move.l #1,%d5                 ; i
.Lgp_tl:
	cmpi.l #10,%d5
	bge .Lgp_done
	move.l (76,%a3),%d1           ; y = y0 + alto - alto*i/10
	move.l %d5,%d0
	.short 0xC2C0                 ; mulu.w d0,d1
	.short 0x82FC,10              ; divu.w #10,d1
	and.l #0xFFFF,%d1
	move.l (92,%a3),%d3
	add.l (76,%a3),%d3
	sub.l %d1,%d3
	move.l (88,%a3),%d2           ; x
	move.l (72,%a3),%d4           ; largo: ancho/2, o 3/4 en el 50%
	sub.l #1,%d4
	cmpi.l #5,%d5
	beq .Lgp_half
	lsr.l #1,%d4
	bra .Lgp_len
.Lgp_half:
	move.l %d4,%d0
	lsr.l #2,%d0
	sub.l %d0,%d4
.Lgp_len:
	and.l #0xFFFF,%d4
	cmpi.l #1,%d4
	bge .Lgp_l1
	move.l #1,%d4
.Lgp_l1:
	move.l (16,%a3),%a1
	move.l %d2,%d0
	move.l %d3,%d1
	LVO -240                      ; Move
	move.l (16,%a3),%a1
	move.l %d2,%d0
	add.l %d4,%d0
	sub.l #1,%d0
	move.l %d3,%d1
	LVO -246                      ; Draw
	add.l #1,%d5
	bra .Lgp_tl
.Lgp_done:
	.short 0x52B9
	.long CntGauge
.Lgp_out:
	lea (128,%sp),%sp
	RESTALL
	rts

; GaugePaintWin(a0 = rp, a1 = ventana): busca el indicador, engancha su
; clase la primera vez y lo pinta
GaugePaintWin:
	SAVEALL
	move.l %a0,%d6
	move.l %a1,%a2
	move.l Disabled,%d0
	bne .Lgw_out
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),%d0
	beq .Lgw_out
	move.l (62,%a2),%a3
	move.l #64,%d5
.Lgw_g:
	move.l %a3,%d0
	beq .Lgw_out
	jsr IsGauge
	cmpi.l #0,%d0
	beq .Lgw_n
	move.l GaugeClass,%d1
	bne .Lgw_have
	move.l %d0,%a4
	move.l SysBase,%a6
	LVO -132                      ; Forbid
	move.l %a4,GaugeClass
	move.l (8,%a4),OldGaugeEntry
	move.l #GaugeEntry,(8,%a4)
	LVO -138                      ; Permit
	bra .Lgw_p
.Lgw_have:
	cmp.l %d1,%d0
	bne .Lgw_n
.Lgw_p:
	jsr GaugePaint
.Lgw_n:
	move.l (%a3),%a3
	sub.l #1,%d5
	bne .Lgw_g
.Lgw_out:
	RESTALL
	rts

; GaugeEntry: despachador de la clase del indicador (h_Entry; a0 clase,
; a1 mensaje, a2 objeto)
	.globl GaugeEntry
GaugeEntry:
	move.l (%a1),%d0
	cmpi.l #1,%d0                 ; GM_RENDER
	beq .Lge_r
	move.l OldGaugeEntry,-(%sp)
	rts
.Lge_r:
	SAVEALL
	move.l %a1,%a5
	move.l %a2,%a3
	move.l OldGaugeEntry,%a4
	jsr (%a4)
	move.l %d0,%d7
	.short 0x52B9
	.long InUse
	move.l Disabled,%d0
	bne .Lge_out
	move.l CurBank,%a0
	move.l (IDX_KNOBV*BE_SIZE+BE_BM,%a0),%d0
	beq .Lge_out
	move.l (4,%a5),%d0            ; gpr_GInfo
	beq .Lge_out
	move.l %d0,%a0
	move.l (4,%a0),%d0            ; gi_Window
	beq .Lge_out
	move.l %d0,%a2
	move.l (8,%a5),%d0            ; gpr_RPort
	beq .Lge_out
	move.l %d0,%d6
	move.l AllScreens,%d0
	bne .Lge_scr
	move.l (46,%a2),%d0
	cmp.l (WBScreen,%pc),%d0
	bne .Lge_out
.Lge_scr:
	jsr IsGauge
	cmpi.l #0,%d0
	beq .Lge_out
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -678                      ; ObtainSemaphoreShared
	jsr GaugePaint
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -570
.Lge_out:
	.short 0x53B9
	.long InUse
	move.l %d7,%d0
	RESTALL
	rts

; InBorder(a2 = ventana, a3 = gadget) -> d0 = 1 si esta en el borde derecho
; o inferior: por sus marcas GACT o, si no las tiene (Directory Opus), por
; su posicion dentro del borde
InBorder:
	.short 0x48E7,0x7000          ; movem.l d1-d3,-(sp)
	move.l #0,%d0
	move.w (14,%a3),%d0
	and.l #0x90,%d0
	bne .Lib_yes
	move.l %d4,-(%sp)
	jsr GadRect                   ; d0 x0, d1 y0, d2 w, d3 h
	move.l (%sp)+,%d4
	move.w (8,%a2),%d2
	ext.l %d2
	move.l #0,%d3
	move.b (56,%a2),%d3           ; BorderRight
	sub.l %d3,%d2
	cmp.l %d2,%d0
	bge .Lib_yes
	move.w (10,%a2),%d2
	ext.l %d2
	move.b (57,%a2),%d3           ; BorderBottom
	sub.l %d3,%d2
	cmp.l %d2,%d1
	bge .Lib_yes
	move.l #0,%d0
	bra .Lib_ret
.Lib_yes:
	move.l #1,%d0
.Lib_ret:
	movem.l (%sp)+,%d1-%d3
	rts

; GInList(a2 = ventana, a3 = gadget) -> d0 = 1 si el gadget sigue en ella  LEAF
GInList:
	move.l (62,%a2),%a0
	move.l #256,%d1
.Lgl_l:
	move.l %a0,%d0
	beq .Lgl_no
	cmp.l %a3,%d0
	beq .Lgl_yes
	move.l (%a0),%a0
	sub.l #1,%d1
	bne .Lgl_l
.Lgl_no:
	move.l #0,%d0
	rts
.Lgl_yes:
	move.l #1,%d0
	rts

; NewCW: CloseWindow(a0 = ventana) parcheado
	.globl NewCW
NewCW:
	SAVEALL
	.short 0x52B9
	.long InUse
	move.l %a0,%d7
	move.l %a6,%d6
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -564
	LVO -132
	lea KnTab,%a5
	move.l #KN_MAX,%d5
	move.l #0,%d4                 ; hay que liberar?
.Lcw_l:
	move.l (4,%a5),%d0
	beq .Lcw_n
	cmpi.l #-1,%d0
	beq .Lcw_n
	cmp.l (0,%a5),%d7
	bne .Lcw_n
	move.l %d7,%a2
	move.l %d0,%a3
	jsr GInList
	cmpi.l #0,%d0
	beq .Lcw_gone
	move.l (8,%a5),(18,%a3)       ; devolver el gadget como estaba
	move.w (18,%a5),(12,%a3)
	move.w (20,%a5),(4,%a3)
	move.w (22,%a5),(8,%a3)
	move.l (34,%a3),%a0
	move.w (16,%a5),(%a0)
.Lcw_gone:
	move.l #-1,(4,%a5)            ; pendiente de liberar
	move.l #1,%d4
.Lcw_n:
	lea (KN_SIZE,%a5),%a5
	sub.l #1,%d5
	bne .Lcw_l
	LVO -138
	move.l %d6,%a6
	move.l %d7,%a0
	move.l OldCW,%a1
	jsr (%a1)
	cmpi.l #0,%d4
	beq .Lcw_rel
	lea KnTab,%a5
	move.l #KN_MAX,%d5
.Lcw_f:
	cmpi.l #-1,(4,%a5)
	bne .Lcw_fn
	cmp.l (0,%a5),%d7
	bne .Lcw_fn
	move.l IntuitionBase,%a6
	move.l (12,%a5),%a0
	LVO -642                      ; DisposeObject
	move.l #0,(0,%a5)
	move.l #0,(4,%a5)
	.short 0x53B9
	.long KnCount
.Lcw_fn:
	lea (KN_SIZE,%a5),%a5
	sub.l #1,%d5
	bne .Lcw_f
.Lcw_rel:
	move.l SysBase,%a6
	lea KnSem,%a0
	LVO -570
	.short 0x53B9
	.long InUse
	RESTALL
	rts

; NewNMP / NewMP: NewModifyProp y ModifyProp parcheados. Si la barra es
; nuestra: se quita AUTOKNOB de las flags y se recalcula el tirador.
	.globl NewNMP
NewNMP:
	move.l OldNMP,-(%sp)
	bra KnModify
	.globl NewMP
NewMP:
	move.l OldMP,-(%sp)
KnModify:
	; pila: funcion original
	.short 0x48E7,0xC0C0           ; movem.l d0-d1/a0-a1,-(sp)
	SAVEALL
	.short 0x52B9
	.long InUse
	move.l %a6,%d6
	move.l %a0,%a3
	move.l %a1,%a2
	move.l SysBase,%a6
	LVO -132
	move.l %a3,%d0
	jsr KnFind
	move.l %a0,%d0
	beq .Lkm_permit
	move.l (12,%a0),%a4
	LVO -138
	; flags (d0 guardado en la pila: 44 bytes de SAVEALL por encima)
	move.l (44,%sp),%d0
	and.l #0xFFFE,%d0
	or.l #8,%d0
	move.l %d0,(44,%sp)
	jsr KnSize                    ; d3/d4 = cuerpos nuevos (intactos)
	bra .Lkm_go
.Lkm_permit:
	LVO -138
.Lkm_go:
	.short 0x53B9
	.long InUse
	move.l %d6,%a6
	RESTALL
	movem.l (%sp)+,%d0-%d1/%a0-%a1
	rts                           ; salta a la funcion original

; KnobEntry: despachador de KnClass (a0 clase, a2 objeto, a1 mensaje)
	.globl KnobEntry
KnobEntry:
	move.l (%a1),%d0
	cmpi.l #0x202,%d0             ; IM_DRAW
	beq .Lke_draw
	cmpi.l #0x206,%d0             ; IM_DRAWFRAME
	beq .Lke_draw
	move.l (24,%a0),%a0           ; cl_Super
	move.l (8,%a0),-(%sp)         ; su h_Entry
	rts
.Lke_draw:
	SAVEALL
	.short 0x52B9
	.long InUse
	move.l %a2,%a4
	move.l %a1,%a5
	move.l SysBase,%a6
	LVO -132
	move.l %a4,%d0
	jsr KnFindObj
	move.l %a0,%d0
	beq .Lke_permit
	move.l (0,%a0),%d6            ; ventana
	move.l (4,%a0),%d7            ; gadget
	LVO -138
	lea ObjSem,%a0
	LVO -678                      ; ObtainSemaphoreShared
	jsr KnPaint
	move.l SysBase,%a6
	lea ObjSem,%a0
	LVO -570
	; Intuition puede borrar restos del tirador anterior despues de pintarlo:
	; pedir al proceso principal que repinte la barra entera dentro de poco
	; (salvo si el dibujo viene de ese mismo repintado)
	.short 0x93C9                 ; suba.l a1,a1
	LVO -294                      ; FindTask(NULL)
	cmp.l (MainTask,%pc),%d0
	beq .Lke_out
	move.l %d6,%d0
	jsr MarkDirty
	bra .Lke_out
.Lke_permit:
	LVO -138
.Lke_out:
	.short 0x53B9
	.long InUse
	RESTALL
	move.l #0,%d0
	rts

; KnPaint(a4 = objeto, a5 = mensaje, d6 = ventana, d7 = gadget)
; Locales (a3): bloque de SkinRect (0..71) + 72 kx, 76 ky, 80 kw, 84 kh,
; 88 x0, 92 y0, 96 w, 100 h, 104 fotograma, 108 vertical
KnPaint:
	SAVEALL
	lea (-128,%sp),%sp
	move.l %sp,%a3
	move.l #0,(112,%a3)
	move.l %sp,%a3
	move.l (4,%a5),%d0            ; rp
	beq .Lkp_out
	move.l %d0,(16,%a3)
	move.w (8,%a5),%d0            ; imp_Offset.x
	ext.l %d0
	move.w (0,%a4),%d1
	ext.l %d1
	add.l %d1,%d0
	move.l %d0,(72,%a3)
	move.w (10,%a5),%d0
	ext.l %d0
	move.w (2,%a4),%d1
	ext.l %d1
	add.l %d1,%d0
	move.l %d0,(76,%a3)
	move.l #0,%d0
	move.w (4,%a4),%d0
	move.l %d0,(80,%a3)
	move.w (6,%a4),%d0
	move.l %d0,(84,%a3)
	cmpi.l #0x206,(0,%a5)         ; IM_DRAWFRAME: usar sus dimensiones
	bne .Lkp_nf
	move.w (20,%a5),%d0
	beq .Lkp_nf
	move.l %d0,(80,%a3)
	move.w (22,%a5),%d0
	move.l %d0,(84,%a3)
.Lkp_nf:
	; canal = rectangulo del gadget
	move.l %a3,-(%sp)
	move.l %d6,%a2
	move.l %d7,%a3
	jsr GadRect
	move.l (34,%a3),%a0
	move.l #0,%d4
	move.w (%a0),%d4              ; flags PropInfo
	move.l (%sp)+,%a3
	move.l %d0,(88,%a3)
	move.l %d1,(92,%a3)
	move.l %d2,(96,%a3)
	move.l %d3,(100,%a3)
	; tamano del tirador segun el canal actual (la ventana puede haber
	; cambiado de tamano): para las proximas veces y para no salirse
	.short 0x48E7,0x0030           ; movem.l a2-a3,-(sp)
	move.l %d6,%a2
	move.l %d7,%a3
	move.l (34,%a3),%a0
	move.l #0,%d3
	move.w (6,%a0),%d3
	move.l #0,%d4
	move.w (8,%a0),%d4
	jsr KnSize
	move.l (34,%a3),%a0
	move.l #0,%d4
	move.w (%a0),%d4              ; flags PropInfo otra vez
	movem.l (%sp)+,%a2-%a3
	cmpi.l #0x206,(0,%a5)
	beq .Lkp_cl
	move.l #0,%d0
	move.w (4,%a4),%d0
	move.l %d0,(80,%a3)
	move.w (6,%a4),%d0
	move.l %d0,(84,%a3)
.Lkp_cl:
	; recortar al canal
	move.l (80,%a3),%d0
	cmp.l (96,%a3),%d0
	ble .Lkp_c1
	move.l (96,%a3),(80,%a3)
.Lkp_c1:
	move.l (84,%a3),%d0
	cmp.l (100,%a3),%d0
	ble .Lkp_c2
	move.l (100,%a3),(84,%a3)
.Lkp_c2:
	move.l (88,%a3),%d0           ; x maxima = x0 + w - kw
	add.l (96,%a3),%d0
	sub.l (80,%a3),%d0
	cmp.l (72,%a3),%d0
	bge .Lkp_c3
	move.l %d0,(72,%a3)
.Lkp_c3:
	move.l (88,%a3),%d0
	cmp.l (72,%a3),%d0
	ble .Lkp_c4
	move.l %d0,(72,%a3)
.Lkp_c4:
	move.l (92,%a3),%d0
	add.l (100,%a3),%d0
	sub.l (84,%a3),%d0
	cmp.l (76,%a3),%d0
	bge .Lkp_c5
	move.l %d0,(76,%a3)
.Lkp_c5:
	move.l (92,%a3),%d0
	cmp.l (76,%a3),%d0
	ble .Lkp_c6
	move.l %d0,(76,%a3)
.Lkp_c6:
	move.l #0,(108,%a3)
	move.l %d4,%d0
	and.l #4,%d0                  ; FREEVERT
	beq .Lkp_hz
	move.l #1,(108,%a3)
.Lkp_hz:
	; fotograma: 0 normal, 1 pulsado, 2 ventana inactiva
	move.l #2,(104,%a3)
	move.l %d6,%a0
	move.l (24,%a0),%d0
	and.l #0x2000,%d0
	beq .Lkp_fr
	move.l #0,(104,%a3)
	and.l #0x100,%d4              ; KNOBHIT
	beq .Lkp_fr
	move.l #1,(104,%a3)
.Lkp_fr:
	move.l (16,%a3),%d0
	move.l %d0,(16,%a3)
	; --- canal: antes y despues del tirador. Como en AmigaOS 4 el canal es
	; el propio marco: se pinta con su degradado, alineado con el borde.
	move.l (104,%a3),-(%sp)
	cmpi.l #1,(104,%a3)
	bne .Lkp_t0
	move.l #0,(104,%a3)           ; pulsado: el canal no cambia
.Lkp_t0:
	move.l %d6,%a0                ; ventana
	move.l #0,%d1
	cmpi.l #0,(108,%a3)
	beq .Lkp_tmh
	move.b (56,%a0),%d1           ; BorderRight
	move.l %d1,(112,%a3)
	move.w (8,%a0),%d0
	ext.l %d0
	sub.l %d1,%d0                 ; x donde empieza el borde
	move.l (88,%a3),%d1
	sub.l %d0,%d1
	move.l %d1,(116,%a3)
	move.l #IDX_FRAMEV,%d0
	bra .Lkp_t1
.Lkp_tmh:
	move.b (57,%a0),%d1           ; BorderBottom
	move.l %d1,(112,%a3)
	move.w (10,%a0),%d0
	ext.l %d0
	sub.l %d1,%d0
	move.l (92,%a3),%d1
	sub.l %d0,%d1
	move.l %d1,(116,%a3)
	move.l #IDX_FRAMEH,%d0
.Lkp_t1:
	move.l CurBank,%a2
	jsr KnSetImg                  ; d0 indice -> bloque; d0 = 0 si no hay imagen
	move.l (%sp)+,(104,%a3)
	cmpi.l #0,%d0
	beq .Lkp_knob
	cmpi.l #0,(108,%a3)
	beq .Lkp_th
	; vertical
	move.l (88,%a3),(20,%a3)
	move.l (96,%a3),(28,%a3)
	move.l #1,(36,%a3)
	move.l (92,%a3),(24,%a3)      ; arriba
	move.l (76,%a3),%d0
	sub.l (92,%a3),%d0
	move.l %d0,(32,%a3)
	move.l #0,(40,%a3)
	move.l #0,(44,%a3)
	jsr SkinRect
	move.l (76,%a3),%d0           ; abajo
	add.l (84,%a3),%d0
	move.l %d0,(24,%a3)
	move.l (92,%a3),%d1
	add.l (100,%a3),%d1
	sub.l %d0,%d1
	move.l %d1,(32,%a3)
	move.l #0,(40,%a3)
	move.l #0,(44,%a3)
	jsr SkinRect
	bra .Lkp_knob
.Lkp_th:
	move.l (92,%a3),(24,%a3)
	move.l (100,%a3),(32,%a3)
	move.l #0,(36,%a3)
	move.l (88,%a3),(20,%a3)      ; izquierda
	move.l (72,%a3),%d0
	sub.l (88,%a3),%d0
	move.l %d0,(28,%a3)
	move.l #0,(40,%a3)
	move.l #0,(44,%a3)
	jsr SkinRect
	move.l (72,%a3),%d0           ; derecha
	add.l (80,%a3),%d0
	move.l %d0,(20,%a3)
	move.l (88,%a3),%d1
	add.l (96,%a3),%d1
	sub.l %d0,%d1
	move.l %d1,(28,%a3)
	move.l #0,(40,%a3)
	move.l #0,(44,%a3)
	jsr SkinRect
.Lkp_knob:
	move.l #0,(112,%a3)
	move.l CurBank,%a2
	move.l #IDX_KNOBV,%d0
	cmpi.l #0,(108,%a3)
	bne .Lkp_k1
	move.l #IDX_KNOBH,%d0
.Lkp_k1:
	jsr KnSetImg
	cmpi.l #0,%d0
	beq .Lkp_plain
	move.l (72,%a3),(20,%a3)
	move.l (76,%a3),(24,%a3)
	move.l (80,%a3),(28,%a3)
	move.l (84,%a3),(32,%a3)
	move.l (108,%a3),(36,%a3)
	move.l #1,(40,%a3)
	move.l #1,(44,%a3)
	jsr SkinRect
	bra .Lkp_out
.Lkp_plain:
	; sin imagenes en la skin: tirador sencillo con plumas
	move.l GfxBase,%a6
	move.l (16,%a3),%a1
	move.l #2,%d0
	LVO -342                      ; SetAPen
	move.l (16,%a3),%a1
	move.l (72,%a3),%d0
	move.l (76,%a3),%d1
	move.l %d0,%d2
	add.l (80,%a3),%d2
	sub.l #1,%d2
	move.l %d1,%d3
	add.l (84,%a3),%d3
	sub.l #1,%d3
	LVO -306                      ; RectFill
.Lkp_out:
	lea (128,%sp),%sp
	RESTALL
	rts

; KnSetImg(a2 = banco, d0 = indice, a3 = bloque) -> d0 = 1 si hay imagen
KnSetImg:
	lsl.l #2,%d0
	move.l %d0,%d1
	add.l %d0,%d0
	add.l %d1,%d0                 ; *12
	lea (0,%a2,%d0),%a0
	move.l (BE_BM,%a0),%d0
	beq .Lsi_no
	move.l %d0,(0,%a3)
	move.l #0,%d0
	move.w (BE_FW,%a0),%d0
	move.l %d0,(4,%a3)
	move.w (BE_FH,%a0),%d1
	and.l #0xFFFF,%d1
	move.l %d1,(8,%a3)
	cmpi.l #2,%d0
	blt .Lsi_no
	cmpi.l #2,%d1
	blt .Lsi_no
	move.l (104,%a3),%d1          ; fotograma * fw
	.short 0xC2C0                 ; mulu.w d0,d1
	move.l %d1,(12,%a3)
	move.l #1,%d0
	rts
.Lsi_no:
	move.l #0,%d0
	rts

; SkinRect(a3 = bloque): 0 bm, 4 fw, 8 fh, 12 x origen, 16 rp, 20 x, 24 y,
; 28 w, 32 h, 36 eje largo vertical, 40 tapa inicio, 44 tapa fin,
; 48 pos, 52 fin, 56 linea, 60 origen linea, 64 lineas por pasada
; Escala el perfil a lo ancho y repite a lo largo (con tapas en los extremos).
SkinRect:
	SAVEALL
	cmpi.l #0,(28,%a3)
	ble .Lsr_ret
	cmpi.l #0,(32,%a3)
	ble .Lsr_ret
	move.l GfxBase,%a6
	cmpi.l #0,(36,%a3)
	beq .Lsr_h
	; ---- eje largo vertical: columnas a lo ancho
	move.l #0,(56,%a3)
.Lsr_vc:
	move.l (56,%a3),%d0
	cmp.l (28,%a3),%d0
	bge .Lsr_ret
	move.l #1,(64,%a3)
	move.l (112,%a3),%d2
	beq .Lsr_vnm
	add.l (116,%a3),%d0           ; columna dentro del borde
	move.l (4,%a3),%d1
	jsr FrScaleC
	bra .Lsr_vs2
.Lsr_vnm:
	move.l (28,%a3),%d2
	cmp.l (4,%a3),%d2
	bne .Lsr_vs
	move.l %d2,(64,%a3)           ; mismo ancho: de una vez
	move.l #0,%d0
	bra .Lsr_vs2
.Lsr_vs:
	move.l (4,%a3),%d1
	jsr FrScale
.Lsr_vs2:
	add.l (12,%a3),%d0
	move.l %d0,(60,%a3)
	move.l (24,%a3),%d0
	move.l %d0,(48,%a3)
	add.l (32,%a3),%d0
	sub.l #1,%d0
	move.l %d0,(52,%a3)
	cmpi.l #0,(40,%a3)
	beq .Lsr_v1
	move.l (60,%a3),%d0           ; tapa de arriba: fila 0
	move.l #0,%d1
	move.l (48,%a3),%d3
	move.l #1,%d5
	jsr SRBltV
	.short 0x52AB,48              ; addq.l #1,(48,a3)
.Lsr_v1:
	cmpi.l #0,(44,%a3)
	beq .Lsr_v2
	move.l (52,%a3),%d0
	cmp.l (48,%a3),%d0
	blt .Lsr_v2
	move.l (60,%a3),%d0           ; tapa de abajo: ultima fila
	move.l (8,%a3),%d1
	sub.l #1,%d1
	move.l (52,%a3),%d3
	move.l #1,%d5
	jsr SRBltV
	.short 0x53AB,52              ; subq.l #1,(52,a3)
.Lsr_v2:
	; centro: filas 1..fh-2 en mosaico
	move.l (8,%a3),%d7
	move.l #1,%d4
	cmpi.l #3,%d7
	bge .Lsr_v3
	move.l #0,%d4
	bra .Lsr_v4
.Lsr_v3:
	sub.l #2,%d7
.Lsr_v4:
	move.l (48,%a3),%d3
	cmp.l (52,%a3),%d3
	bgt .Lsr_vn
	move.l (52,%a3),%d5
	sub.l %d3,%d5
	add.l #1,%d5
	cmp.l %d7,%d5
	ble .Lsr_v5
	move.l %d7,%d5
.Lsr_v5:
	move.l (60,%a3),%d0
	move.l %d4,%d1
	jsr SRBltV
	add.l %d5,%d3
	move.l %d3,(48,%a3)
	bra .Lsr_v4
.Lsr_vn:
	move.l (56,%a3),%d0
	add.l (64,%a3),%d0
	move.l %d0,(56,%a3)
	bra .Lsr_vc
	; ---- eje largo horizontal: filas a lo alto
.Lsr_h:
	move.l #0,(56,%a3)
.Lsr_hc:
	move.l (56,%a3),%d0
	cmp.l (32,%a3),%d0
	bge .Lsr_ret
	move.l #1,(64,%a3)
	move.l (112,%a3),%d2
	beq .Lsr_hnm
	add.l (116,%a3),%d0
	move.l (8,%a3),%d1
	jsr FrScaleC
	bra .Lsr_hs2
.Lsr_hnm:
	move.l (32,%a3),%d2
	cmp.l (8,%a3),%d2
	bne .Lsr_hs
	move.l %d2,(64,%a3)
	move.l #0,%d0
	bra .Lsr_hs2
.Lsr_hs:
	move.l (8,%a3),%d1
	jsr FrScale
.Lsr_hs2:
	move.l %d0,(60,%a3)           ; fila origen
	move.l (20,%a3),%d0
	move.l %d0,(48,%a3)
	add.l (28,%a3),%d0
	sub.l #1,%d0
	move.l %d0,(52,%a3)
	cmpi.l #0,(40,%a3)
	beq .Lsr_h1
	move.l (12,%a3),%d0           ; tapa izquierda: columna 0
	move.l (48,%a3),%d2
	move.l #1,%d4
	jsr SRBltH
	.short 0x52AB,48
.Lsr_h1:
	cmpi.l #0,(44,%a3)
	beq .Lsr_h2
	move.l (52,%a3),%d0
	cmp.l (48,%a3),%d0
	blt .Lsr_h2
	move.l (12,%a3),%d0
	add.l (4,%a3),%d0
	sub.l #1,%d0
	move.l (52,%a3),%d2
	move.l #1,%d4
	jsr SRBltH
	.short 0x53AB,52
.Lsr_h2:
	move.l (4,%a3),%d7
	move.l #1,%d5
	cmpi.l #3,%d7
	bge .Lsr_h3
	move.l #0,%d5
	bra .Lsr_h4
.Lsr_h3:
	sub.l #2,%d7
.Lsr_h4:
	move.l (48,%a3),%d2
	cmp.l (52,%a3),%d2
	bgt .Lsr_hn
	move.l (52,%a3),%d4
	sub.l %d2,%d4
	add.l #1,%d4
	cmp.l %d7,%d4
	ble .Lsr_h5
	move.l %d7,%d4
.Lsr_h5:
	move.l (12,%a3),%d0
	add.l %d5,%d0
	jsr SRBltH
	add.l %d4,%d2
	move.l %d2,(48,%a3)
	bra .Lsr_h4
.Lsr_hn:
	move.l (56,%a3),%d0
	add.l (64,%a3),%d0
	move.l %d0,(56,%a3)
	bra .Lsr_hc
.Lsr_ret:
	RESTALL
	rts

; SRBltV(d0 x origen, d1 y origen, d3 y destino, d5 alto): columna(s) en x+linea
SRBltV:
	SAVEALL
	move.l (0,%a3),%a0
	move.l (16,%a3),%a1
	move.l (20,%a3),%d2
	add.l (56,%a3),%d2
	move.l (64,%a3),%d4
	move.l #0xC0,%d6
	LVO -606                      ; BltBitMapRastPort
	RESTALL
	rts

; SRBltH(d0 x origen, d2 x destino, d4 ancho): fila(s) en y+linea
SRBltH:
	SAVEALL
	move.l (0,%a3),%a0
	move.l (16,%a3),%a1
	move.l (60,%a3),%d1
	move.l (24,%a3),%d3
	add.l (56,%a3),%d3
	move.l (64,%a3),%d5
	move.l #0xC0,%d6
	LVO -606
	RESTALL
	rts

; DsCopy(a3 = rp, d0 x, d1 y origen, d2 x, d3 y destino, d4 ancho, d5 alto)
; copia un trozo de la ventana dentro de la misma ventana (ClipBlit)
DsCopy:
	SAVEALL
	move.l %a3,%a0
	move.l %a3,%a1
	move.l #0xC0,%d6
	move.l GfxBase,%a6
	LVO -552                      ; ClipBlit
	RESTALL
	rts

; DsBlt(a2 = bitmap, a3 = rp, d0 x, d1 y origen, d2 x, d3 y destino, d4 ancho, d5 alto)
DsBlt:
	SAVEALL
	move.l %a2,%a0
	move.l %a3,%a1
	move.l #0xC0,%d6
	move.l GfxBase,%a6
	LVO -606
	RESTALL
	rts

; DsFill(a4 = locales de DrawSkin, d2 x, d3 y, d4 ancho, d5 alto): rellena
; el rectangulo con el marco (framev por columnas o frameh por filas)
DsFill:
	SAVEALL
	cmpi.l #0,%d4
	ble .Ldf_ret
	cmpi.l #0,%d5
	ble .Ldf_ret
	move.l GfxBase,%a6
	cmpi.l #0,(72,%a4)
	beq .Ldf_h
	; vertical: una columna de framev por cada x
	move.l %d2,%a2                ; x
	move.l %d2,%a3
	adda.l %d4,%a3                ; fin
.Ldf_vx:
	move.l %a3,%d0
	cmp.l %a2,%d0
	ble .Ldf_ret
	move.l %a2,%d0
	sub.l (20,%a4),%d0
	move.l (60,%a4),%d1
	move.l %d2,-(%sp)
	move.l (28,%a4),%d2
	jsr FrScaleC
	move.l (%sp)+,%d2
	add.l (68,%a4),%d0
	move.l %d0,%a5                ; columna origen
	move.l %d3,%d6                ; y
	move.l %d5,%d7                ; filas que faltan
.Ldf_vy:
	cmpi.l #0,%d7
	ble .Ldf_vn
	.short 0x48E7,0x3F00          ; movem.l d2-d7,-(sp)
	move.l %d7,%d5
	cmp.l (64,%a4),%d5
	ble .Ldf_vh
	move.l (64,%a4),%d5
.Ldf_vh:
	move.l %a2,%d2
	move.l %d6,%d3
	move.l %a5,%d0
	move.l #0,%d1
	move.l #1,%d4
	move.l (56,%a4),%a0
	move.l (12,%a4),%a1
	move.l #0xC0,%d6
	LVO -606
	movem.l (%sp)+,%d2-%d7
	add.l (64,%a4),%d6
	sub.l (64,%a4),%d7
	bra .Ldf_vy
.Ldf_vn:
	adda.l #1,%a2
	bra .Ldf_vx
.Ldf_h:
	; horizontal: una fila de frameh por cada y
	move.l %d3,%a2
	move.l %d3,%a3
	adda.l %d5,%a3
.Ldf_hy:
	move.l %a3,%d0
	cmp.l %a2,%d0
	ble .Ldf_ret
	move.l %a2,%d0
	sub.l (24,%a4),%d0
	move.l (64,%a4),%d1
	move.l %d2,-(%sp)
	move.l (32,%a4),%d2
	jsr FrScaleC
	move.l (%sp)+,%d2
	move.l %d0,%a5                ; fila origen
	move.l %d2,%d6                ; x
	move.l %d4,%d7                ; columnas que faltan
.Ldf_hx:
	cmpi.l #0,%d7
	ble .Ldf_hn
	.short 0x48E7,0x3F00          ; movem.l d2-d7,-(sp)
	move.l %d7,%d4
	cmp.l (60,%a4),%d4
	ble .Ldf_hw
	move.l (60,%a4),%d4
.Ldf_hw:
	move.l %d6,%d2
	move.l %a2,%d3
	move.l (68,%a4),%d0
	move.l %a5,%d1
	move.l #1,%d5
	move.l (56,%a4),%a0
	move.l (12,%a4),%a1
	move.l #0xC0,%d6
	LVO -606
	movem.l (%sp)+,%d2-%d7
	add.l (60,%a4),%d6
	sub.l (60,%a4),%d7
	bra .Ldf_hx
.Ldf_hn:
	adda.l #1,%a2
	bra .Ldf_hy
.Ldf_ret:
	RESTALL
	rts

; DrawSkin(a2 = entrada del banco, d0 = indice, a4 = imagen, a5 = impDraw)
; Locales: 0 bw, 4 bh, 8 sx, 12 rp, 16 indice
DrawSkin:
	SAVEALL
	lea (-80,%sp),%sp
	move.l %d0,(16,%sp)
	move.l (4,%a5),%d0            ; imp_RPort
	beq .Lds_out
	move.l %d0,(12,%sp)
	move.l #0,%d7
	move.l (12,%a5),%d0           ; imp_State
	cmpi.l #1,%d0
	beq .Lds_f1
	cmpi.l #6,%d0
	beq .Lds_f1
	cmpi.l #5,%d0
	beq .Lds_f2
	cmpi.l #7,%d0
	beq .Lds_f2
	bra .Lds_f0
.Lds_f1:
	move.l #1,%d7
	bra .Lds_f0
.Lds_f2:
	move.l #2,%d7
.Lds_f0:
	move.w (%a4),%d2
	ext.l %d2
	move.w (8,%a5),%d0
	ext.l %d0
	add.l %d0,%d2
	move.w (2,%a4),%d3
	ext.l %d3
	move.w (10,%a5),%d0
	ext.l %d0
	add.l %d0,%d3
	move.l (%a5),%d0
	cmpi.l #0x206,%d0
	bne .Lds_nodims
	move.w (20,%a5),%d4
	move.w (22,%a5),%d5
	bra .Lds_dims
.Lds_nodims:
	move.w (4,%a4),%d4
	move.w (6,%a4),%d5
.Lds_dims:
	ext.l %d4
	ext.l %d5
	cmpi.l #0,%d4
	ble .Lds_out
	cmpi.l #0,%d5
	ble .Lds_out
	move.l %d2,(20,%sp)           ; hueco de la imagen
	move.l %d3,(24,%sp)
	move.l %d4,(28,%sp)
	move.l %d5,(32,%sp)
	; huecos vistos (informe)
	lea SeenTab,%a0
	move.l (16,%sp),%d0
	lsl.l #2,%d0
	move.w %d4,(0,%a0,%d0)
	move.w %d5,(2,%a0,%d0)
	move.w (BE_FW,%a2),%d0
	ext.l %d0
	move.w (BE_FH,%a2),%d1
	ext.l %d1
	move.l %d0,%d6
	cmp.l %d4,%d6
	ble .Lds_bw
	move.l %d4,%d6
.Lds_bw:
	move.l %d6,(0,%sp)
	move.l %d1,%d6
	cmp.l %d5,%d6
	ble .Lds_bh
	move.l %d5,%d6
.Lds_bh:
	move.l %d6,(4,%sp)
	move.l %d0,%d6
	sub.l (0,%sp),%d6
	asr.l #1,%d6
	cmpi.l #0,%d7
	beq .Lds_sx
	add.l %d0,%d6
	cmpi.l #1,%d7
	beq .Lds_sx
	add.l %d0,%d6
.Lds_sx:
	move.l %d6,(8,%sp)
	sub.l (4,%sp),%d1
	asr.l #1,%d1
	sub.l (0,%sp),%d4
	asr.l #1,%d4
	add.l %d4,%d2
	sub.l (4,%sp),%d5
	asr.l #1,%d5
	add.l %d5,%d3
	move.l (BE_BM,%a2),%a0
	move.l (8,%sp),%d0
	move.l (12,%sp),%a1
	move.l (0,%sp),%d4
	move.l (4,%sp),%d5
	move.l #0xC0,%d6
	move.l GfxBase,%a6
	move.l %d2,(36,%sp)           ; x destino
	move.l %d7,(76,%sp)           ; estado (0 normal, 1 pulsado, 2 inactivo)
	move.l %d3,%d7                ; y destino
	move.l %d1,(40,%sp)           ; y origen
	move.l %a0,(44,%sp)           ; bitmap
	LVO -606                      ; BltBitMapRastPort
	; flechas y tamano: el hueco que sobra alrededor del dibujo se rellena
	; con el marco de la skin (si no, se ve el fondo del sistema)
	move.l (16,%sp),%d0
	move.l #IDX_FRAMEV,%d1
	move.l #1,(72,%sp)
	cmpi.l #4,%d0
	beq .Lds_m
	cmpi.l #7,%d0
	beq .Lds_m
	cmpi.l #8,%d0
	beq .Lds_m
	move.l #IDX_FRAMEH,%d1
	move.l #0,(72,%sp)
	cmpi.l #5,%d0
	beq .Lds_m
	cmpi.l #6,%d0
	bne .Lds_out
.Lds_m:
	move.l CurBank,%a0
	move.l %d1,%d0                ; *12
	lsl.l #2,%d0
	lsl.l #3,%d1
	add.l %d0,%d1
	adda.l %d1,%a0
	move.l (BE_BM,%a0),%d0
	beq .Lds_out
	move.l %d0,(56,%sp)
	move.l #0,%d0
	move.w (BE_FW,%a0),%d0
	move.l %d0,(60,%sp)
	beq .Lds_out
	move.w (BE_FH,%a0),%d0
	move.l %d0,(64,%sp)
	beq .Lds_out
	move.l #0,%d1                 ; marco: activo 0, inactivo 2
	cmpi.l #2,(76,%sp)
	bne .Lds_fi
	move.l (60,%sp),%d1
	add.l %d1,%d1
.Lds_fi:
	move.l %d1,(68,%sp)
	move.l %sp,%a4
	; arriba
	move.l (20,%sp),%d2
	move.l (24,%sp),%d3
	move.l (28,%sp),%d4
	move.l %d7,%d5
	sub.l %d3,%d5
	jsr DsFill
	; abajo
	move.l %d7,%d3
	add.l (4,%sp),%d3
	move.l (24,%sp),%d5
	add.l (32,%sp),%d5
	sub.l %d3,%d5
	jsr DsFill
	; izquierda
	move.l %d7,%d3
	move.l (36,%sp),%d4
	sub.l %d2,%d4
	move.l (4,%sp),%d5
	jsr DsFill
	; derecha
	move.l (36,%sp),%d2
	add.l (0,%sp),%d2
	move.l (20,%sp),%d4
	add.l (28,%sp),%d4
	sub.l %d2,%d4
	jsr DsFill
.Lds_out:
	lea (80,%sp),%sp
	RESTALL
	rts

; ===========================================================================
	.data
	.p2align 2
Version:  .asciz "$VER: SkinPatch 1.4 (23.11.2026) Amigatronics"
WBName:   .asciz "Workbench"
LayersName: .asciz "layers.library"
TimerName: .asciz "timer.device"
SysIName: .asciz "sysiclass"
Template: .asciz "SKIN,ALLSCREENS/S,QUIT/S,LOG/K,STATS/K,BORDER/K/N"
ProgName: .asciz "SkinPatch"
Banner:   .asciz "SkinPatch 1.4 - by Amigatronics\n"
MsgNoLibs:.asciz "SkinPatch: needs AmigaOS 3.0+ libraries (v39+)\n"
MsgNoScreen: .asciz "SkinPatch: cannot lock the Workbench screen\n"
MsgNoClass: .asciz "SkinPatch: cannot access sysiclass\n"
MsgNoDir: .asciz "SkinPatch: selected skin not found in SYS:Prefs/Skins\n"
MsgSkin:  .asciz "Skin: %s (%ld images)\n"
MsgImgLine: .asciz "  %-11s %ldx%ld\n"
MsgActive: .asciz "SkinPatch active. Use \"SkinPatch QUIT\" or Ctrl-C to stop it.\n"
MsgSent:  .asciz "Command sent to the running SkinPatch.\n"
MsgNotRunning: .asciz "SkinPatch is not running.\n"
MsgCantRemove: .asciz "SkinPatch: another program patched sysiclass later.\nRemove it first (or reboot). SkinPatch stays active.\n"
MsgSizes: .asciz "Image sizes seen (width x height):\n"
MsgDiag1: .asciz "Diagnostics: class %lx (%s), original dispatcher %lx\n"
MsgDiag2: .asciz "  messages=%ld  OM_NEW=%ld (known type %ld)  IM_DRAW=%ld\n"
MsgDiag3: .asciz "  skinned draws=%ld (found through window gadgets %ld)\n"
MsgDiag4: .asciz "  SYSIA_Which %ld created %ld times\n"
NoId:     .asciz "?"
MsgLogged: .asciz "Report written to the LOG file.\n"
MsgLog1:  .asciz "Titles skipped=%ld, title bar texts logged=%ld:\n"
MsgLog2:  .asciz "  window %lx y=%ld bar=%ld n=%ld mode=%ld skipped=%ld pen=%ld bg=%ld text='%s' title='%s'\n"
MsgQuitFail: .asciz "SkinPatch cannot be stopped now (other programs patched the system later,\nor Workbench scroll bars are in use). It stays active. Reboot to change version.\n"
	.p2align 2
StatTab:
	.long ST1, AllScreens, ST2, WBScreen, ST3, WBDri, ST4, CntAll, ST5, CntDraw
	.long ST6, CntSkinned, ST7, CntMatched, ST8, CntBars, ST9, CntMarked, ST10, CntProcess
	.long ST11, CntRpOK, ST12, CntRpGone, ST13, CntRpScreen, ST14, LastWinScr, ST15, CntTitles
	.long ST16, LastPen, ST17, LastDri, ST18, DirtyN, ST19, InUse, ST20, CntTick, ST21, TimerOK, ST22, KnClass, ST23, KnCount, ST24, CntTkCall, ST25, CntTkWB, ST26, CntTkProp, ST27, CntTkAuto, ST28, LastPFlags, ST29, LastSigTask, ST30, KnImg, ST32, CntPg, ST33, CntPgPaint, ST34, CntExtra, ST35, PgClass, ST36, CntFrNow, ST37, GaugeClass, ST38, CntGauge, ST39, CntRebind, ST40, TubePen, ST41, TubeRGB, ST42, TubeRGB+4, ST43, TubeRGB+8, ST44, CntTubeNew, ST45, DbgFrBM, ST46, DbgFrWH, ST47, DbgPix, ST48, DbgPix+4, ST49, DbgRGB, ST50, TitlePen, ST51, TitlePenW, 0
ST1:  .asciz "AllScreens        %ld\n"
ST2:  .asciz "WBScreen          %lx\n"
ST3:  .asciz "WBDri             %lx\n"
ST4:  .asciz "messages          %ld\n"
ST5:  .asciz "IM_DRAW           %ld\n"
ST6:  .asciz "skinned gadgets   %ld\n"
ST7:  .asciz "found by scan     %ld\n"
ST8:  .asciz "bars on draw      %ld\n"
ST9:  .asciz "windows marked    %ld\n"
ST10: .asciz "processed         %ld\n"
ST11: .asciz "repainted         %ld\n"
ST12: .asciz "already closed    %ld\n"
ST13: .asciz "other screen      %ld\n"
ST14: .asciz "last screen       %lx\n"
ST15: .asciz "titles drawn      %ld\n"
ST16: .asciz "last pen          %ld\n"
ST17: .asciz "last DrawInfo     %lx\n"
ST18: .asciz "pending           %ld\n"
ST19: .asciz "InUse             %ld\n"
ST20: .asciz "timer repaints    %ld\n"
ST21: .asciz "timer             %ld\n"
ST22: .asciz "knob class        %lx\n"
ST23: .asciz "scrollers skinned %ld\n"
ST24: .asciz "takeover calls    %ld\n"
ST25: .asciz "WB windows        %ld\n"
ST26: .asciz "border scrollers  %ld\n"
ST27: .asciz "with AUTOKNOB     %ld\n"
ST28: .asciz "flags PropInfo    %lx\n"
ST29: .asciz "window flags      %lx\n"
ST30: .asciz "knob image        %lx\n"
ST32: .asciz "propg renders     %ld\n"
ST33: .asciz "propg skinned     %ld\n"
ST34: .asciz "extra gadgets     %ld\n"
ST35: .asciz "propgclass        %lx\n"
ST36: .asciz "frames now        %ld\n"
ST37: .asciz "gauge class       %lx\n"
ST38: .asciz "gauge painted     %ld\n"
ST39: .asciz "screen resets     %ld\n"
ST40: .asciz "tube pen          %ld\n"
ST41: .asciz "tube red          %lx\n"
ST42: .asciz "tube green        %lx\n"
ST43: .asciz "tube blue         %lx\n"
ST44: .asciz "tube pen changes  %ld\n"
ST45: .asciz "frame bitmap      %lx\n"
ST46: .asciz "frame w/row       %lx\n"
ST47: .asciz "frame pens 0-3    %lx\n"
ST48: .asciz "frame pens 4-7    %lx\n"
ST49: .asciz "last sample rgb   %lx\n"
ST50: .asciz "black pen         %ld\n"
ST51: .asciz "white pen         %ld\n"
ST31: .asciz "task name         %s\n"
MsgBye:   .asciz "SkinPatch stopped.\n"
WBTaskName: .asciz "Workbench"
ImageClassName: .asciz "imageclass"
PropGName: .asciz "propgclass"
GadgetClassName: .asciz "gadgetclass"
ButtonGName: .asciz "buttongclass"
DopusButtonGName: .asciz "dopusbuttongclass"
	.p2align 2
KnTags:   .long 0, 0
MsgDgWin: .asciz "\nWindow: %s  %ldx%ld  borders %ld %ld %ld %ld  flags %lx\ntype flags activ   x    y    w    h sysi class\n"
MsgDgGad: .asciz "%04lx %04lx %04lx %4ld %4ld %4ld %4ld %ld %s %lx\n"

	.bss
	.p2align 2
RDArgs:        .space 4
ArgArray:      .space 24
LogFH:         .space 4
OldOut:        .space 4
ReplyPort:     .space 4
PubPort:       .space 4
AllScreens:    .space 4
FrBusy:        .space 4
FrSwap:        .space 12
CntFrNow:      .space 4
FrStack:       .space 4096
WBScreen:      .space 4
InitLock:      .space 4
ExitLock:      .space 4
SnapCur:       .space 16
SnapTmp:       .space 16
TubePen:       .space 4
TubeRGB:       .space 12
CntTubeNew:    .space 4
DbgFrBM:       .space 4
DbgFrWH:       .space 4
DbgPix:        .space 8
DbgRGB:        .space 4
CntRebind:     .space 4
WBDri:         .space 4
SysIClass:     .space 4
OrigEntry:     .space 4
OldSWT:        .space 4
OldCW:         .space 4
OldNMP:        .space 4
OldMP:         .space 4
PrefBorder:    .space 4
PgClass:       .space 4
GaugeClass:    .space 4
OldGaugeEntry: .space 4
CntGauge:      .space 4
CntPg:         .space 4
CntPgPaint:    .space 4
CntExtra:      .space 4
OldPgEntry:    .space 4
Disabled:      .space 4
BorSet:        .space 4
OrigBor:       .space 4
CntTkCall:     .space 4
CntTkWB:       .space 4
CntTkProp:     .space 4
CntTkAuto:     .space 4
LastPFlags:    .space 4
LastSigTask:   .space 4
KnImg:         .space 4
LastTName:     .space 4
KnClass:       .space 4
KnCount:       .space 4
KnSem:         .space 48
KnTab:         .space 24*32
OldText:       .space 4
LayersBase:    .space 4
MainTask:      .space 4
DirtySig:      .space 4
DirtyMask:     .space 4
DirtyN:        .space 4
DirtyList:     .space 4*16
CntTextSkip:   .space 4
CntMarked:     .space 4
CntProcess:    .space 4
CntRpOK:       .space 4
CntRpGone:     .space 4
CntRpScreen:   .space 4
CntTitles:     .space 4
LastWinScr:    .space 4
LastPen:       .space 4
LastDri:       .space 4
TitlePen:      .space 4
TitlePenW:     .space 4
TimerPort:     .space 4
TimerIO:       .space 4
TimerOK:       .space 4
TimerBusy:     .space 4
TimerMask:     .space 4
TTNext:        .space 4
CntTick:       .space 4
TitleTab:      .space 8*64
LogFlag:       .space 4
LogN:          .space 4
LogBuf:        .space 48*32
	.globl InUse
InUse:         .space 4
ObjTop:        .space 4
CntAll:        .space 4
CntNew:        .space 4
CntTracked:    .space 4
CntDraw:       .space 4
CntSkinned:    .space 4
CntMatched:    .space 4
CntBars:       .space 4
WhichCnt:      .space 4*32
CurBank:       .space 4
PrintArgs:     .space 48
CmdMsg:        .space PM_SIZE
PrefsBuf:      .space PR_SIZE
DirBuf:        .space 260
BankA:         .space BANK_SIZE
BankB:         .space BANK_SIZE
SeenTab:       .space 4*NUM_SKIN
ObjSem:        .space 48
ObjTab:        .space 8*MAX_OBJ
