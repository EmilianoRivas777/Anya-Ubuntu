# ==========================================
# ANYA - Terminal Companion
# ==========================================

# Directorio principal de Anya
ANYA_DIR="$HOME/.config/anya"

# ==========================================
# Establecer estado de Anya
# ==========================================

anya_set_estado() {
    local estado="$1"
    local archivo="$2"

    local expresion
    local mensaje

    case "$estado" in

        normal)
            expresion="normal"
            mensaje="¿Eh? ¿Qué harás?"
            ;;

        sorpresa)
            expresion="sorpresa"
            mensaje="¿Eh...? Algo salió mal..."
            ;;

        descarga)
            expresion="feliz2"
            mensaje="¡Descarga terminada: $archivo!"
            ;;

        *)
            return 1
            ;;
    esac

    printf '%s\n' "$expresion" \
        > "$HOME/.config/anya/estado/expresion.txt"

    printf '%s\n' "$mensaje" \
        > "$HOME/.config/anya/estado/mensaje.txt"
}

# ==========================================
# Mostrar una reacción
# ==========================================

anya() {
    local estado="$1"

    case "$estado" in
        bienvenida)
	    anya_mostrar "feliz" "¡Hola, Emiliano! ♡"
            cat "$ANYA_DIR/bienvenida.txt"
            ;;

	error)
    	   anya_mostrar "sorpresa" "¿Eh...? Algo salió mal..."
    	   cat "$ANYA_DIR/error.txt"
    	   ;;
	descarga)
   	    local archivo="$2"
            anya_mostrar "feliz2" "¡Descarga terminada! $archivo"
    	    awk -v archivo="$archivo" '{gsub(/\{\{archivo\}\}/, archivo); print}' "$ANYA_DIR/descarga.txt"
    	    ;;;

        *)
            echo "Estado de Anya desconocido: $estado"
            return 1
            ;;
    esac
}


# ==========================================
# Gestionar eventos
# ==========================================

anya_event() {
    local evento="$1"

    case "$evento" in
        bienvenida)
            anya bienvenida
            ;;

        error)
            anya error
            ;;

        descarga)
            anya descarga "$2"
            ;;

        *)
            echo "Evento de Anya desconocido: $evento"
            return 1
            ;;
    esac
}


# ==========================================
# Detectar comandos ejecutados
# ==========================================

autoload -Uz add-zsh-hook

ANYA_LAST_COMMAND=""

anya_preexec() {
    ANYA_LAST_COMMAND="$1"
    anya_set_estado normal

}

# ==========================================
# Detectar errores reales
# ==========================================

anya_error() {
    local estado="$?"
    local comando="$ANYA_LAST_COMMAND"

    # El comando terminó correctamente
    [[ "$estado" -eq 0 ]] && return

    # Ctrl+C no es un error
    [[ "$estado" -eq 130 ]] && return
	# Los comandos internos de Anya no generan
	# una reacción de error adicional
	if [[ "$comando" == anya_event\ * || "$comando" == anya\ * ]]; then
    return
	fi

    # grep:
    # 0 = encontró coincidencias
    # 1 = no encontró coincidencias
    # 2 = error real
    if [[ "$comando" == grep\ * && "$estado" -eq 1 ]]; then
        return
    fi

    # ripgrep:
    # 0 = encontró coincidencias
    # 1 = no encontró coincidencias
    # 2+ = error
    if [[ "$comando" == rg\ * && "$estado" -eq 1 ]]; then
        return
    fi

    echo ""

    builtin printf '%s\n' "sorpresa" > "$HOME/.config/anya/estado/expresion.txt"
    builtin printf '%s\n' "¿Eh...? Algo salió mal..." > "$HOME/.config/anya/estado/mensaje.txt"

    anya_event error

    echo ""
}

add-zsh-hook preexec anya_preexec
add-zsh-hook precmd anya_error

# ==========================================
# Detectar archivos nuevos o modificados
# ==========================================

anya_snapshot() {
    find . -maxdepth 1 -type f -printf '%T@ %p\n' | sort
}

anya_detectar_cambios() {
    local antes="$1"
    local despues="$2"

    local cambios

    cambios=$(comm -13 "$antes" "$despues")

    if [[ -n "$cambios" ]]; then
        echo "$cambios" | sed 's/^[0-9.]* //' | sed 's|^\./||'
    fi
}


# ==========================================
# Detectar descargas con wget
# ==========================================
wget() {
    local archivo=""
    local estado

    # Detectar archivo indicado explícitamente
    local i=1

    while (( i <= $# )); do
        case "${@[$i]}" in
            -O)
                (( i++ ))
                archivo="${@[$i]}"
                ;;
            -O*)
                archivo="${@[$i]#-O}"
                ;;
            --output-document=*)
                archivo="${@[$i]#--output-document=}"
                ;;
            --output-document)
                (( i++ ))
                archivo="${@[$i]}"
                ;;
        esac

        (( i++ ))
    done

    # Crear snapshots solamente si wget no indica
    # explícitamente el nombre del archivo
    local snapshot_antes=""
    local snapshot_despues=""

    if [[ -z "$archivo" ]]; then
        snapshot_antes=$(mktemp)
        anya_snapshot > "$snapshot_antes"
    fi

    # Ejecutar wget real
    command wget "$@"
    estado="$?"

    # Solo continuar si wget terminó correctamente
    if [[ "$estado" -eq 0 ]]; then

        # ------------------------------------------
        # Caso 1: sabemos directamente el archivo
        # ------------------------------------------

        if [[ -n "$archivo" ]]; then
            echo ""
            anya_set_estado descarga "$archivo"
            echo ""

        # ------------------------------------------
        # Caso 2: wget eligió automáticamente el nombre
        # ------------------------------------------

        else
            snapshot_despues=$(mktemp)
            anya_snapshot > "$snapshot_despues"

            local archivo_nuevo
            archivo_nuevo=$(anya_detectar_cambios \
                "$snapshot_antes" \
                "$snapshot_despues"
            )

            if [[ -n "$archivo_nuevo" ]]; then
                echo ""
                anya_set_estado descarga "$archivo_nuevo"
                echo ""
            fi

            rm -f "$snapshot_antes" "$snapshot_despues"
        fi
    fi

    return "$estado"
}
# ============================================================
# Estado persistente de Anya
# ============================================================

anya_mostrar() {
    local expresion="$1"
    local mensaje="$2"

    [[ -z "$expresion" ]] && expresion="normal"
    [[ -z "$mensaje" ]] && mensaje="¡Waku waku! ✦ Emiliano, sigo aquí contigo ♡"

    printf '%s\n' "$mensaje" > "$HOME/.config/anya/estado/mensaje.txt"
    printf '%s\n' "$expresion" > "$HOME/.config/anya/estado/expresion.txt"
}

# ==========================================
# Conversación con Anya / OpenAI
# ==========================================

Anya() {
    # Comprobar que recibimos un mensaje
    if [[ $# -eq 0 ]]; then
        echo 'Uso: Anya mensaje'
        return 1
    fi

    # Ejecutar el cerebro de Anya
    "$ANYA_DIR/venv/bin/python" \
        "$ANYA_DIR/anya.py" \
        "$@" > /dev/null
}
# Evitar que Zsh interprete ?, *, [] y otros comodines
# dentro de los mensajes enviados a Anya.
alias Anya='noglob Anya'
