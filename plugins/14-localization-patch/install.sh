set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

# if DEFAULT_APPS contains shotwell:
if [[ $DEFAULT_APPS =~ "shotwell" ]]; then
    print_ok "Patching Shotwell localization..."
    sed -i "/^Name=/a Name#ZH#=å›¾åº“" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[zh_TW]=åœ-åº«" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[zh_HK]=åœ-åº«" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[ja_JP]=å†™çœŸ" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[ko_KR]=ì‚¬ì§„" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[vi_VN]=áº¢nh" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[th_TH]=à¸£à¸¹à¸›à¸à¸²à¸ž" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[de_DE]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[fr_FR]=Photos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[es_ES]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[ru_RU]=Ð¤Ð¾Ñ‚Ð¾Ð³Ñ€Ð°Ñ„Ð¸Ð¸" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[it_IT]=Foto" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[pt_PT]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[pt_BR]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[ar_SA]=Ø§Ù„ØµÙˆØ±" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[nl_NL]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[sv_SE]=Foton" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[pl_PL]=ZdjÄ™cia" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^Name=/a Name[tr_TR]=FotoÄŸraflar" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName#ZH#=å›¾åº“" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[zh_TW]=åœ-åº«" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[zh_HK]=åœ-åº«" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ja_JP]=å†™çœŸ" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ko_KR]=ì‚¬ì§„" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[vi_VN]=áº¢nh" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[th_TH]=à¸£à¸¹à¸›à¸ à¸²à¸ž" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[de_DE]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[fr_FR]=Photos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[es_ES]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ru_RU]=Ð¤Ð¾Ñ‚Ð¾Ð³Ñ€Ð°Ñ„Ð¸Ð¸" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[it_IT]=Foto" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pt_PT]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pt_BR]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ar_SA]=Ø§Ù„ØµÙˆØ±" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[nl_NL]=Fotos" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[sv_SE]=Foton" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pl_PL]=ZdjÄ™cia" /usr/share/applications/org.gnome.Shotwell.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[tr_TR]=FotoÄŸraflar" /usr/share/applications/org.gnome.Shotwell.desktop
    judge "Patch Shotwell localization"
fi

if [[ $DEFAULT_APPS =~ "rhythmbox" ]]; then
    print_ok "Patching rhythmbox localization..."
    sed -i "/^Name=Rhythmbox/a Name#ZH#=éŸ³ä¹" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[zh_TW]=éŸ³æ¨‚" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[zh_HK]=éŸ³æ¨‚" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[ja_JP]=éŸ³æ¥½" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[ko_KR]=ìŒì•…" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[vi_VN]=Ã‚m nháº¡c" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[th_TH]=à¹€à¸žà¸¥à¸‡" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[de_DE]=Musik" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[fr_FR]=Musique" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[es_ES]=MÃºsica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[ru_RU]=ÐœÑƒÐ·Ñ‹ÐºÐ°" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[it_IT]=Musica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[pt_PT]=MÃºsica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[pt_BR]=MÃºsica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[ar_SA]=Ø§Ù„Ù…ÙˆØ³ÙŠÙ‚Ù‰" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[nl_NL]=Muziek" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[sv_SE]=Musik" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[pl_PL]=Muzyka" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^Name=Rhythmbox/a Name[tr_TR]=MÃ¼zik" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName#ZH#=éŸ³ä¹" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[zh_TW]=éŸ³æ¨‚" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[zh_HK]=éŸ³æ¨‚" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ja_JP]=éŸ³æ¥½" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ko_KR]=ìŒì•…" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[vi_VN]=Ã‚m nháº¡c" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[th_TH]=à¹€à¸žà¸¥à¸‡" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[de_DE]=Musik" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[fr_FR]=Musique" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[es_ES]=MÃºsica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ru_RU]=ÐœÑƒÐ·Ñ‹ÐºÐ°" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[it_IT]=Musica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pt_PT]=MÃºsica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pt_BR]=MÃºsica" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ar_SA]=Ø§Ù„Ù…ÙˆØ³ÙŠÙ‚Ù‰" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[nl_NL]=Muziek" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[sv_SE]=Musik" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pl_PL]=Muzyka" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[tr_TR]=MÃ¼zik" /usr/share/applications/org.gnome.Rhythmbox3.desktop
    judge "Patch rhythmbox localization"
fi

