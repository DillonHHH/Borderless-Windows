// conflicting size functions for native ui and ffi means ffi has to have a custom import
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'components/components.dart';
import 'tools/monitors.dart';
import 'tools/windows.dart';

List<Monitor> monitors = [];
ValueNotifier<List<WindowItem>> windows = ValueNotifier(getWindows());
ValueNotifier<WindowItem?> selectedWindow = ValueNotifier(null);
List<String> borderlessWindows = [];

void updateWindowsList() {
  // following line triggers the valuenotifier, must be done manually since modifying a list doesn't trigger notifiers.
  windows.value = [...windows.value];
}

void reloadWindows() {
  windows.value = getWindows();
  for (WindowItem window in windows.value) {
    if (borderlessWindows.contains(window.title)) {
      window.borderless = true;
    }
  }
  updateWindowsList();
}

void makeWindowBorderless() {
  if (selectedWindow.value == null) {
    return;
  }
  //get hwnd from window title
  int hwnd = FindWindow(nullptr, selectedWindow.value!.title.toNativeUtf16());

  int dwStyle = GetWindowLongPtr(hwnd, GWL_STYLE);
  final gWpprev = calloc<WINDOWPLACEMENT>();

  // credit for most of the code in the following if else statement goes to Raymond Chen: https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
  if (!borderlessWindows.contains(selectedWindow.value!.title)) {
    borderlessWindows.add(selectedWindow.value!.title);
    selectedWindow.value!.borderless = true;
    updateWindowsList();

    // later this will only be true if the selected window isn't already selected for borderless
    SetWindowLongPtr(hwnd, GWL_STYLE, dwStyle & ~WS_OVERLAPPEDWINDOW);
    SetWindowPos(hwnd, HWND_TOP, 0, 0, monitors[0].width, monitors[0].height,
        SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
  } else {
    borderlessWindows.remove(selectedWindow.value!.title);
    selectedWindow.value!.borderless = false;
    updateWindowsList();

    SetWindowLongPtr(hwnd, GWL_STYLE, dwStyle | WS_OVERLAPPEDWINDOW);
    SetWindowPlacement(hwnd, gWpprev);
    SetWindowPos(
        hwnd,
        NULL,
        0,
        0,
        0,
        0,
        SWP_NOMOVE |
            SWP_NOSIZE |
            SWP_NOZORDER |
            SWP_NOOWNERZORDER |
            SWP_FRAMECHANGED);
  }
}

void main() {
  runApp(const MyApp());

  // set window size on start, better than manually modifiying in main.cpp since this allows a custom default resolution to be set by the user
  final user32 = DynamicLibrary.open('user32.dll');
  final findWindowA = user32.lookupFunction<
      Int32 Function(Pointer<Utf8> lpClassName, Pointer<Utf8> lpWindowName),
      int Function(Pointer<Utf8> lpClassName,
          Pointer<Utf8> lpWindowName)>('FindWindowA');
  // windows/runner/win32_window.cpp also contains the name of the window, which must be used in order to get the windows through winapi
  int hWnd = findWindowA('Borderless_Flutter_App'.toNativeUtf8(), nullptr);
  SetWindowPos(hWnd, HWND_TOP, 800, 400, 800, 600, SWP_SHOWWINDOW);

  monitors = getMonitors();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[200]),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            Expanded(
                child: WindowListColumn(
              windows: windows,
              selectedWindow: selectedWindow,
            )),
            Container(
              child: SizedBox(
                height: 50,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: reloadWindows,
                      child: Text('Get\nWindows',
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: makeWindowBorderless,
                      child: Text('Make\nBorderless',
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
