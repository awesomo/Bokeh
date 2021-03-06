base = require('../base')
Collections = base.Collections
HasParent = base.HasParent
safebind = base.safebind
build_views = base.build_views

properties = require('../renderers/properties')
text_properties = properties.text_properties

ContinuumView = require('./continuum_view').ContinuumView

LinearMapper = require('../mappers/1d/linear_mapper').LinearMapper
GridMapper = require('../mappers/2d/grid_mapper').GridMapper

ViewState = require('./view_state').ViewState

ActiveToolManager = require("../tools/active_tool_manager").ActiveToolManager


LEVELS = ['image', 'underlay', 'glyph', 'overlay', 'annotation', 'tool']

class PlotView extends ContinuumView
  events:
    "mousemove .bokeh_canvas_wrapper": "_mousemove"
    "mousedown .bokeh_canvas_wrapper": "_mousedown"

  view_options: () ->
    _.extend({plot_model: @model, plot_view: @}, @options)

  _mousedown: (e) =>
    for f in @mousedownCallbacks
      f(e, e.layerX, e.layerY)

  _mousemove: (e) =>
    for f in @moveCallbacks
      f(e, e.layerX, e.layerY)

  pause : () ->
    @is_paused = true

  unpause : (render_canvas=false) ->
    @is_paused = false
    if render_canvas
      @request_render_canvas(true)
    else
      @request_render()

  request_render : () ->
    if not @is_paused
      @throttled_render()
    return

  request_render_canvas : (full_render) ->
    if not @is_paused
      @throttled_render_canvas(full_render)
    return

  initialize: (options) ->
    # $('body').mousedown(@_mousedown)
    # $('body').mousemove(@_mousemove)
    @throttled_render = _.throttle(@render, 100)
    @throttled_render_canvas = _.throttle(@render_canvas, 100)

    @title_props = new text_properties(@, {}, 'title_')

    super(_.defaults(options, @default_options))

    @view_state = new ViewState({
      canvas_width:      options.canvas_width       ? @mget('canvas_width')
      canvas_height:     options.canvas_height      ? @mget('canvas_height')
      x_offset:          options.x_offset           ? @mget('x_offset')
      y_offset:          options.y_offset           ? @mget('y_offset')
      outer_width:       options.outer_width        ? @mget('outer_width')
      outer_height:      options.outer_height       ? @mget('outer_height')
      min_border_top:    (options.min_border_top    ? @mget('min_border_top'))    ? @mget('min_border')
      min_border_bottom: (options.min_border_bottom ? @mget('min_border_bottom')) ? @mget('min_border')
      min_border_left:   (options.min_border_left   ? @mget('min_border_left'))   ? @mget('min_border')
      min_border_right:  (options.min_border_right  ? @mget('min_border_right'))  ? @mget('min_border')
      requested_border_top: 0
      requested_border_bottom: 0
      requested_border_left: 0
      requested_border_right: 0
    })

    @x_range = options.x_range ? @mget_obj('x_range')
    @y_range = options.y_range ? @mget_obj('y_range')

    @xmapper = new LinearMapper({
      source_range: @x_range
      target_range: @view_state.get('inner_range_horizontal')
    })

    @ymapper = new LinearMapper({
      source_range: @y_range
      target_range: @view_state.get('inner_range_vertical')
    })

    @mapper = new GridMapper({
      domain_mapper: @xmapper
      codomain_mapper: @ymapper
    })

    @requested_padding = {
      top: 0
      bottom: 0
      left: 0
      right: 0
    }

    @am_rendering = false

    @renderers = {}
    @tools = {}

    @eventSink = _.extend({}, Backbone.Events)
    @moveCallbacks = []
    @mousedownCallbacks = []
    @keydownCallbacks = []
    @render_init()
    @render_canvas(false)
    @atm = new ActiveToolManager(@eventSink)
    @levels = {}
    for level in LEVELS
      @levels[level] = {}
    @build_levels()
    @request_render()
    @atm.bind_bokeh_events()
    @bind_bokeh_events()
    return this

  map_to_screen : (x, x_units, y, y_units, units) ->
    if x_units == 'screen'
      sx = x[..]
      sy = y[..]
    else
      [sx, sy] = @mapper.v_map_to_target(x, y)

    sx = @view_state.v_sx_to_device(sx)
    sy = @view_state.v_sy_to_device(sy)

    return [sx, sy]

  map_from_screen : (sx, sy, units) ->
    sx = @view_state.v_device_sx(sx[..])
    sy = @view_state.v_device_sx(sy[..])

    if units == 'screen'
      x = sx
      y = sy
    else
      [x, y] = @mapper.v_map_from_target(sx, sy)  # TODO: in-place?

    return [x, y]

  build_tools: () ->
    return build_views(@tools, @mget_obj('tools'), @view_options())


  build_views: ()->
    return build_views(@renderers, @mget_obj('renderers'), @view_options())

  build_levels: () ->
    # need to separate renderer/tool creation from event binding
    # because things like box selection overlay needs to bind events
    # on the select tool
    #
    # should only bind events on NEW views and tools
    views = @build_views()
    tools = @build_tools()
    for v in views
      level = v.mget('level')
      @levels[level][v.model.id] = v
      v.bind_bokeh_events()
    for t in tools
      level = t.mget('level')
      @levels[level][t.model.id] = t
      t.bind_bokeh_events()
    return this

  bind_bokeh_events: () ->
    safebind(this, @view_state, 'change', () =>
      @request_render_canvas()
      @request_render()
    )
    safebind(this, @x_range, 'change', @request_render)
    safebind(this, @y_range, 'change', @request_render)
    safebind(this, @model, 'change:renderers', @build_levels)
    safebind(this, @model, 'change:tool', @build_levels)
    safebind(this, @model, 'change', @request_render)
    safebind(this, @model, 'destroy', () => @remove())

  render_init: () ->
    # TODO use template
    @$el.append($("""
      <div class='button_bar btn-group'/>
      <div class='bokeh_canvas_wrapper'>
        <canvas class='bokeh_canvas'></canvas>
      </div>
      """))
    @button_bar = @$el.find('.button_bar')
    @canvas_wrapper = @$el.find('.bokeh_canvas_wrapper')
    @canvas = @$el.find('canvas.bokeh_canvas')

  render_canvas: (full_render=true) ->
    oh = @view_state.get('outer_height')
    ow = @view_state.get('outer_width')

    @button_bar.attr('style', "width:#{ow}px;")
    @canvas_wrapper.attr('style', "width:#{ow}px; height:#{oh}px")
    @canvas.attr('width', ow).attr('height', oh)
    @$el.attr("width", ow).attr('height', oh)

    @ctx = @canvas[0].getContext('2d')
    if full_render
      @render()

  save_png: () ->
    @render()
    data_uri = @canvas[0].toDataURL()
    @model.set('png', @canvas[0].toDataURL())
    base.Collections.bulksave([@model])


  save_png: () ->
    @render()
    data_uri = @canvas[0].toDataURL()
    @model.set('png', @canvas[0].toDataURL())
    base.Collections.bulksave([@model])


  render: (force) ->
    super()
    #newtime = new Date()
    # if @last_render
    #   console.log(newtime - @last_render)
    # @last_render = newtime
    # console.log('fullrender')
    @requested_padding = {
      top: 0
      bottom: 0
      left: 0
      right: 0
    }
    for level in ['image', 'underlay', 'glyph', 'overlay', 'annotation', 'tool']
      renderers = @levels[level]
      for k, v of renderers
        if v.padding_request?
          pr = v.padding_request()
          for k, v of pr
            @requested_padding[k] += v

    title = @mget('title')
    if title
      @title_props.set(@ctx, {})
      th = @ctx.measureText(@mget('title')).ascent
      @requested_padding['top'] += (th + @mget('title_standoff'))

    @is_paused = true
    for k, v of @requested_padding
      @view_state.set("requested_border_#{k}", v)
    @is_paused = false

    @ctx.fillStyle = @mget('border_fill')
    @ctx.fillRect(0, 0,  @view_state.get('canvas_width'), @view_state.get('canvas_height')) # TODO
    @ctx.fillStyle = @mget('background_fill')
    @ctx.fillRect(
      @view_state.get('border_left'), @view_state.get('border_top'),
      @view_state.get('inner_width'), @view_state.get('inner_height'),
    )

    @ctx.save()

    @ctx.beginPath()
    @ctx.rect(
      @view_state.get('border_left'), @view_state.get('border_top'),
      @view_state.get('inner_width'), @view_state.get('inner_height'),
    )
    @ctx.clip()
    @ctx.beginPath()

    for level in ['image', 'underlay', 'glyph']
      renderers = @levels[level]
      for k, v of renderers
        v.render()

    @ctx.restore()

    for level in ['overlay', 'annotation', 'tool']
      renderers = @levels[level]
      for k, v of renderers
        v.render()

    if title
      sx = @view_state.get('outer_width')/2
      sy = th
      @title_props.set(@ctx, {})
      @ctx.fillText(title, sx, sy)



