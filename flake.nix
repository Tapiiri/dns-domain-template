{
  description = "DNS-as-code for one domain: octoDNS on Hetzner, run from GitHub Actions";

  # All tooling lives in dns-as-code. This flake only re-exports its octoDNS
  # package, so this flake.lock pins the version CI builds.
  # Upgrade with `nix flake update dns-as-code`, then expect a zero-change plan.
  inputs.dns-as-code.url = "github:Tapiiri/dns-as-code";

  outputs = {dns-as-code, ...}: {
    packages = dns-as-code.packages;
  };
}
