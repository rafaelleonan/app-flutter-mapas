import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition _posicaoCamera = const CameraPosition(
    target: LatLng(-23.565160, -46.651797),
    zoom: 10,
  );

  Set<Marker> _marcadores = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};

  _onMapCreated(GoogleMapController googleMapController) {
    _controller.complete(googleMapController);
  }

  _movimentarCamera() async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(_posicaoCamera),
    );
  }

  _carregarMarcadores() {
    Set<Polyline> listaPolylines = {};
    Polyline polyline = Polyline(
      polylineId: const PolylineId("polyline"),
      color: Colors.red,
      width: 40,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      points: const [
        LatLng(-23.563645, -46.653642),
        LatLng(-23.565160, -46.651797),
        LatLng(-23.563232, -46.648020),
      ],
      consumeTapEvents: true,
      onTap: () {
        print("clicado na área");
      },
    );

    listaPolylines.add(polyline);
    setState(() {
      _polylines = listaPolylines;
    });
  }

  _recuperarLocalizacaoAtual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Os serviços de localização estão desabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissões de localização são permanentemente negadas.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _posicaoCamera = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 17,
      );
      _movimentarCamera();
    });
  }

  _adicionarListenerLocalizacao() {
    var locationOptions = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationOptions)
        .listen((Position position) {
      print("localizacao atual: ${position.toString()}");

      Marker marcadorUsuario = Marker(
        markerId: const MarkerId("marcador-usuario"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(
          title: "Meu local",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta,
        ),
        onTap: () {
          print("Meu local clicado!!");
        },
      );

      setState(() {
        _marcadores.add(marcadorUsuario);
        _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
        );
        _movimentarCamera();
      });
    });
  }

  _recuperarEnderecoParaLatLong() async {
    try {
      List<Placemark> listaEnderecos = await placemarkFromCoordinates(-23.565564, -46.652753);

      print("total: ${listaEnderecos.length.toString()}");

      if (listaEnderecos.isNotEmpty) {
        Placemark endereco = listaEnderecos[0];
        String resultado;

        resultado = "\n administrativeArea: ${endereco.administrativeArea}";
        resultado += "\n subAdministrativeArea: ${endereco.subAdministrativeArea}";
        resultado += "\n locality: ${endereco.locality}";
        resultado += "\n subLocality: ${endereco.subLocality}";
        resultado += "\n thoroughfare: ${endereco.thoroughfare}";
        resultado += "\n subThoroughfare: ${endereco.subThoroughfare}";
        resultado += "\n postalCode: ${endereco.postalCode}";
        resultado += "\n country: ${endereco.country}";
        resultado += "\n isoCountryCode: ${endereco.isoCountryCode}";

        print("resultado: $resultado");
      }
    } catch (e) {
      print("Erro ao recuperar endereço: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarMarcadores();
    _recuperarLocalizacaoAtual();
    _adicionarListenerLocalizacao();
    _recuperarEnderecoParaLatLong();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapas e geolocalização"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        onPressed: _movimentarCamera,
        child: const Icon(Icons.done),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _posicaoCamera,
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        markers: _marcadores,
        polygons: _polygons,
        polylines: _polylines,
      ),
    );
  }
}
