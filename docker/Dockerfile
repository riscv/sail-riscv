From ocaml/opam2:ubuntu-lts

RUN sudo apt-get update; sudo apt-get -y install build-essential libgmp-dev z3 m4 pkg-config zlib1g-dev device-tree-compiler; sudo apt-get -y clean

RUN opam switch create ocaml-base-compiler.4.06.1
RUN opam config env

ENV OPAM_SWITCH_PREFIX='/home/opam/.opam/ocaml-base-compiler.4.06.1'
ENV CAML_LD_LIBRARY_PATH='/home/opam/.opam/ocaml-base-compiler.4.06.1/lib/stublibs:Updated by package ocaml'
ENV OCAML_TOPLEVEL_PATH='/home/opam/.opam/ocaml-base-compiler.4.06.1/lib/toplevel'
ENV MANPATH=':/home/opam/.opam/4.06.1/man:/home/opam/.opam/ocaml-base-compiler.4.06.1/man'
ENV PATH='/home/opam/.opam/ocaml-base-compiler.4.06.1/bin:/home/opam/.opam/4.06.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

RUN which ocaml
RUN opam config env
RUN opam repository add rems https://github.com/rems-project/opam-repository.git; opam install sail

