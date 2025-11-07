import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import 'package:caldensmartfabrica/aws/dynamo/dynamo_certificates.dart';
import 'package:caldensmartfabrica/master.dart';

Future<void> queryItems(String pc, String sn) async {
  try {
    printLog("Buscando Item");
    final response = await service.query(
      tableName: 'sime-domotica',
      keyConditionExpression: 'product_code = :pk AND device_id = :sk',
      expressionAttributeValues: {
        ':pk': AttributeValue(s: pc),
        ':sk': AttributeValue(s: sn),
      },
    );

    if (response.items != null) {
      printLog('Items encontrados');
      for (var item in response.items!) {
        printLog(item);
        owner = item['owner']?.s ?? '';
        distanceOn = item['distanceOn']?.n ?? '3000';
        distanceOff = item['distanceOff']?.n ?? '100';
        secAdmDate =
            item['DateSecAdm']?.s ?? 'No tiene activado este beneficio';
        atDate = item['DateAT']?.s ?? 'No tiene activado este beneficio';
        secondaryAdmins = item['secondary_admin']?.ss ?? [];
        if (secondaryAdmins.contains('') && secondaryAdmins.length == 1) {
          secondaryAdmins = [];
        }
        isConnectedToAWS = item['cstate']?.boolValue ?? false;
        hasEntry = item['hasEntry']?.boolValue ?? false;
        hasSpark = item['hasSpark']?.boolValue ?? false;
        labProcessFinished = item['LabProcessFinished']?.boolValue ?? false;
        distanceControlActive =
            item['distanceControlActive']?.boolValue ?? false;
        riegoActive = item['riegoActive']?.boolValue ?? false;
        riegoMaster = item['riegoMaster']?.s ?? '';

        // Leer historicTemp
        if (item['historicTemp']?.m != null) {
          historicTemp.clear();
          item['historicTemp']!.m!.forEach((key, value) {
            if (value.n != null) {
              historicTemp[key] = value.n!;
            }
          });
        }
        historicTempPremium = item['historicTempPremium']?.boolValue ?? false;
      }
    } else {
      printLog('Dispositivo no encontrado');
    }
  } catch (e) {
    printLog('Error durante la consulta: $e');
  }
}

Future<void> putOwner(String pc, String sn, String data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'owner': AttributeValueUpdate(value: AttributeValue(s: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putDistanceOn(String pc, String sn, String data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'distanceOn': AttributeValueUpdate(value: AttributeValue(n: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putDistanceOff(String pc, String sn, String data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'distanceOff': AttributeValueUpdate(value: AttributeValue(n: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putSecondaryAdmins(String pc, String sn, List<String> data) async {
  if (data.isEmpty) {
    data.add('');
  }
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'secondary_admin': AttributeValueUpdate(value: AttributeValue(ss: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putDate(String pc, String sn, String data, bool at) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      at ? 'DateAT' : 'DateSecAdm':
          AttributeValueUpdate(value: AttributeValue(s: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putLabProcessFinished(String pc, String sn, bool done) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'LabProcessFinished':
          AttributeValueUpdate(value: AttributeValue(boolValue: done)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<bool> getConnection(String pc, String sn) async {
  try {
    final response = await service.getItem(
      tableName: 'sime-domotica',
      key: {
        'product_code': AttributeValue(s: pc),
        'device_id': AttributeValue(s: sn),
      },
    );
    if (response.item != null) {
      // Convertir AttributeValue a String
      var item = response.item!;
      bool o = item['cstate']?.boolValue ?? false;
      return o;
    } else {
      printLog('Item no encontrado.');
      return false;
    }
  } catch (e) {
    printLog('Error al obtener el item: $e');
    return false;
  }
}

Future<void> putHasEntry(String pc, String sn, bool data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'hasEntry': AttributeValueUpdate(value: AttributeValue(boolValue: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putHasSpark(String pc, String sn, bool data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'hasSpark': AttributeValueUpdate(value: AttributeValue(boolValue: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putDistanceControl(String pc, String sn, bool data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'distanceControlActive':
          AttributeValueUpdate(value: AttributeValue(boolValue: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putRiego(String pc, String sn, bool data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'riegoActive':
          AttributeValueUpdate(value: AttributeValue(boolValue: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> putRiegoMaster(String pc, String sn, String data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'riegoMaster': AttributeValueUpdate(value: AttributeValue(s: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<void> removeRiegoMaster(String pc, String sn) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'riegoMaster': AttributeValueUpdate(
        action: AttributeAction.delete,
      ),
    });

    printLog('RiegoMaster eliminado perfectamente $response');
  } catch (e) {
    printLog('Error eliminando riegoMaster: $e');
  }
}

Future<void> putHistoricTempPremium(String pc, String sn, bool premium) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'historicTempPremium':
          AttributeValueUpdate(value: AttributeValue(boolValue: premium)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}
