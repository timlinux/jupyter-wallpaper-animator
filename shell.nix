#let
#  #
#  # Note that I am using a specific version from NixOS here because of
#  # https://github.com/NixOS/nixpkgs/issues/267916#issuecomment-1817481744
#  #
#  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-22.11.tar.gz";
#  #nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/51f732d86fac4693840818ad2aa4781d78be2e89.tar.gz";
#  pkgs = import nixpkgs { config = { }; overlays = [ ]; };
#  pythonPackages = pkgs.python311Packages;

with import <nixpkgs> { };
let
  # For packages pinned to a specific version
  pinnedHash = "617579a787259b9a6419492eaac670a5f7663917";
  pinnedPkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/${pinnedHash}.tar.gz") { };
  pythonPackages = python3Packages;
in pkgs.mkShell rec {
  name = "impurePythonEnv";
  venvDir = "./.venv";
  buildInputs = [
    # A Python interpreter including the 'venv' module is required to bootstrap
    # the environment.
    pythonPackages.python

    # This executes some shell code to initialize a venv in $venvDir before
    # dropping into the shell
    pythonPackages.venvShellHook
    pinnedPkgs.virtualenv
    # Those are dependencies that we would like to use from nixpkgs, which will
    # add them to PYTHONPATH and thus make them accessible from within the venv.
    pythonPackages.jupyter
    pythonPackages.ipython
    pythonPackages.opencv4
    pythonPackages.pygame
    pythonPackages.cairosvg
    pythonPackages.pillow
    pythonPackages.imageio
    pythonPackages.matplotlib
    #python311Packages.jupyterlab
    pythonPackages.ipympl
    # For printing from jupyter
    # The list after scheme-small and latex are all .sty latex
    # modules that are needed for jupyter printing to work. 
    # I obtained the list from this issue:
    # https://github.com/jupyter/nbconvert/issues/1328#issue-659661022
    # Scheme-small is a small footprint latext install. The
    # latex schemes and the sytax for the entry below are 
    # described here:
    # https://nixos.wiki/wiki/TexLive
    # To actually generate a pdf in jupyter, do
    # File -> Save and export notebook as -> PDF
    (pinnedPkgs.texlive.combine { inherit (texlive)
        scheme-small latex adjustbox caption collectbox enumitem environ eurosym jknapltx
        parskip pgf rsfs tcolorbox titling trimspaces ucs ulem upquote 
        lastpage titlesec advdate pdfcol soul
        collection-langgerman collection-langenglish
    ;})
    pinnedPkgs.pandoc
  ];
  # Run this command, only after creating the virtual environment
  PROJECT_ROOT = builtins.getEnv "PWD";

  postVenvCreation = ''
    unset SOURCE_DATE_EPOCH
    pip install -r requirements.txt
  '';

  # Now we can execute any commands within the virtual environment.
  # This is optional and can be left out to run pip manually.
  postShellHook = ''
    # allow pip to install wheels
    unset SOURCE_DATE_EPOCH
    echo "Start your jupyter using:"
    echo "jupyter lab"
  '';


}
