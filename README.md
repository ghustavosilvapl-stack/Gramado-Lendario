# Gramado Lendário — protótipo 3D jogável

Este é o primeiro núcleo 3D do projeto, feito para Godot 4.3+ com renderizador Compatibility, adequado para começar a testar em Android.

## O que já está no código
- Campo 3D, linhas, arquibancadas, gols simplificados, iluminação e ambiente.
- Jogadores 3D em duas equipes e bola com física.
- Movimento do jogador, corrida, passe e chute.
- IA inicial para adversários e movimentação básica dos companheiros.
- Câmera que acompanha o jogador.
- HUD de placar/cronômetro e botões de toque.
- Alternância inicial entre perfil Realista (até 60 FPS) e Otimizado (até 30 FPS).

## Como abrir
1. Instale Godot 4.3 ou superior.
2. Abra o Godot Project Manager e importe a pasta deste projeto selecionando `project.godot`.
3. Execute com F6/F5.

## Controles no computador
- WASD: movimentar
- Shift: correr
- J: passe (perto da bola)
- K: chute (perto da bola)

No Android, use o joystick virtual no canto inferior esquerdo e os botões de toque à direita. A seleção manual de jogador ainda precisa ser implementada na próxima etapa.

## Estado e limitações
É um protótipo inicial, não um jogo completo nem um APK pronto. Ainda faltam joystick virtual, goleiros funcionais, regras completas, faltas/cartões/escanteios/pênaltis, animações, modelos humanos detalhados, menus, modos carreira/gestão, conteúdo de ligas e otimização/testes em aparelhos reais. Os perfis gráficos são uma primeira configuração de desempenho, não dois pacotes visuais finais.
