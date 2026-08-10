# ==========================================
#        TERMINAL MASCOT - ANYA
# ==========================================

mascota() {
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
            echo "Estado de mascota desconocido: $estado"
            ;;
    esac
}


# ==========================================
# Detectar errores de comandos
# ==========================================

autoload -Uz add-zsh-hook

mascota_error() {
    local estado="$?"

    if [[ "$estado" -ne 0 ]]; then
        echo ""
        mascota error
        echo ""
    fi
}

add-zsh-hook precmd mascota_error


# ==========================================
# Detectar descargas con wget
# ==========================================

wget() {
    command wget "$@"
    local estado="$?"

    if [[ "$estado" -eq 0 ]]; then
        echo ""
        mascota descarga
        echo ""
    fi

    return "$estado"
}
