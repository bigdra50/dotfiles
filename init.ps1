function InstallPkgs{
  winget install -e --id Git.Git
  winget install -e --id Microsoft.VisualStudioCode
  winget install -e --id vim.vim
  winget install -e --id OpenJS.Nodejs
  winget install -e --id Docker.DockerDesktop
  winget install -e --id Notion.Notion
  winget install -e --id Microsoft.VisualStudio.Community
  winget install -e --id JetBrains.Toolbox
  winget install -e --id Microsoft.PowerToys
  winget install -e --id Python.Python
  winget install -e --id SlackTechnologies.Slack
  winget install -e --id marha.VcXsrv
  winget install -e --id Yarn.Yarn
  winget install -e --id Microsoft.PowerToys
}

InstallPkgs
