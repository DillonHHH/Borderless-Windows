import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../components/window_item.dart';

List<WindowItem> windows = [];

int enumerateWindowsCallback(
  int hWnd,
  int lParam,
) {
  if (IsWindowVisible(hWnd) == TRUE) {
    // Get the window title
    final textLength = GetWindowTextLength(hWnd);
    final stringBuffer = calloc<Uint16>(textLength + 1);
    GetWindowText(hWnd, stringBuffer.cast<Utf16>(), textLength + 1);

    // Convert the buffer to a Dart string and add it to the list
    final windowTitle = stringBuffer.cast<Utf16>().toDartString();
    calloc.free(stringBuffer);
    if (windowTitle.trim() != "" &&
        !windows.any((item) => item.title == windowTitle)) {
      windows.add(WindowItem(windowTitle));
    }
  }

  return TRUE; // Continue enumeration
}

List<WindowItem> getWindows() {
  windows = [];
  final callback =
      Pointer.fromFunction<EnumWindowsProc>(enumerateWindowsCallback, 0);
  EnumWindows(callback, 0);
  print(windows.length);
  windows.sort((a, b) => a.title.compareTo(b.title));
  return windows;
}