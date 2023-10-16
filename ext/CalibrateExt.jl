module CalibrateExt

using GridDetector, VideoIO, GLMakie
using MultipleViewGeometry

function MultipleViewGeometry.detect_boards(device; save=false, draw=false)
    cam = VideoIO.opencamera("video=" * device)

    count = 0
    @info count "Calibrating..."
    fps = VideoIO.framerate(cam)
    images = []
    corners = []

    if (draw == true)
        fig = Figure(size=(1000, 700), title="Stereo View")
        ax = GLMakie.Axis(
            fig[1, 1],
            aspect=DataAspect(),
            title="Image",
        )

        img = Gray.(read(cam))
        node = Observable(rotr90(img))
        image!(ax, node)
    end

    display(fig)
    try
        while (count < 9)
            try
                img = Gray.(read(cam))

                # @info "Info:" cam.flush cam.finished cam.bits_per_result_pixel cam.frame_queue
                res = find_checkerboard(img)

                if (length(res) == 63)
                    @info "Checkerboard size:" length(res)
                    push!(images, img)
                    push!(corners, res)
                    if (draw == true)
                        draw_rect(img, res, Gray(1))
                        node[] = rotr90(img)
                    end
                    count = count + 1
                    sleep(0.5)
                else
                    if (draw == true)
                        node[] = rotr90(img)
                    end
                    sleep(0.01)
                end
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


function get_normalization_matrix(pts, name="A")
	pts = Float64.(pts)
	x_mean, y_mean = mean(pts, dims=1)
	var_x, var_y = var(pts, dims=1;corrected=false)

	s_x , s_y = sqrt(2/var_x), sqrt(2/var_y)
	
	# println("Matrix: $(name) : meanx $(x_mean) , meany $(y_mean) , varx $(var_x) , vary $(var_y) , sx $(s_x) , sy $(s_y)")

	n = [s_x 0 -s_x*x_mean;0 s_y -s_y*y_mean; 0 0 1]
	# print(n)

	n_inv = [(1 ./ s_x) 0 x_mean; 0 (1 ./ s_y) y_mean;0 0 1]

	
	# @info "N:" n n_inv
	return Float64.(n), Float64.(n_inv)
end
	
function normalize_points(cords)
	views = size(cords)[1]

	ret_correspondences = [] 
    for i in 1:views
        imp, objp = chessboard_correspondences[i,:]
        N_x, N_x_inv = get_normalization_matrix(objp, "A")
        N_u, N_u_inv = get_normalization_matrix(imp, "B")
		val = ones(Float64,(54,1))
		
		normalized_hom_imp = hcat(imp, val)
        normalized_hom_objp = hcat(objp, val)

		for i in 1:size(normalized_hom_objp)[1]
			n_o = N_x * normalized_hom_objp[i,:]
            normalized_hom_objp[i,:] = n_o/n_o[end]

            n_u = N_u * normalized_hom_imp[i,:] 
            normalized_hom_imp[i,:]  = n_u/n_u[end]
		end

		normalized_objp =  normalized_hom_objp
		normalized_imp =  normalized_hom_imp
		push!(ret_correspondences, (imp, objp, normalized_imp, normalized_objp, N_u, N_x, N_u_inv, N_x_inv))
	end
	return ret_correspondences
end

function model(X, h)
    # @show X length(X)
    # @show h
    N = trunc(Int, length(X) / 2)
    x_j = reshape(X, (2, N))'
    # @info "x_j:" x_j
    projected = zeros(2*N)
    
    for j in 1:N
        x, y = x_j[j,:]
        w = h[7]*x + h[8]*y + h[9]
        projected[(2*j) - 1] = (h[1] * x + h[2] * y + h[3]) / w
        projected[2*j] = (h[4] * x + h[5] * y + h[6]) / w
    end
    # @info "Projected:" projected length(projected)
    return projected
end

