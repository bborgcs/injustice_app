import 'package:flutter/material.dart';
import '../../../../../helper_dev/fakes/character_factory.dart';
import '../../../../controllers/characters_view_model.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:injustice_app/core/typedefs/types_defs.dart';
import 'package:injustice_app/presentation/views/character_create_view.dart';

class CharactersFab extends StatelessWidget {
  final CharactersViewModel viewModel;

  const CharactersFab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isExecuting =
          viewModel.commands.createCharacterCommand.isExecuting.value;

      return FloatingActionButton(
        onPressed: isExecuting
        ? null
        : () {
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return const CharacterCreateView(
                  onSubmit: (character) async {
                    viewModel.createCharacterCommand.parameter =
                        CharacterParams(character: character);

                    await viewModel.createCharacterCommand.execute();
                  },
                );
              },
            );
          },
        child: isExecuting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
      );
    });
  }
}
