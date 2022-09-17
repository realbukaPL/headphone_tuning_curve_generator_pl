import "package:awesome_notifications/awesome_notifications.dart";

Future<void> createNotification() async{

await AwesomeNotifications().createNotification(

      content: NotificationContent(
          id: 2,
          channelKey: 'basic_channel',
          body: 'Aplikacja odtwarza dźwięk w tle',
          notificationLayout: NotificationLayout.Default,
        autoDismissible: true,
      ),
          actionButtons: [NotificationActionButton(key: "mute", label: "Wycisz"), NotificationActionButton(key: "exit", label: "Zakończ")]
  );

}