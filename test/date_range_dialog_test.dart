import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vacation_itinerary/shared/widgets/inputs/date_range_dialog.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // A curva com quique (easeOutBack) passa do alvo: ao tirar a sombra da
  // data selecionada, o desfoque ia abaixo de zero por um quadro e o
  // Flutter lançava. Este teste anda quadro a quadro para pegar isso.
  testWidgets('trocar a seleção não lança em nenhum quadro', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTripDatesDialog(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    Future<void> tapAndStep(String day) async {
      await tester.tap(find.text(day).last);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // Ida, volta, nova ida (desfaz a seleção anterior), ida antes da ida.
    await tapAndStep('10');
    await tapAndStep('15');
    await tapAndStep('20');
    await tapAndStep('5');
    await tapAndStep('22');
    expect(tester.takeException(), isNull);
  });
}
