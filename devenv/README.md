# how packages are split

Home Manager = how i work
base = what almost every dev environment needs
profile = what a category of your work needs
repo = what this exact project needs

```
├── devenv.nix
├── devenv.yaml
└── modules/
    ├── base.nix
    ├── work.nix
    ├── personal.nix
    └── dotfiles.nix
```

# commands
`devenv lsp` - start lsp for `devenv.nix`

# autoactivation
- add to `~/.zshrc`
```
eval "$(devenv hook zsh)"
```

- Before a project can auto activate, you need to explicitly trust it. 
```
cd ~/myproject
devenv allow
devenv: allowed /home/user/myproject
```

# secret spec to keep secrets out of of shell

```devenv.yaml
secretspec:
  enable: true
  provider: openbao
  cachix_auth_token: MY_TEAM_CACHIX_TOKEN
```

# tasks
- execute code in parallel 

```deveenv.nix
{ pkgs, ... }:

{
  tasks."myapp:hello" = {
    exec = ''echo "Hello, world!"'';
  };
}

```
then run:
```
$ devenv tasks run myapp:hello

Running tasks     myapp:hello
Succeeded         myapp:hello         9ms
1 Succeeded                           10.14ms
```
- lifescyle hooks: `enterShell`
