{
  description = "Lorenzo's HomeLab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (msystem:
    let
      pkgs = import nixpkgs { system = "${msystem}"; config.allowUnfree = true; };
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          age
          gnupg
          coreutils
          moreutils
          nomad
          consul
          gnumake
          envsubst
          postgresql
          redis
          jq
          git
          mosh
          openssh
          ssh-to-age
          sops
          rsync
          nixos-generators
          nixos-rebuild
          fping
        ];
      };
    }
  );
}
