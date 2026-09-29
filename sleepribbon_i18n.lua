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
    ["Automatic color schemes"] = "Esquemas de cores automáticos",
    ["Generate cover-based color suggestions for the current layout and banner position."] = "Gera sugestões de cores com base na capa para o layout e a posição atuais da faixa.",
    ["Format"] = "Formato",
    ["Text only"] = "Apenas texto",
    ["Text + background"] = "Texto + fundo",
    ["Text + completed bar"] = "Texto + meia barra",
    ["Text + full bar"] = "Texto + barra completa",
    ["Text + background + completed bar"] = "Texto + fundo + meia barra",
    ["Text + background + full bar"] = "Texto + fundo + barra completa",
    ["Generate schemes"] = "Gerar esquemas",
    ["Regenerate schemes"] = "Gerar novamente",
    ["Generated schemes"] = "Esquemas gerados",
    ["layout changed"] = "layout alterado",
    ["Clear schemes for this book"] = "Limpar esquemas deste livro",
    ["Scheme"] = "Esquema",
    ["No generated schemes for this book"] = "Nenhum esquema gerado para este livro",
    ["Layout changed since these schemes were generated"] = "O layout mudou desde que estes esquemas foram gerados",
    ["You can still preview or apply them, or regenerate them for the current layout."] = "Você ainda pode pré-visualizá-los ou aplicá-los, ou gerar novos para o layout atual.",
    ["Open a book before generating color schemes."] = "Abra um livro antes de gerar esquemas de cores.",
    ["No cover image is available for this book."] = "Não há uma imagem de capa disponível para este livro.",
    ["Color-scheme generation failed for this cover."] = "A geração de esquemas de cores falhou para esta capa.",
    ["Generated 4 color schemes"] = "4 esquemas de cores gerados",
    ["Color scheme applied"] = "Esquema de cores aplicado",
    ["Cached schemes cleared"] = "Esquemas em cache apagados",
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
    ["Automatic color schemes"] = "Esquemas de color automáticos",
    ["Generate cover-based color suggestions for the current layout and banner position."] = "Genera sugerencias de color basadas en la portada para el diseño y la posición actuales de la franja.",
    ["Format"] = "Formato",
    ["Text only"] = "Solo texto",
    ["Text + background"] = "Texto + fondo",
    ["Text + completed bar"] = "Texto + barra completada",
    ["Text + full bar"] = "Texto + barra completa",
    ["Text + background + completed bar"] = "Texto + fondo + barra completada",
    ["Text + background + full bar"] = "Texto + fondo + barra completa",
    ["Generate schemes"] = "Generar esquemas",
    ["Regenerate schemes"] = "Generar de nuevo",
    ["Generated schemes"] = "Esquemas generados",
    ["layout changed"] = "diseño modificado",
    ["Clear schemes for this book"] = "Borrar esquemas de este libro",
    ["Scheme"] = "Esquema",
    ["No generated schemes for this book"] = "No hay esquemas generados para este libro",
    ["Layout changed since these schemes were generated"] = "El diseño cambió desde que se generaron estos esquemas",
    ["You can still preview or apply them, or regenerate them for the current layout."] = "Todavía puedes previsualizarlos o aplicarlos, o generar otros para el diseño actual.",
    ["Open a book before generating color schemes."] = "Abre un libro antes de generar esquemas de color.",
    ["No cover image is available for this book."] = "No hay una imagen de portada disponible para este libro.",
    ["Color-scheme generation failed for this cover."] = "La generación de esquemas de color falló para esta portada.",
    ["Generated 4 color schemes"] = "Se generaron 4 esquemas de color",
    ["Color scheme applied"] = "Esquema de color aplicado",
    ["Cached schemes cleared"] = "Esquemas en caché borrados",
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
