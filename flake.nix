{
  description = "Ambiente de desenvolvimento do site pessoal";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              hugo
              dart-sass
              nodejs_22
              git
            ];

            shellHook = ''
              if [ -f package-lock.json ] && [ ! -d node_modules ]; then
                npm ci
              fi
            '';
          };
        });
    };
}
