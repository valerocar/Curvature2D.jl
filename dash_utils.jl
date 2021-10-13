# Html components utilities
function input_field(id, label; value="")
    html_div([dcc_input(id=id, type="text", value=value),html_span("  "*label),html_break(1)])
end

function html_break(n)
    html_div([html_br() for i = 1:n])
end

function row_div(row_data)
    html_div(className="row",[html_div(className="six columns", data) for data in row_data])
end

function load_markdown(filename)
    s = open(filename) do file
        read(file, String)
    end
    html_div(dcc_markdown(s))
end

export input_field, html_break, row_div, load_markdown