.arm.little
.arm

getBatteryLevel:
    stmfd sp!, {r1-r12,lr}

    mov r5, r0 ; cache # calls

    load r0, BatteryCachePtr
    ldr r0, [r0]
    mov r1, r0, lsl 16 ; counter
    mov r1, r1, lsr 16
    mov r2, r0, lsr 16 ; cached value

    cmp r1, 0
    beq getBatteryLevel_update

    mov r0, r2
    b getBatteryLevel_out

getBatteryLevel_update:
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

    ldrb r6, [r11, 0x08] ; out = cmdbuf[2]

    mov r0, r10
    _svc 0x23 ; svcCloseHandle(mcuhwcHandle)
    mov r0, r6

    b getBatteryLevel_out

getBatteryLevel_err:
    mov r0, r10
    _svc 0x23 ; svcCloseHandle(mcuhwcHandle)
    mov r0, 0

getBatteryLevel_out:
    load r1, BatteryCachePtr
    ldr r1, [r1]
    mov r2, r1, lsl 16 ; counter
    mov r2, r2, lsr 16

    add r2, r2, 1
    cmp r2, r5
    movge r2, 0

    mov r4, r2
    orr r4, r4, r0, lsl 16
    load r1, BatteryCachePtr
    str r4, [r1]

    ldmfd sp!, {r1-r12,pc}

.pool
.align 4
    GetServiceHandleCommand : .word 0x50100
    GetBatteryLevelCommand  : .word 0x50000
    MCUHWCServiceName       : .dcb "mcu::HWC"
    SrvHandlePtr            : .word 0xdead0000
    BatteryCachePtr         : .word 0xdead0001
