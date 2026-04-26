set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error


# STORE_PROVIDER = none, flatpak, web, snap

if [ "$STORE_PROVIDER" == "none" ]; then
    print_ok "No need to install a store because STORE_PROVIDER is set to none, please check the config file"
elif [ "$STORE_PROVIDER" == "flatpak" ]; then
    print_ok "Installing gnome software and flatpak support"
    apt install $INTERACTIVE \
        flatpak \
        gnome-software \
        gnome-software-plugin-flatpak --no-install-recommends
    install_opt gnome-software-plugin-deb
    judge "Install gnome software with flatpak support"

    print_ok "Adding official flathub repository..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    judge "Add official flatpak repository"

    if [ -n "$FLATHUB_MIRROR" ]; then
        print_warn "Using mirror for flatpak. Replacing flathub repository with mirror $FLATHUB_MIRROR..."

        # FLATHUB_GPG
        if [ -n "$FLATHUB_GPG" ]; then
            print_ok "Adding flathub gpg key..."
            wget $FLATHUB_GPG -O /tmp/flathub.gpg

            print_ok "Adding flathub repository with mirror $FLATHUB_MIRROR and gpg key: $FLATHUB_GPG"
            flatpak remote-modify flathub --url="$FLATHUB_MIRROR" --gpg-import=/tmp/flathub.gpg
            judge "Set flathub mirror"

            rm /tmp/flathub.gpg
            judge "Clear temp flathub.gpg"
        else
            print_ok "Adding flathub repository with mirror $FLATHUB_MIRROR..."
            flatpak remote-modify flathub --url="$FLATHUB_MIRROR"
            judge "Set flathub mirror"
        fi
    fi

    print_ok "Current flathub repository:"
    flatpak remotes --columns=name,url

    print_ok "Installing default flatpak tools..."
    for pkg in $DEFAULT_FLATPAK_TOOLS; do
        # trim leading/trailing whitespace
        pkg="${pkg## }"
        pkg="${pkg%% }"
        [[ -z "$pkg" ]] && continue

        print_ok "Installing ${pkg}â€¦"
        flatpak install -y flathub "${pkg}"
        judge "Install flatpak tool ${pkg}"
    done

elif [ "$STORE_PROVIDER" == "snap" ]; then
    print_ok "Installing snap store..."
    apt install $INTERACTIVE \
        snapd \
        snap \
        gnome-software \
        gnome-software-plugin-snap --no-install-recommends
    install_opt gnome-software-plugin-deb
    judge "Install snap store"
elif [ "$STORE_PROVIDER" == "web" ]; then
    print_ok "Adding new app called EDYOUOS Software..."
    cat << EOF > /usr/share/applications/edyouos-software.desktop
