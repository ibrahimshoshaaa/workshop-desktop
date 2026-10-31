#ifndef WORKSHOP_CLOSE_GUARD_H_
#define WORKSHOP_CLOSE_GUARD_H_

#include <windows.h>
#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <optional>
#include <variant>

// WM_CLOSE must be intercepted before plugin delegates, including invisible
// helper windows. Windows session ending is a different, synchronous message.
class WorkshopCloseGuard {
 public:
  WorkshopCloseGuard(HWND window, flutter::BinaryMessenger* messenger)
      : window_(window),
        channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "workshop/close_guard",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler(
        [this](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
          if (call.method_name() == "ready") {
            ready_ = true;
            SetBlockReason();
            result->Success();
          } else if (call.method_name() == "finishClose") {
            const auto* close = call.arguments()
                ? std::get_if<bool>(call.arguments()) : nullptr;
            if (!close) {
              result->Error("invalid_argument", "Expected a close decision");
              return;
            }
            pending_ = false;
            if (*close) {
              allow_close_ = true;
              ShutdownBlockReasonDestroy(window_);
              PostMessage(window_, WM_CLOSE, 0, 0);
            }
            result->Success();
          } else {
            result->NotImplemented();
          }
        });
  }

  ~WorkshopCloseGuard() {
    channel_->SetMethodCallHandler(nullptr);
    ShutdownBlockReasonDestroy(window_);
  }

  std::optional<LRESULT> HandleMessage(UINT message, WPARAM wparam, LPARAM lparam) {
    if (message == WM_CLOSE && ready_ && !allow_close_) {
      RequestClose(false);
      return 0;
    }
    if (message == WM_QUERYENDSESSION) {
      // Critical / forced termination cannot be made safe by a dialog.
      if (!ready_ || allow_close_ || (lparam & ENDSESSION_CRITICAL)) return TRUE;
      SetBlockReason();
      RequestClose(true);
      return FALSE;
    }
    if (message == WM_ENDSESSION && !wparam && pending_) {
      PostMessage(window_, kShowClosePrompt, 0, 0);
      return 0;
    }
    if (message == kShowClosePrompt) {
      ShowWindow(window_, SW_RESTORE);
      SetForegroundWindow(window_);
      return 0;
    }
    return std::nullopt;
  }

 private:
  void SetBlockReason() {
    ShutdownBlockReasonCreate(window_,
        L"\u0627\u062d\u0641\u0638 \u0646\u0633\u062e\u0629 \u0627\u062d\u062a\u064a\u0627\u0637\u064a\u0629 \u0648\u062a\u0623\u0643\u062f \u0645\u0646 \u0631\u0641\u0639\u0647\u0627 \u0625\u0644\u0649 Drive. \u0627\u062e\u062a\u0631 \u0625\u0644\u063a\u0627\u0621 \u0625\u063a\u0644\u0627\u0642 \u0648\u064a\u0646\u062f\u0648\u0632 \u062b\u0645 \u0627\u0631\u062c\u0639 \u0644\u0644\u0628\u0631\u0646\u0627\u0645\u062c.");
  }

  void RequestClose(bool shutdown) {
    if (pending_) return;
    pending_ = true;
    channel_->InvokeMethod("closeRequested",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
            {flutter::EncodableValue("shutdown"), flutter::EncodableValue(shutdown)}}));
  }

  static constexpr UINT kShowClosePrompt = WM_APP + 0x2A90;
  HWND window_;
  bool ready_ = false;
  bool allow_close_ = false;
  bool pending_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // WORKSHOP_CLOSE_GUARD_H_
