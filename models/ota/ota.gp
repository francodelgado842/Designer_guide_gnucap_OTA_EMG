set terminal pdfcairo size 7in,4in
set output "plots/ota_ac.pdf"
set logscale x
set grid
set xlabel "Frecuencia (Hz)"
set ylabel "Ganancia (dB)"
set title "OTA conductual en lazo abierto"
plot "results/ota_ac.txt" using 1:(20*log10($2)) with lines lw 2 title "Ganancia"
