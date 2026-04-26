import 'package:flutter/material.dart';
import '../../core/di/dependency_injection.dart';
import '../../core/failure/failure.dart';
import '../../core/messages/app_messages.dart';
import '../../core/theme/app_theme.dart';
import '../../core/typedefs/types_defs.dart';
import '../../core/validators/empty_str_validator.dart';
import '../../core/validators/text_field_validator.dart';
import '../../domain/entities/character_entity.dart';
import '../controllers/character_state_viewmodel.dart';
import '../controllers/character_viewmodel.dart';


import 'package:signals_flutter/signals_flutter.dart';

/// Página de cadastro de personagem
class CharacterCreateView extends StatefulWidget {
  const CharacterCreateView({super.key});

  @override
  State<CharacterCreateView> createState() => _CharacterCreateViewState();
}

class _CharacterCreateViewState extends State<CharacterCreateView> {
  //late final CharacterViewModel viewModel;

  late final CharacterViewModel _vmCharacter;
  late final void Function() _disposeCharacterEffect;
  late final void Function() _disposeSuccessEffect;
  late final void Function() _disposeErrorEffect;

  @override
  void initState() {
    super.initState();
    _formFields = CharacterFormFieldsController();

    _vmCharacter = injector.get<CharacterViewModel>();
    _vmCharacter.accountState.clearMessage();
    _vmCharacter.accountState.clearSuccessEvent();

    _disposeCharacterEffect =effect(() {
      final character = _vmCharacter.accountState.characterEffect.value;
      
      if (character != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personagem criado com sucesso!')),
        );
      } else {
        _limparCampos();
      }
    });

    _disposeErrorEffect = effect(() {
      final errorMessage = _vmCharacter.characterState.errorMessage.value;

        if (errorMessage != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
        showSnackBar(context, errorMessage, backgroundColor: Colors.red);

          _vmCharacter.characterState.clearMessage();
        });
        }
    });

    _disposeSuccessEffect = effect(() {
      final successMessage = _vmCharacter.accountState.successEvent.value;

        if (successMessage != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                String message;
                Color color;
                
                switch (event) {
                    case CharacterSucessEvent.created:
                        message = 'Personagem criado com sucesso!';
                        color = Colors.green;
                        
                    case CharacterSucessEvent.updated:
                        message = 'Personagem atualizado com sucesso!';
                        color = Colors.green;

                    case CharacterSucessEvent.deleted:
                        message = 'Personagem deletado com sucesso!';
                        color = Colors.red.shade400;
                }
                showSnackBar(context, message, backgroundColor: color);

            _vmCharacter.characterState.clearSuccessEvent();
            });
        }
    });
  }

  @override
  void dispose() {
    _disposeAccountEffect();
    _disposeSuccessEffect();
    _disposeErrorEffect();

    _scrollController.dispose();

    _formFields.dispose();
    super.dispose();
  }

  void _preencherCampos(Character character) {
    _formFields.name.controller.text = character.name;

    _createdAt = character.createdAt;
    _characterClass = character.characterClass;
    _rarity = character.rarity;
    _level = character.level;
    _threat = character.threat;
    _attack = character.attack;
    _health = character.health;
    _stars = character.stars;
    _alignment = character.alignment;

    setState(() {});
  }

    void _limparCampos() {
        _formKey.currentState?.reset();
        _formFields.clear();
    
        _createdAt = DateTime.now();
        _characterClass = null;
        _rarity = null;
        _level = 1;
        _threat = 0;
        _attack = 0;
        _health = 0;
        _stars = 1;
        _alignment = null;
    
        setState(() {});
    }

    void _resetFormView() {
        // Remove foco de qualquer TextField
        FocusScope.of(context).unfocus();

        // Rola para o topo
        _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        );
    }

    void _focusFirstError() {
        for (final field in _formFields.fields) {
        final state = field.key.currentState;

        if (state != null && !state.isValid) {
            field.focus.requestFocus();

            Scrollable.ensureVisible(
            field.key.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            );

            break;
        }
        }
    }

    bool _validateForm() {
        final valid = _formKey.currentState!.validate();

        if (!valid) {
        _focusFirstError();
        }

        return valid;
    }

    Future<void> _salvarPersonagem() async {
        if (!_validateForm()) return;

        Character newCharacter = Character(
            id: _editingCharacterId ?? UniqueKey().toString(),
            name: _formFields.name.controller.text.trim(),
            characterClass: _characterClass!,
            rarity: _rarity!,
            level: _level,
            threat: _threat,
            attack: _attack,
            health: _health,
            stars: _stars,
            alignment: _alignment!,
            createdAt: _createdAt,
            updatedAt: DateTime.now(),
        );

        if (_vmCharacter.characterState.hasCharacter.value) {
            await _vmCharacter.commands.updateCharacter(newCharacter);
        } else {
            await _vmCharacter.commands.saveCharacter(newCharacter);
        }

        _resetFormView();
    }

    Future<void> _excluirPersonagem() async {
        final confirm = await confirmDialog(
        context,
        title: 'Excluir personagem',
        message:
            'Tem certeza que deseja excluir este personagem?\n\n'
            'Esta ação não poderá ser desfeita.',
        confirmText: 'EXCLUIR',
        );

        if (!confirm) return;

        await _vmCharacter.commands.deleteCharacter();
        _formKey.currentState?.reset();
        _formFields.clear();
        _resetFormView();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: const Text('Criar Personagem'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            children: [
                // Formulário de criação de personagem
                CharacterForm(onSubmit: (character) async {
                viewModel.commands.createCharacterCommand.parameter =
                    CharacterParams(character: character);

                final result = await viewModel.commands.createCharacterCommand.execute();

                result.fold(
                    (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppMessages.getFailureMessage(failure))),
                    ),
                    (success) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Personagem criado com sucesso!')),
                    ),
                );
                }),
            ],
            ),
        ),
        );
    }
    }