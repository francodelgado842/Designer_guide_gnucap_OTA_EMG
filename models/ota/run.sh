#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [[ ! -f ota.so || ota.vams -nt ota.so || build.sh -nt ota.so ]]; then
    bash build.sh
fi

simulator=${GNUCAP:-gnucap}
plotter=${GNUPLOT:-gnuplot}
outputs=(results/ota_dc.txt results/ota_ac.txt results/ota_tran.txt)
log=results/ota_run.log

mkdir -p results
rm -f -- "${outputs[@]}"
if ! "$simulator" ota_tb.gc </dev/null >"$log" 2>&1; then
    cat "$log" >&2
    exit 1
fi
for result in "${outputs[@]}"; do
    if [[ ! -s "$result" ]] || ! awk 'NR > 1 && NF > 1 { found=1; exit } END { exit !found }' "$result"; then
        printf 'No se generaron datos en %s. Revisa %s.\n' "$result" "$log" >&2
        tail -n 20 "$log" >&2
        exit 1
    fi
done
printf 'Resultados: %s\n' "${outputs[*]}"

if command -v "$plotter" >/dev/null 2>&1; then
    mkdir -p plots
    "$plotter" ota.gp
    "$plotter" ota_tran.gp
    echo 'Gráficas: plots/ota_ac.pdf y plots/ota_tran.pdf'
fi
