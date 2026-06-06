import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmhub/core/theme/app_theme.dart';
import 'package:farmhub/core/theme/app_colors.dart';

void main() {
  testWidgets('AppTheme lightTheme applies dark blue theme colors smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                children: [
                  Text('Text', style: theme.textTheme.bodyLarge),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Button'),
                  ),
                  const Card(
                    child: Text('Card'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Verify theme brightness is dark (since the Dark Blue theme uses ColorScheme.dark)
    final BuildContext context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });
}
