#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set page(width: auto, height: auto)

#diagram(
    spacing: 1em,
    edge-stroke: 0.1em,
    {
        let blob(pos, label, tint: white, ..args) = node(
            pos,
            align(center, label),
            width: auto,
            fill: tint.lighten(60%),
            stroke: 1pt + tint.darken(20%),
            corner-radius: 0.5em,
            inset: 0.5em,
            ..args,
        )

        let (proj, sail) = ((0, -1), (0, 0))
        blob(proj, `riscv.sail_project`, tint: purple)
        blob(sail, `*.sail`, tint: blue)
        node(enclose: (proj, sail),
            stroke: 1pt + teal.darken(20%),
            fill: teal.lighten(60%),
            inset: 0.5em,
            corner-radius: 0.5em,
            name: <sail-riscv>)
        node((<sail-riscv.north-west>, 33%, <sail-riscv.north>),
            align(top+left)[RISC-V model],
            height: 3.5em)

        let disp = 3
        let docs = (rel: (-disp, disp), to: sail)
        let schema = (rel: (disp, disp),  to: sail)
        // Enclose doesn't work with relative coordinates.
        // https://github.com/Jollywatt/typst-fletcher/issues/138
        // let model = (rel: (0, 2*disp),   to: sail)
        // let harness = (rel: (0, 2*disp + 1), to: sail)
        let model = (0, 2*disp)
        let harness = (0, 2*disp + 1)

        blob(docs, [JSON \ + \ HTML], tint: green)
        blob(schema, `sail_riscv_config_schema.json`, tint: olive)

        blob(model, `sail_riscv_model.{h,cpp}`, tint: lime)
        blob(harness, `C++ harness`, tint: blue)
        node(enclose: (model, harness),
            stroke: 1pt + teal.darken(20%),
            fill: teal.lighten(60%),
            inset: 0.5em,
            corner-radius: 0.5em,
            name: <sim>)
        node((<sim.north-west>, 33%, <sim.north>),
            align(top+left)[`sail_riscv_sim`],
            height: 3.5em)

        let config = (<sim>, "-|", schema)
        blob(config, `dut_config.json`, tint: eastern)

        let elf = (rel: (0, disp), to: model)
        blob(elf, `test.elf`, tint: orange)

        edge(<sail-riscv>, docs, "-|>")
        edge(<sail-riscv>, schema, "-|>")
        edge(<sail-riscv>, <sim>, "-|>")

        edge(schema, config, [validation], "~>")

        edge(config, <sim>, "-->", stroke: green.darken(33%))
        edge(elf, <sim>, "-->", stroke: green.darken(33%))
    }
)
