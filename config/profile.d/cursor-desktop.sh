# Интерактивный bash: tab-дополнение команд и путей.
case "$-" in
    *i*) ;;
    *) return ;;
esac

if [ -f /usr/share/bash-completion/bash_completion ]; then
    # shellcheck source=/dev/null
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    # shellcheck source=/dev/null
    . /etc/bash_completion
fi

# readline: Tab — дополнение, двойной Tab — список вариантов
bind 'set completion-ignore-case on' 2>/dev/null || true
bind 'set show-all-if-ambiguous on' 2>/dev/null || true
bind 'set menu-complete-display-prefix on' 2>/dev/null || true
bind 'TAB:menu-complete' 2>/dev/null || bind 'TAB:complete' 2>/dev/null || true
