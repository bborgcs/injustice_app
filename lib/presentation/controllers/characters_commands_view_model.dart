import '../../core/failure/failure.dart';
import '../../core/patterns/command.dart';
import '../../domain/models/character_entity.dart';
import '../commands/character_commands.dart';
import 'characters_state_viewmodel.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CharactersCommandsViewModel {
  final CharactersStateViewmodel state;
  final GetAllCharactersCommand _getAllCharactersCommand;
  final GetCharacterByIdCommand _getCharacterByIdCommand;
  final CreateCharacterCommand _createCharacterCommand;
  final DeleteCharacterCommand _deleteCharacterCommand;
  final UpdateCharacterCommand _updateCharacterCommand;

  CharactersCommandsViewModel({
    required this.state,
    required GetAllCharactersCommand getAllCharactersCommand,
    required GetCharacterByIdCommand getCharacterByIdCommand,
    required DeleteCharacterCommand deleteCharacterCommand,
    required UpdateCharacterCommand updateCharacterCommand,
    required CreateCharacterCommand createCharacterCommand,
  }) : _getAllCharactersCommand = getAllCharactersCommand,
       _getCharacterByIdCommand = getCharacterByIdCommand,
        _deleteCharacterCommand = deleteCharacterCommand,
        _updateCharacterCommand = updateCharacterCommand,
       _createCharacterCommand = createCharacterCommand {
    // Observers para cada comando
    _observeGetAllCharacters();
    _observeGetCharacterById();
    _observeDeleteCharacter();
    _observeUpdateCharacter();
    _observeCreateCharacter();
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  GetAllCharactersCommand get getAllCharactersCommand => _getAllCharactersCommand;
  GetCharacterByIdCommand get getCharacterByIdCommand => _getCharacterByIdCommand;
  DeleteCharacterCommand get deleteCharacterCommand => _deleteCharacterCommand;
  UpdateCharacterCommand get updateCharacterCommand => _updateCharacterCommand;
  CreateCharacterCommand get createCharacterCommand => _createCharacterCommand;

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    Command<T, Failure> command, {
    required void Function(T data) onSuccess,
    void Function(Failure err)? onFailure,
  }) {
    effect(() {
      // 1) Ignora enquanto está executando
      if (command.isExecuting.value) return;

      // 2) Ignora até existir um resultado
      final result = command.result.value;
      if (result == null) return;

      // 3) Sucesso ou falha
      result.fold(
        onSuccess: (data) {
          state.clearMessage(); // sempre limpa erros em sucesso
          onSuccess(data); // ação específica para esse comando
          command.clear();
        },
        onFailure: (err) {
          state.setMessage(err.msg); // registra o erro no estado
          if (onFailure != null) onFailure(err);
          command.clear();
        },
      );
    });
  }

  // ========================================================
  //   OBSERVERS ESPECÍFICOS
  // ========================================================

  /// Buscar todos os personagens
  void _observeGetAllCharacters() {
    _observeCommand<List<Character>>(
      _getAllCharactersCommand,
      onSuccess: (characters) {
        state.clearMessage(); // Limpa mensagens anteriores
        state.state.value = characters;
      },
      onFailure: (err) =>
          state.setMessage(err.msg), // registra o erro no estado
    );
  }

  /// Buscar personagem por ID
  void _observeGetCharacterById() {
    _observeCommand<Character>(
      _getCharacterByIdCommand,
      onSuccess: (character) {
        
        // Atualiza o personagem específico na lista, se necessário
        final currentList = state.state.value;
        final index = currentList.indexWhere((c) => c.id == character.id);
        if (index != -1) {
          currentList[index] = character; // Atualiza o personagem na lista
          state.state.value = [...currentList]; // Gera uma nova lista para notificar os listeners
        }
      },
      onFailure: (err) =>
          state.setMessage(err.msg), // registra o erro no estado
    );
  }
    

  /// Criar um novo personagem
  void _observeCreateCharacter() {  
    _observeCommand<Character>(
      _createCharacterCommand,
      onSuccess: (newCharacter) {
        final currentList = state.state.value;
        final newlist = [...currentList, newCharacter]; // Adiciona o novo personagem à lista
        state.state.value = newlist; 
      },
      onFailure: (err) =>
          state.setMessage(err.msg), // registra o erro no estado
    );
  }

  /// Deletar um personagem
  void _observeDeleteCharacter() {
    _observeCommand<Character>(
      _deleteCharacterCommand,
      onSuccess: (deletedCharacter) {
        final currentList = state.state.value;

        state.state.value =
            currentList.where((c) => c.id != deletedCharacter.id).toList();
      },
      onFailure: (err) => state.setMessage(err.msg),
    );
  }

  /// Atualizar um personagem
  void _observeUpdateCharacter() {
    _observeCommand<Character>(
      _updateCharacterCommand,
      onSuccess: (updatedCharacter) {
        final currentList = state.state.value;

        final index =
            currentList.indexWhere((c) => c.id == updatedCharacter.id);

        if (index != -1) {
          currentList[index] = updatedCharacter;
          state.state.value = [...currentList];
        }
      },
      onFailure: (err) => state.setMessage(err.msg),
    );
  }

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  //   que disparam os commands
  // ========================================================
  /// buscca personagens e atualiza o estado
  Future<void> fetchCharacters() async {
    state.clearMessage(); // Limpa mensagens anteriores
    await _getAllCharactersCommand.executeWith(());
  }

  /// adiciona personagem e atualiza o estado
  Future<void> addCharacter(Character character) async {
    state.clearMessage(); // Limpa mensagens anteriores
    await _createCharacterCommand.executeWith((character: character));
  }

  /// deleta personagem e atualiza o estado
  Future<void> deleteCharacter(String id) async {
    state.clearMessage(); // Limpa mensagens anteriores
    await _deleteCharacterCommand.executeWith((id: id));
  }

  /// atualiza personagem e atualiza o estado
  Future<void> updateCharacter(Character character) async {
    state.clearMessage(); // Limpa mensagens anteriores
    await _updateCharacterCommand.executeWith((character: character));
  }

  
}
