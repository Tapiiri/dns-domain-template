# DNS for one domain

DNS-as-code for a single domain whose zone lives in Hetzner DNS. The YAML in
`zones/` is the only source of truth; octoDNS reconciles it with the zone.
Everything runs in GitHub Actions through the shared tooling in
[Tapiiri/dns-as-code](https://github.com/Tapiiri/dns-as-code), so no local machine is
needed.

This repo is a template. Create one repo per domain from it, then follow the setup
below.

## Setup

Starting point: the domain's zone already exists in Hetzner DNS, possibly with records.

1. **Hetzner.** Put the zone in a Hetzner Console project of its own, so its tokens
   reach no other domain. In that project, create two API tokens: one read-only, one
   read and write.
2. **1Password, or wherever you keep secrets.** Store both tokens. They are the master
   copy; GitHub gets copies.
3. **This repo.** Create it from the template, one repo per domain. If a Claude Code
   session should work on it, the Claude GitHub App must be installed for its owner.
4. **Read-only token.** Settings → Secrets and variables → Actions → Repository
   secrets: `HETZNER_TOKEN_RO`.
5. **Read-write token.** Settings → Environments → new environment `production`.
   Set deployment branches to `main` only, and add the environment secret
   `HETZNER_TOKEN`.
6. **Onboard.** Actions → dns → Run workflow, with action `onboard` and the zone
   name, e.g. `example.com`. It dumps the live zone, writes the zone file, adds the
   zone to `config/production.yaml`, and checks that the plan shows no changes. Then
   it pushes branch `onboard/<zone>`. The run summary links to the page where you
   open the pull request.
7. **Open and merge the onboard PR.** Open it from the link, or have a Claude Code
   session open it. Its plan comment must say "No changes were planned". Merging
   starts managing the zone; the apply on `main` should report 0 changes.
8. **Protect `main`.** Settings → Rules → Rulesets → New ruleset → Import a ruleset,
   and pick [`.github/rulesets/main.json`](.github/rulesets/main.json). On the
   default branch it requires a pull request with the status check `plan / plan`,
   and blocks force pushes and deletion.

Then change records as below. Records for common services, such as Migadu mail, are in
dns-as-code's [`record-sets/`](https://github.com/Tapiiri/dns-as-code/tree/main/record-sets);
adding one is an ordinary PR.

The onboard workflow does not open the PR in step 7 itself. GitHub starts no workflows
for pull requests opened by the built-in workflow token, so the required plan check
would never report on one.

## Changing records

1. Edit `zones/<zone>.yaml` on a branch and open a PR. The **plan** job dry-runs
   octoDNS with the read-only token and posts the changes as a PR comment, updated on
   every push.
2. Merge it. The push to `main` runs **apply** with the read-write token.

Keep each plan to the records you meant to touch. octoDNS owns the zone completely and
deletes any record the YAML does not contain, so do not edit the zone in the Hetzner
Console. Applies run one at a time and skip themselves if `main` has moved on, so DNS
always converges on the newest `main`. A failed apply leaves DNS behind the repo; fix
the cause and re-run the job.

## Upgrading the tooling

`.github/workflows/dns.yml` pins dns-as-code to one release's commit SHA, never to
`@main`, because the apply job holds the read-write token. To upgrade, replace the SHA
and version comment on every `Tapiiri/dns-as-code` line, and update the `dns-as-code`
entry in `flake.lock` to the same commit (`nix flake update dns-as-code`, or by hand in
a Claude Code session). The PR's plan shows whether DNS would change.

## License

[MIT](LICENSE). A repo created from this template may replace or drop it.