[Desktop Entry]
Name=Apps Store
GenericName=Apps Store
Name[zh_CN]=åº”ç”¨å•†åº—
Name[zh_TW]=æ‡‰ç”¨å•†åº—
Name[zh_HK]=æ‡‰ç”¨å•†åº—
Name[ja_JP]=ã‚¢ãƒ—ãƒªã‚¹ãƒˆã‚¢
Name[ko_KR]=ì•± ìŠ¤í† ì-´
Name[vi_VN]=Cá»­a hÃ ng á»©ng dá»¥ng
Name[th_TH]=à¸£à¹‰à¸²à¸™à¸„à¹‰à¸²à¹à¸­à¸›à¸žà¸¥à¸´à¹€à¸„à¸Šà¸±à¸™
Name[de_DE]=App-Store
Name[fr_FR]=Magasin d'applications
Name[es_ES]=Tienda de aplicaciones
Name[ru_RU]=ÐœÐ°Ð³Ð°Ð·Ð¸Ð½ Ð¿Ñ€Ð¸Ð»Ð¾Ð¶ÐµÐ½Ð¸Ð¹
Name[it_IT]=Negozio di applicazioni
Name[pt_PT]=Loja de aplicativos
Name[pt_BR]=Loja de aplicativos
Name[ar_SA]=Ù…ØªØ¬Ø± Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Ø§Øª
Name[nl_NL]=App Store
Name[sv_SE]=App Store
Name[pl_PL]=Sklep z aplikacjami
Name[tr_TR]=Uygulama MaÄŸazasÄ±
Comment=Browse EDYOUOS's software collection and install our verified applications
Comment[zh_CN]=æµè§ˆ EDYOUOS çš„è½¯ä»¶å•†åº—å¹¶å®‰è£…æˆ‘ä»¬éªŒè¯è¿‡çš„åº”ç”¨
Comment[zh_TW]=ç€è¦½ EDYOUOS çš„è»Ÿé«”å•†åº—ä¸¦å®‰è£æˆ‘å€‘é©—è­‰éŽçš„æ‡‰ç”¨
Comment[zh_HK]=ç€è¦½ EDYOUOS çš„è»Ÿé«”å•†åº—ä¸¦å®‰è£æˆ‘å€‘é©—è­‰éŽçš„æ‡‰ç”¨
Comment[ja_JP]=EDYOUOS ã®ã‚½ãƒ•ãƒˆã‚¦ã‚§ã‚¢ã‚³ãƒ¬ã‚¯ã‚·ãƒ§ãƒ³ã‚’é-²è¦§ã—ã€æ¤œè¨¼æ¸ˆã¿ã®ã‚¢ãƒ—ãƒªã‚±ãƒ¼ã‚·ãƒ§ãƒ³ã‚’ã‚¤ãƒ³ã‚¹ãƒˆãƒ¼ãƒ«ã—ã¾ã™
Comment[ko_KR]=EDYOUOSì˜ ì†Œí”„íŠ¸ì›¨ì-´ ì»¬ë ‰ì…˜ì„ íƒìƒ‰í•˜ê³  ê²€ì¦ëœ ì• í”Œë¦¬ì¼€ì´ì…˜ì„ ì„¤ì¹˜í•©ë‹ˆë‹¤
Comment[vi_VN]=Duyá»‡t bá»™ sÆ°u táº­p pháº§n má»m cá»§a EDYOUOS vÃ  cÃ i Ä‘áº·t cÃ¡c á»©ng dá»¥ng Ä‘Ã£ Ä‘Æ°á»£c xÃ¡c minh cá»§a chÃºng tÃ´i
Comment[th_TH]=à¹€à¸£à¸µà¸¢à¸à¸”à¸¹à¸„à¸­à¸¥à¹€à¸¥à¸à¸Šà¸±à¸™à¸‹à¸­à¸Ÿà¸•à¹Œà¹à¸§à¸£à¹Œà¸‚à¸­à¸‡ EDYOUOS à¹à¸¥à¸°à¸•à¸´à¸”à¸•à¸±à¹‰à¸‡à¹à¸­à¸›à¸žà¸¥à¸´à¹€à¸„à¸Šà¸±à¸™à¸—à¸µà¹ˆà¹„à¸”à¹‰à¸£à¸±à¸šà¸à¸²à¸£à¸•à¸£à¸§à¸ˆà¸ªà¸­à¸šà¸‚à¸­à¸‡à¹€à¸£à¸²
Comment[de_DE]=Durchsuchen Sie die Softwarekollektion von EDYOUOS und installieren Sie unsere verifizierten Anwendungen
Comment[fr_FR]=Parcourez la collection de logiciels d'EDYOUOS et installez nos applications vÃ©rifiÃ©es
Comment[es_ES]=Explore la colecciÃ³n de software de EDYOUOS e instale nuestras aplicaciones verificadas
Comment[ru_RU]=ÐŸÑ€Ð¾ÑÐ¼Ð°Ñ‚Ñ€Ð¸Ð²Ð°Ð¹Ñ‚Ðµ ÐºÐ¾Ð»Ð»ÐµÐºÑ†Ð¸ÑŽ Ð¿Ñ€Ð¾Ð³Ñ€Ð°Ð¼Ð¼Ð½Ð¾Ð³Ð¾ Ð¾Ð±ÐµÑÐ¿ÐµÑ‡ÐµÐ½Ð¸Ñ EDYOUOS Ð¸ ÑƒÑÑ‚Ð°Ð½Ð°Ð²Ð»Ð¸Ð²Ð°Ð¹Ñ‚Ðµ Ð½Ð°ÑˆÐ¸ Ð¿Ñ€Ð¾Ð²ÐµÑ€ÐµÐ½Ð½Ñ‹Ðµ Ð¿Ñ€Ð¸Ð»Ð¾Ð¶ÐµÐ½Ð¸Ñ
Comment[it_IT]=Esplora la collezione di software di EDYOUOS e installa le nostre applicazioni verificate
Comment[pt_PT]=Explore a coleÃ§Ã£o de software da EDYOUOS e instale nossos aplicativos verificados
Comment[pt_BR]=Explore a coleÃ§Ã£o de software da EDYOUOS e instale nossos aplicativos verificados
Comment[ar_SA]=ØªØµÙØ­ Ù…Ø¬Ù…ÙˆØ¹Ø© Ø§Ù„Ø¨Ø±Ø§Ù…Ø¬ Ø§Ù„Ø®Ø§ØµØ© Ø¨Ù€ EDYOUOS ÙˆÙ‚Ù… Ø¨ØªØ«Ø¨ÙŠØª ØªØ·Ø¨ÙŠÙ‚Ø§ØªÙ†Ø§ Ø§Ù„Ù…ÙˆØ«Ù‚Ø©
Comment[nl_NL]=Blader door de softwarecollectie van EDYOUOS en installeer onze geverifieerde applicaties
Comment[sv_SE]=BlÃ¤ddra i EDYOUOS programvarusamling och installera vÃ¥ra verifierade applikationer
Comment[pl_PL]=PrzeglÄ…daj kolekcjÄ™ oprogramowania EDYOUOS i instaluj nasze zweryfikowane aplikacje
Comment[tr_TR]=EDYOUOS'un yazÄ±lÄ±m koleksiyonunu gÃ¶z atÄ±n ve doÄŸrulanmÄ±ÅŸ uygulamalarÄ±mÄ±zÄ± yÃ¼kleyin
Categories=System;
Exec=xdg-open https://edyou-os.vercel.app/App-Store-Disabled.html
Terminal=false
Type=Application
Icon=system-software-install
StartupNotify=true
EOF
else
    print_error "Unknown store provider: $STORE_PROVIDER"
    print_error "Please check the config file"
    exit 1
fi
