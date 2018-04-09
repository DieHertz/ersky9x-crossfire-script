array byte deviceIds[5]
array deviceTimeouts[5]
array byte receiveBuffer[64]
array byte transmitBuffer[64]
array byte deviceNames[100]

if init = 0
    init = 1
    deviceIndex = 0
    deviceCount = 0
    devicesRefreshTimeout = 0
    DEVICE_ID_BROADCAST = 0
    DEVICE_ID_RADIO_TX = 0xEA
    FRAME_POLL_DEVICES = 0x28
    FRAME_DEVICE_INFO = 0x29

    POLL_INTERVAL = 100
    DEVICE_TIMEOUT = 3000

    rem -- including terminating zero
    rem -- @todo should be 45 according to spec, change later
    kMaxDeviceNameLength = 16
    rem -- dictated by the number of device names we could fit, will be raised later
    kMaxDeviceCount = 6
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

    result = crossfirereceive(count, command, receiveBuffer)

    if result = 1
        if command = FRAME_DEVICE_INFO
            gosub parseDeviceInfo
        end
    else
        gosub pollDevices
    end

    return

pollDevices:
    let time = gettime()
    if time > devicesRefreshTimeout
        devicesRefreshTimeout = time + POLL_INTERVAL
        transmitBuffer[0] = DEVICE_ID_BROADCAST
        transmitBuffer[1] = DEVICE_ID_RADIO_TX
        result = crossfiresend(FRAME_POLL_DEVICES, 2, transmitBuffer)
    end

    return

parseDeviceInfo:
    rem -- payload format:
    rem --  uint8_t Destination node address
    rem --  uint8_t Device node address
    rem --  char[] Device name ( Null-terminated string )
    rem --  uint32_t Serial number
    rem --  uint32_t Hardware ID
    rem --  uint32_t Firmware ID
    rem --  uint8_t Parameters count
    rem --  uint8_t Parameter version number

    let id = receiveBuffer[1]
    let index = 0
    let break = 0

    while (index < deviceCount) & (id != deviceIds[index])
        index += 1
    end

    rem -- add new device
    if index = deviceCount
        if deviceCount < kMaxDeviceCount
            rem -- device fits
            deviceCount += 1
        else
            rem -- have to evict one of the devices to fit
            index -= 1
        end
    end

    rem -- fill device entry
    deviceIds[index] = id

    let nameOffset = kMaxDeviceNameLength * index
    let i = 0

    rem -- copy device name string
    rem -- @todo remove whitespace or trim the string to allow more devices in one array
    while (receiveBuffer[i + 2] != 0) & (i < kMaxDeviceNameLength - 1)
        deviceNames[nameOffset + i] = receiveBuffer[i + 2]
        i += 1
    end

    rem -- add terminating zero
    deviceNames[nameOffset + i] = 0
    deviceTimeouts[index] = gettime() + DEVICE_TIMEOUT

    return

main:
    if Event = EVT_EXIT_BREAK
        goto exit
    elseif (Event = EVT_DOWN_FIRST) | (Event = EVT_DOWN_REPT)
        gosub nextDevice
    elseif (Event = EVT_UP_FIRST) | (Event = EVT_UP_REPT)
        gosub previousDevice
    end

    drawclear()
    drawtext(0, 0, "CROSSFIRE SETUP", INVERS)

    if deviceCount > 0
        let i = 0

        while i < deviceCount
            let attr = 0
            if i = deviceIndex then attr = INVERS

            let nameOffset = kMaxDeviceNameLength * i

            drawtext(0, i * 8 + 9, deviceNames[nameOffset], attr)

            i += 1
        end
    else
        drawtext(0, 28, "Waiting for devices...")
    end

    gosub refreshNext

    stop

exit:
    finish
