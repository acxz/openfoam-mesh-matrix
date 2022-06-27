using Plots
using SparseArrays

#unicodeplots()
#pyplot()
plotlyjs()

function read_bt_paran(file)
    fh = open(file)

    paran_start = false
    paran_end = false
    paran_end_maybe = false
    bt_paran_str = ""
    num_cells = 0
    format_str = ""

    while !eof(fh)
        line = readline(fh, keep=true)
        if occursin("format", line)
            split_line = split(line)
            format_str = split(split_line[2], ";")[1]
        end
        if occursin("nCells", line)
            split_line = split(line)
            num_cells_str = split(split_line[3], ":")[2]
            num_cells = parse(Int32, num_cells_str)
        end
        if occursin(")\n", line)
            if format_str == "ascii"
                paran_end = true
            end
            paran_end_maybe = true
        end
        if line == "\n" && !paran_end && paran_end_maybe
            paran_end = true
            bt_paran_str = bt_paran_str[1:end-2]
        end
        if paran_start && !paran_end
            bt_paran_str = bt_paran_str * line
        end
        if occursin("(", line) && !paran_start
            paran_start = true
            if format_str == "binary"
                bt_paran_str = bt_paran_str * line[2:end]
            end
        end
    end

    close(fh)

    bt_paran_vec = Vector{Int32}()
    if format_str == "ascii"
        bt_paran_vec = parse.(Int32, split(bt_paran_str))
    end
    if format_str == "binary"
        bt_paran_uint8_vec = Vector{UInt8}(bt_paran_str)
        bt_paran_vec = reinterpret(Int32, bt_paran_uint8_vec)
    end

    bt_paran_vec = bt_paran_vec .+ 1

    return bt_paran_vec, num_cells
end

# Read in ascii with multiple values

#casedir = "sampleMeshes/polyMesh/"
#casedir = "sampleMeshes/polyMesh-bin/"
casedir = "sampleMeshes/polyMesh-comp/"

neighbour_file = casedir * "neighbour"
owner_file = casedir * "owner"

neighbour_vec, num_cells = read_bt_paran(neighbour_file)
owner_vec, _ = read_bt_paran(owner_file)

owner_vec = owner_vec[1:length(neighbour_vec)]

idx_vec = 1:num_cells

row_idx_vec = [neighbour_vec; owner_vec; idx_vec]
col_idx_vec = [owner_vec; neighbour_vec; idx_vec]

mesh_matrix = sparse(row_idx_vec, col_idx_vec, 1)
spy(mesh_matrix)
