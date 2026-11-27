set terminal pdfcairo size 7in,5in
set output "plots/ota_tran.pdf"
set multiplot layout 2,1 title "OTA conductual | Respuesta al escalón"
set grid
set xrange [0:30]
set xlabel "Tiempo (µs)"
set ylabel "Entrada diferencial (µV)"
plot "results/ota_tran.txt" using ($1*1e6):(($2-$3)*1e6) with lines lw 2 lc rgb "#00796b" notitle
set ylabel "Salida (mV)"
plot "results/ota_tran.txt" using ($1*1e6):($4*1e3) with lines lw 2 lc rgb "#245fa1" notitle
unset multiplot
