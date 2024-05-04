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
          pkgs.coreutils
          pkgs.moreutils
          pkgs.jinja2-cli
          pkgs.python311Packages.jinja2
          pkgs.python311Packages.jinja2-ansible-filters
          pkgs.nomad
          pkgs.consul
          pkgs.gnumake
          pkgs.python311Packages.dnspython
          pkgs.python311Packages.ansible
          pkgs.jq
          pkgs.git
          pkgs.radicle-cli
        ];
      };
    }
  );
}
