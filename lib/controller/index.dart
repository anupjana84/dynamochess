import 'package:dynamochess/controller/home_Controller.dart';
import 'package:get/get.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
  }
}
