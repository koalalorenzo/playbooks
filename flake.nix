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
          coreutils
          moreutils
          jinja2-cli
          python311Packages.jinja2
          python311Packages.jinja2-ansible-filters
          nomad
          consul
          gnumake
          python311Packages.dnspython
          python311Packages.ansible
          jq
          git
          mosh
          openssh
          radicle-cli
          sops
        ];
      };
    }
  );
}
