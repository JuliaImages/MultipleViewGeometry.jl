using VideoIO, FFMPEG
using GLMakie

function stereo_setup()
    devices = []
	append!(devices, VideoIO.get_camera_devices(FFMPEG, "dshow", "dummy"))
    cam1 = VideoIO.opencamera("video=" * devices[4])
    cam2 = VideoIO.opencamera("video=" * devices[6])
    return cam1, cam2
end


function show_output(cam2, cam1)
    fig = Figure(size = (1000, 700), title = "Stereo View")
    ax = GLMakie.Axis(
        fig[1, 1],
        aspect = DataAspect(),
        title = "Left",
    )
    ax2 = GLMakie.Axis(
        fig[1, 2],
        aspect = DataAspect(),
        title = "Right",
    )
    img1 = read(cam1)
    img2 = read(cam2)
    node1 = Observable(rotr90(img1))
    node2 = Observable(rotr90(img2))
    makieimg1 = image!(ax, node1)
    makieimg2 = image!(ax2, node2)
    
    fps = VideoIO.framerate(cam1)

    display(fig)
    while isopen(cam1) && isopen(cam2) && !eof(cam1) && !eof(cam2)
        img1 = read(cam1)
        img2 = read(cam2)

        node1[] = rotr90(img1)
        node2[] = rotr90(img2)
        sleep(1 / fps)
    end
end