class PNGView extends ContinuumView

  initialize: (options) ->
    super(options)
    @thumb_x = options.thumb_x or 40
    @thumb_y = options.thumb_y or 40
    @render()
    return this

  render: () ->
    png = @model.get('png')
    @$el.append($("<img  modeltype='#{@model.type}' modelid='#{@model.get('id')}' class='pngview' width='#{@thumb_x}'  height='#{@thumb_y}'  src='#{png}'/>"))

class Plot extends HasParent
  type: 'Plot'
  #default_view: PNGView
  default_view: PlotView

  add_renderers: (new_renderers) ->
    renderers = @get('renderers')
    renderers = renderers.concat(new_renderers)
    @set('renderers', renderers)

  parent_properties: [
    'background_fill',
    'border_fill',
    'canvas_width',
    'canvas_height',
    'outer_width',
    'outer_height',
    'min_border',
    'min_border_top',
    'min_border_bottom'
    'min_border_left'
    'min_border_right'
  ]

Plot::defaults = _.clone(Plot::defaults)
_.extend(Plot::defaults , {
  'data_sources': {},
  'renderers': [],
  'tools': [],
  'title': 'Plot',
})

Plot::display_defaults = _.clone(Plot::display_defaults)
_.extend(Plot::display_defaults
  ,
    background_fill: "#fff",
    border_fill: "#eee",
    min_border: 40,
    x_offset: 0,
    y_offset: 0,
    canvas_width: 300,
    canvas_height: 300,
    outer_width: 300,
    outer_height: 300,

    title_standoff: 8,
    title_text_font: "helvetica",
    title_text_font_size: "20pt",
    title_text_font_style: "normal",
    title_text_color: "#444444",
    title_text_alpha: 1.0,
    title_text_align: "center",
    title_text_baseline: "alphabetic"
)

class Plots extends Backbone.Collection
   model: Plot


exports.Plot = Plot
exports.PlotView = PlotView
exports.PNGView = PNGView
exports.plots = new Plots
