import 'package:flutter/material.dart';
import 'widgets/characters_app_bar.dart';
import 'widgets/characters_body.dart';
import 'widgets/characters_floating_button.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/account_entity.dart';
import '../../../../domain/models/character_entity.dart';
import '../../../../domain/models/extensions/character_ui.dart';
import '../../../controllers/characters_state_viewmodel.dart';
import '../../../controllers/characters_view_model.dart';
import '../../../widgets/account_summary_card.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/star_rating.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Página de listagem de personagens
class CharactersView extends StatefulWidget {
  final Account account;

  const CharactersView({super.key, required this.account});

  @override
  State<CharactersView> createState() => _CharactersViewState();
}

class _CharactersViewState extends State<CharactersView> {
  late final CharactersViewModel _viewModel;
  Account get account => widget.account;

  @override
  void initState() {
    super.initState();
    _viewModel = injector.get<CharactersViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.commands.fetchCharacters();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _viewModel.refresh();
  }

  Future<void> _deleteCharacter(Character character) async {
    _viewModel.commands.deleteCharacterCommand.parameter =
      (id: character.id);

      await _viewModel.commands.deleteCharacterCommand.execute();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${character.name} removido')),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CharactersAppBar(state: _viewModel.charactersState),

      drawer: AppDrawer(),
      body: CharactersBody(account: account, viewModel: _viewModel),
      floatingActionButton: CharactersFab(viewModel: _viewModel),
    );
  }
}

