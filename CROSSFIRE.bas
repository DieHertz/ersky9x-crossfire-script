array byte deviceIds[16]
array deviceTimeouts[16]
if init = 0
    init = 1
    deviceIndex = 0
    deviceCount = 0
end

goto main

previousDevice:
    if deviceCount > 0 then deviceIndex = (deviceIndex - 1 + deviceCount) % deviceCount
    return

nextDevice:
    if deviceCount > 0 then deviceIndex = (deviceIndex + 1) % deviceCount
    return

refreshNext:
    deviceCount = 4
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
            drawtext(0, i * 8 + 9, "CRSF device present", attr)
            i += 1
        end
    else
        drawtext(0, 28, "Waiting for crossfire devices...")
    end

    gosub refreshNext

    stop

exit:
    finish
