/// Status da fase como um todo (diferente de CardState, que é por carta).
enum GamePhaseStatus {
  previewing, // primeiros 4s mostrando tudo
  waitingFirstPick,
  waitingSecondPick,
  checkingPair, // trava novos cliques durante a resolução do par
  completed,
}
