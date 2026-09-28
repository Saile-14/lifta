module ChartsHelper
  # Draws a LineChart as inline SVG. It scales to its container's width, so
  # it fits a phone, and takes its colours from the palette in CSS.
  #
  # WCAG 1.1.1: role="img" makes the chart one image to assistive technology,
  # named by its <title> and described by its <desc>, which should say what
  # the chart shows in words. The table it was drawn from sits beside it.
  def line_chart(chart, id:, title:, description:)
    tag.svg(class: "chart", viewBox: "0 0 #{chart.width} #{chart.height}", role: "img",
      aria: { labelledby: "#{id}-title", describedby: "#{id}-desc" }, id: id) do
      safe_join([
        tag.title(title, id: "#{id}-title"),
        tag.desc(description, id: "#{id}-desc"),
        chart_grid(chart),
        chart_date_labels(chart),
        tag.path(class: "chart__line", d: chart.path),
        chart_markers(chart)
      ])
    end
  end

  # A value as the chart's tables and gridlines show it: "142.5", "17".
  def chart_number(value)
    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  private
    def chart_grid(chart)
      tag.g(class: "chart__grid") do
        safe_join(chart.y_ticks.map do |tick|
          safe_join([
            tag.line(x1: chart.plot_left, x2: chart.plot_right, y1: tick.y, y2: tick.y),
            content_tag(:text, chart_number(tick.value), x: chart.plot_left - 6, y: tick.y, dy: "0.35em",
              "text-anchor": "end", class: "chart__label")
          ])
        end)
      end
    end

    # Just the first and last dates: long enough dates ("2026年9月18日") that
    # any more would collide at phone width, and the table has the rest.
    def chart_date_labels(chart)
      y = chart.plot_bottom + 20
      safe_join([
        content_tag(:text, format_date(chart.first.date), x: chart.first.x, y: y, "text-anchor": "start",
          class: "chart__label"),
        content_tag(:text, format_date(chart.last.date), x: chart.last.x, y: y, "text-anchor": "end",
          class: "chart__label")
      ])
    end

    # A dot per day while there's room for them; past that the line alone
    # reads better, with the latest point still marked. Each dot's <title> is
    # a native tooltip for mouse users.
    def chart_markers(chart)
      points = chart.size <= 30 ? chart.points : [ chart.last ]
      safe_join(points.map do |point|
        tag.circle(class: "chart__point", cx: point.x, cy: point.y, r: 4) do
          tag.title("#{format_date(point.date)}: #{chart_number(point.value)}")
        end
      end)
    end
end
