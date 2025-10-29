#!/bin/bash


# Abilita lo script a fermarsi in caso di errore
set -euo pipefail

# --- 1. Configurazione del Benchmark ---

# Numero totale di richieste per il Test 1(a) 
TOTAL_REQUESTS=10000

# Array dei "rate" (Query Per Second) da testare per il Test 1(a) 
RATES=(25 50 75 100 150 200)

# Durata (in secondi) per i test di "rottura" 1(b)
# Usiamo una durata fissa per stressare il server
BREAKPOINT_DURATION="30s"

# Livelli di concorrenza (utenti simultanei) da testare per il Test 1(b) 
# Incrementiamo da 50 a 1000, con step di 50
CONCURRENCY_LEVELS=$(seq 50 50 1000)

# Definizioni dei server (dal tuo docker-compose.yml)
declare -A SERVERS
SERVERS["apache"]="http://localhost:8080"
SERVERS["nginx"]="http://localhost:8081"
SERVERS["litespeed"]="http://localhost:8082"

# Definizioni dei file da testare (ASSUNZIONE)
# Assicurati che questi file esistano nella tua cartella ./fileSorgenti
declare -A CONTENT
CONTENT["static"]="/index.html"  # 
CONTENT["dynamic"]="/info.php" # 

# Cartelle per i risultati
RESULTS_DIR_1A="results_test_1a"

# Crea le cartelle se non esistono
mkdir -p "$RESULTS_DIR_1A"

# Pausa in secondi tra un test e l'altro per far "raffreddare" i server
COOLDOWN=2

# --- 2. Esecuzione Test 1(a): Rate Variabile ---
# 
echo "================================================="
echo "INIZIO TEST 1(a): Rate variabile, 10k richieste"
echo "Contenuto: Statico e Dinamico" 
echo "================================================="

for content_type in "${!CONTENT[@]}"; do
    echo
    echo "--- Test Contenuto: $content_type ---"
    
    for server_name in "${!SERVERS[@]}"; do
        echo "  > Test Server: $server_name"
        
        for rate in "${RATES[@]}"; do
            TARGET_URL="${SERVERS[$server_name]}${CONTENT[$content_type]}"
            OUTPUT_FILE="${RESULTS_DIR_1A}/${server_name}_${content_type}_q${rate}.csv"
            
            echo "    -> Rate: ${rate} QPS. Output: $OUTPUT_FILE"
            
            # Esegue hey con -n (numero richieste) e -q (rate limit)
            # Salva l'output (-o) in formato csv
            hey -n "$TOTAL_REQUESTS"  -c "$rate" -q 1 -o csv "$TARGET_URL" > "$OUTPUT_FILE"
            
            echo "    -> Test completato. Pausa di $COOLDOWN secondi..."
            sleep "$COOLDOWN"
        done
    done
done

echo "================================================="
echo "TEST 1(a) COMPLETATO. Risultati in: $RESULTS_DIR_1A"
echo "================================================="
echo
echo
