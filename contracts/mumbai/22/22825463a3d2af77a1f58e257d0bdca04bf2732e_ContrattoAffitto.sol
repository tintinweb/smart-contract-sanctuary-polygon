/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT




contract ContrattoAffitto {
    address payable public proprietario;
    address payable public inquilino;
    uint256 public importoAffitto;
    uint256 public dataInizio;
    uint256 public dataFine;
    uint256 public caparra;
    uint256 public penalita;
    uint256 public pagamentoMensile;

    constructor(
        address payable _proprietario,
        address payable _inquilino,
        uint256 _importoAffitto,
        uint256 _dataInizio,
        uint256 _dataFine,
        uint256 _caparra,
        uint256 _penalita
    ) {
        proprietario = _proprietario;
        inquilino = _inquilino;
        importoAffitto = _importoAffitto;
        dataInizio = _dataInizio;
        dataFine = _dataFine;
        caparra = _caparra;
        penalita = _penalita;
        pagamentoMensile = _importoAffitto / ((_dataFine - _dataInizio) / 30);
    }

    function pagaAffitto() public payable {
        require(msg.sender == inquilino, "no inquilino");
        require(msg.value == pagamentoMensile, "pagamento non corretto");
        uint256 mesiPassati = (block.timestamp - dataInizio) / 30 days;
        require(mesiPassati > 0, "contratto non iniziato");
        uint256 mesiPagati = mesiPassati - 1;
        uint256 importoPagato = mesiPagati * pagamentoMensile;
        uint256 importoDaPagare = pagamentoMensile;
        if (mesiPagati > 0) {
            importoDaPagare = pagamentoMensile - (importoPagato - msg.value);
        }
        require(importoDaPagare <= msg.value, "importo pagato non sufficiente");
        proprietario.transfer(msg.value);
        if (mesiPagati > 0 && importoPagato < importoAffitto) {
            uint256 importoPenalita = importoAffitto - importoPagato;
            if (importoPenalita > penalita) {
                importoPenalita = penalita;
            }
            inquilino.transfer(importoPenalita);
        }
    }

    function restituisciCaparra() public payable {
        require(msg.sender == inquilino, "inquilino puo restituire la caparra");
        require(block.timestamp >= dataFine, "Il contratto non e' ancora terminato");
        require(msg.value == caparra, "L'importo della caparra non e' corretto");
        proprietario.transfer(msg.value);
    }
}