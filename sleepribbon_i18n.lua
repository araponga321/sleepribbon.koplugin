-- SleepRibbon lightweight localization.
-- English is the source language and universal fallback.
-- Portuguese (Brazil) is also used for Portuguese (Portugal) for now.

local M = {}

local PT = {
    ["Styles KOReader's native sleep-screen Banner with configurable typography, colors, spacing, and a reading-progress bar."] = "Estiliza a Faixa nativa da tela de descanso do KOReader com tipografia, cores, espaçamento e barra de progresso configuráveis.",
    ["SleepRibbon preview"] = "Prévia do SleepRibbon",
    ["Tap anywhere to close"] = "Toque em qualquer lugar para fechar",
    ["Use interface font"] = "Usar fonte da interface",
    ["Follow KOReader's current UI content font. If the UI font changes, SleepRibbon follows it automatically."] = "Usa a fonte atual de conteúdo da interface do KOReader. Se a fonte da interface mudar, o SleepRibbon acompanha automaticamente.",
    ["Preview current font"] = "Pré-visualizar fonte atual",
    ["No fonts were discovered"] = "Nenhuma fonte foi encontrada",
    ["unavailable; using interface font"] = "indisponível; usando a fonte da interface",
    ["SleepRibbon font list refreshed"] = "Lista de fontes do SleepRibbon atualizada",
    ["The font list could not be refreshed. KOReader's existing font cache will be used until the next restart."] = "Não foi possível atualizar a lista de fontes. O cache de fontes atual do KOReader será usado até a próxima reinicialização.",
    ["Enabled"] = "Ativado",
    ["Profile"] = "Perfil",
    ["Global"] = "Global",
    ["Current book"] = "Livro atual",
    ["Sleep screen message"] = "Mensagem da tela de descanso",
    ["Message"] = "Mensagem",
    ["Position"] = "Posição",
    ["Opacity"] = "Opacidade",
    ["Text"] = "Texto",
    ["Maintenance"] = "Manutenção",
    ["Restore global defaults"] = "Restaurar padrões globais",
    ["Reset current book profile"] = "Redefinir perfil do livro atual",
    ["Restore global SleepRibbon defaults?"] = "Restaurar os padrões globais do SleepRibbon?",
    ["Reset the current book profile and inherit global settings?"] = "Redefinir o perfil do livro atual e voltar a herdar as configurações globais?",
    ["Global SleepRibbon defaults restored"] = "Padrões globais do SleepRibbon restaurados",
    ["Current book profile reset"] = "Perfil do livro atual redefinido",
    ["Configures and styles KOReader's native sleep-screen Banner, with optional per-book profiles."] = "Configura e estiliza a Faixa nativa da tela de descanso do KOReader, com perfis opcionais por livro.",
    ["Preview"] = "Prévia",
    ["Font"] = "Fonte",
    ["Font size"] = "Tamanho da fonte",
    ["Text color"] = "Cor do texto",
    ["Text alignment"] = "Alinhamento do texto",
    ["Left"] = "Esquerda",
    ["Center"] = "Centralizado",
    ["Right"] = "Direita",
    ["Horizontal padding"] = "Margem horizontal",
    ["Background"] = "Fundo",
    ["Background color"] = "Cor do fundo",
    ["Ribbon vertical padding"] = "Margem vertical da faixa",
    ["Progress bar"] = "Barra de progresso",
    ["Bar position"] = "Posição da barra",
    ["Top"] = "Acima",
    ["Bottom"] = "Abaixo",
    ["Progress display"] = "Exibição do progresso",
    ["Completed only"] = "Somente concluído",
    ["Completed + remaining"] = "Concluído + restante",
    ["Bar thickness"] = "Espessura da barra",
    ["Completed progress color"] = "Cor do progresso concluído",
    ["Remaining progress color"] = "Cor do progresso restante",
    ["Refresh font list"] = "Atualizar lista de fontes",
    ["Restore SleepRibbon defaults"] = "Restaurar padrões do SleepRibbon",
    ["Restore SleepRibbon's default appearance?"] = "Restaurar a aparência padrão do SleepRibbon?",
    ["Restore"] = "Restaurar",
    ["SleepRibbon defaults restored"] = "Padrões do SleepRibbon restaurados",
    ["Styles the native sleep-screen Banner. KOReader remains responsible for the cover, message tokens, opacity and vertical position."] = "Estiliza a Faixa nativa da tela de descanso. O KOReader continua responsável pela capa, tokens da mensagem, opacidade e posição vertical.",
    ["Set"] = "Definir",
    ["Pick a color"] = "Escolher uma cor",
    ["Cancel"] = "Cancelar",
    ["Default"] = "Padrão",
    ["Apply"] = "Aplicar",
    ["Invalid color. Enter six hexadecimal digits (RRGGBB)."] = "Cor inválida. Digite seis dígitos hexadecimais (RRGGBB).",
    ["Palette"] = "Paleta",
    ["Standard"] = "Padrão",
    ["Cover"] = "Capa",
    ["Cover palette unavailable."] = "Paleta da capa indisponível.",
    ["Refresh cover palette"] = "Atualizar paleta da capa",
    ["Cover palette refreshed"] = "Paleta da capa atualizada",
    ["No book is available for a cover palette."] = "Nenhum livro está disponível para gerar a paleta da capa.",
    ["No cover image is available for this book."] = "Nenhuma imagem de capa está disponível para este livro.",
    ["Could not extract colors from the cover."] = "Não foi possível extrair cores da capa.",
}

