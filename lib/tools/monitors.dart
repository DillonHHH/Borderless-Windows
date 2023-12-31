import 'dart:ffi';
import 'package:win32/win32.dart';

class Monitor {
  int monitor;
  int startingX;
  int startingY;
  int width;
  int height;
  Monitor(
      this.monitor, this.startingX, this.startingY, this.width, this.height);
}

List<Monitor> monitors = [];

typedef MonitorEnumProc = Int32 Function(IntPtr hMonitor, IntPtr hdcMonitor,
    Pointer<RECT> lprcMonitor, IntPtr dwData);
typedef MonitorEnumProcDart = int Function(
    int hMonitor, int hdcMonitor, Pointer<RECT> lprcMonitor, int dwData);

int monitorEnumProc(
    int hMonitor, int hdcMonitor, Pointer<RECT> lprcMonitor, int dwData) {
  final rect = lprcMonitor.ref;
  monitors.add(Monitor(hMonitor, rect.left, rect.top, rect.right, rect.bottom));
  return 1; // Continue enumeration
}

List<Monitor> getMonitors() {
  monitors.clear();

  final _user32 = DynamicLibrary.open('user32.dll');

  final EnumDisplayMonitors = _user32.lookupFunction<
      Int32 Function(IntPtr hdc, Pointer lpRect,
          Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum, IntPtr dwData),
      int Function(
          int hdc,
          Pointer lpRect,
          Pointer<NativeFunction<MonitorEnumProc>> lpfnEnum,
          int dwData)>('EnumDisplayMonitors');

  final monitorEnumProcPointer =
      Pointer.fromFunction<MonitorEnumProc>(monitorEnumProc, 0);

  EnumDisplayMonitors(NULL, nullptr, monitorEnumProcPointer, NULL);
  
  return monitors;
}
