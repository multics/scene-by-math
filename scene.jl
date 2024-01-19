using Plots
plotly(size=(3200, 1300))

deci(x) = x - trunc(x)
norm1(a, b, x) = min(1.0, max(0.0, (x - a) / (b - a)))
norm2(a, b, x) = (x - a) / (b - a)
smoothstep(a, b, x) = 3 * norm2(a, b, x) * norm2(a, b, x) - 2 * norm2(a, b, x) * norm2(a, b, x) * norm2(a, b, x)
s1(x) = smoothstep(0, 1, x)

function a(i, j)
  uu = 50.0 * deci(i / pi)
  vv = 50.0 * deci(j / pi)
  return 2 * deci(uu * vv * (uu + vv)) - 1
end

function N(p)
  x, y = p
  i = floor(x)
  j = floor(y)
  return a(i, j) + (a(i + 1, j) - a(i, j)) * s1(x - i) + (a(i, j + 1) - a(i, j)) * s1(y - j) + (a(i, j) - a(i + 1, j) - a(i, j + 1) + a(i + 1, j + 1)) * s1(x - i) * s1(y - j)
end

function F(x, y)
  M = [0.8 -0.6; 0.6 0.8]
  p = [x; y]
  r = N(p)
  for i in 1:20
    r += N(2^i * M^i * p) / (2^i)
  end

  return r
end

xs = 0:0.1:200
ys = xs
# zs = N.([xs; ys])

# surface(xs, ys, (x, y) -> N([x; y]), xlims=(0, 100), ylims=(0, 100), zlims=(-2, 100), showaxis=false, show=true)
# surface(xs, ys, (x, y) -> N([x; y]), xlims=(0, 200), ylims=(0, 200), zlims=(-1, 200), showaxis=false, show=true)
surface(xs, ys, F, xlims=(0, 200), ylims=(0, 200), zlims=(-1, 200), showaxis=false, show=true)

# readline()
