import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/di/dependency_injection.dart';
import '../../core/messages/app_messages.dart';
import '../../core/theme/app_theme.dart';
import '../../core/typedefs/types_defs.dart';
import '../../core/validators/empty_str_validator.dart';
import '../../core/validators/text_field_validator.dart';

import '../../domain/models/character_entity.dart';
import '../controllers/characters_view_model.dart';
import '../controllers/characters_state_viewmodel.dart';

class CharacterCreateView extends StatefulWidget {
  final Character? character;

  const CharacterCreateView({super.key, this.character});

  @override
  State<CharacterCreateView> createState() => _CharacterCreateViewState();
}

class _CharacterCreateViewState extends State<CharacterCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final CharactersViewModel _vmCharacter;

  final _nameController = TextEditingController();

  CharacterClass? _characterClass;
  CharacterRarity? _rarity;
  CharacterAlignment? _alignment;

  int _level = 1;
  int _threat = 0;
  int _attack = 0;
  int _health = 0;
  int _stars = 1;

  DateTime _createdAt = DateTime.now();
  String? _editingCharacterId;

  late final void Function() _disposeSuccessEffect;
  late final void Function() _disposeErrorEffect;

  @override
  void initState() {
    super.initState();

    _vmCharacter = injector.get<CharactersViewModel>();

    if (widget.character != null) {
      final c = widget.character!;

      _editingCharacterId = c.id;
      _nameController.text = c.name;
      _characterClass = c.characterClass;
      _rarity = c.rarity;
      _alignment = c.alignment;
      _level = c.level;
      _threat = c.threat;
      _attack = c.attack;
      _health = c.health;
      _stars = c.stars;
      _createdAt = c.createdAt;
    }

    /// SUCCESS
    _disposeSuccessEffect = effect(() {
  final success = _vmCharacter.charactersState.successEvent.value;

  if (success != null && mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String message = '';

      switch (success) {
        case CharacterSuccessEvent.created:
          message = 'Personagem criado com sucesso!';
          break;
        case CharacterSuccessEvent.updated:
          message = 'Personagem atualizado com sucesso!';
          break;
        case CharacterSuccessEvent.deleted:
          message = 'Personagem deletado com sucesso!';
          break;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      Navigator.pop(context); 

      _vmCharacter.charactersState.clearSuccessEvent();
    });
  }
});

    /// ERROR
    _disposeErrorEffect = effect(() {
      final error = _vmCharacter.charactersState.errorMessage.value;

      if (error != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));

          _vmCharacter.charactersState.clearMessage();
        });
      }
    });
  }

  @override
  void dispose() {
    _disposeSuccessEffect();
    _disposeErrorEffect();
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validateForm() => _formKey.currentState!.validate();

  Future<void> _salvar() async {
    print('Salvar personagem');
    if (!_validateForm()) return;

    final character = Character(
      id: _editingCharacterId ?? UniqueKey().toString(),
      name: _nameController.text.trim(),
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

    if (_editingCharacterId != null) {
    _vmCharacter.commands.updateCharacterCommand.parameter =
        (character: character);

    await _vmCharacter.commands.updateCharacterCommand.execute();
    } else {
    _vmCharacter.commands.createCharacterCommand.parameter =
        (character: character);

    await _vmCharacter.commands.createCharacterCommand.execute();

    
print('✅ Execute terminou');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personagem')),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// NOME
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) {
                final validator = TextFieldValidator(
                    validators: [EmptyStrValidator()],
                );

                final isValid = validator.validations(v);

                return isValid ? null : 'Nome é obrigatório';
                },
              ),

              const SizedBox(height: 16),
              /// CLASSE
              DropdownButtonFormField<CharacterClass>(
                value: _characterClass,
                decoration: const InputDecoration(labelText: 'Classe'),
                items: CharacterClass.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _characterClass = value);
                },
                validator: (value) => value == null ? 'Selecione uma classe' : null,
              ),

              const SizedBox(height: 16),
              /// RARIDADE
              DropdownButtonFormField<CharacterRarity>(
                value: _rarity,
                decoration: const InputDecoration(labelText: 'Raridade'),
                items: CharacterRarity.values.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(r.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _rarity = value);
                },
                validator: (value) => value == null ? 'Selecione uma raridade' : null,
              ),


              const SizedBox(height: 16),
              /// ALINHAMENTO
              DropdownButtonFormField<CharacterAlignment>(
                value: _alignment,
                decoration: const InputDecoration(labelText: 'Alinhamento'),
                items: CharacterAlignment.values.map((a) {
                  return DropdownMenuItem(
                    value: a,
                    child: Text(a.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _alignment = value);
                },
                validator: (value) => value == null ? 'Selecione um alinhamento' : null,
              ),

              const SizedBox(height: 16),
              /// BOTÕES
              Row(
                children: [
                  Expanded(
                    child: Watch((_) {
                      final isLoading =
                        _vmCharacter.commands.createCharacterCommand.isExecuting.value ||
                        _vmCharacter.commands.updateCharacterCommand.isExecuting.value;

                      return ElevatedButton(
                        onPressed: isLoading ? null : _salvar,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('SALVAR'),
                      );
                    }),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}