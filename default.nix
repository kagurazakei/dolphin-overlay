# This Nix overlay modifies the Dolphin file manager package (GPL-licensed)
# to fix its "Open with" menu functionality when running outside of KDE.
#
# This overlay is provided as-is and is intended for personal use or as a
# contribution to Nixpkgs. It is compatible with the GPL license of Dolphin.
#
# Copyright (c) 2025 rumboon
# This overlay is licensed under the terms of the MIT license.
#
# The modified package retains its original GPL license.

final: prev: {
  kdePackages = prev.kdePackages.overrideScope (
    kfinal: kprev:
    let
      menuDir = final.runCommand "dolphin-menu" { } ''
        mkdir -p $out/etc/xdg/menus
        cp ${prev.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu $out/etc/xdg/menus/applications.menu
      '';
      dolphin-plugins-fixed = kprev.dolphin-plugins.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          kprev.extra-cmake-modules
        ];
        buildInputs = (old.buildInputs or [ ]) ++ [
          kprev.dolphin
        ];
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DDolphinVcs_DIR=${kprev.dolphin}/lib/cmake/DolphinVcs"
        ];
      });
    in
    {
      dolphin = prev.symlinkJoin {
        name = "dolphin-wrapped";
        paths = [
          kprev.dolphin
          dolphin-plugins-fixed
        ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          rm $out/bin/dolphin
          makeWrapper ${kprev.dolphin}/bin/dolphin $out/bin/dolphin \
            --set XDG_CONFIG_DIRS "${menuDir}/etc/xdg:$XDG_CONFIG_DIRS" \
            --run "${kprev.kservice}/bin/kbuildsycoca6 --noincremental ${menuDir}/etc/xdg/menus/applications.menu"
        '';
        meta = kprev.dolphin.meta // {
          description = "Dolphin with plugins and fixed 'Open with' menu using plasma-applications.menu renamed to applications.menu";
        };
      };
      dolphin-plugins = dolphin-plugins-fixed;
    }
  );
}
