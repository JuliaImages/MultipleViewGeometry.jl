module CalibrateExt

using GridDetector, VideoIO
using MultipleViewGeometry

function MultipleViewGeometry.calibrate(device;save=false)
    cam = VideoIO.opencamera("video=" * device)
    
    count = 0
    @info count "Calibrating..."
    fps = VideoIO.framerate(cam)
    images = []
    corners = []
    
    try
        while (count < 9)
            try
                img = Gray.(read(cam))
                cam.flush  = true

                # @info "Info:" cam.flush cam.finished cam.bits_per_result_pixel cam.frame_queue
                res = find_checkerboard(img) 

                if (length(res) == 63)
                    @info "Checkerboard size:" length(res) 
                    push!(images, img)
                    push!(corners, res)
                    count = count + 1
                    sleep(0.5)
                else
                    sleep(0.01)
                end  

                cam.flush = false
            catch e
                @info e.message
                if typeof(e) <: InterruptException
                    println("caught Interrupt")
                    return
                end
            end
        end

        if (save == true)
            for i in 1:9                                                                                                                          
                save("image-$i.jpg", images[i])                                                                                                   
            end
        end

        @info "Images:" length(images) 
    finally
        close(cam)
    end
    
    return images, corners
end


end