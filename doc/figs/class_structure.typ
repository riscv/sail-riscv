#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#set page(width: auto, height: auto)

#diagram(
  spacing: 1em,
  edge-stroke: 0.1em,
  {
    let blob(pos, label, tint: white, ..args) = node(
      pos,
      align(center, label),
      width: 16em,
      height: 4em,
      fill: tint.lighten(60%),
      stroke: 1pt + tint.darken(20%),
      corner-radius: 0.5em,
      inset: 0.5em,
      ..args,
    )

    let disp = 3
    let (impl, model, intf) = ((0, 0), (0, disp), (0, 2 * disp))

    blob(
      impl,
      [`ModelImpl` \ (`riscv_model_impl.{h,cpp}`)],
      tint: yellow,
      name: <impl>,
    )
    node(
      <impl.north>,
      align(top + center)[Actual callback implementations],
      height: 3.5em,
    )

    blob(
      model,
      [`hart::Model` \ (`sail_riscv_model.{h,cpp}`)],
      tint: green,
      name: <model>,
    )
    edge(<model>, <impl>, "-|>", stroke: blue.lighten(33%))

    blob(
      intf,
      [`PlatformInterface` \ (`riscv_platform_if.{h,cpp}`)],
      tint: yellow,
      name: <intf>,
    )
    node(
      <intf.south>,
      align(bottom + center)[Hand-written "nop" callback implementations],
      height: 3.5em,
    )
    edge(<intf>, <model>, "-|>", stroke: blue.lighten(33%))

    edge(
      <model.east>,
      <intf.east>,
      "-|>",
      [Sail code calls platform callback],
      bend: 90deg,
      label-side: left,
    )
    edge(
      <intf.west>,
      <impl.west>,
      "-|>",
      [Virtual function delegation],
      bend: 90deg,
      label-side: left,
    )

    // legend
    let legend_blob(
      pos,
      msg,
      blob_label,
      msg_label,
      is_node: true,
      tint: white,
      ..args,
    ) = {
      node(
        (pos.at(0) + 1, pos.at(1)),
        align(left, msg),
        name: msg_label,
        width: 10em, // as wide as widest label
      )
      if is_node {
        node(
          pos,
          [],
          width: 2em,
          height: 2em,
          fill: tint.lighten(60%),
          stroke: 1pt + tint.darken(20%),
          corner-radius: 0.5em,
          name: blob_label,
          ..args,
        )
      } else {
        let inset = 0.35
        let edge_shift = 0.15
        let sep = 0.2
        let A = (pos.at(0) + edge_shift / 2, pos.at(1) + inset)
        node(A, [A])
        let B = (pos.at(0) + edge_shift / 2, pos.at(1) - inset)
        node(B, [B])
        edge(A, B, "-|>", shift: edge_shift, stroke: blue.lighten(33%))
      }
    }
    let (hand, sail, inherits) = (
      (2 * disp, -2 * disp),
      (2 * disp, -2 * disp + 1),
      (2 * disp, -2 * disp + 2),
    )
    legend_blob(
      hand,
      "Hand written",
      <hand>,
      <hand_label>,
      is_node: true,
      tint: yellow,
    )
    legend_blob(
      sail,
      "Generated from Sail",
      <sail>,
      <sail_label>,
      is_node: true,
      tint: green,
    )
    legend_blob(
      inherits,
      "B inherits from A",
      <inherits>,
      <inherits_label>,
      is_node: false,
    )
    node(
      hand, // ignored
      enclose: (<hand>, <hand_label>, <sail>, <sail_label>, <inherits_label>),
      stroke: 1pt,
      name: <legend>,
    )
  },
)
