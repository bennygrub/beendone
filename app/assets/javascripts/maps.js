$(window).bind("load", function() {
   
 var mapStyle =
  [
    {
        "featureType": "administrative",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "administrative.country",
        "elementType": "geometry.stroke",
        "stylers": [
            {
                "visibility": "on"
            },
            {
                "color": "#F7F5F2"
            },
            {
                "weight": 0.8
            }
        ]
    },
    {
        "featureType": "water",
        "elementType": "all",
        "stylers": [
            {
                "color": "#F7F5F2"
            }
        ]
    },
    {
        "featureType": "landscape",
        "elementType": "all",
        "stylers": [
            {
                "color": "#DDD4CB"
            }
        ]
    },
    {
        "featureType": "poi",
        "elementType": "all",
        "stylers": [
            {
                "color": "#DDD4CB"
            }
        ]
    },
    {
        "featureType": "road",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "transit",
        "elementType": "all",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    },
    {
        "featureType": "all",
        "elementType": "labels",
        "stylers": [
            {
                "visibility": "off"
            }
        ]
    }
  ] 

















  handler = Gmaps.build('Google');
  handler.buildMap({
      provider: {
        //disableDefaultUI: true
        // pass in other Google Maps API options here
        styles: mapStyle,
        zoom: -10

      },
      internal: {
        id: 'map'
      }
    },
    function(){
      markers = handler.addMarkers([
        { lat: 43, lng: 3.5},
        { lat: 45, lng: 4},
        { lat: 47, lng: 3.5},
        { lat: 49, lng: 4},
        { lat: 51, lng: 3.5}
      ]);
      handler.bounds.extendWith(markers);
      handler.fitMapToBounds();
    }
  );




    
});