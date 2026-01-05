import 'package:flutter/material.dart';

/// 統一錯誤處理
class ErrorHandler {
  /// 顯示錯誤訊息
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: '關閉',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  /// 顯示成功訊息
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// 顯示載入對話框
  static void showLoading(BuildContext context, {String message = '載入中...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  /// 隱藏載入對話框
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  /// 處理 API 錯誤
  static String handleApiError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return '網絡連接失敗，請檢查網絡';
    } else if (error.toString().contains('TimeoutException')) {
      return '請求超時，請稍後再試';
    } else if (error.toString().contains('401')) {
      return '未授權，請重新登入';
    } else if (error.toString().contains('404')) {
      return '資源不存在';
    } else if (error.toString().contains('500')) {
      return '服務器錯誤，請稍後再試';
    }
    return '發生錯誤: $error';
  }
}

