import 'package:flutter/material.dart';

class ConfirmDialog {
  static Future<bool?> show({
    required BuildContext context,
    String title = 'Xác nhận',
    String content = 'Bạn có chắc chắn muốn thực hiện hành động này không?',
    String textCancel = 'Không',
    String textConfirm = 'Có',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                textCancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(textConfirm),
            ),
          ],
        );
      },
    );
  }
}
