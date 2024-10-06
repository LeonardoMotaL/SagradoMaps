import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geodesy/geodesy.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _currentLocation = const LatLng(0, 0);
  LatLng _destinationLocation = const LatLng(0, 0);
  List<LatLng> _polylineCoordinates = [];
  List<LatLng> interpointIni = [];
  List<LatLng> interpointFinal = [];
  bool _showRoute = false;
  late StreamSubscription<Position> _positionStreamSubscription;
  String blocoAtual = '';
  bool noQuadrant = false;
  int selectedFloor = 0;
  Color terreoCor = Colors.black;
  Color andar1Cor = Colors.black;
  Color andar2cor = Colors.black;
  Color andar3Cor = Colors.black;

  final Map<String, List<LatLng>> blocoQuadrantes = {
    'Blocos A e B': [
      const LatLng(-22.327993435682192, -49.05300175331678),
      const LatLng(-22.327720513509053, -49.05191277639787),
      const LatLng(-22.328008322330817, -49.051805488031476),
      const LatLng(-22.328206810827485, -49.052926651460304),
    ],
    'Blocos C, D e E': [
      const LatLng(-22.328415223445035, -49.05277644774735),
      const LatLng(-22.328112528826782, -49.05178939477651),
      const LatLng(-22.328509505241154, -49.051676741991805),
      const LatLng(-22.32879235024723, -49.05273889681911),
    ],
    'Blocos F e G': [
      const LatLng(-22.328876707418736, -49.052733532400794),
      const LatLng(-22.328583938193102, -49.05164991990021),
      const LatLng(-22.328891593973108, -49.05154263153381),
      const LatLng(-22.3291645138552, -49.05262087961607),
    ],
    'Bloco J': [
      const LatLng(-22.330018005333717, -49.05237948078415),
      const LatLng(-22.32975004927552, -49.051311961538524),
      const LatLng(-22.33001304318917, -49.05121003759045),
      const LatLng(-22.330280998742168, -49.05228828567272),
    ],
    'Bloco K': [
      const LatLng(-22.33039016567176, -49.0522560991628),
      const LatLng(-22.3301172481876, -49.051161757825575),
      const LatLng(-22.330400089933836, -49.051092020387415),
      const LatLng(-22.330653158378542, -49.052175632888),
    ],
    'Bloco O': [
      const LatLng(-22.330985620166636, -49.051821581277444),
      const LatLng(-22.330916150608797, -49.051542631524825),
      const LatLng(-22.331352815826158, -49.051419249903475),
      const LatLng(-22.331422285166532, -49.0516981996561),
    ],
    'Bloco L': [
      const LatLng(-22.331630692996015, -49.05160164013504),
      const LatLng(-22.331551299579967, -49.0511563934145),
      const LatLng(-22.33164061716984, -49.05114030015954),
      const LatLng(-22.331729934702505, -49.05158554688008),
    ],
    'Bloco Enfermagem': [
      const LatLng(-22.329114892108855, -49.05333434719837),
      const LatLng(-22.329080156868432, -49.053157321393826),
      const LatLng(-22.32974508711171, -49.05306612628239),
      const LatLng(-22.329824481555804, -49.053114406047264),
    ],
    'Bloco Quadra': [
      const LatLng(-22.3320028490313, -49.051515809441916),
      const LatLng(-22.331888721286045, -49.05096327435499),
      const LatLng(-22.33210209047302, -49.05088817249851),
      const LatLng(-22.33224102837279, -49.05143534316713),
    ],
  };

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  void _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _startLocationUpdates();
    } else {
      setState(() {});
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (_showRoute) {
          _updateRoute();
        }
      });
    });
  }

  void processLatLngList(List<LatLng> userLocations, List<LatLng> interpointIni,
      List<LatLng> interpointFinal, List<LatLng> finalLocations) {
    _polylineCoordinates.clear();
    _polylineCoordinates.addAll(userLocations);
    _polylineCoordinates.addAll(interpointIni);
    _polylineCoordinates.addAll(interpointFinal);
    _polylineCoordinates.addAll(finalLocations);
  }

  void _updateRoute() {
    interpointIni.clear();
    interpointFinal.clear();

    setState(() {
      LatLng currentLocation = _currentLocation;
      noQuadrant = false;

      for (var entry in blocoQuadrantes.entries) {
        final polygon = Polygon(points: entry.value);
        final geodesy = Geodesy();
        if (geodesy.isGeoPointInPolygon(currentLocation, polygon.points)) {
          blocoAtual = entry.key;
          noQuadrant = true;
          break;
        }
      }

      if (blocoAtual == 'Blocos A e B' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.3279163, -49.0525214));
      } else if (blocoAtual == 'Blocos C, D e E' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.328443432881073, -49.05224869755595));
      } else if (blocoAtual == 'Blocos F e G' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.3291972, -49.0522247));
      } else if (blocoAtual == 'Bloco J' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.3300683, -49.0517948));
      } else if (blocoAtual == 'Bloco K' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.330437985080614, -49.05165541296699));
      } else if (blocoAtual == 'Bloco O' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.331077725255266, -49.051642753031444));
      } else if (blocoAtual == 'Bloco L' && selectedFloor >= 1) {
        interpointIni.add(const LatLng(-22.33180500973702, -49.05131463223576));
      }

      processLatLngList([_currentLocation], interpointIni, interpointFinal, [_destinationLocation]);

      if (interpointIni.any((element) => interpointFinal.contains(element))) {
        interpointIni.clear();
        interpointFinal.clear();
        processLatLngList([_currentLocation], interpointIni, interpointFinal, [_destinationLocation]);
      }
    });
  }

  void button5Function() {
    setState(() {
      _destinationLocation = const LatLng(-22.3279957, -49.0524341);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void lanchonete1Btn() {
    setState(() {
      _destinationLocation = const LatLng(-22.32844352801771, -49.05267458024632);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void lanchonete2Btn() {
    setState(() {
      _destinationLocation = const LatLng(-22.32836189156452, -49.052475427926304);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void updateDestination(LatLng newDestination) {
    setState(() {
      _destinationLocation = newDestination;
      _showRoute = true;
    });
  }
  void secretariaButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32809055912719, -49.052827397275564);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void financeiroButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32809055912719, -49.052827397275564);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void uatiButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32812033240214, -49.05289445249825);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void lojaButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328447838009588, -49.05265305368895);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void laboratorionutricaoButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3284408, -49.0522646);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void laboratorioanatomiaButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3283260, -49.0521667);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void sanitarioscdeButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328532195389393, -49.05250284999015);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labbiocienciasButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3283697, -49.0522324);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labquimicaButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328485054506974, -49.05223999351725);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labtecnologiafarmae007ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328485054506974, -49.05223999351725);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labanalisemedicase007ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328485054506974, -49.05223999351725);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void anfiteatroe001ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328601666134485, -49.05245725243872);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void anfiteatroe002ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328442875809184, -49.051899352986034);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void salasmet1ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32851482769773, -49.052006641342324);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void areasexatasButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328859700027593, -49.05180815788319);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labinfoButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328896916415097, -49.05250553219905);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void CapelaButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32890684078342, -49.05236337512697);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void areasaudeButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.329040819686707, -49.052537718705935);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void centraleventosButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.328996160066577, -49.05247602790108);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void coordextensaoButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32886714330588, -49.051786700211935);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void coordpedagogicaButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32886714330588, -49.051786700211935);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void comunicacaoButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32886714330588, -49.051786700211935);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void posgradButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32886714330588, -49.051786700211935);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void pastoralButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.32939065288824, -49.052135387365986);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void restauranteuniverButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3299443, -49.0518110);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labgastroButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3300572, -49.0518811);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void nuphisButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3303248, -49.0513195);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void anfilButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3316277, -49.0510171);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labeng1ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3316481, -49.0513312);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void labeng2ButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3316481, -49.0513312);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void quadraButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.332024962047157, -49.05119155583825);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void canteiroButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.332346562502725, -49.05189966966368);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void setorcomprasButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.33077479609208, -49.051243370965814);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void clinicaodontoButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3311848, -49.0514003);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void laboperacoesButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.33115738836352, -49.051186625657415);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void anfiteatrooButtonFunction() {
    setState(() {
      _destinationLocation = const LatLng(-22.3311994, -49.0516387);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void clinicapsiBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3303605, -49.0514070);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void rampaabBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3279163, -49.0525214);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void rampacdeBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3283260, -49.0521667);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void rampafgBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.329145639729965, -49.0522231041821);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void rampajBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3300683, -49.0517948);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void rampakBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.330535190216118, -49.051626571563176);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void meiolBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3317899, -49.0512826);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void rampaoBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3311994, -49.0516387);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void sanitariosoBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.331142047716906, -49.05150591873438);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void enfermagemBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.329547433321125, -49.05302345872447);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void viveabBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.327954563151124, -49.05241303655974);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void vivecdeBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.328416077889642, -49.05230767404165);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void vivefgBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.328829461283327, -49.05217101568447);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void vivejBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.329976943215954, -49.05177566460427);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void vivekBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.330425419965312, -49.051657645632964);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void viveoBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.331195498387704, -49.05161298981289);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void vivelBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.331606821926563, -49.05122573958626);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void cantBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.33202385150873, -49.05079588865488);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }
  void sanitariosjBtn() {
    setState(() {
      _destinationLocation = const LatLng(-22.3302057, -49.0519357);
      _showRoute = true;
      _updateRoute();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(-22.329781921895503, -49.05214550633222),
            initialZoom: 17.6,
            initialRotation: 15.5,
            maxBounds: LatLngBounds(
              const LatLng(-22.332669864966952, -49.05251028676222),
              const LatLng(-22.327032862103955, -49.05181291241111),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            PolylineLayer(polylines: [
              Polyline(
                points: _polylineCoordinates,
                strokeWidth: 4.0,
                color: Colors.red,
              ),
            ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  child: const Icon(Icons.circle, size: 22,
                      color: Colors.deepPurpleAccent),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _destinationLocation,
                  child: Container(
                      alignment: Alignment.center,
                      child: Icon(Icons.location_on_rounded, size: 18, color: Colors.red[900]!,)
                  ),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.32836159807512, -49.05246894103362),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.fastfood, size: 18, color: Colors.red,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.328413435157938, -49.052636592949035),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.shopping_bag, size: 18, color: Colors.black,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.32844505203085, -49.052783577699564),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.fastfood, size: 18, color: Colors.red,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.327934840973754, -49.05215355330124),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.menu_book, size: 18, color: Colors.red,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.332053946888276, -49.05121863294338),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.sports_basketball, size: 18, color: Colors.deepOrange,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.3299443, -49.0518110),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.restaurant_menu, size: 18, color: Colors.black,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.3281936, -49.0528259),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.support_agent_outlined, size: 18, color: Colors.black,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.327429444426155, -49.053121577195796),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.directions_bus, size: 18, color: Colors.blueAccent,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.330261540977098, -49.05302957493218),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.directions_bus, size: 18, color: Colors.blueAccent,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.332404694225673, -49.052448836405226),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: const Icon(Icons.directions_bus, size: 18, color: Colors.blueAccent,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.32966250860545, -49.05198338683339),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: Icon(Icons.directions_car, size: 18, color: Colors.blue[800]!,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    point: const LatLng(-22.33118932915177, -49.05255026308147),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                          alignment: Alignment.center,
                          child: Icon(Icons.directions_car, size: 18, color: Colors.blue[800]!,)
                      ),
                    )
                )
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 50,
                    height: 40,
                    point: const LatLng(-22.32800412566698, -49.05233435883637),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                                'Blocos A , B',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center
                            )
                        )))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 50,
                    height: 40,
                    point: const LatLng(-22.328427460293295, -49.05227810235844),
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                            'Blocos C , D, E',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                            ),
                            textAlign: TextAlign.center
                        ),
                      ),))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 50,
                  height: 40,
                  point: const LatLng(-22.32885584116473, -49.05217190361199),
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Blocos F, G',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 55,
                    height: 40,
                    point: const LatLng(-22.33010348671078, -49.05178776442375),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Bloco J',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            )
                        ))),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 55,
                    height: 40,
                    point: const LatLng(-22.33046488892245, -49.051677761156135),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Bloco K',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            )
                        )))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 60,
                    height: 40,
                    point: const LatLng(-22.331118375789742, -49.0514419023634),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Bloco O',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            )
                        )))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 55,
                    height: 40,
                    point: const LatLng(-22.331747889022612, -49.051199217547484),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Bloco L',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            )
                        )))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 55,
                    height: 40,
                    point: const LatLng(-22.332142063634166, -49.0511770566056),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Quadra ',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            )
                        )))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 90,
                    height: 50,
                    point: const LatLng(-22.32943920508712, -49.05305887858332),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                                'LAB. Enfermagem',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold
                                )
                            )
                        )))
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                    width: 90,
                    height: 50,
                    point: const LatLng(-22.329638365111855, -49.05297435147503),
                    child: Transform.rotate(
                        angle: -0.25,
                        child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                                'Clínica Nutrição',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold
                                )
                            )
                        )))
              ],
            ),
          ],
        ),

        floatingActionButton:
        Column(
            children: [
              const SizedBox(height: 70),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                        label:const Text(' Selecione em qual\n andar você está'),
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Lembre-se de sempre atualizar o seu andar sempre que você mudar de andar, para que assim o aplicativo formule as melhores rotas para você.',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedFloor = 0;
                                              terreoCor = Colors.red;
                                              andar1Cor = Colors.black;
                                              andar2cor = Colors.black;
                                              andar3Cor = Colors.black;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text('Térreo', style: TextStyle(color: terreoCor)),
                                        ),

                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedFloor = 1;
                                              terreoCor = Colors.black;
                                              andar1Cor = Colors.red;
                                              andar2cor = Colors.black;
                                              andar3Cor = Colors.black;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text('Andar 1', style: TextStyle(color: andar1Cor)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedFloor = 2;
                                              terreoCor = Colors.black;
                                              andar1Cor = Colors.black;
                                              andar2cor = Colors.red;
                                              andar3Cor = Colors.black;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text('Andar 2', style: TextStyle(color: andar2cor)),
                                        ),

                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedFloor = 3;
                                              terreoCor = Colors.black;
                                              andar1Cor = Colors.black;
                                              andar2cor = Colors.black;
                                              andar3Cor = Colors.red;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text('Andar 3', style: TextStyle(color: andar3Cor)),
                                        ),
                                      ]
                                  ),
                                );
                              }
                          );
                        }
                    ),
                    FloatingActionButton(
                        child: const Icon(Icons.view_headline),
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => Creditos()),
                                            );
                                          },
                                          child: const Text('Créditos'),
                                        ),
                                      ]
                                  ),
                                );
                              }
                          );
                        }
                    ),
                  ]),

              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(selectedFloor == 0 ? 'Térreo' : '$selectedFloor',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ]
              ),

              Spacer(),
              Align(alignment: Alignment.bottomLeft,
                child:
                Column(

                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FloatingActionButton.extended(
                      icon: const Icon(Icons.signpost, color: Colors.red,),
                      label: const Text('Direção das Salas'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Placa(blocoAtual: blocoAtual, selectedFloor: selectedFloor,),
                          ),
                        );
                      },
                    ),
                    FloatingActionButton.extended(
                      icon: const Icon(Icons.roundabout_right_rounded, color: Colors.red,),
                      label: const Text('Selecionar Rota'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyHomePage(
                              showRoute: _showRoute,
                              destinationLocation: _destinationLocation,
                              updateRoute: _updateRoute,
                              lanchonete1Btn: lanchonete1Btn,
                              lanchonete2Btn: lanchonete2Btn,
                              button5Function: button5Function,
                              secretariaButtonFunction: secretariaButtonFunction,
                              financeiroButtonFunction: financeiroButtonFunction,
                              uatiButtonFunction: uatiButtonFunction,
                              lojaButtonFunction: lojaButtonFunction,
                              laboratorionutricaoButtonFunction:laboratorionutricaoButtonFunction,
                              laboratorioanatomiaButtonFunction:laboratorioanatomiaButtonFunction,
                              sanitarioscdeButtonFunction:sanitarioscdeButtonFunction,
                              labbiocienciasButtonFunction:labbiocienciasButtonFunction,
                              labquimicaButtonFunction:labquimicaButtonFunction,
                              labtecnologiafarmae007ButtonFunction:labtecnologiafarmae007ButtonFunction,
                              labanalisemedicase007ButtonFunction:labanalisemedicase007ButtonFunction,
                              anfiteatroe001ButtonFunction:anfiteatroe001ButtonFunction,
                              anfiteatroe002ButtonFunction:anfiteatroe002ButtonFunction,
                              salasmet1ButtonFunction:salasmet1ButtonFunction,
                              areasexatasButtonFunction:areasexatasButtonFunction,
                              labinfoButtonFunction:labinfoButtonFunction,
                              CapelaButtonFunction:CapelaButtonFunction,
                              areasaudeButtonFunction:areasaudeButtonFunction,
                              centraleventosButtonFunction:centraleventosButtonFunction,
                              coordextensaoButtonFunction:coordextensaoButtonFunction,
                              coordpedagogicaButtonFunction:coordpedagogicaButtonFunction,
                              comunicacaoButtonFunction:comunicacaoButtonFunction,
                              posgradButtonFunction:posgradButtonFunction,
                              pastoralButtonFunction:pastoralButtonFunction,
                              restauranteuniverButtonFunction:restauranteuniverButtonFunction,
                              labgastroButtonFunction:labgastroButtonFunction,
                              nuphisButtonFunction:nuphisButtonFunction,
                              anfilButtonFunction:anfilButtonFunction,
                              labeng1ButtonFunction:labeng1ButtonFunction,
                              labeng2ButtonFunction:labeng2ButtonFunction,
                              quadraButtonFunction:quadraButtonFunction,
                              canteiroButtonFunction:canteiroButtonFunction,
                              setorcomprasButtonFunction:setorcomprasButtonFunction,
                              clinicaodontoButtonFunction:clinicaodontoButtonFunction,
                              laboperacoesButtonFunction:laboperacoesButtonFunction,
                              anfiteatrooButtonFunction:anfiteatrooButtonFunction,
                              clinicapsiBtn: clinicapsiBtn,
                              rampaabBtn: rampaabBtn,
                              rampacdeBtn: rampacdeBtn,
                              rampafgBtn:rampafgBtn,
                              rampajBtn:rampajBtn,
                              rampakBtn:rampakBtn,
                              meiolBtn:meiolBtn,
                              rampaoBtn:rampaoBtn,
                              sanitariosoBtn:sanitariosoBtn,
                              enfermagemBtn:enfermagemBtn,
                              viveabBtn:viveabBtn,
                              vivecdeBtn:vivecdeBtn,
                              vivefgBtn:vivefgBtn,
                              vivejBtn:vivejBtn,
                              vivekBtn:vivekBtn,
                              viveoBtn:viveoBtn,
                              vivelBtn:vivelBtn,
                              cantBtn:cantBtn,
                              sanitariosjBtn: sanitariosjBtn,
                            ),
                          ),
                        );
                      },
                    ),
                    FloatingActionButton.extended(
                      icon: const Icon(Icons.close, color: Colors.red,),
                      label: const Text('Limpar a rota'),
                      onPressed: () {
                        setState(() {
                          if (_showRoute) {
                            _showRoute = false;
                            _polylineCoordinates.clear();
                            _destinationLocation = const LatLng(0, 0);
                          }
                        });
                      },
                    ),
                  ],
                ),
              )
            ]
        )
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool showRoute;
  final LatLng destinationLocation;
  final VoidCallback updateRoute;
  final VoidCallback lanchonete1Btn;
  final VoidCallback lanchonete2Btn;
  final VoidCallback button5Function;
  final VoidCallback secretariaButtonFunction;
  final VoidCallback financeiroButtonFunction;
  final VoidCallback uatiButtonFunction;
  final VoidCallback lojaButtonFunction;
  final VoidCallback laboratorionutricaoButtonFunction;
  final VoidCallback laboratorioanatomiaButtonFunction;
  final VoidCallback sanitarioscdeButtonFunction;
  final VoidCallback labbiocienciasButtonFunction;
  final VoidCallback labquimicaButtonFunction;
  final VoidCallback labtecnologiafarmae007ButtonFunction;
  final VoidCallback labanalisemedicase007ButtonFunction;
  final VoidCallback anfiteatroe001ButtonFunction;
  final VoidCallback anfiteatroe002ButtonFunction;
  final VoidCallback salasmet1ButtonFunction;
  final VoidCallback areasexatasButtonFunction;
  final VoidCallback labinfoButtonFunction;
  final VoidCallback CapelaButtonFunction;
  final VoidCallback areasaudeButtonFunction;
  final VoidCallback centraleventosButtonFunction;
  final VoidCallback coordextensaoButtonFunction;
  final VoidCallback coordpedagogicaButtonFunction;
  final VoidCallback comunicacaoButtonFunction;
  final VoidCallback posgradButtonFunction;
  final VoidCallback pastoralButtonFunction;
  final VoidCallback restauranteuniverButtonFunction;
  final VoidCallback labgastroButtonFunction;
  final VoidCallback nuphisButtonFunction;
  final VoidCallback anfilButtonFunction;
  final VoidCallback labeng1ButtonFunction;
  final VoidCallback labeng2ButtonFunction;
  final VoidCallback quadraButtonFunction;
  final VoidCallback canteiroButtonFunction;
  final VoidCallback setorcomprasButtonFunction;
  final VoidCallback clinicaodontoButtonFunction;
  final VoidCallback laboperacoesButtonFunction;
  final VoidCallback anfiteatrooButtonFunction;
  final VoidCallback clinicapsiBtn;
  final VoidCallback rampaabBtn;
  final VoidCallback rampacdeBtn;
  final VoidCallback rampafgBtn;
  final VoidCallback rampajBtn;
  final VoidCallback rampakBtn;
  final VoidCallback meiolBtn;
  final VoidCallback rampaoBtn;
  final VoidCallback sanitariosoBtn;
  final VoidCallback enfermagemBtn;
  final VoidCallback viveabBtn;
  final VoidCallback vivecdeBtn;
  final VoidCallback vivefgBtn;
  final VoidCallback vivejBtn;
  final VoidCallback vivekBtn;
  final VoidCallback viveoBtn;
  final VoidCallback vivelBtn;
  final VoidCallback cantBtn;
  final VoidCallback sanitariosjBtn;

  MyHomePage({
    required this.showRoute,
    required this.destinationLocation,
    required this.updateRoute,
    required this.lanchonete1Btn,
    required this.lanchonete2Btn,
    required this.button5Function,
    required this.secretariaButtonFunction,
    required this.financeiroButtonFunction,
    required this.uatiButtonFunction,
    required this.lojaButtonFunction,
    required this.laboratorionutricaoButtonFunction,
    required this.laboratorioanatomiaButtonFunction,
    required this.sanitarioscdeButtonFunction,
    required this.labbiocienciasButtonFunction,
    required this.labquimicaButtonFunction,
    required this.labtecnologiafarmae007ButtonFunction,
    required this.labanalisemedicase007ButtonFunction,
    required this.anfiteatroe001ButtonFunction,
    required this.anfiteatroe002ButtonFunction,
    required this.salasmet1ButtonFunction,
    required this.areasexatasButtonFunction,
    required this.labinfoButtonFunction,
    required this.CapelaButtonFunction,
    required this.areasaudeButtonFunction,
    required this.centraleventosButtonFunction,
    required this.coordextensaoButtonFunction,
    required this.coordpedagogicaButtonFunction,
    required this.comunicacaoButtonFunction,
    required this.posgradButtonFunction,
    required this.pastoralButtonFunction,
    required this.restauranteuniverButtonFunction,
    required this.labgastroButtonFunction,
    required this.nuphisButtonFunction,
    required this.anfilButtonFunction,
    required this.labeng1ButtonFunction,
    required this.labeng2ButtonFunction,
    required this.quadraButtonFunction,
    required this.canteiroButtonFunction,
    required this.setorcomprasButtonFunction,
    required this.clinicaodontoButtonFunction,
    required this.laboperacoesButtonFunction,
    required this.anfiteatrooButtonFunction,
    required this.clinicapsiBtn,
    required this.rampaabBtn,
    required this.rampacdeBtn,
    required this.rampafgBtn,
    required this.rampajBtn,
    required this.rampakBtn,
    required this.meiolBtn,
    required this.rampaoBtn,
    required this.sanitariosoBtn,
    required this.enfermagemBtn,
    required this.viveabBtn,
    required this.vivecdeBtn,
    required this.vivefgBtn,
    required this.vivejBtn,
    required this.vivekBtn,
    required this.viveoBtn,
    required this.vivelBtn,
    required this.cantBtn,
    required this.sanitariosjBtn,
  });

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();
  List<String> allLocations = [];
  List<String> filteredLocations = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    filteredLocations = allLocations;
    searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _initializeLocations() {
    blockOptions.forEach((block, floors) {
      floors.forEach((floor, locations) {
        allLocations.addAll(locations.map((location) => '$location ($floor, $block)'));
      });
    });
  }

  void _filterLocations() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredLocations = allLocations.where((location) {
        return location.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredBlocks = blockKeys.where((block) {
      return blockOptions[block]!.entries.any((entry) {
        return entry.value.any((option) =>
            option.toLowerCase().contains(_searchText.toLowerCase()));
      });
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Pesquisar...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (text) {
            setState(() {
              _searchText = text;
            });
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            ...blockKeys.map((block) {
              if (!filteredBlocks.contains(block)) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bloco $block:', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...blockOptions[block]!.entries.where((entry) {
                    if (entry.key.toLowerCase().contains(_searchText.toLowerCase())) {
                      return true;
                    }
                    return entry.value.any((option) =>
                        option.toLowerCase().contains(_searchText.toLowerCase()));
                  }).map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ...entry.value.where((option) =>
                            option.toLowerCase().contains(_searchText.toLowerCase()))
                            .map((option) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TextButton(
                              onPressed: () {
                                if (option.contains('Biblioteca')) {
                                  widget.button5Function();
                                } else if (option.contains('Secretaria Acadêmica')) {
                                  widget.secretariaButtonFunction();
                                } else if (option.contains('Financeiro')) {
                                  widget.financeiroButtonFunction();
                                } else if (option.contains('UATI')) {
                                  widget.uatiButtonFunction();
                                } else if (option.contains('Recursos Humanos')) {
                                  widget.financeiroButtonFunction();
                                } else if (option.contains('Pró Reitoria')) {
                                  widget.rampaabBtn();
                                } else if (option.contains('Lanchonete 1')) {
                                  widget.lanchonete1Btn();
                                } else if (option.contains('Lanchonete 2')) {
                                  widget.lanchonete2Btn();
                                } else if (option.contains('Loja UNISAGRADO STORE')) {
                                  widget.lojaButtonFunction();
                                } else if (option.contains('Laboratório de Nutrição')) {
                                  widget.laboratorionutricaoButtonFunction();
                                } else if (option.contains('Laboratório de Anatomia')) {
                                  widget.laboratorioanatomiaButtonFunction();
                                } else if (option.contains('Sanitários - Bloco C/D/E')) {
                                  widget.sanitarioscdeButtonFunction();
                                } else if (option.contains('Brinquedoteca')) {
                                  widget.rampacdeBtn();
                                } else if (option.contains('Laboratório de Biociências')) {
                                  widget.labbiocienciasButtonFunction();
                                } else if (option.contains('Laboratório de Química')) {
                                  widget.labquimicaButtonFunction();
                                } else if (option.contains('Laboratório de Tecnologia Farmacêutica - E007')) {
                                  widget.labtecnologiafarmae007ButtonFunction();
                                } else if (option.contains('Laboratório de Análise de Medicamentos - E007')) {
                                  widget.labanalisemedicase007ButtonFunction();
                                } else if (option.contains('Anfiteatro - E001')) {
                                  widget.anfiteatroe001ButtonFunction();
                                } else if (option.contains('Anfiteatro - E002')) {
                                  widget.anfiteatroe002ButtonFunction();
                                } else if (option.contains('Sala Metodologias Ativas 1')) {
                                  widget.salasmet1ButtonFunction();
                                } else if (option.contains('Área Exatas, Humanas e Sociais')) {
                                  widget.areasexatasButtonFunction();
                                } else if (option.contains('Laboratório de Informática')) {
                                  widget.labinfoButtonFunction();
                                } else if (option.contains('Capela')) {
                                  widget.CapelaButtonFunction();
                                } else if (option.contains('Área da Saúde')) {
                                  widget.areasaudeButtonFunction();
                                } else if (option.contains('Central de Eventos')) {
                                  widget.centraleventosButtonFunction();
                                } else if (option.contains('Coordenadoria de Extensão')) {
                                  widget.coordextensaoButtonFunction();
                                } else if (option.contains('Coordenadoria Pedagógica')) {
                                  widget.coordpedagogicaButtonFunction();
                                } else if (option.contains('Comunicação')) {
                                  widget.comunicacaoButtonFunction();
                                } else if (option.contains('Pós Graduação e Iniciação Científica')) {
                                  widget.posgradButtonFunction();
                                } else if (option.contains('Pastoral')) {
                                  widget.pastoralButtonFunction();
                                } else if (option.contains('Restaurante Universitário')) {
                                  widget.restauranteuniverButtonFunction();
                                } else if (option.contains('Lab. de Gastronomia')) {
                                  widget.labgastroButtonFunction();
                                } else if (option.contains('NUPHIS')) {
                                  widget.nuphisButtonFunction();
                                } else if (option.contains('Clínica de Psicologia')) {
                                  widget.clinicapsiBtn();
                                } else if (option.contains('Anfiteatro Bloco L')) {
                                  widget.anfilButtonFunction();
                                } else if (option.contains('Laboratórios Engenharias 1')) {
                                  widget.labeng1ButtonFunction();
                                } else if (option.contains('Laboratórios Engenharias 2')) {
                                  widget.labeng2ButtonFunction();
                                } else if (option.contains('Quadra Poliesportiva')) {
                                  widget.quadraButtonFunction();
                                } else if (option.contains('Canteiro Experimental / Área de Produção Vegetal')) {
                                  widget.cantBtn();
                                } else if (option.contains('Setor de Compras / Almoxarifado')) {
                                  widget.setorcomprasButtonFunction();
                                } else if (option.contains('Clínica de Odontologia')) {
                                  widget.clinicaodontoButtonFunction();
                                } else if (option.contains('Laboratório de Operações Unitárias')) {
                                  widget.laboperacoesButtonFunction();
                                } else if (option.contains('Anfiteatro Bloco O')) {
                                  widget.anfiteatrooButtonFunction();
                                } else if (option.contains('Reitoria')) {
                                  widget.rampaabBtn();
                                } else if (option.contains('Reitoria')) {
                                  widget.rampaabBtn();
                                } else if (option.contains('Salas de Aula C')) {
                                  widget.rampacdeBtn();
                                } else if (option.contains('Salas de Aula D')) {
                                  widget.rampacdeBtn();
                                } else if (option.contains('Salas de Aula E')) {
                                  widget.rampacdeBtn();
                                } else if (option.contains('Sala Metodologias Ativas 2')) {
                                  widget.rampacdeBtn();
                                } else if (option.contains('Sala Metodologias Ativas 3')) {
                                  widget.rampacdeBtn();
                                } else if (option.contains('Salas de Aula F')) {
                                  widget.rampafgBtn();
                                } else if (option.contains('Salas de Aula G')) {
                                  widget.rampafgBtn();
                                } else if (option.contains('Laboratório de Projetos')) {
                                  widget.rampajBtn();
                                } else if (option.contains('NEPRI')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Auditório João Paulo II')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Auditório Clélia Merloni')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Salas de Aula J')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Núcleo de Produção Multimídia')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Laboratório de Criação em Vestuários - J301')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Laboratório de Modelos e Maquetes - J309')) {
                                  widget.rampajBtn();
                                } else if (option.contains('Clínica de Fisioterapia')) {
                                  widget.rampakBtn();
                                } else if (option.contains('Laboratório Multidisciplinar')) {
                                  widget.rampakBtn();
                                } else if (option.contains('Salas de Aula K')) {
                                  widget.rampakBtn();
                                } else if (option.contains('Laboratório Zoobotânico')) {
                                  widget.rampakBtn();
                                } else if (option.contains('Laboratório de Estética e Cosmética')) {
                                  widget.rampakBtn();
                                } else if (option.contains('Salas de Aula L')) {
                                  widget.meiolBtn();
                                } else if (option.contains('Sanitários L')) {
                                  widget.meiolBtn();
                                } else if (option.contains('Salas de Aula O')) {
                                  widget.rampaoBtn();
                                } else if (option.contains('Anfiteatros Bloco O')) {
                                  widget.rampaoBtn();
                                } else if (option.contains('Sanitários O')) {
                                  widget.sanitariosoBtn();
                                } else if (option.contains('Laboratório de Enfermagem')) {
                                  widget.enfermagemBtn();
                                } else if (option.contains('Clínica de Nutrição')) {
                                  widget.enfermagemBtn();
                                } else if (option.contains('Vivencia - Bloco A/B')) {
                                  widget.viveabBtn();
                                } else if (option.contains('Vivencia - Bloco C/D/E')) {
                                  widget.vivecdeBtn();
                                } else if (option.contains('Vivencia - Bloco F/G')) {
                                  widget.vivefgBtn();
                                } else if (option.contains('Vivencia - Bloco J')) {
                                  widget.vivejBtn();
                                } else if (option.contains('Vivencia - Bloco K')) {
                                  widget.vivekBtn();
                                } else if (option.contains('Vivencia - Bloco O')) {
                                  widget.viveoBtn();
                                } else if (option.contains('Vivencia - Bloco L')) {
                                  widget.vivelBtn();
                                } else if (option.contains('Sanitários J')) {
                                  widget.sanitariosjBtn();
                                }
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                                minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 40)),
                                alignment: Alignment.center,
                              ),
                              child: Text(option, style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

const List<String> blockKeys = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'J', 'K', 'L', 'O', 'Q'
];

final Map<String, Map<String, List<String>>> blockOptions = {
  'A': {
    'Térreo': ['Biblioteca', 'Vivencia - Bloco A/B'],
    '1°Andar': ['Reitoria'],
  },
  'B': {
    'Térreo': ['Vivencia - Bloco A/B', 'Secretaria Acadêmica', 'Financeiro', 'UATI'],
    '1°Andar': ['Recursos Humanos', 'Pró Reitoria Administrativa'],
  },
  'C': {
    'Térreo': [
      'Vivencia - Bloco C/D/E',
      'Lanchonete 1',
      'Lanchonete 2',
      'Loja UNISAGRADO STORE',
      'Laboratório de Nutrição',
      'Laboratório de Anatomia',
      'Sanitários - Bloco C/D/E'
    ],
    '1°Andar': ['Salas de Aula C', 'Brinquedoteca'],
  },
  'D': {
    'Térreo': ['Vivencia - Bloco C/D/E', 'Laboratório de Biociências', 'Sanitários - Bloco C/D/E'],
    '1°Andar': ['Salas de Aula D'],
  },
  'E': {
    'Térreo': [
      'Vivencia - Bloco C/D/E',
      'Laboratório de Química',
      'Laboratório de Tecnologia Farmacêutica - E007',
      'Laboratório de Análise de Medicamentos - E007',
      'Anfiteatro - E001',
      'Anfiteatro - E002',
      'Sala Metodologias Ativas 1',
      'Sanitários - Bloco C/D/E'
    ],
    '1°Andar': ['Salas de Aula E', 'Sala Metodologias Ativas 2', 'Sala Metodologias Ativas 3'],
  },
  'F': {
    'Térreo': ['Vivencia - Bloco F/G', 'Área Exatas, Humanas e Sociais', 'Laboratório de Informática'],
    '1°Andar': ['Salas de Aula F'],
  },
  'G': {
    'Térreo': [
      'Vivencia - Bloco F/G',
      'Capela',
      'Área da Saúde',
      'Central de Eventos',
      'Coordenadoria de Extensão',
      'Coordenadoria Pedagógica',
      'Comunicação',
      'Pós Graduação e Iniciação Científica',
      'Pastoral'
    ],
    '1°Andar': ['Salas de Aula G'],
  },
  'J': {
    'Térreo': ['Vivencia - Bloco J', 'Restaurante Universitário', 'Lab. de Gastronomia', 'Sanitários J'],
    '1°Andar': ['Laboratório de Projetos', 'NEPRI', 'Auditório João Paulo II', 'Auditório Clélia Merloni', 'Salas de Aula J'],
    '2°Andar': ['Salas de Aula J'],
    '3°Andar': [
      'Núcleo de Produção Multimídia',
      'Laboratório de Criação em Vestuários - J301',
      'Laboratório de Modelos e Maquetes - J309',
      'Salas de Aula J'
    ],
  },
  'K': {
    'Térreo': ['Vivencia - Bloco K', 'NUPHIS'],
    '1°Andar': ['Clínica de Fisioterapia', 'Clínica de Psicologia', 'Laboratório Multidisciplinar', 'Salas de Aula K'],
    '2°Andar': ['Laboratório Zoobotânico', 'Salas de Aula K'],
    '3°Andar': ['Laboratório de Estética e Cosmética', 'Salas de Aula K'],
  },
  'L': {
    'Térreo': [
      'Vivencia - Bloco L',
      'Anfiteatro Bloco L',
      'Laboratórios Engenharias 1',
      'Laboratórios Engenharias 2',
      'Quadra Poliesportiva',
      'Canteiro Experimental / Área de Produção Vegetal',
      'Sanitários L'
    ],
    '1°Andar': ['Salas de Aula L'],
  },
  'O': {
    'Térreo': [
      'Vivencia - Bloco O',
      'Setor de Compras / Almoxarifado',
      'Clínica de Odontologia',
      'Laboratório de Operações Unitárias',
      'Anfiteatros Bloco O',
      'Sanitários O'
    ],
    '1°Andar': ['Salas de Aula O'],
  },
  'Q': {
    'Térreo': ['Laboratório de Enfermagem', 'Clínica de Nutrição'],
  },
};

class Placa extends StatefulWidget {
  late String blocoAtual = '';
  late int selectedFloor;

  Placa({super.key, required this.blocoAtual, required this.selectedFloor});

  @override
  _PlacaState createState() => _PlacaState();
}

class _PlacaState extends State<Placa> {
  String _magnetometerData = 'No data';
  double _rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initMagnetometer();
  }

  void _initMagnetometer() {
    magnetometerEvents.listen(
          (MagnetometerEvent event) {
        setState(() {
          _magnetometerData =
          'x: ${event.x.toStringAsFixed(2)}, y: ${event.y.toStringAsFixed(
              2)}, z: ${event.z.toStringAsFixed(2)}';
          _updateRotationAngle(event.x, event.y);
        });
      },
      onError: (error) {
      },
      cancelOnError: true,
    );
  }

  void _updateRotationAngle(double x, double y) {
    double angle = atan2(x, y);
    setState(() {
      _rotationAngle = angle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direção das salas'),
        backgroundColor: Colors.red,
      ),
      backgroundColor: Colors.deepOrangeAccent,
      body: Center(
        child: SingleChildScrollView(
            child: _buildContentForBloco(widget.blocoAtual, widget.selectedFloor)
        ),
      ),
    );
  }

  Widget _buildContentForBloco(String bloco, int selectedFloor) {
    switch (bloco) {
      case 'Blocos C, D e E':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bloco',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            const Text(
              'CDE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Text(
                  'ALA PAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                  ),
                ),
                const Spacer(),
                const Text(
                  'ALA ÍMPAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setac.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'C104 - Lab de Praticas Musicais',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Salas - C101 a C129',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(width: 50.0),
                const Flexible(
                  child: Text(
                    'C106 - Lab de Praticas Teatrais',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Salas - D101 a D125',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'E102 a E104 - Lab de Metodologias Ativas',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Salas e Lab - E101 a E111',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
          ],
        );
      case 'Blocos F e G':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bloco',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            const Text(
              'FG',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Text(
                  'ALA PAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                  ),
                ),
                const Spacer(),
                const Text(
                  'ALA ÍMPAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setac.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'F102 a F108 - Salas e Lab de informática',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'F101 a F113 - Salas e Lab de informática',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setac.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'G102 a G108 - Salas',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'G101 a G113 - Salas',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
          ],
        );
      case 'Bloco O':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rampa do Bloco',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            const Text(
              'O',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40.0,
              ),
            ),

            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setaipec.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'Salas - O112 a O122',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Salas - O102 a O110',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setaipdc.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'Auditório O004',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Auditório O002',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'Sanitários',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Sanitários',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
          ],
        );
      case 'Bloco J':
        String andar;
        String L1e;
        String L2e;
        String L3e;
        String L4e;
        String L1d;
        String L2d;
        String L3d;
        String L4d;

        switch (selectedFloor) {
          case 0:
            andar = 'Térreo';
            L1e = 'Restaurante';
            L2e = 'Lanchonete';
            L3e = 'Laboratórios';
            L4e = 'Salas de Aula';
            L1d = 'Lab. de Gastronomia';
            L2d = 'Sanitários';
            L3d = 'Auditórios';
            L4d = 'Nucleo de Produção Multimídia';
            break;
          case 1:
            andar = 'Primeiro Andar';
            L1e = 'Auditório João Paulo II';
            L2e = 'Auditório Clélia Merloni';
            L3e = '';
            L4e = '';
            L1d = 'Salas e Labs. - J101 a J115';
            L2d = '';
            L3d = '';
            L4d = '';
            break;
          case 2:
            andar = 'Segundo Andar';
            L1e = 'Salas - J202 a J222';
            L2e = 'J208 - Sala dos Professores';
            L3e = 'Sanitários';
            L4e = '';
            L1d = 'Salas - J201 a J219';
            L2d = 'Sanitários';
            L3d = '';
            L4d = '';
            break;
          case 3:
            andar = 'Terceiro Andar';
            L1e = 'Salas - J302 a J316';
            L2e = 'Nucleo de Produção Multimídia';
            L3e = 'Sanitários';
            L4e = '';
            L1d = 'Salas e Labs. - J301 a J317';
            L2d = 'Sanitários';
            L3d = '';
            L4d = '';
            break;
          default:
            andar = 'Andar desconhecido';
            L1e = '';
            L2e = '';
            L3e = '';
            L4e = '';
            L1d = '';
            L2d = '';
            L3d = '';
            L4d = '';
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bloco',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            const Text(
              'J',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40.0,
              ),
            ),
            Text(
              andar,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),

            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                Flexible(
                  child: Text(
                    L1e,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    L1d,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                Flexible(
                  child: Text(
                    L2e,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    L2d,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                Flexible(
                  child: Text(
                    L3e,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    L3d,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setaipdc.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setaipec.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                Flexible(
                  child: Text(
                    L4e,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    L4d,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setaipdc.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
          ],
        );

      case 'Bloco L':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bloco:',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            const Text(
              'L',
              style: TextStyle(
                color: Colors.black,
                fontSize: 40.0,
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/setae.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Flexible(
                  child: Text(
                    'Salas - L008 a L014',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Flexible(
                  child: Text(
                    'Salas - L002 a L006',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const Flexible(
                  child: Text(
                    'Sanitários',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const Flexible(
                  child: Text(
                    'Elevador',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAngle ?? 0,
                  child: Image.asset(
                    'images/seta.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ],
            ),
          ],
        );

      default:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nenhum bloco identificado',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),

            Flexible(
              child: Text(
                'Para exibir as direções das salas de um bloco você deve selecionar uma rota',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),),
          ],
        );
    }
  }
}

class Creditos extends StatefulWidget {

  @override
  _CreditosState createState() => _CreditosState();
}

class _CreditosState extends State<Creditos> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos'),
        backgroundColor: Colors.red,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Disciplina:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const Text(
                'Desenvolvimento de Software',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Prof. Dr. Elvio Gilberto da Silva',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Eduardo Dos Santos Martins',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const Text(
                'João Renato Cardoso Marques',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const Text(
                'Leonardo Mota Leite',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const Text(
                'Vinícius Trabuco Gonçalves',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const Text(
                'Yago Vitorato Silva',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Desenvolvimento:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              Image.asset('images/Ciencia_da_Computacao.jpg'),
              const SizedBox(height: 20.0),
              const Text(
                'Apoio:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                ),
              ),
              Image.asset('images/coordenadoria-de-extensao.jpg'),
            ],
          ),
        ),
      ),
    );
  }
}
