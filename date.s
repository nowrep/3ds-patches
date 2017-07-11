.arm.little
.create "date.bin", 0

.macro addr, reg, func
    add reg, pc, #func-.-8
.endmacro
.macro load, reg, func
    ldr reg, [pc, #func-.-8]
.endmacro
.macro _svc, num
    .word 0xEF000000 + num
.endmacro

.arm
_start:

    mov r3, 0 ; restore overwritten instruction

    stmfd sp!, {r0-r12,lr}
    add r12, sp, 14 * 0x4 ; get old SP

    bl getBatteryLevel

    cmp r0, 0
    beq zerobat

    load r4, Prefix
    str r4, [r12, 0x10]

    cmp r0, 100
    bge fullbat

    mov r6, 0
loop:
    cmp r0, 10
    blt outloop
    sub r0, r0, 10
    add r6, r6, 1
    b loop
outloop:
    cmp r6, 0
    addne r6, r6, 0x30
    addeq r6, r6, 0x20
    add r0, r0, 0x30
    orr r6, r6, r0, lsl 16

    str r6, [r12, 0x10 + 4]

    load r4, PercentSign
    str r4, [r12, 0x10 + 8]
    mov r4, 0
    str r4, [r12, 0x10 + 12]

    b outf

zerobat:
    load r4, SMErrorMessage
    str r4, [r12, 0x10]
    load r4, SMErrorMessage + 4
    str r4, [r12, 0x10 + 4]
    load r4, SMErrorMessage + 8
    str r4, [r12, 0x10 + 8]
    load r4, SMErrorMessage + 12
    str r4, [r12, 0x10 + 12]
    mov r4, 0
    str r4, [r12, 0x10 + 16]

    b outf

fullbat:
    load r4, FullBatteryMessage
    str r4, [r12, 0x10 + 4]
    load r4, FullBatteryMessage + 4
    str r4, [r12, 0x10 + 8]
    mov r4, 0
    str r4, [r12, 0x10 + 12]

outf:
    ldmfd sp!, {r0-r12,pc}

; END _start

getBatteryLevel:
    stmfd sp!, {r1-r12,lr}

    mov r10, 0 ; r10 = mcuhwcHandle
    mrc p15, 0, r0, c13, c0, 3
    add r11, r0, 0x80 ; r11 = thread command buffer

    load r0, GetServiceHandleCommand
    str r0, [r11, 0x00] ; cmdbuff[0] = GetServiceHandleCommand
    load r0, MCUHWCServiceName
    str r0, [r11, 0x04] ; cmdbuff[1] = "mcu:"
    load r0, MCUHWCServiceName + 4
    str r0, [r11, 0x08] ; cmdbuff[2] = ":HWC"
    mov r0, 0x8
    str r0, [r11, 0x0C] ; cmdbuff[3] = 0x8
    mov r0, 0
    str r0, [r11, 0x10] ; cmdbuff[4] = 0x0

    load r0, SrvHandlePtr
    ldr r0, [r0]
    _svc 0x32 ; svcSendSyncRequest(srvHandle)
    cmp r0, 0
    blt getBatteryLevel_err

    ldr r9, [r11, 0x04] ; mcuhwcHandle = cmdbuff[3]
    ldr r10, [r11, 0x0C] ; mcuhwcHandle = cmdbuff[3]

    load r0, GetBatteryLevelCommand
    str r0, [r11, 0x00] ; cmdbuff[0] = GetBatteryLevelCommand

    mov r0, r10
    _svc 0x32 ; svcSendSyncRequest(mcuhwcHandle)
    cmp r0, 0
    blt getBatteryLevel_err

    ldrb r6, [r11, 0x08] ; return cmdbuf[2]

    mov r0, r10
    _svc 0x23 ; svcCloseHandle(mcuhwcHandle)
    mov r0, r6

    b getBatteryLevel_out

getBatteryLevel_err:
    mov r0, r10
    _svc 0x23 ; svcCloseHandle(mcuhwcHandle)
    mov r0, 0

getBatteryLevel_out:
    ldmfd sp!, {r1-r12,pc}

; END getBatteryLevel

.pool
.align 4
    GetServiceHandleCommand : .word 0x50100
    GetBatteryLevelCommand  : .word 0x50000
    MCUHWCServiceName       : .dcb "mcu::HWC"
    SMErrorMessage          : .dcb "S", 0, "M", 0, \
                                   " ", 0, "F", 0, \
                                   "a", 0, "i", 0, \
                                   "l", 0,  0,  0
    FullBatteryMessage      : .dcb "1", 0, "0", 0, \
                                   "0", 0, ":", 0
    PercentSign             : .dcb ":", 0,  0 , 0
    Prefix                  : .dcb " ", 0, ":", 0
    SrvHandlePtr            : .word 0xdead0000
.close
