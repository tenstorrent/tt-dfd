# Contributing Guidelines

## Branches & Pull Requests

Contributions to [tt-dfd](https://github.com/tenstorrent/tt-dfd) are highly encouraged and welcome.  

When opening a PR, please keep in mind the following policies:
* Name branches as `<feature/bugfix/hotfix>/<short-description>` (e.g., `bugfix/fix_dfd_counter_mechanism`)
* Make sure the title and description of the PR are appropriate and descriptive - if the change is related to an ongoing issue, please link the issue in the PR description
* Squash commits before merging; commit messages should clearly describe the changes
* We highly recommend following the [lowRISC Verilog Coding Style Guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md#use-logic-for-synthesis) for any SystemVerilog contributions
* For any updates, please update the [CHANGELOG.MD's](CHANGELOG.MD) Unreleased section alongside the PR.  

The team will make an effort to regularly review PRs and may give feedback to contributors. 

## Reporting Issues

Find a bug or want an enhancement? Please let us know! 

If you find a security vulnerability, do __NOT__ open an issue. Email joeychen+tt-dfd@tenstorrent.com instead.

When creating issue tickets, please include as much detail as possible, including labels, so that we can assist. In general, we recommend the following format when creating an issue:

```
Title: [Short and appropriate title]

Version: [Version of tt-dfd this ticket applies to, alongside tool version(s) if applicable]

Description: [Description of the bug/enhancement/clarification/etc. If you found a bug, explain what you believe should have occurred and what happened instead.]

Steps to Reproduce: [For applicable bugs, steps should be provided to reproduce the issue, along with applicable logs such as waveforms, debug log dumps, specifications, etc.]

```