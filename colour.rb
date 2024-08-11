class RGB
  attr_reader :r, :g, :b

  def initialize(r, g, b)
    @r = r
    @g = g
    @b = b
  end

  def to_hsv
    r = @r / 255.0
    g = @g / 255.0
    b = @b / 255.0

    max = [r, g, b].max
    min = [r, g, b].min
    delta = max - min

    h = 0
    if delta != 0
      if max == r
        h = 60 * (((g - b) / delta) % 6)
      elsif max == g
        h = 60 * (((b - r) / delta) + 2)
      else
        h = 60 * (((r - g) / delta) + 4)
      end
    end

    s = (max == 0 ? 0 : delta / max)
    v = max

    [h, s, v]
  end
end

class HSV
  attr_reader :h, :s, :v

  def initialize(h, s, v)
    @h = h
    @s = s
    @v = v
  end

  def to_rgb
    c = @v * @s
    x = c * (1 - ((@h / 60.0) % 2 - 1).abs)
    m = @v - c

    r, g, b = if @h >= 0 && @h < 60
                [c, x, 0]
              elsif @h >= 60 && @h < 120
                [x, c, 0]
              elsif @h >= 120 && @h < 180
                [0, c, x]
              elsif @h >= 180 && @h < 240
                [0, x, c]
              elsif @h >= 240 && @h < 300
                [x, 0, c]
              elsif @h >= 300 && @h < 360
                [c, 0, x]
              else
                [0, 0, 0]
              end

    r = ((r + m) * 255).round
    g = ((g + m) * 255).round
    b = ((b + m) * 255).round

    [r, g, b]
  end

  def to_hex
    r, g, b = to_rgb
    format("#%02X%02X%02X", r, g, b)
  end
end
