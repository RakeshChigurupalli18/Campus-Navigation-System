<!DOCTYPE html>
<html>
<head>
  <title>GIET Campus Guide System</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- Leaflet CSS -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet-routing-machine/dist/leaflet-routing-machine.css" />

  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
    }
    .header {
      background-color: #2c3e50;
      color: white;
      text-align: center;
      padding: 15px;
    }
    .controls {
      text-align: center;
      padding: 10px;
      background-color: #ecf0f1;
    }
    select, button {
      font-size: 16px;
      padding: 6px 10px;
      margin: 5px;
    }
    #map {
      height: 85vh;
      width: 100%;
    }
    .leaflet-control-zoom {
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .leaflet-control-zoom-in, .leaflet-control-zoom-out {
      font-size: 22px !important;
      width: 40px;
      height: 40px;
      line-height: 36px;
    }
  </style>
</head>
<body>

  <div class="header">
    <h2>GIET Campus Guide System Live Tracker + Voice</h2>
  </div>

  <div class="controls">
    <label for="destination">Choose a destination:</label>
    <select id="destination" onchange="showRoute()">
      <option value="">-- Select --</option>
      <option value="GGUcampus">GGUcampus</option>
      <option value="GietEngineeringCollege">GietEngineeringCollege</option>
      <option value="DegreeCollege">DegreeCollege</option>
      <option value="Pharmacy">Pharmacy</option>
      <option value="RKblock">RKblock</option>
      <option value="GirlsHostel">GirlsHostel</option>
      <option value="BoysHostel">BoysHostel</option>
      <option value="SpicyHub">SpicyHub</option>
      <option value="Cfc">Cfc</option>
      <option value="Library">Library</option>
      <option value="Playground">Playground</option>
      <option value="Busstand">Busstand</option>
      <option value="Entry&Exit">Entry&Exit</option>
    </select><br><br>

    <button onclick="startListening()"> Voice Search</button>
    <button onclick="zoomIn()">Zoom In</button>
    <button onclick="zoomOut()">Zoom Out</button>
    <p id="voiceStatus" style="font-style: italic; color: #555;"></p>
  </div>

  <div id="map"></div>

  <!-- Leaflet JS -->
  <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
  <script src="https://unpkg.com/leaflet-routing-machine/dist/leaflet-routing-machine.js"></script>

  <script>
    const locations = {
      "GGUcampus": [17.061498, 81.868672],
      "GietEngineeringCollege": [17.069252, 81.867208],
      "DegreeCollege": [17.071184, 81.868441],
      "Pharmacy": [17.064064, 81.865466],
      "GirlsHostel": [17.062195, 81.866531],
      "BoysHostel": [17.063018, 81.865120],
      "RKblock": [17.064562, 81.865679],
      "SpicyHub": [17.068989, 81.868323],
      "Cfc": [17.064753, 81.867348],
      "Library": [17.068309, 81.867923],
      "Playground": [17.065178, 81.868702],
      "Busstand": [17.066069, 81.869513],
      "Entry&Exit": [17.059746, 81.869264]
    };

    let currentPosition = null;
    let userMarker = null;
    let mapCentered = false;
    let destinationMarker = null;
    let routingControl = null;

    const blueIcon = L.icon({
      iconUrl: 'https://maps.google.com/mapfiles/ms/icons/blue-dot.png',
      iconSize: [30, 30]
    });

    const redIcon = L.icon({
      iconUrl: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png',
      iconSize: [30, 30]
    });

    const map = L.map('map', { zoomControl: false }).setView([17.0685, 81.8681], 17);
    L.control.zoom({ position: 'bottomright' }).addTo(map);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: 'Map data © OpenStreetMap contributors'
    }).addTo(map);

    // Add static location markers
    for (const place in locations) {
      L.marker(locations[place]).addTo(map).bindPopup(place);
    }

    // Live location tracking
    navigator.geolocation.watchPosition((position) => {
      currentPosition = [position.coords.latitude, position.coords.longitude];

      if (!userMarker) {
        userMarker = L.marker(currentPosition, { icon: blueIcon })
          .addTo(map)
          .bindPopup("📍 You are here")
          .openPopup();
      } else {
        userMarker.setLatLng(currentPosition);
      }

      if (!mapCentered) {
        map.setView(currentPosition, 17);
        mapCentered = true;
      }

      const selected = document.getElementById("destination").value;
      if (selected) {
        updateRouteTo(locations[selected]);
      }

    }, (err) => {
      alert("⚠️ Location access denied. Please enable GPS.");
      console.error("Location error:", err);
    }, {
      enableHighAccuracy: true
    });

    function updateRouteTo(destinationLatLng) {
      if (!currentPosition) return;

      if (routingControl) map.removeControl(routingControl);
      if (destinationMarker) map.removeLayer(destinationMarker);

      destinationMarker = L.marker(destinationLatLng, { icon: redIcon })
        .addTo(map)
        .bindPopup("🎯 Destination")
        .openPopup();

      routingControl = L.Routing.control({
        waypoints: [
          L.latLng(currentPosition),
          L.latLng(destinationLatLng)
        ],
        routeWhileDragging: false,
        createMarker: () => null
      }).addTo(map);
    }

    function showRoute() {
      const destination = document.getElementById("destination").value;
      if (destination && currentPosition) {
        updateRouteTo(locations[destination]);
        speak("Showing route to " + destination);
      }
    }

    function startListening() {
      const voiceStatus = document.getElementById("voiceStatus");

      if (!('webkitSpeechRecognition' in window)) {
        alert("Speech recognition not supported in this browser.");
        return;
      }

      const recognition = new webkitSpeechRecognition();
      recognition.lang = 'en-IN';
      recognition.interimResults = false;
      recognition.maxAlternatives = 1;

      voiceStatus.textContent = "🎙 Listening...";
      recognition.start();

      recognition.onresult = (event) => {
        const spokenText = event.results[0][0].transcript.toLowerCase().trim();
        voiceStatus.textContent = "🧠 You said: " + spokenText;

        if (spokenText.includes("help") || spokenText.includes("what can i say")) {
          speak("You can say: Take me to library, Go to playground, Where is GGU campus, Navigate to spicy hub.");
          voiceStatus.textContent += " — Help instructions provided ℹ";
          return;
        }

        let found = false;
        for (const place in locations) {
          const placeLower = place.toLowerCase();
          if (
            spokenText.includes(placeLower) ||
            spokenText.includes("go to " + placeLower) ||
            spokenText.includes("take me to " + placeLower) ||
            spokenText.includes("navigate to " + placeLower) ||
            spokenText.includes("where is " + placeLower)
          ) {
            document.getElementById("destination").value = place;
            showRoute();
            const friendlyName = place.replace(/([A-Z])/g, ' $1').trim();
            speak(`Okay! Navigating to ${friendlyName}`);
            voiceStatus.textContent += ` — Matched: ${place} ✅`;
            found = true;
            break;
          }
        }

        if (!found) {
          speak("Sorry, I couldn't find that location. Please try again.");
          voiceStatus.textContent += " — No match ❌";
        }
      };

      recognition.onerror = (e) => {
        voiceStatus.textContent = "❗ Error: " + e.error;
        speak("Sorry, I couldn't hear that. Please try again.");
      };
    }

    function speak(text) {
      if (!('speechSynthesis' in window)) return;
      const msg = new SpeechSynthesisUtterance();
      msg.text = text;
      msg.lang = 'en-IN';
      msg.rate = 1;
      speechSynthesis.speak(msg);
    }

    function zoomIn() {
      map.zoomIn();
    }

    function zoomOut() {
      map.zoomOut();
    }
  </script>

</body>
</html>
