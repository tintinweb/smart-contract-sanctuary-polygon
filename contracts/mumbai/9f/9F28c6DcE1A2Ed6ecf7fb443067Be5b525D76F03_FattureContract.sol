/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

contract FattureContract {
    
    struct Fattura {
        string tipo;
        uint256 numero;
        uint256 data;
        string anagrafica;
        string piva;
        string descrizione;
        uint256 data_consegna;
        uint256 imponibile;
        uint256 iva;
        uint256 totale;
    }
    
    Fattura[] public fatture;
    
    function aggiungiFattura(
        string memory _tipo,
        uint256 _numero,
        uint256 _data,
        string memory _anagrafica,
        string memory _piva,
        string memory _descrizione,
        uint256 _data_consegna,
        uint256 _imponibile,
        uint256 _iva,
        uint256 _totale
    ) public {
        Fattura memory nuovaFattura = Fattura({
            tipo: _tipo,
            numero: _numero,
            data: _data,
            anagrafica: _anagrafica,
            piva: _piva,
            descrizione: _descrizione,
            data_consegna: _data_consegna,
            imponibile: _imponibile,
            iva: _iva,
            totale: _totale
        });
        fatture.push(nuovaFattura);
    }
    function getFattureEmesse() public view returns (Fattura[] memory) {
    Fattura[] memory emesse;
    uint256 count = 0;
    for (uint256 i = 0; i < fatture.length; i++) {
        if (keccak256(abi.encodePacked(fatture[i].tipo)) == keccak256(abi.encodePacked("emessa"))) {
            count++;
        }
    }
    emesse = new Fattura[](count);
    count = 0;
    for (uint256 i = 0; i < fatture.length; i++) {
        if (keccak256(abi.encodePacked(fatture[i].tipo)) == keccak256(abi.encodePacked("emessa"))) {
            emesse[count] = fatture[i];
            count++;
        }
    }
    return emesse;
}

function getFattureRicevute() public view returns (Fattura[] memory) {
    Fattura[] memory ricevute;
    uint256 count = 0;
    for (uint256 i = 0; i < fatture.length; i++) {
        if (keccak256(abi.encodePacked(fatture[i].tipo)) == keccak256(abi.encodePacked("ricevuta"))) {
            count++;
        }
    }
    ricevute = new Fattura[](count);
    count = 0;
    for (uint256 i = 0; i < fatture.length; i++) {
        if (keccak256(abi.encodePacked(fatture[i].tipo)) == keccak256(abi.encodePacked("ricevuta"))) {
            ricevute[count] = fatture[i];
            count++;
        }
    }
    return ricevute;
}

    
}