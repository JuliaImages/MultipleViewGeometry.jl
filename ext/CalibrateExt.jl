module CalibrateExt

using GridDetector, VideoIO
using MultipleViewGeometry

function MultipleViewGeometry.calibrate(cam)
    count = 0
    @info count "Calibrating..."
    fps = VideoIO.framerate(cam)
    while (count < 1000)
        try
            img = Gray.(read(cam))
            @info "Checkerboard size:" length(process_image(img)) 
            count = count + 1
            sleep(0.01)
        catch e
            @info e.message
            if typeof(e) <: InterruptException
                println("caught Interrupt")
                return
            end
        end
    end
end


end