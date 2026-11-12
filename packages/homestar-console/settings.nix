{
  arch = "aarch64";
  vmType = "vz";
  rosetta = true;
  runtime = "docker";
  cpu = 2;
  memory = 2;
  disk = 10;
  autoActivate = false;
  sshConfig = false;
  forwardAgent = false;
  mountType = "virtiofs";
  mounts = [];
  kubernetes.enabled = false;
  network.address = false;
}
