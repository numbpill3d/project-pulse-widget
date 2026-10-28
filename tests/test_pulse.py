import os
import unittest
from pathlib import Path
from unittest import mock

from scripts import pulse


class LedgerRootTests(unittest.TestCase):
    def test_defaults_to_current_users_documents_directory(self):
        with mock.patch.dict(os.environ, {}, clear=True):
            with mock.patch.object(Path, "home", return_value=Path("/tmp/alice")):
                self.assertEqual(
                    pulse.ledger_root(),
                    Path("/tmp/alice/Documents/Hermes Ledger"),
                )

    def test_environment_override_supports_tilde(self):
        with mock.patch.dict(
            os.environ,
            {
                "HOME": "/tmp/alice",
                "PROJECT_PULSE_LEDGER": "~/vaults/Hermes Ledger",
            },
            clear=True,
        ):
            self.assertEqual(
                pulse.ledger_root(), Path("/tmp/alice/vaults/Hermes Ledger")
            )


if __name__ == "__main__":
    unittest.main()