local ES = {
    ["Styles KOReader's native sleep-screen Banner with configurable typography, colors, spacing, and a reading-progress bar."] = "Estiliza la franja nativa de la pantalla de reposo de KOReader con tipografía, colores, espaciado y barra de progreso configurables.",
    ["SleepRibbon preview"] = "Vista previa de SleepRibbon",
    ["Tap anywhere to close"] = "Toca en cualquier lugar para cerrar",
    ["Use interface font"] = "Usar fuente de la interfaz",
    ["Follow KOReader's current UI content font. If the UI font changes, SleepRibbon follows it automatically."] = "Usa la fuente actual del contenido de la interfaz de KOReader. Si cambia la fuente de la interfaz, SleepRibbon la sigue automáticamente.",
    ["Preview current font"] = "Previsualizar fuente actual",
    ["No fonts were discovered"] = "No se encontraron fuentes",
    ["unavailable; using interface font"] = "no disponible; usando la fuente de la interfaz",
    ["SleepRibbon font list refreshed"] = "Lista de fuentes de SleepRibbon actualizada",
    ["The font list could not be refreshed. KOReader's existing font cache will be used until the next restart."] = "No se pudo actualizar la lista de fuentes. Se usará la caché actual de KOReader hasta el próximo reinicio.",
    ["Enabled"] = "Activado",
    ["Profile"] = "Perfil",
    ["Global"] = "Global",
    ["Current book"] = "Libro actual",
    ["Sleep screen message"] = "Mensaje de la pantalla de reposo",
    ["Message"] = "Mensaje",
    ["Position"] = "Posición",
    ["Opacity"] = "Opacidad",
    ["Text"] = "Texto",
    ["Maintenance"] = "Mantenimiento",
    ["Restore global defaults"] = "Restaurar valores globales predeterminados",
    ["Reset current book profile"] = "Restablecer perfil del libro actual",
    ["Restore global SleepRibbon defaults?"] = "¿Restaurar los valores globales predeterminados de SleepRibbon?",
    ["Reset the current book profile and inherit global settings?"] = "¿Restablecer el perfil del libro actual y volver a heredar la configuración global?",
    ["Global SleepRibbon defaults restored"] = "Valores globales predeterminados de SleepRibbon restaurados",
    ["Current book profile reset"] = "Perfil del libro actual restablecido",
    ["Configures and styles KOReader's native sleep-screen Banner, with optional per-book profiles."] = "Configura y estiliza la franja nativa de la pantalla de reposo de KOReader, con perfiles opcionales por libro.",
    ["Preview"] = "Vista previa",
    ["Font"] = "Fuente",
    ["Font size"] = "Tamaño de fuente",
    ["Text color"] = "Color del texto",
    ["Text alignment"] = "Alineación del texto",
    ["Left"] = "Izquierda",
    ["Center"] = "Centrado",
    ["Right"] = "Derecha",
    ["Horizontal padding"] = "Margen horizontal",
    ["Background"] = "Fondo",
    ["Background color"] = "Color de fondo",
    ["Ribbon vertical padding"] = "Margen vertical de la franja",
    ["Progress bar"] = "Barra de progreso",
    ["Bar position"] = "Posición de la barra",
    ["Top"] = "Arriba",
    ["Bottom"] = "Abajo",
    ["Progress display"] = "Visualización del progreso",
    ["Completed only"] = "Solo completado",
    ["Completed + remaining"] = "Completado + restante",
    ["Bar thickness"] = "Grosor de la barra",
    ["Completed progress color"] = "Color del progreso completado",
    ["Remaining progress color"] = "Color del progreso restante",
    ["Refresh font list"] = "Actualizar lista de fuentes",
    ["Restore SleepRibbon defaults"] = "Restaurar valores predeterminados de SleepRibbon",
    ["Restore SleepRibbon's default appearance?"] = "¿Restaurar la apariencia predeterminada de SleepRibbon?",
    ["Restore"] = "Restaurar",
    ["SleepRibbon defaults restored"] = "Valores predeterminados de SleepRibbon restaurados",
    ["Styles the native sleep-screen Banner. KOReader remains responsible for the cover, message tokens, opacity and vertical position."] = "Estiliza la franja nativa de la pantalla de reposo. KOReader sigue controlando la portada, los tokens del mensaje, la opacidad y la posición vertical.",
    ["Set"] = "Establecer",
    ["Pick a color"] = "Elegir un color",
    ["Cancel"] = "Cancelar",
    ["Default"] = "Predeterminado",
    ["Apply"] = "Aplicar",
    ["Invalid color. Enter six hexadecimal digits (RRGGBB)."] = "Color no válido. Introduce seis dígitos hexadecimales (RRGGBB).",
    ["Palette"] = "Paleta",
    ["Standard"] = "Estándar",
    ["Cover"] = "Portada",
    ["Cover palette unavailable."] = "La paleta de la portada no está disponible.",
    ["Refresh cover palette"] = "Actualizar paleta de la portada",
    ["Cover palette refreshed"] = "Paleta de la portada actualizada",
    ["No book is available for a cover palette."] = "No hay ningún libro disponible para generar una paleta de portada.",
    ["No cover image is available for this book."] = "No hay una imagen de portada disponible para este libro.",
    ["Could not extract colors from the cover."] = "No se pudieron extraer colores de la portada.",
}

local function languageFamily()
    local settings = rawget(_G, "G_reader_settings")
    local code = settings and settings:readSetting("language") or "en"
    code = tostring(code or "en"):gsub("-", "_")
    if code:match("^pt") then
        return "pt"
    elseif code:match("^es") then
        return "es"
    end
    return "en"
end

function M.gettext(source)
    local lang = languageFamily()
    if lang == "pt" then
        return PT[source] or source
    elseif lang == "es" then
        return ES[source] or source
    end
    return source
end

return M
