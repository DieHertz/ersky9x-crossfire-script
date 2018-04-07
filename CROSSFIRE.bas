array byte deviceIds[16]
array deviceTimeouts[16]
array byte receiveBuffer[64]
array byte transmitBuffer[64]
if init = 0
    init = 1
    deviceIndex = 0
    deviceCount = 0
    devicesRefreshTimeout = 0
    CROSSFIRE_COMMAND_GET_DEVICES = 0x28
    CROSSFIRE_COMMAND_DEVICE_INFO = 0x29
end

goto main

previousDevice:
    if deviceCount > 0 then deviceIndex = (deviceIndex - 1 + deviceCount) % deviceCount
    return

nextDevice:
    if deviceCount > 0 then deviceIndex = (deviceIndex + 1) % deviceCount
    return

refreshNext:
    let command = 0
    let count = 0
    result = crossfirereceive(command, count, receiveBuffer[0])

    if result = 0
        gosub pollDevices
    else
        if command = CROSSFIRE_COMMAND_DEVICE_INFO
            gosub parseDeviceInfo
        else
            gosub parseDeviceInfo
        end
    end

    return

pollDevices:
    let time = gettime()
    if time > devicesRefreshTimeout
        devicesRefreshTimeout = time + 100
        transmitBuffer[0] = 0x00
        transmitBuffer[1] = 0xEA
        crossfiresend(CROSSFIRE_COMMAND_GET_DEVICES, 2, transmitBuffer[0])
    end

    return

parseDeviceInfo:
    if deviceCount < 6 then deviceCount += 1
    return

main:
    if Event = EVT_EXIT_BREAK
        goto exit
    elseif Event = EVT_DOWN_FIRST
        gosub nextDevice
    elseif Event = EVT_DOWN_REPT
        gosub nextDevice
    elseif Event = EVT_UP_FIRST
        gosub previousDevice
    elseif Event = EVT_UP_REPT
        gosub previousDevice
    end

    drawclear()
    drawtext(0, 0, "CROSSFIRE SETUP", INVERS)

    if deviceCount > 0
        let i = 0
        while i < deviceCount
            let attr = 0
            if i = deviceIndex then attr = INVERS
            drawtext(0, i * 8 + 9, "CRSF device", attr)
            i += 1
        end
    else
        drawtext(0, 28, "Waiting for devices...")
    end

    gosub refreshNext

    stop

exit:
    finish
