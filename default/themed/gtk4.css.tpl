/* zanken GTK4 theme — generated from colors.toml */

@define-color window_bg_color rgba({{ background_rgb }}, 0.82);
@define-color view_bg_color rgba({{ background_rgb }}, 0.82);
@define-color headerbar_bg_color rgba({{ background_rgb }}, 0.82);
@define-color headerbar_backdrop_color rgba({{ background_rgb }}, 0.82);
@define-color sidebar_bg_color rgba({{ background_rgb }}, 0.82);
@define-color sidebar_backdrop_color rgba({{ background_rgb }}, 0.82);
@define-color sidebar_border_color rgba({{ background_rgb }}, 0.82);
@define-color secondary_sidebar_bg_color rgba({{ background_rgb }}, 0.82);
@define-color card_bg_color rgba({{ background_rgb }}, 0.55);
@define-color popover_bg_color rgba({{ background_rgb }}, 0.92);
@define-color dialog_bg_color rgba({{ background_rgb }}, 0.92);
@define-color overview_bg_color rgba({{ background_rgb }}, 0.82);
@define-color window_fg_color {{ foreground }};
@define-color view_fg_color {{ foreground }};
@define-color headerbar_fg_color {{ foreground }};
@define-color sidebar_fg_color {{ foreground }};
@define-color card_fg_color {{ foreground }};
@define-color popover_fg_color {{ foreground }};
@define-color accent_color {{ accent }};
@define-color accent_bg_color {{ accent }};

:root {
    --window-bg-color: rgba({{ background_rgb }}, 0.82);
    --view-bg-color: rgba({{ background_rgb }}, 0.82);
    --headerbar-bg-color: rgba({{ background_rgb }}, 0.82);
    --headerbar-backdrop-color: rgba({{ background_rgb }}, 0.82);
    --sidebar-bg-color: rgba({{ background_rgb }}, 0.82);
    --sidebar-backdrop-color: rgba({{ background_rgb }}, 0.82);
    --secondary-sidebar-bg-color: rgba({{ background_rgb }}, 0.82);
    --card-bg-color: rgba({{ background_rgb }}, 0.55);
    --popover-bg-color: rgba({{ background_rgb }}, 0.92);
    --dialog-bg-color: rgba({{ background_rgb }}, 0.92);
    --window-fg-color: {{ foreground }};
    --view-fg-color: {{ foreground }};
    --headerbar-fg-color: {{ foreground }};
    --accent-color: {{ accent }};
    --accent-bg-color: {{ accent }};
    --headerbar-shade-color: transparent;
    --headerbar-darker-shade-color: transparent;
    --shade-color: transparent;
    --scrollbar-outline-color: transparent;
}

/* Cover all focus states — libadwaita mixes accent into bg on :focus-within */
window,
window.backdrop,
window:focus,
window:focus-within {
    background-color: rgba({{ background_rgb }}, 0.82) !important;
    color: {{ foreground }};
}

headerbar,
headerbar.backdrop,
headerbar:focus,
headerbar:focus-within {
    background-color: rgba({{ background_rgb }}, 0.82) !important;
    box-shadow: none;
    color: {{ foreground }};
}

.sidebar-pane,
.sidebar-pane.backdrop,
.sidebar-pane:focus-within,
.navigation-sidebar,
.navigation-sidebar.backdrop,
.navigation-sidebar:focus-within {
    background-color: rgba({{ background_rgb }}, 0.82) !important;
    color: {{ foreground }};
}

.view,
.view.backdrop,
.view:focus-within {
    background-color: rgba({{ background_rgb }}, 0.82) !important;
    color: {{ foreground }};
}
