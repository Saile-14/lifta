require "rails_helper"

RSpec.describe LineChart do
  let(:left) { LineChart::PADDING[:left] }
  let(:right) { LineChart::WIDTH - LineChart::PADDING[:right] }
  let(:top) { LineChart::PADDING[:top] }
  let(:bottom) { LineChart::HEIGHT - LineChart::PADDING[:bottom] }

  describe "with no data" do
    subject(:chart) { described_class.new([]) }

    it "is empty, with nothing to draw" do
      expect(chart).to be_empty
      expect(chart).not_to be_trend
      expect(chart.points).to eq([])
      expect(chart.path).to be_nil
      expect(chart.y_ticks).to eq([])
    end
  end

  describe "with a single point" do
    subject(:chart) { described_class.new([ [ Date.new(2026, 9, 1), 100 ] ]) }

    it "is not a trend" do
      expect(chart).not_to be_empty
      expect(chart).not_to be_trend
    end

    it "sits in the middle rather than on an edge" do
      point = chart.points.first
      expect(point.x).to eq((left + right) / 2.0)
      expect(point.y).to be_between(top, bottom).exclusive
      expect(chart.y_ticks.first.value).to be < 100
      expect(chart.y_ticks.last.value).to be > 100
    end
  end

  describe "with a series" do
    subject(:chart) do
      described_class.new([
        [ Date.new(2026, 1, 11), 120 ],
        [ Date.new(2026, 1, 1), 100 ],
        [ Date.new(2026, 1, 21), 140 ]
      ])
    end

    it "sorts the points by date" do
      expect(chart.points.map(&:value)).to eq([ 100, 120, 140 ])
      expect(chart.first.date).to eq(Date.new(2026, 1, 1))
      expect(chart.last.date).to eq(Date.new(2026, 1, 21))
    end

    it "spans the plot width by date" do
      expect(chart.points.map(&:x)).to eq([ left, (left + right) / 2.0, right ])
    end

    it "spaces x by time, not by index" do
      chart = described_class.new([ [ Date.new(2026, 1, 1), 1 ], [ Date.new(2026, 1, 2), 2 ], [ Date.new(2026, 1, 11), 3 ] ])

      expect(chart.points[1].x).to eq((left + (right - left) / 10.0).round(1))
    end

    it "puts gridlines at round values spanning the data" do
      expect(chart.y_ticks.map(&:value)).to eq([ 100, 120, 140 ])
    end

    it "puts higher values higher up, the extremes on the plot edges" do
      ys = chart.points.map(&:y)
      expect(ys).to eq(ys.sort.reverse)
      expect(ys.first).to eq(bottom)
      expect(ys.last).to eq(top)
    end

    it "draws one line through every point" do
      expect(chart.path).to eq("M#{left},#{bottom}L#{(left + right) / 2},#{(top + bottom) / 2}L#{right},#{top}")
    end

    it "knows its lowest and highest points" do
      expect(chart.min.value).to eq(100)
      expect(chart.max.value).to eq(140)
    end
  end

  it "doesn't start the axis at zero" do
    chart = described_class.new([ [ Date.new(2026, 1, 1), 142.5 ], [ Date.new(2026, 2, 1), 147.5 ] ])

    expect(chart.y_ticks.first.value).to be >= 140
    expect(chart.y_ticks.last.value).to be <= 150
  end

  it "never takes the axis below zero for positive values" do
    chart = described_class.new([ [ Date.new(2026, 1, 1), 1 ], [ Date.new(2026, 2, 1), 30 ] ])

    expect(chart.y_ticks.first.value).to eq(0)
  end

  it "handles fractional steps" do
    chart = described_class.new([ [ Date.new(2026, 1, 1), 80.1 ], [ Date.new(2026, 2, 1), 80.4 ] ])

    expect(chart.y_ticks.map(&:value)).to eq([ 80.1, 80.2, 80.3, 80.4 ])
  end

  it "gives a flat series room above and below" do
    chart = described_class.new([ [ Date.new(2026, 1, 1), 80 ], [ Date.new(2026, 2, 1), 80 ] ])

    expect(chart.points.map(&:y).uniq.size).to eq(1)
    expect(chart.points.first.y).to be_between(top, bottom).exclusive
  end

  it "scales to the size it's given" do
    chart = described_class.new([ [ Date.new(2026, 1, 1), 1 ], [ Date.new(2026, 2, 1), 2 ] ], width: 600, height: 300)

    expect(chart.last.x).to eq(600 - LineChart::PADDING[:right])
    expect(chart.first.y).to eq(300 - LineChart::PADDING[:bottom])
  end
end
