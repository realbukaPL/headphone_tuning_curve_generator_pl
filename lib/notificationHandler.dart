import "package:awesome_notifications/awesome_notifications.dart";

Future<void> createNotification() async{

await AwesomeNotifications().createNotification(

      content: NotificationContent(
          id: 2,
          channelKey: 'basic_channel',
          body: 'App odtwarza dźwięk w tle',
          notificationLayout: NotificationLayout.Default,

      ),
          actionButtons: [NotificationActionButton(key: "key", label: "Wycisz")]
  );

}