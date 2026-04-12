set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
# ...existing code...

# Dictionary of localized strings for "Add to Taskbar" and "Unpin from Taskbar"
declare -A taskbar_add_strings=(
    ["en"]="Add to Taskbar"
    ["zh_CN"]="æ·»åŠ åˆ°ä»»åŠ¡æ "
    ["zh_TW"]="åŠ å…¥å·¥ä½œåˆ—"
    ["zh_HK"]="åŠ å…¥å·¥ä½œæ¬„"
    ["ja"]="ã‚¿ã‚¹ã‚¯ãƒãƒ¼ã«è¿½åŠ "
    ["ko"]="ìž‘ì—…í‘œì‹œì¤„ì— ì¶”ê°€"
    ["vi"]="ThÃªm vÃ o thanh tÃ¡c vá»¥"
    ["th"]="à¹€à¸žà¸´à¹ˆà¸¡à¹„à¸›à¸¢à¸±à¸‡à¹à¸–à¸šà¸‡à¸²à¸™"
    ["de"]="Zur Taskleiste hinzufügen"
    ["fr"]="Ajouter Ã  la barre des tÃ¢ches"
    ["es"]="Agregar a la barra de tareas"
    ["ru"]="Ð”Ð¾Ð±Ð°Ð²Ð¸Ñ‚ÑŒ Ð½Ð° Ð¿Ð°Ð½ÐµÐ»ÑŒ Ð·Ð°Ð´Ð°Ñ‡"
    ["it"]="Aggiungi alla barra delle applicazioni"
    ["pt"]="Adicionar Ã  barra de tarefas"
    ["pt_BR"]="Adicionar Ã  barra de tarefas"
    ["ar"]="Ø¥Ø¶Ø§ÙØ© Ø¥Ù„Ù‰ Ø´Ø±ÙŠØ· Ø§Ù„Ù…Ù‡Ø§Ù…"
    ["nl"]="Toevoegen aan taakbalk"
    ["sv"]="LÃ¤gg till i aktivitetsfÃ¤ltet"
    ["pl"]="Dodaj do paska zadaÅ„"
    ["tr"]="GÃ¶rev Ã§ubuÄŸuna ekle"
)

declare -A taskbar_remove_strings=(
    ["en"]="Unpin from Taskbar"
    ["zh_CN"]="ä»Žä»»åŠ¡æ ä¸­ç§»é™¤"
    ["zh_TW"]="å¾žå·¥ä½œåˆ—ç§»é™¤"
    ["zh_HK"]="å¾žå·¥ä½œæ¬„ç§»é™¤"
    ["ja"]="ã‚¿ã‚¹ã‚¯ãƒãƒ¼ã‹ã‚‰å‰Šé™¤"
    ["ko"]="ìž‘ì—…í‘œì‹œì¤„ì—ì„œ ì œê±°"
    ["vi"]="XÃ³a khá»i thanh tÃ¡c vá»¥"
    ["th"]="à¸¥à¸šà¸­à¸­à¸à¸ˆà¸²à¸à¹à¸–à¸šà¸‡à¸²à¸™"
    ["de"]="Aus der Taskleiste entfernen"
    ["fr"]="Retirer de la barre des tÃ¢ches"
    ["es"]="Eliminar de la barra de tareas"
    ["ru"]="Ð£Ð´Ð°Ð»Ð¸Ñ‚ÑŒ Ñ Ð¿Ð°Ð½ÐµÐ»Ð¸ Ð·Ð°Ð´Ð°Ñ‡"
    ["it"]="Rimuovi dalla barra delle applicazioni"
    ["pt"]="Remover da barra de tarefas"
    ["pt_BR"]="Remover da barra de tarefas"
    ["ar"]="Ø¥Ø²Ø§Ù„Ø© Ù…Ù† Ø´Ø±ÙŠØ· Ø§Ù„Ù…Ù‡Ø§Ù…"
    ["nl"]="Verwijderen van taakbalk"
    ["sv"]="Ta bort frÃ¥n aktivitetsfÃ¤ltet"
    ["pl"]="UsuÅ„ z paska zadaÅ„"
    ["tr"]="GÃ¶rev Ã§ubuÄŸundan kaldÄ±r"
)

# Special case for English - create new .mo file
print_ok "Creating and Patching Gnome Shell for en..."
if [ -d "/usr/share/locale-langpack/en/LC_MESSAGES" ]; then
    cat <<EOL > /tmp/gnome-shell.po
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"

msgid "Pin to Dash"
msgstr "Add to Taskbar"

msgid "Unpin"
msgstr "Remove from Taskbar"
EOL
    msgfmt /tmp/gnome-shell.po -o /usr/share/locale-langpack/en/LC_MESSAGES/gnome-shell.mo
    judge "Patch Gnome Shell (en)"
    rm /tmp/gnome-shell.po
fi

# For all other languages, patch existing files
print_ok "Scanning and patching all available language packs..."
found_languages=0

# Loop through all directories in locale-langpack
for lang_dir in /usr/share/locale-langpack/*/; do
    lang=$(basename "$lang_dir")
    # Skip English as it's handled separately
    if [ "$lang" == "en" ]; then
        continue
    fi
    
    mo_file="$lang_dir/LC_MESSAGES/gnome-shell.mo"
    
    # Check if language has gnome-shell.mo file and if we have translations for it
    if [ -f "$mo_file" ] && [ -n "${taskbar_add_strings[$lang]+isset}" ] || [ -n "${taskbar_add_strings[$lang]+isset}" ]; then
        print_ok "Patching Gnome Shell for $lang..."
        msgunfmt "$mo_file" -o /tmp/gnome-shell.po
        
        # Get the translations (use language code without country if specific one not available)
        lang_code="${lang%%_*}"
        add_string="${taskbar_add_strings[$lang]:-${taskbar_add_strings[$lang_code]:-Add to Taskbar}}"
        remove_string="${taskbar_remove_strings[$lang]:-${taskbar_remove_strings[$lang_code]:-Remove from Taskbar}}"
        
        sed -i '/msgid "Pin to Dash"/{n;s/.*/msgstr "'"$add_string"'"/}' /tmp/gnome-shell.po
        sed -i '/msgid "Unpin"/{n;s/.*/msgstr "'"$remove_string"'"/}' /tmp/gnome-shell.po
        
        msgfmt /tmp/gnome-shell.po -o "$mo_file"
        judge "Patch Gnome Shell ($lang)"
        found_languages=$((found_languages + 1))
    fi
done

rm -f /tmp/gnome-shell.po
print_ok "Patched gnome-shell.mo for $found_languages languages"
