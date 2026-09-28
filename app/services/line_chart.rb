# The geometry of a small line chart of values over time: where each point
# sits, the line through them, and the gridlines to read them against. It
# knows nothing about HTML or words; ChartsHelper draws it as inline SVG, so
# it renders on the server and needs no JavaScript.
#
# x is real time, not the point's index, so a month off shows as a gap. y
# doesn't start at zero: this shows change, and a squat going 140 -> 150
# would be a flat line on a zero-based axis.
class LineChart
  Point = Data.define(:date, :value, :x, :y)
  Tick = Data.define(:value, :y)

  WIDTH = 320
  HEIGHT = 190
  # Room for the value labels on the left and the date labels underneath.
  PADDING = { top: 12, right: 14, bottom: 30, left: 46 }.freeze
  # A nice step is 1, 2, 2.5 or 5 times a power of ten.
  NICE_STEPS = [ 1, 2, 2.5, 5, 10 ].freeze

  attr_reader :width, :height

  # data: [date, value] pairs, in any order.
  def initialize(data, width: WIDTH, height: HEIGHT, ticks: 4)
    @data = data.map { |date, value| [ date.to_date, value.to_f ] }.sort_by(&:first)
    @width = width
    @height = height
    @tick_target = ticks
  end

  def empty?
    @data.empty?
  end

  # A line needs two points; one is a dot, not a trend.
  def trend?
    @data.size >= 2
  end

  def size
    @data.size
  end

  def points
    @points ||= @data.map { |date, value| Point.new(date: date, value: value, x: x_for(date), y: y_for(value)) }
  end

  def first
    points.first
  end

  def last
    points.last
  end

  def min
    points.min_by(&:value)
  end

  def max
    points.max_by(&:value)
  end

  # SVG path data for the line: "M46,180L300,12".
  def path
    return if empty?

    points.each_with_index.map { |point, i| "#{i.zero? ? "M" : "L"}#{compact(point.x)},#{compact(point.y)}" }.join
  end

  # Horizontal gridlines at round values spanning the data, bottom up.
  def y_ticks
    return [] if empty?

    low, high, step = domain
    count = ((high - low) / step).round
    (0..count).map do |i|
      value = (low + i * step).round(6)
      Tick.new(value: value, y: y_for(value))
    end
  end

  def plot_left
    PADDING[:left]
  end

  def plot_right
    width - PADDING[:right]
  end

  def plot_top
    PADDING[:top]
  end

  def plot_bottom
    height - PADDING[:bottom]
  end

  private
    def x_for(date)
      span = (last_date - first_date).to_i
      # One day's data (or one point) sits in the middle.
      return ((plot_left + plot_right) / 2.0).round(1) if span.zero?

      (plot_left + (plot_right - plot_left) * (date - first_date).to_i / span.to_f).round(1)
    end

    def y_for(value)
      low, high, = domain
      (plot_bottom - (plot_bottom - plot_top) * (value - low) / (high - low)).round(1)
    end

    def first_date
      @data.first.first
    end

    def last_date
      @data.last.first
    end

    # [low, high, step]: round values just outside the data. A flat series
    # (or a single point) gets some room either side so it sits mid-chart
    # rather than on an edge.
    def domain
      @domain ||= begin
        low, high = @data.map(&:last).minmax
        if low == high
          pad = [ low.abs * 0.05, 1.0 ].max
          low -= pad
          high += pad
        end

        step = nice_step((high - low) / (@tick_target - 1))
        # The epsilon keeps float error (80.1 / 0.1 = 800.99...) from adding
        # a gridline beyond the data.
        nice_low = ((low / step) + 1e-9).floor * step
        # Weights and reps are never negative, so neither is the axis.
        nice_low = 0.0 if nice_low.negative? && low >= 0
        [ nice_low, ((high / step) - 1e-9).ceil * step, step ]
      end
    end

    # 46.0 -> "46", 91.5 -> "91.5"
    def compact(number)
      number == number.to_i ? number.to_i.to_s : number.to_s
    end

    def nice_step(raw)
      magnitude = 10.0**Math.log10(raw).floor
      NICE_STEPS.find { |step| step * magnitude >= raw - 1e-9 } * magnitude
    end
end
