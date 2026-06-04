{ self }:
{ config, lib, pkgs, ... }:
let
  cfg = config.services.coverfetch;
  defaultPackage = self.packages.${pkgs.system}.default;
in
{
  options.services.coverfetch = {
    enable = lib.mkEnableOption "coverfetch";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "self.packages.${pkgs.system}.default";
      description = "Package providing the coverfetch binary.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address to bind the service to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "TCP port the service listens on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the configured port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    systemd.services.coverfetch = {
      description = "coverfetch API service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = true;
        Restart = "always";
        RestartSec = 2;
        ExecStart = "${cfg.package}/bin/coverfetch --host ${cfg.host} --port ${toString cfg.port}";
      };
    };
  };
}
