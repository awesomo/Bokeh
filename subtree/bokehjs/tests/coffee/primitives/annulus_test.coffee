Collections = require('../../base').Collections
make_glyph_test = require('../testutils').make_glyph_test

xrange = Collections('Range1d').create({start: 0, end: 10})
yrange = Collections('Range1d').create({start: 0, end: 10})

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5, outer_radius:10},
    {x: 2, y: 4},
    {x: 3, y: 3, fill: 'red'},
    {x: 4, y: 2, outer_radius: 8, fill_alpha: 0.3},
    {x: 5, y: 1},
  ]
)

defaults = {
  inner_radius: 3
  inner_radius_units: 'screen'
  outer_radius_units: 'screen'
}

glyph = {
  type: 'annulus'
  fill: 'blue'
  outer_radius:
    field: 'outer_radius'
    default: 5
  x: 'x'
  y: 'y'
}

opts = {}

test('annulus_glyph', make_glyph_test('annulus_glyph', data_source, defaults, glyph, xrange, yrange, opts))

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5, line_color: 'red'},
    {x: 2, y: 4},
    {x: 3, y: 3},
    {x: 4, y: 2, line_color: '#4488ff'},
    {x: 5, y: 1},
  ]
)

glyph = {
  type: 'annulus'
  line_color: 'black'
  line_width: 2
  fill_alpha: 0.2
  outer_radius:
    field: 'outer_radius'
    default: 12
  x: 'x'
  y: 'y'
}

test('annulus_glyph_line_color', make_glyph_test('annulus_glyph_line_color', data_source, defaults, glyph, xrange, yrange, opts))

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5, outer_radius: 2},
    {x: 2, y: 4, outer_radius: 4},
    {x: 3, y: 3, outer_radius: 6},
    {x: 4, y: 2, outer_radius: 8},
    {x: 5, y: 1},
  ]
)

glyph = {
  type: 'annulus'
  line_color: 'black'
  fill_alpha: 0.5
  outer_radius:
    field: 'outer_radius'
    default: 16
  x: 'x'
  y: 'y'
}

test('annulus_glyph_outer_radius', make_glyph_test('annulus_glyph_outer_radius', data_source, defaults, glyph, xrange, yrange, opts))

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5, lwidth: 7},
    {x: 2, y: 4, lwidth: 4},
    {x: 3, y: 3},
    {x: 4, y: 2, lwidth: 2},
    {x: 5, y: 1},
  ]
)

glyph = {
  outer_radius: 10
  line_width:
    field: 'lwidth'
    default: .5
  type: 'annulus'
  fill: 'blue'
  x: 'x'
  y: 'y'
}

test('annulus_glyph_line_width', make_glyph_test('annulus_glyph_line_width', data_source, defaults, glyph, xrange, yrange, opts))

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5},
    {x: 2, y: 4, alpha: .2},
    {x: 3, y: 3, alpha: .4},
    {x: 4, y: 2, alpha: .6},
    {x: 5, y: 1, alpha: .8},
  ]
)

glyph = {
  line_width: 5
  fill_alpha: 0.2
  line_alpha:
    field: 'alpha'
    default: 0
  type: 'annulus'
  fill: 'grey'
  outer_radius: 10
  x: 'x'
  y: 'y'
}

test('annulus_glyph_line_alpha', make_glyph_test('annulus_glyph_line_alpha', data_source, defaults, glyph, xrange, yrange, opts))

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5, color: 'green'},
    {x: 2, y: 4},
    {x: 3, y: 3},
    {x: 4, y: 2, color: 'orange'},
    {x: 5, y: 1},
  ]
)

glyph = {
  type: 'annulus'
  fill:
    field: 'color'
    default: 'blue'
  outer_radius: 10
  x: 'x'
  y: 'y'
}

test('annulus_glyph_fill', make_glyph_test('annulus_glyph_fill', data_source, defaults, glyph, xrange, yrange, opts))

data_source = Collections('ObjectArrayDataSource').create(
  data: [
    {x: 1, y: 5, dash: [1,1]},
    {x: 2, y: 4},
    {x: 3, y: 3},
    {x: 4, y: 2, dash: [1,1,2,1]},
    {x: 5, y: 1},
  ]
)

glyph = {
  outer_radius: 12
  line_width: 4
  line_dash:
    field: 'dash'
    default: [2,2]
  type: 'annulus'
  fill: 'grey'
  fill_alpha: 0.2
  x: 'x'
  y: 'y'
}

test('annulus_glyph_linedash', make_glyph_test('annulus_glyph_linedash', data_source, defaults, glyph, xrange, yrange, opts))