function jac_function(X, h)
    N = trunc(Int, length(X) /2)
    # @show N
    x_j = reshape(X , (2, N))'
    jacobian = zeros(Float64, (2*N, 9))
    for j in 1:N
        x, y = x_j[j,:]
        sx = Float64(h[1]*x + h[2]*y + h[3])
        sy = Float64(h[4]*x + h[5]*y + h[6])
        w = Float64(h[7]*x + h[8]*y + h[9])
        jacobian[(2*j) - 1,:] = [x/w, y/w, 1/w, 0, 0, 0, -sx*x/w^2, -sx*y/w^2, -sx/w^2]
        jacobian[2*j,:] = [0, 0, 0, x/w, y/w, 1/w, -sy*x/w^2, -sy*y/w^2, -sy/w^2]
    end

    # @info "Jacobian:" jacobian length(jacobian)
    return jacobian
end
    
function refine_homographies(H, correspondence; skip=false)
    if skip
        return H
    end

    image_points = correspondence[1]
    object_points = correspondence[2]
    normalized_image_points = correspondence[3]
    normalized_object_points = correspondence[4]
    # N_u = correspondence[5]
    N_x = correspondence[6]
    N_u_inv = correspondence[7]
    N_x_inv = correspondence[8]
    
    N = size(normalized_object_points)[1]
    X = Float64.(collect(flatten(object_points')))
    Y = Float64.(collect(flatten(image_points')))
    h = collect(flatten(H'))
    # @show h
    # @show det(H)

    # @info "data:" X Y h

    fit = curve_fit(model, jac_function, Float64.(X), Float64.(Y), h;)

    if fit.converged
        H =  reshape(fit.param,  (3, 3))
    end
    H = H/H[3, 3]
    
    return H
end

function get_intrinsic_parameters(H_r)
    M = length(H_r)
    V = zeros(Float64, (2*M, 6))

    function v_pq(p, q, H)
        v = [
                H[1, p]*H[1, q] 
                (H[1, p]*H[2, q] + H[2, p]*H[1, q]) 
                H[2, p]*H[2, q] 
                (H[3, p]*H[1, q] + H[1, p]*H[3, q]) 
                (H[3, p]*H[2, q] + H[2, p]*H[3, q]) 
                H[3, p]*H[3, q]
            ]
        return v
	end 

    for i in 1:M
        H = H_r[i]
        V[(2*i)-1,:] = v_pq(1, 2, H)
        V[2*i,:] = v_pq(1,1, H) .- v_pq(2, 2, H)
	end 

    # solve V.b = 0
    u, s, vh = svd(V)
    # print(u, "\n", s, "\n", vh)
	# @info u
    b = vh[:,findmin(s)[2]]
	@info size(u) size(s) size(vh)
    print("V.b = 0 Solution : ", b)

    # according to zhangs method
    vc = (b[2]*b[4] - b[1]*b[5])/(b[1]*b[3] - b[2]^2)
    l = b[6] - (b[4]^2 + vc*(b[2]*b[3] - b[1]*b[5]))/b[1]
    alpha = sqrt((l/b[1]))
    beta = sqrt((l*b[1])/(b[1]*b[3] - b[2]^2))
    gamma = -1*((b[2])*(alpha^2) *(beta/l))
    uc = (gamma*vc/beta) - (b[4]*(alpha^2)/l)

    A = [ alpha gamma uc;
          0 beta vc;
            0 0 1.0;
        ]
    return A, b
end


function MultipleViewGeometry.calibrate(correspondences)
    correspondences_normalized = normalize_points(correspondences)
    
    H = []
	for correspondence in correspondences_normalized
	    push!(H, compute_view_based_homography(correspondence; reproj=0))
	end

    H_r = []

	for i in 1:length(H)
		# @info "Input Homography:" H[i]
	    h_opt = refine_homographies(H[i], chessboard_correspondences_normalized[i]; skip=false)
		# @info h_opt
	    # push!(H_r, h_opt')
		# @info "Refined Homography:" h_opt
		push!(H_r, h_opt')
	end  
    
    res = get_intrinsic_parameters(H_r)
end




end