# Data used for curve construction from curvature function
mutable struct CurveData
    κ_formula::String
    # Initial position
    x0::Float64
    y0::Float64
    # Initial orientation
    θ0::Float64
    # arc-length range
    smin::Float64
    smax::Float64
end

# Constructor for default values of initial position and orientation
CurveData(κ_formula::String, smin::Float64,smax::Float64) = CurveData(κ_formula,0.0,0.0,0.0,smin,smax)

# evaluate curvature function from string formula
function kappa(s::Float64, formula::String)
    ex = quote
        s = $s
        "formula here"
    end
    ex.args[4] = Meta.parse(formula::String)
    eval(ex)
end


# Second order ODE (as first order ODE) to construct curve from curvature
function kappa_field_from_formula(κ_formula)
    function f(q,s)
        x = q[1]
        y = q[2]
        tx = q[3]
        ty = q[4]
        κ_val = kappa(s,κ_formula)
        [tx,ty,-κ_val*ty,κ_val*tx]
    end
    f
end

# Obtain curve by integrating differential equation using RK4
function curve_from_curvature(cd::CurveData; n = 250)
    f = kappa_field_from_formula(cd.κ_formula)
    h = (cd.smax-cd.smin)/n # length step
    k1 = zeros(4)
    k2 = zeros(4)
    k3 = zeros(4)
    k4 = zeros(4)
    # Setting Initial conditions
    qs = [zeros(4) for i = 1:(n+1)]
    qs[1] = [cd.x0,cd.y0,cos(cd.θ0),sin(cd.θ0)]
    s = cd.smin
    for i = 2:(n+1)
        q = qs[i-1]
        k1 = f(q,s)
        k2 = f(q + (h/2.0)*k1,s)
        k3 = f(q + (h/2.0)*k2,s)
        k4 = f(q + h*k3,s)
        qs[i] = q + (h/6.0)*(k1 + 2*k2 +2*k3 + k4)
        s = s + h
    end
    qs
end
