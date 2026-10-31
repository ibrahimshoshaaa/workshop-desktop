"""Apply the versioned close guard after flutter create generates windows/."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
runner = root / "windows" / "runner"
shutil.copyfile(root / "windows_support" / "workshop_close_guard.h", runner / "workshop_close_guard.h")

header = runner / "flutter_window.h"
source = runner / "flutter_window.cpp"
h = header.read_text(encoding="utf-8-sig")
c = source.read_text(encoding="utf-8-sig")
if "std::unique_ptr<WorkshopCloseGuard> close_guard_;" not in h:
    assert '#include "win32_window.h"' in h, "Unexpected Flutter window header"
    h = h.replace('#include "win32_window.h"', '#include "win32_window.h"\n#include "workshop_close_guard.h"')
    needle = "  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;"
    assert needle in h, "Unexpected Flutter controller field"
    h = h.replace(needle, needle + "\n  std::unique_ptr<WorkshopCloseGuard> close_guard_;")

if "close_guard_ = std::make_unique<WorkshopCloseGuard>" not in c:
    needle = "  RegisterPlugins(flutter_controller_->engine());"
    assert needle in c, "Unexpected Flutter initialization"
    c = c.replace(needle, needle + "\n  close_guard_ = std::make_unique<WorkshopCloseGuard>(\n      GetHandle(), flutter_controller_->engine()->messenger());")
    needle = "void FlutterWindow::OnDestroy() {"
    assert needle in c, "Unexpected Flutter destruction"
    c = c.replace(needle, needle + "\n  close_guard_.reset();")
    needle = "  // Give Flutter, including plugins, an opportunity to handle window messages."
    assert needle in c, "Unexpected Flutter message handler"
    c = c.replace(needle, "  if (close_guard_) {\n    const auto close_result = close_guard_->HandleMessage(message, wparam, lparam);\n    if (close_result.has_value()) return *close_result;\n  }\n\n" + needle)

header.write_text(h, encoding="utf-8")
source.write_text(c, encoding="utf-8")
print("Windows close and session-ending guard installed.")
