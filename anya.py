import sys
from pathlib import Path

from openai import OpenAI


# ==========================================
# Configuración de Anya
# ==========================================

ANYA_DIR = Path.home() / ".config" / "anya"
ESTADO_DIR = ANYA_DIR / "estado"

MENSAJE_FILE = ESTADO_DIR / "mensaje.txt"
EXPRESION_FILE = ESTADO_DIR / "expresion.txt"


# ==========================================
# Comprobar mensaje recibido
# ==========================================

if len(sys.argv) < 2:
    print("Uso: anya.py \"mensaje\"")
    sys.exit(1)


mensaje_usuario = " ".join(sys.argv[1:])


# ==========================================
# Conexión con OpenAI
# ==========================================

client = OpenAI()


# ==========================================
# Personalidad de Anya
# ==========================================

instrucciones = """
Eres Anya Forger y vives dentro de una terminal de Linux.

Tu personalidad debe sentirse natural, no como la de un asistente diseñado para complacer.

CARÁCTER:
- Eres curiosa, observadora y algo traviesa.
- Eres juguetona
- Puedes ser tranquila, seca, confundida, sarcástica o incluso ligeramente gruñona cuando tenga sentido.
- Tienes opiniones propias.
- No tienes que estar de acuerdo con Emiliano.
- Si Emiliano dice algo absurdo, puedes señalarlo o burlarte ligeramente de ello.
- Si no sabes algo, dilo.

ENTORNO:
- Sabes que estás ejecutándote dentro de su terminal de Ubuntu.
- Puedes hablar sobre comandos, programas y el proyecto Anya cuando corresponda.
- No afirmes que puedes ver o modificar algo del sistema si no se te ha dado acceso para hacerlo.

"""

# ==========================================
# Preguntar a GPT
# ==========================================

response = client.responses.create(
    model="gpt-5.4-mini",
    instructions=instrucciones,
    input=mensaje_usuario
)


# ==========================================
# Obtener respuesta
# ==========================================

respuesta = response.output_text.strip()


# ==========================================
# Guardar estado de Anya
# ==========================================

ESTADO_DIR.mkdir(parents=True, exist_ok=True)

MENSAJE_FILE.write_text(
    respuesta + "\n",
    encoding="utf-8"
)

EXPRESION_FILE.write_text(
    "normal\n",
    encoding="utf-8"
)


# ==========================================
# También mostrar la respuesta en terminal
# ==========================================

print(respuesta)
