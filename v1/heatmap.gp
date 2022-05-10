# set term pngcairo size 1050 ,680 font "Times,12"
# set output "ball.png"
set size ratio -1


set datafile separator ','
# set title 'ball position'

set arrow from 0,-34 to 0,34 nohead lw 1
set object 1 rectangle from -52.5,-34 to 52.5,34 lw 1
set object 2 circle at 0,0 size 9.15 fillcolor rgb "black" lw 1
set object 3 circle at -52.5+11.0,0 size 9.15 arc [-53:53] fillcolor rgb "black" lw 1
set object 4 circle at -52.5+11.0,0 front size 9.13 arc [-54:54] fc rgb 'white'
set object 5 circle at 52.5-11.0,0 size 9.15 arc [-53+180:53+180] fillcolor rgb "black" lw 1
set object 6 circle at 52.5-11.0,0 front size 9.13 arc [-54+180:54+180] fc rgb 'white'
set object 7 rectangle from -52.5,-20.16 to -52.5+16.5,20.16 lw 1
set object 8 rectangle from 52.5-16.5,-20.16 to 52.5,20.16 lw 1
set object 9 rectangle from -52.5,-9.16 to -52.5+5.5,9.16 lw 1
set object 10 rectangle from 52.5-5.5,-9.16 to 52.5,9.16 lw 1
set object 11 circle at -52.5+11.0,0 size 0.1
set object 12 circle at 52.5-11.0,0 size 0.1
set object 13 rectangle from -52.5-2.44,-7.01 to -52.5,7.01 lw 10 fc rgb 'black'
set object 14 rectangle from 52.5,-7.01 to 52.5+2.44,7.01 lw 10 fc rgb 'black'

set xrange [-52.5-5:52.5+5]
set yrange [-34.0-5:34.0+5]

plot "/dev/stdin" using 1:2 with dot
