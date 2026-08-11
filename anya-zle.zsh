# ~/.config/anya/anya-zle-test.zsh

# ============================================================
# Anya para ZLE
# ============================================================
# ============================================================
# Estado de Anya para ZLE
# ============================================================

ANYA_ZLE_ESTADO="$HOME/.config/anya/estado"

anya_zle() {
    # --------------------------------------------------------
    # Configuración
    # --------------------------------------------------------

local nombre='✦ Anya'
local estado_dir="$HOME/.config/anya/estado"

local mensaje
local expresion

mensaje="$(< "$estado_dir/mensaje.txt")"
expresion="$(< "$estado_dir/expresion.txt")"

local ascii_dir="$HOME/.config/anya/ascii"
local ascii_file="$ascii_dir/${expresion}.txt"
if [[ ! -f "$ascii_file" ]]; then
    ascii_file="$ascii_dir/normal.txt"
fi

    # Ancho de la terminal
    local terminal_width=${COLUMNS:-80}

    # Ancho máximo del panel
    local ancho=58

    # Nunca superar el ancho de la terminal
    local max_ancho=$(( terminal_width - 4 ))

    (( ancho > max_ancho )) && ancho=$max_ancho

    # Mínimo razonable
    (( ancho < 30 )) && ancho=30

    # --------------------------------------------------------
    # Espacio interior
    #
    # ╭────────────╮
    # │ contenido  │
    # ╰────────────╯
    #
    # ancho incluye los dos bordes.
    # --------------------------------------------------------

    local interior=$(( ancho - 2 ))
    local texto_ancho=$(( interior - 2 ))


    # --------------------------------------------------------
    # Función local para crear una línea con padding
    # --------------------------------------------------------

    local rellenar

    rellenar() {
        local texto="$1"
        local objetivo="$2"

        local longitud=${#texto}
        local espacios=$(( objetivo - longitud ))

        (( espacios < 0 )) && espacios=0

        printf '%s%*s' "$texto" "$espacios" ''
    }

# ============================================================
# Control de Anya
# ============================================================

anya_mostrar() {
    local expresion="${1:-normal}"
    local mensaje="${2:-¡Waku waku! ✦}"

    mkdir -p "$ANYA_ZLE_ESTADO"

    printf '%s\n' "$mensaje" > "$ANYA_ZLE_ESTADO/mensaje.txt"
    printf '%s\n' "$expresion" > "$ANYA_ZLE_ESTADO/expresion.txt"
}
    # --------------------------------------------------------
    # Construir panel
    # --------------------------------------------------------

    local panel=""
    local i

    # Borde superior
    panel+='╭'

    for (( i = 0; i < interior; i++ )); do
        panel+='─'
    done

    panel+='╮'
    panel+=$'\n'


    # --------------------------------------------------------
    # Título
    # --------------------------------------------------------

    panel+='│ '

    panel+="$(rellenar "$nombre" "$texto_ancho")"

    panel+=' │'
    panel+=$'\n'


    # --------------------------------------------------------
    # Línea vacía
    # --------------------------------------------------------

    panel+='│ '

    panel+="$(rellenar '' "$texto_ancho")"

    panel+=' │'
    panel+=$'\n'


    # --------------------------------------------------------
    # Wrap del mensaje
    # --------------------------------------------------------

    local -a palabras
    local palabra
    local linea=""

    # ${(z)...} separa respetando palabras de zsh.
    palabras=(${(z)mensaje})

    for palabra in "${palabras[@]}"; do

        if [[ -z "$linea" ]]; then
            linea="$palabra"

        elif (( ${#linea} + ${#palabra} + 1 <= texto_ancho )); then
            linea+=" $palabra"

        else
            panel+='│ '
            panel+="$(rellenar "$linea" "$texto_ancho")"
            panel+=' │'
            panel+=$'\n'

            linea="$palabra"
        fi
    done

    # Última línea
    if [[ -n "$linea" ]]; then
        panel+='│ '
        panel+="$(rellenar "$linea" "$texto_ancho")"
        panel+=' │'
        panel+=$'\n'
    fi


    # --------------------------------------------------------
    # Línea vacía inferior
    # --------------------------------------------------------

    panel+='│ '

    panel+="$(rellenar '' "$texto_ancho")"

    panel+=' │'
    panel+=$'\n'


    # --------------------------------------------------------
    # Borde inferior
    # --------------------------------------------------------

    panel+='╰'

    for (( i = 0; i < interior; i++ )); do
        panel+='─'
    done

    panel+='╯'


    # --------------------------------------------------------
    # Mostrar mediante ZLE
    # --------------------------------------------------------
zle -M "$panel"
# ============================================================
# Seleccionar expresión de Anya
# ============================================================

local expression="$(< "$ANYA_ZLE_ESTADO/expresion.txt")"
local imagen_file="$HOME/.config/anya/ascii/${expression}.txt"

# Si la expresión no existe, volver a normal
if [[ ! -f "$imagen_file" ]]; then
    imagen_file="$HOME/.config/anya/ascii/normal.txt"
fi

# --------------------------------------------------------
# Cargar imagen ASCII
# --------------------------------------------------------

local -a imagen_lineas
imagen_lineas=("${(@f)$(<"$imagen_file")}")


# --------------------------------------------------------
# Convertir panel en líneas
# --------------------------------------------------------

local -a panel_lineas
panel_lineas=("${(@f)panel}")


# --------------------------------------------------------
# Calcular ancho de la imagen
# --------------------------------------------------------

local imagen_ancho=0
local linea

for linea in "${imagen_lineas[@]}"; do
    (( ${#linea} > imagen_ancho )) && imagen_ancho=${#linea}
done


# --------------------------------------------------------
# Separación entre imagen y panel
# --------------------------------------------------------

local separacion="   "


# --------------------------------------------------------
# Combinar imagen + panel
# --------------------------------------------------------

local escena=""
local total_lineas
local izquierda
local derecha

if (( ${#imagen_lineas[@]} > ${#panel_lineas[@]} )); then
    total_lineas=${#imagen_lineas[@]}
else
    total_lineas=${#panel_lineas[@]}
fi

for (( i = 1; i <= total_lineas; i++ )); do

    if (( i <= ${#imagen_lineas[@]} )); then
        izquierda="${imagen_lineas[$i]}"
    else
        izquierda=""
    fi

    if (( i <= ${#panel_lineas[@]} )); then
        derecha="${panel_lineas[$i]}"
    else
        derecha=""
    fi

    izquierda="$(rellenar "$izquierda" "$imagen_ancho")"

    escena+="$izquierda$separacion$derecha"

    if (( i < total_lineas )); then
        escena+=$'\n'
    fi
done


# --------------------------------------------------------
# Mostrar mediante ZLE
# --------------------------------------------------------

zle -M "$escena"
}


# Registrar widget
zle -N anya_zle

# Mostrar Anya cada vez que ZLE inicia una nueva línea
zle-line-init() {
    anya_zle
}

zle -N zle-line-init
