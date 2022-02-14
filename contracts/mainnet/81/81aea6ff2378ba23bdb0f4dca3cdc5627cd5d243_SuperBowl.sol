/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

/** 
 * Gratta e vinci con montepremi
 */
contract SuperBowl{
    address payable private _controllerAddress ;
    uint private _availableBalance;
    uint private _unavailableBalance;
    // bool private  _isPaused;

    constructor() {
        _controllerAddress = payable(msg.sender);
    }

    /**
    *Ricevi fondi e accantona il 5% a riserva indisponibile
    */
    function play() public payable {
        // require(!_isPaused, "The contract is paused!");
        _availableBalance += msg.value;
        uint unavailableValue = msg.value / 20;
        _availableBalance -= unavailableValue;
        _unavailableBalance += unavailableValue;
        //condizione per trasferire aggio a controller
        if (_unavailableBalance > 1000000000000000000) {
            //trasferisci riserva indisponibile a _controllerAddress
            _controllerAddress.transfer(_unavailableBalance);
            _unavailableBalance = 0;
        }
        //inserire condizione pseudorandom, per trasferire montepremi a msg.sender
        if (_random() == 500) {
            address payable winner = payable(msg.sender);
            winner.transfer(_availableBalance); //trasferisci montepremi a winner
            _availableBalance = 0;
        }
    }

    // function setPaused(bool _paused) public {
    //     require(msg.sender == _controllerAddress, "Error 403 :) Sorry, that's not allowed.");
    //     _isPaused =_paused;
    // }

    function getBalance() public view returns (uint) {
        require(msg.sender == _controllerAddress, "Error 403 :) Sorry, that's not allowed.");
        return address(this).balance;
    }


    /**
     * Restituisce il montepremi
     * @return uint il montepremi in wei
     */
    function getAvailableBalance() public view returns (uint) {
        return _availableBalance;
    }

    /**
     * Restituisce la riserva indisponible (destinata al controller address)
     * @return uint il montepremi in wei
     */
    function getUnavailableBalance() public view returns (uint) {
        return _unavailableBalance;
    }


    /**
     * Funzione pseudorandom. 
     * Il valore è determinato dall'dentificazione del blocco, per cui sarà uguale per tutte le
     * call effettuate in pendenza dello stesso blocco.
     * @dev bisogna aggiungere, come parametro da passare a abi.encodePacked(), il msg.sender e
     * anche il valore della variabile _unavailableBalance.
     *
     */
    function _random() public view returns (uint) {
        bytes memory randomNum = abi.encodePacked(block.difficulty, block.timestamp, msg.sender, _availableBalance);
        uint randomHash = uint(keccak256(randomNum));
        return randomHash % 1000;
    }

    /**
     * Distrugge il contratto e trasferisce tutti i fondi a msg.sender
     * Funzioni permessa solo al controller del contratto.
     * Fare sempre attenzione ai contratti che presentano l'istruzione selfdestruct().
     * Se il contratto è già stato distrutto, i fondi inviati qui sono persi per sempre.
     */
    function destroyContract() public {
        require(msg.sender == _controllerAddress, "Error 403 :) Sorry, that's not allowed.");
        selfdestruct(payable(msg.sender));        
    }


}