pragma Singleton
import QtQuick

QtObject {
  id: root

  function t(key, fallback) {
    var translations = {
      "polkit.authenticationNeeded": "Authentication Required",
      "polkit.authorizeRunning": "Authorize running '%1'",
      "polkit.wrong": "Wrong password",
      "polkit.checking": "Checking...",
      "polkit.enterPassword": "Enter password",
    }
    return translations[key] || fallback || key
  }

  readonly property bool rightToLeft: false
}