# ==========================================
# ANYA - Terminal Companion
# ==========================================

# ------------------------------------------
# Mostrar una reacción
# ------------------------------------------

anya() {
    local estado="$1"

    case "$estado" in
        bienvenida)
            cat ~/.config/anya/bienvenida.txt
            ;;

        error)
            cat ~/.config/anya/error.txt
            ;;

        descarga)
            cat ~/.config/anya/descarga.txt
            ;;

        *)
            echo "Estado de Anya desconocido: $estado"
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

    # --------------------------------------
    # Comandos cuyo código 1 es normal
    # --------------------------------------

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

    # --------------------------------------
    # Mostrar reacción
    # --------------------------------------

    echo ""
    anya error
    echo ""
}

add-zsh-hook preexec anya_preexec
add-zsh-hook precmd anya_error


# ==========================================
# Detectar descargas con wget
# ==========================================

wget() {
    command wget "$@"
    local estado="$?"

    if [[ "$estado" -eq 0 ]]; then
        echo ""
        anya descarga
        echo ""
    fi

    return "$estado"
}
