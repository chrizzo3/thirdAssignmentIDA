# Abilita lo script a fermarsi in caso di errore
set -eu

# Definizioni delle cartelle e file di output
RESULTS_DIR_1A="results_test_1a"
RESULTS_DIR_1B="results_test_1b"

SUMMARY_FILE_1A="summary_test_1a.csv"
SUMMARY_FILE_1B="summary_test_1b.csv"

# --- 1. Analisi Test 1(a): Rate Variabile ---

echo "================================================="
echo "INIZIO ANALISI TEST 1(a) (Rate Variabile)"
echo "Cartella: $RESULTS_DIR_1A"
echo "Output: $SUMMARY_FILE_1A"
echo "================================================="

# Crea l'intestazione per il file CSV di riepilogo
echo "server,content_type,rate,avg_response_time_s,error_count" > "$SUMMARY_FILE_1A"

# Controlla se la cartella dei risultati esiste
if [ ! -d "$RESULTS_DIR_1A" ]; then
    echo "ERRORE: Cartella $RESULTS_DIR_1A non trovata."
    exit 1
fi

# Cicla su tutti i file CSV nella cartella
for file in "$RESULTS_DIR_1A"/*.csv; do
    if [ ! -f "$file" ]; then continue; fi

    # Estrae le informazioni dal nome del file
    # Es: apache_static_q25.csv
    basename=$(basename "$file" .csv)
    server=$(echo "$basename" | cut -d_ -f1)
    content_type=$(echo "$basename" | cut -d_ -f2)
    rate_str=$(echo "$basename" | cut -d_ -f3)
    rate=${rate_str//q/} # Rimuove la 'q' -> "25"

    echo "  -> Analisi: $basename"

    # Processa il file CSV con awk
    # I file CSV di 'hey' hanno 8 colonne
    # 1: response-time, 7: status, 8: error
    stats=$(awk '
        BEGIN {
            FS=","
            total_time = 0
            error_count = 0
        }
        # Salta la riga di intestazione
        NR > 1 {
            # Somma il tempo di risposta (colonna 1)
            total_time += $1

            # Controlla se la colonna 8 (error) non è vuota
            # O se la colonna 7 (status) non è "200"
            if ($8 != "" || $7 != "200") {
                error_count++
            }
        }
        END {
            # (NR-1) è il numero totale di righe (esclusa intestazione)
            if ((NR-1) > 0) {
                avg_time = total_time / (NR-1)
                print avg_time "," error_count
            } else {
                print "0,0" # File vuoto o solo intestazione
            }
        }
    ' "$file")

    avg_time=$(echo "$stats" | cut -d, -f1)
    error_count=$(echo "$stats" | cut -d, -f2)

    # Scrive i risultati aggregati nel file di riepilogo
    echo "$server,$content_type,$rate,$avg_time,$error_count" >> "$SUMMARY_FILE_1A"
done

echo "================================================="
echo "ANALISI TEST 1(a) COMPLETATA."
echo


# --- 2. Analisi Test 1(b): Punto di Rottura ---

echo "================================================="
echo "INIZIO ANALISI TEST 1(b) (Punto di Rottura)"
echo "Cartella: $RESULTS_DIR_1B"
echo "Output: $SUMMARY_FILE_1B"
echo "================================================="

# Crea l'intestazione per il file CSV di riepilogo
echo "server,content_type,concurrency,avg_response_time_s,error_count" > "$SUMMARY_FILE_1B"

# Controlla se la cartella dei risultati esiste
if [ ! -d "$RESULTS_DIR_1B" ]; then
    echo "ERRORE: Cartella $RESULTS_DIR_1B non trovata."
    echo "Hai eseguito lo script autoRun_1b.sh?"
    exit 1
fi

# Cicla su tutti i file CSV nella cartella
for file in "$RESULTS_DIR_1B"/*.csv; do
    if [ ! -f "$file" ]; then continue; fi

    # Estrae le informazioni dal nome del file
    # Es: apache_static_c50.csv
    basename=$(basename "$file" .csv)
    server=$(echo "$basename" | cut -d_ -f1)
    content_type=$(echo "$basename" | cut -d_ -f2)
    concurrency_str=$(echo "$basename" | cut -d_ -f3)
    concurrency=${concurrency_str//c/} # Rimuove la 'c' -> "50"

    echo "  -> Analisi: $basename"

    # Usa lo stesso identico comando awk di prima
    stats=$(awk '
        BEGIN {
            FS=","
            total_time = 0
            error_count = 0
        }
        NR > 1 {
            total_time += $1
            if ($8 != "" || $7 != "200") {
                error_count++
            }
        }
        END {
            if ((NR-1) > 0) {
                avg_time = total_time / (NR-1)
                print avg_time "," error_count
            } else {
                print "0,0"
            }
        }
    ' "$file")

    avg_time=$(echo "$stats" | cut -d, -f1)
    error_count=$(echo "$stats" | cut -d, -f2)

    # Scrive i risultati aggregati nel file di riepilogo
    echo "$server,$content_type,$concurrency,$avg_time,$error_count" >> "$SUMMARY_FILE_1B"
done

echo "================================================="
echo "ANALISI TEST 1(b) COMPLETATA."
echo
echo "Script terminato. I file di riepilogo sono:"
echo "1. $SUMMARY_FILE_1A"
echo "2. $SUMMARY_FILE_1B"
echo "================================================="
