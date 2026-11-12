import 'package:flutter/material.dart';

/// Ponto de corte celular/tablet, seguindo a convenção do Material (600dp).
/// Usamos `shortestSide` (o menor lado da tela) porque ele não muda quando
/// o aparelho gira — um tablet continua "tablet" tanto em retrato quanto em
/// paisagem, diferente de `width` sozinho.
const double _tabletBreakpoint = 600;

bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= _tabletBreakpoint;

bool isLandscape(BuildContext context) =>
    MediaQuery.orientationOf(context) == Orientation.landscape;

/// Escolhe um valor conforme o dispositivo, pra não espalhar
/// `isTablet(context) ? x : y` por tudo quanto é widget de tela.
T responsiveValue<T>(
  BuildContext context, {
  required T phone,
  required T tablet,
}) => isTablet(context) ? tablet : phone;

/// Limite de largura pro conteúdo de telas com listas/grades de cards
/// (escolha de jogo, dificuldade, fase). Sem isso, num tablet em paisagem o
/// conteúdo esticaria até a borda da tela com um espaçamento gigante entre
/// cards; com isso, ele centraliza como um "cartão" de largura confortável.
/// `double.infinity` no celular mantém o comportamento de sempre (sem limite).
double maxContentWidth(BuildContext context) =>
    responsiveValue(context, phone: double.infinity, tablet: 900);
