# Artes da equipe — cutscenes

Arquivos fornecidos pelo usuário em `/home/fbrandes/Imagens/Sprites EMA/`,
atribuídos por ele à equipe de arte do projeto. Foram copiados sem alterações;
nomes de destino usam caminhos sem espaços/acentos para facilitar as referências.
Os arquivos de origem permanecem intactos. Registrar os nomes dos autores nos
créditos quando definidos pela equipe.

| Destino | Origem dentro de `Sprites EMA` |
| --- | --- |
| `backgrounds/poste.png` | `Cenários /poste.png` |
| `backgrounds/floresta.png` | `Cenários /floresta.png` |
| `backgrounds/riacho.png` | `Cenários /riacho.png` |
| `backgrounds/rua.png` | `Cenários /rua.png` |
| `backgrounds/poste_chuvoso.png` | `Cenários /posteChuvoso.png` |
| `backgrounds/veterinario.png` | `Cenários /veterinario.png` |
| `characters/tob_triste.png` | `Sprites/Triste/Frame01.png` |
| `characters/tob_doente.png` | `Sprites/Doente/Frame01.png` |
| `characters/tob_feliz.png` | `Sprites/Feliz/Frame01.png` |
| `characters/tob_filhote.png` | `Sprites/Filhote/Frame01.png` |
| `backgrounds/sala_tapete.png` | `Cenários /salaTapete.png` |
| `characters/tob_triste_deitado.png` | `Sprites/TristeDeitado/Frame01.png` |
| `characters/tob_feliz_deitado.png` | `Sprites/FelizDeitado/Frame01.png` |
| `characters/mae_tob.png` | `Sprites/MaeTob/Frame01.png` |

As imagens têm canvas comum de 1024 × 512 pixels. Os sprites mantêm sua
transparência e posição nesse canvas; não recortar suas margens transparentes,
pois elas determinam o alinhamento sobre o fundo. O motor exibe fundo e camadas
com o mesmo enquadramento proporcional e filtro nearest.

Nesta integração, somente os primeiros frames estáticos foram utilizados nas
cutscenes, incluindo o cenário chuvoso da terceira fase. As sequências animadas e os cenários de fases futuras não foram
importados, e o sprite de Tob na gameplay não foi substituído.

Na quarta fase, o Tob doente foi associado à introdução e a arte da clínica foi
integrada como ilustração do ambiente veterinário. Não foram feitas alterações
nos PNGs originais.

Na quinta fase, Tob triste deitado aparece na introdução e no encerramento
temporário. O final de adoção usa a sala com tapete e Tob feliz deitado.
