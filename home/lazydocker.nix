# lazydocker Tokyo Night "best effort" theme. Verbatim port of
# `~/dotfiles/lazydocker/.config/lazydocker/config.yml`. Same XDG-first note
# as lazygit.nix applies — the macOS `~/Library/Application Support/...`
# symlink is dropped.
#
# lazydocker's YAML uses Go template strings (`{{ .DockerCompose }} ...`) in
# commandTemplates, so we keep them as verbatim Nix strings. The HM
# programs.lazydocker module writes them through to `~/.config/lazydocker/config.yml`.

{ pkgs, ... }:

let
  # `open` is macOS-only; Linux uses xdg-open. The HM bundle is
  # platform-agnostic, so fork on the host platform.
  openCmd = if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open";
in
{
  programs.lazydocker = {
    enable = true;
    settings = {
      gui = {
        scrollHeight = 2;
        language = "auto";
        border = "rounded";
        theme = {
          activeBorderColor = [ "blue" "bold" ];
          inactiveBorderColor = [ "white" ];
          selectedLineBgColor = [ "blue" ];
          optionsTextColor = [ "cyan" ];
        };
        returnImmediately = false;
        wrapMainPanel = true;
        sidePanelWidth = 0.333;
        showBottomLine = true;
        expandFocusedSidePanel = false;
        screenMode = "normal";
        containerStatusHealthStyle = "long";
      };

      commandTemplates = {
        dockerCompose = "docker compose";
        restartService = "{{ .DockerCompose }} restart {{ .Service.Name }}";
        startService = "{{ .DockerCompose }} start {{ .Service.Name }}";
        stopService = "{{ .DockerCompose }} stop {{ .Service.Name }}";
        serviceLogs = "{{ .DockerCompose }} logs --since=60m --follow {{ .Service.Name }}";
        viewServiceLogs = "{{ .DockerCompose }} logs --follow {{ .Service.Name }}";
        rebuildService = "{{ .DockerCompose }} up -d --build {{ .Service.Name }}";
        recreateService = "{{ .DockerCompose }} up -d --force-recreate {{ .Service.Name }}";
        allLogs = "{{ .DockerCompose }} logs --tail=300 --follow";
        viewAllLogs = "{{ .DockerCompose }} logs";
        dockerComposeConfig = "{{ .DockerCompose }} config";
        checkDockerComposeConfig = "{{ .DockerCompose }} config --quiet";
        serviceTop = "{{ .DockerCompose }} top {{ .Service.Name }}";
      };

      customCommands = {
        containers = [ ];
        images = [ ];
        volumes = [ ];
        networks = [ ];
      };

      oS = {
        openCommand = "${openCmd} {{filename}}";
        openLinkCommand = "${openCmd} {{link}}";
      };

      stats = {
        graphs = [
          { caption = "CPU (%)"; statPath = "DerivedStats.CPUPercentage"; color = "blue"; }
          { caption = "Memory (%)"; statPath = "DerivedStats.MemoryPercentage"; color = "cyan"; }
        ];
        maxDuration = "5m";
      };

      logs = {
        timestamps = false;
        since = "60m";
        tail = "300";
      };
    };
  };
}