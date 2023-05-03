/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Affitto {
    address payable public locatore;
    address payable public conduttore;
    uint256 public prezzoAffittoMensile;
    uint256 public scadenzaPagamento;
    
    constructor(address payable _locatore, address payable _conduttore, uint256 _prezzoAffittoMensile, uint256 _scadenzaPagamento) {
        locatore = _locatore;
        conduttore = _conduttore;
        prezzoAffittoMensile = _prezzoAffittoMensile;
        scadenzaPagamento = _scadenzaPagamento;
    }
    
    function pagaAffitto() public payable {
        require(msg.sender == conduttore, "Solo il conduttore puo' pagare l'affitto");
        require(msg.value == prezzoAffittoMensile, "Importo di affitto errato");
        require(block.timestamp <= scadenzaPagamento, "Il periodo di pagamento e' scaduto");
        locatore.transfer(msg.value);
        scadenzaPagamento += 30 days;
    }
    
    function prelevaAffitto() public {
        require(msg.sender == locatore, "Solo il locatore puo' prelevare l'affitto");
        require(block.timestamp >= scadenzaPagamento, "Non e' ancora scaduto il periodo di pagamento");
        locatore.transfer(address(this).balance);
        scadenzaPagamento += 30 days;
    }
}