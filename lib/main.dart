import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arabawy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Google Map with Tracking'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription _streamSubscription;
  GoogleMapController controller;
  Location _locationTracker = Location();
  Marker marker;
  Circle circle;

  getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load('assets/images/car.png');
    return byteData.buffer.asUint8List();
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarkerAndLocation(location, imageData);

      if (_streamSubscription != null) {
        _streamSubscription.cancel();
      }

      _streamSubscription =
          _locationTracker.onLocationChanged.listen((newLocation) {
        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(newLocation.latitude, newLocation.longitude),
            zoom: 10)));
        updateMarkerAndLocation(newLocation, imageData);
      });
    } catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("PERMISSION_DENIED_ERROR");
      }
    }
  }

  updateMarkerAndLocation(LocationData myLocationData, Uint8List imageData) {
    LatLng latLng = LatLng(myLocationData.latitude, myLocationData.longitude);
    setState(() {
      marker = Marker(
          markerId: MarkerId("home"),
          position: latLng,
          zIndex: 2,
          flat: true,
          icon: BitmapDescriptor.fromBytes(imageData),
          rotation: myLocationData.heading,
          anchor: Offset(0.5, 0.5),
          draggable: false);

      circle = Circle(
          circleId: CircleId("car"),
          radius: myLocationData.heading,
          zIndex: 1,
          fillColor: Colors.red.withAlpha(70),
          strokeColor: Colors.red,
          center: latLng);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           getCurrentLocation();
        },
        child: Icon(Icons.location_searching_rounded),
      ),
      body: GoogleMap(
        mapType: MapType.terrain,
        markers: Set.of(marker != null ? [marker] : []),
        circles: Set.of(circle != null ? [circle] : []),
        initialCameraPosition: CameraPosition(zoom: 10, target: LatLng(30, 31)),
        onMapCreated: (GoogleMapController googleMapController) {
          setState(() {
            controller = googleMapController;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _streamSubscription.cancel();
  }
}
