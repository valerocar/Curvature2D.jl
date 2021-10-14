using Pkg
Pkg.activate(".")

using PlotlyJS
using Dash

 include("dash_utils.jl")
 include("ode.jl")

mutable struct ParametricModel
    name::String # Name for the model (e.g linear, quadratic, periodic, etc)
    formula::Function # Formula for the curvature function (depending on parameters)
    params::Vector{String} # Parameters in formula
end

mutable struct Example
    name::String
    model::ParametricModel
    param_values::Vector{Float64}
    smin::Float64
    smax::Float64
    resolution::Int64
end

# CurveData constructor for and Example
function CurveData(e::Example)
    κ_formula = e.model.formula(e.param_values...) # Evaluate model using parameter values
    CurveData(κ_formula, e.smin, e.smax)
end

# Parametric models for curvature function
linear = ParametricModel("Linear Model", (a,b)->"$a*s+$b", ["a","b"])
quadratic = ParametricModel("Quadratic Model", (a,b,c)->"$a*s^2+$b*s+$c", ["a","b","c"])
cubic = ParametricModel("Cubic Model", (a,b,c,d)->"$a*s^3+$b*s^2+$c*s+$d", ["a","b","c","d"])
periodic = ParametricModel("Periodic Model", (a,b,ω)->"$a*($b-cos($ω*s))", ["a","b","ω"])

# Examples
mpi = 3.1416 

examples_list = [
    Example("Circle", linear, [0.0,1.0], -mpi, mpi, 250),
    Example("Double Spiral", linear, [1.0,0.0], -5,5, 300),
    Example("Hair", quadratic, [1.0,0.0,1.0],-5,5,500),
    Example("Periodic", periodic,[1.4142,1.0,1.0],-5*mpi,5*mpi,1000 ),
    Example("Cross", periodic,[7/4,1.0,1.0],-5*mpi,5*mpi,1000 ),
    Example("Snail", cubic,[1.0,0.0,0.0,2.0],-2.5,2.5,500 )
]
examples = Dict(e.name => e for e in examples_list)
default_example = examples["Circle"]
cd_default = CurveData(default_example)
sol = curve_from_curvature(CurveData(default_example),n = default_example.resolution)

plot_width = 500
plot_height = 500

function plot_solution(sol)
    x = [q[1] for q in sol]
    y = [q[2] for q in sol]
    min_x = minimum(x)
    max_x = maximum(x)
    min_y = minimum(y)
    max_y = maximum(y)
    Δx = max_x - min_x
    Δy = max_y - min_y
    mx = (min_x + max_x)/2
    my = (min_y + max_y)/2
    if Δy < Δx
        min_y = my - Δx/2 
        max_y = my + Δx/2 
    else
        min_x = mx - Δy/2 
        max_x = mx + Δy/2  
    end
    
    ϵ = 0.25
    layout = Layout(xaxis_title="x", yaxis_title="y",
    xaxis_range=[min_x-ϵ,max_x+ϵ],yaxis_range=[min_y-ϵ,max_y+ϵ], title="Curve",
    width=plot_width, height=plot_height)
    plot_data =[scatter(;x=x, y=y, mode="lines", name="Solution")] 
    plot(plot_data, layout)
end

function plot_κ(cd::CurveData; sres=300)
    ss = LinRange(cd.smin,cd.smax, sres)
    κs = kappa.(ss,cd.κ_formula)
    layout = Layout(xaxis_title="arc-length", yaxis_title="curvature", title="Curvature function",
    xaxis_range=[cd.smin,cd.smax],
    width=plot_width, height=plot_height)
    plot_data =[scatter(;x=ss, y=κs, mode="lines")] 
    plot(plot_data, layout)
end


mathjax = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.4/MathJax.js?config=TeX-MML-AM_CHTML"
app = dash(external_scripts=[mathjax])
app.title = "DashCurvature"

basics = load_markdown("basics.md")
details = load_markdown("details.md")


info = html_div([
    dcc_tabs(id="tabs", value="tab-1", children=[
        dcc_tab(label="Basics", value="tab-1"),
        dcc_tab(label="Details", value="tab-2"),
    ]),
    html_div(id="tabs-content")
])

sol_plot = plot_solution(sol)
κ_plot = plot_κ(CurveData(default_example))

curve_graph = dcc_graph(id="curve_graph",figure=sol_plot)
κ_graph = dcc_graph(id="κ_graph",figure=κ_plot)
main_graph = row_div([κ_graph,curve_graph])


inputs =html_div([
    html_center(html_h4("Curvature input")),
    html_break(1),
    html_center(html_div([
    input_field("kappa",raw"$\kappa=\kappa(s)$", value = cd_default.κ_formula),
    input_field("smin", "length min", value = string(cd_default.smin)),
    input_field("smax", "length max", value = string(cd_default.smax)),
    input_field("res", "resolution", value = string(300)),
    html_button("Solve", id="solve-button", n_clicks=0),
    html_break(1)
    ]))])
 
dropdown = html_div(style=Dict("width"=>"250px"), dcc_dropdown(id="examples", options=[(label = e.name, value = e.name) for e in values(examples)], value=default_example.name))

function to_info(e::Example)
    str = "Parameter's values: "
    for (i, p) in enumerate(e.model.params)
        val = e.param_values[i]
        str = str*p*"= $val, "
    end
    str = str[1:end-2] 
    ["Parametric model: s->"*e.model.formula(e.model.params...),html_br(), str]
end


examples_control = html_div([
    dropdown,
    html_break(1),
    html_div(id="model_info", to_info(default_example)),
    html_br(),
    ])

controls = row_div([inputs, examples_control])


# App Layout
app.layout = html_div(
    [
        html_center(html_h1("Curve from Curvature")),
        html_h5(),
        basics,
        html_break(1),
        main_graph,
        html_break(1),
        controls, 
        html_break(1),
        details        
    ]
)

callback!(
    app, 
    Output("model_info","children"), 
    Output("kappa", "value"),
    Output("smin","value"), 
    Output("smax","value"),
    Output("res","value"),
    Output("solve-button","n_clicks"),
    Input("examples", "value")) do value
    e = examples[value]
    formula = e.model.formula(e.param_values...)
    cd = CurveData(formula,e.smin,e.smax)
    κ_plot = plot_κ(cd)
    return (to_info(e),formula, string(e.smin), string(e.smax), string(e.resolution),2)
end

callback!(
    app,
    Output("curve_graph", "figure"),
    Output("κ_graph", "figure"),
    Input("solve-button", "n_clicks"),
    State("kappa", "value"),
    State("smin", "value"),
    State("smax", "value"),
    State("res", "value")
) do clicks, kappa, smin, smax, res
    sminf = parse(Float64,smin)
    smaxf = parse(Float64,smax)
    resf = parse(Int64, res)
    cd = CurveData(kappa,sminf,smaxf)
    sol = curve_from_curvature(cd,n=resf)
    sol_plot = plot_solution(sol)
    κ_plot = plot_κ(cd)
    return sol_plot, κ_plot
end

run_server(app, "0.0.0.0", debug=true)