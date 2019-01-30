import Pkg

function Pkg_update()
    pkgs = readlines(joinpath(homedir(), ".julia", "REQUIRE"))
    Pkg.add(pkgs)
    Pkg.update(pkgs)
end

user = ENV["USER"]
push!(LOAD_PATH, "/home/$user/Raftaar/Backtester/")
push!(LOAD_PATH, "/home/$user/Raftaar/Yojak/src/")
push!(LOAD_PATH, "/home/$user/Raftaar/Logger/")
push!(LOAD_PATH, "/home/$user/Raftaar/API/")
push!(LOAD_PATH, "/home/$user/Raftaar/Optimizer/")
push!(LOAD_PATH, "/home/$user/Raftaar/Utilities/")
push!(LOAD_PATH, "/home/$user/Raftaar/MarketTechnicals/src")