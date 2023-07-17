using PaperOracle
using Documenter

DocMeta.setdocmeta!(PaperOracle, :DocTestSetup, :(using PaperOracle); recursive=true)

makedocs(;
    modules=[PaperOracle],
    authors="Jarvist Moore Frost",
    repo="https://github.com/Frost-group/PaperOracle.jl/blob/{commit}{path}#{line}",
    sitename="PaperOracle.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Frost-group.github.io/PaperOracle.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Frost-group/PaperOracle.jl",
    devbranch="main",
)
