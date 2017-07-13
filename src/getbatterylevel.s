.arm.little
.arm

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
    ldmfd sp!, {r1-r12,pc}

.pool
.align 4
    GetServiceHandleCommand : .word 0x50100
    GetBatteryLevelCommand  : .word 0x50000
    MCUHWCServiceName       : .dcb "mcu::HWC"
    SrvHandlePtr            : .word 0xdead0000