if [ $DEFAULT_APPS =~ "baobab" ]; then
    print_ok "Patching baobab localization..."
    sed -i "/^Name=/a Name#ZH#=ç£ç›˜åˆ†æž" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[zh_TW]=ç£ç¢Ÿåˆ†æž" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[zh_HK]=ç£ç¢Ÿåˆ†æž" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[ja_JP]=ãƒ‡ã‚£ã‚¹ã‚¯ä½¿ç”¨çŠ¶æ³" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[ko_KR]=ë””ìŠ¤í¬ ì‚¬ìš©ëŸ‰ ë¶„ì„" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[vi_VN]=PhÃ¢n tÃch Ä'Ä©a" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[th_TH]=à¸§à¸´à¹€à¸„à¸£à¸²à¸°à¸«à¹Œà¸à¸²à¸£à¹ƒà¸Šà¹‰à¸‡à¸²à¸™à¸”à¸´à¸ªà¸à¹Œ" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[de_DE]=Festplattenbelegung" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[fr_FR]=Analyseur d'utilisation des disques" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[es_ES]=Analizador de uso de disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[ru_RU]=ÐÐ½Ð°Ð»Ð¸Ð· Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¸Ñ Ð´Ð¸ÑÐºÐ°" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[it_IT]=Analizzatore utilizzo disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[pt_PT]=Analisador de uso de disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[pt_BR]=Analisador de uso de disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[ar_SA]=Ù…Ø­Ù„Ù„ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ù‚Ø±Øµ" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[nl_NL]=Schijfgebruik" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[sv_SE]=DiskanvÃ¤ndning" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[pl_PL]=Analiza uÅ¼ycia dysku" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^Name=/a Name[tr_TR]=Disk KullanÄ±m Analizi" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName#ZH#=ç£ç›˜åˆ†æž" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[zh_TW]=ç£ç¢Ÿåˆ†æž" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[zh_HK]=ç£ç¢Ÿåˆ†æž" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ja_JP]=ãƒ‡ã‚£ã‚¹ã‚¯ä½¿ç”¨çŠ¶æ³" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ko_KR]=ë””ìŠ¤í¬ ì‚¬ìš©ëŸ‰ ë¶„ì„" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[vi_VN]=PhÃ¢n tÃch Ä'Ä©a" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[th_TH]=à¸§à¸´à¹€à¸„à¸£à¸²à¸°à¸«à¹Œà¸à¸²à¸£à¹ƒà¸Šà¹‰à¸‡à¸²à¸™à¸”à¸´à¸ªà¸à¹Œ" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[de_DE]=Festplattenbelegung" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[fr_FR]=Analyseur d'utilisation des disques" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[es_ES]=Analizador de uso de disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ru_RU]=ÐÐ½Ð°Ð»Ð¸Ð· Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¸Ñ Ð´Ð¸ÑÐºÐ°" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[it_IT]=Analizzatore utilizzo disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pt_PT]=Analisador de uso de disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pt_BR]=Analisador de uso de disco" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[ar_SA]=Ù…Ø­Ù„Ù„ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø§Ù„Ù‚Ø±Øµ" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[nl_NL]=Schijfgebruik" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[sv_SE]=DiskanvÃ¤ndning" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[pl_PL]=Analiza uÅ¼ycia dysku" /usr/share/applications/org.gnome.baobab.desktop
    sed -i "/^X-GNOME-FullName=/a X-GNOME-FullName[tr_TR]=Disk KullanÄ±m Analizi" /usr/share/applications/org.gnome.baobab.desktop
    judge "Patch baobab localization"
fi

if [[ $DEFAULT_APPS =~ "qalculate" ]]; then
    DESKTOP_FILE="/usr/share/applications/qalculate-gtk.desktop"
    print_ok "Patching qalculate localization..."

    # Map of locale codes â†’ translated application name
    declare -A LOCALIZED_NAMES=(
        [zh_TW]="è¨ˆç®—å™¨"
        [zh_HK]="è¨ˆç®—å™¨"
        [ja_JP]="è¨ˆç®—æ©Ÿ"
        [ko_KR]="ê³„ì‚°ê¸°"
        [vi_VN]="MÃ¡y tÃnh"
        [th_TH]="à¹€à¸„à¸£à¸·à¹ˆà¸­à¸‡à¸„à¸´à¸”à¹€à¸¥à¸‚"
        [de_DE]="Taschenrechner"
        [fr_FR]="Calculatrice"
        [es_ES]="Calculadora"
        [ru_RU]="ÐšÐ°Ð»ÑŒÐºÑƒÐ»ÑÑ‚Ð¾Ñ€"
        [it_IT]="Calcolatrice"
        [pt_PT]="Calculadora"
        [pt_BR]="Calculadora"
        [ar_SA]="Ø¢Ù„Ø© Ø­Ø§Ø³Ø¨Ø©"
        [nl_NL]="Rekenmachine"
        [sv_SE]="Kalkylator"
        [pl_PL]="Kalkulator"
        [tr_TR]="Hesap Makinesi"
    )

    # For each locale: remove any existing Name[<locale>] line, then insert our translation
    for locale in "${!LOCALIZED_NAMES[@]}"; do
        name="${LOCALIZED_NAMES[$locale]}"
        # delete any old entries
        sed -i "/^Name\[$locale\]=/d" "$DESKTOP_FILE"
        # insert immediately after the default Name= line
        sed -i "/^Name=/a Name[$locale]=${name}" "$DESKTOP_FILE"
        judge "Patch qalculate localization for $locale"
    done

    print_ok "Done. All locales patched in $DESKTOP_FILE."

fi
