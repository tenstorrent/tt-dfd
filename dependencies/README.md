# In-repository RTL dependencies

This directory contains approved open-source implementations that replace
internal common RTL used by DFD. DFD-owned RTL remains under `rtl/`.

The release workflow must copy only dependencies selected by its reviewed
mapping manifest. A newly discovered internal module without an approved
replacement is a release blocker and must not be copied from an internal
repository.
