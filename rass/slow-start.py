"""rass preset: wait longer for servers to start. PARKED, not used yet.

For Clojure + Tailwind (see lisp/init-lsp.el). Last test hung; unfinished.

clojure-lsp analyses the whole project before answering `initialize`, which
takes more than rass's default 3 s on big projects. Without this, rass gives
up on clojure-lsp and only Tailwind answers. Servers are passed after `--`.
"""

from rassumfrassum.frassum import LspLogic


class SlowStartLogic(LspLogic):
    def get_aggregation_timeout_ms(self, method):
        if method == 'initialize':
            return 120_000
        return super().get_aggregation_timeout_ms(method)


def servers():
    return []


def logic_class():
    return SlowStartLogic
