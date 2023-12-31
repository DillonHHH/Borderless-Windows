import 'package:flutter/material.dart';
import 'window_item.dart';

class WindowListColumn extends StatefulWidget {
  const WindowListColumn(
      {super.key, required this.windows, required this.selectedWindow});

  final ValueNotifier<List<WindowItem>> windows;
  final ValueNotifier<WindowItem?> selectedWindow;

  @override
  _WindowListColumnState createState() => _WindowListColumnState();
}

class _WindowListColumnState extends State<WindowListColumn> {
  int selectedIndex = -1;

  void selectItem(int index) {
    setState(() {
      if (selectedIndex != -1) {
        widget.windows.value[selectedIndex].selected = false;
      }
      widget.windows.value[index].selected = true;
      widget.selectedWindow.value = widget.windows.value[index];
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WindowItem>>(
      valueListenable: widget.windows,
      builder: (context, value, child) {
        return ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return Column(
              children: widget.windows.value.map((windowItem) {
                int index = widget.windows.value.indexOf(windowItem);
                return GestureDetector(
                  onTap: () {
                    selectItem(index);
                  },
                  child: Row(
                    children: [
                      windowItem.borderless ? const Icon(Icons.check) : Container(),
                      Expanded(
                        child: Container(
                          color: windowItem.selected
                              ? Colors.blue[100]
                              : Colors.transparent,
                          child: Text(
                            windowItem.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
