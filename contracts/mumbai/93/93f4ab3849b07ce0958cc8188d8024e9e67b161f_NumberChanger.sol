/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INumber {
    function setNumber(uint _number) external;
}

contract NumberChanger {

  constructor() {
  }

    //vado a richiamare la funzione change owner 
  function change(address _numberAddress) external {

        uint256 t = 8;
        //noi richiamiamo un contratto ma l'origine la chiamiamo noi quindi tx.origin siamo noi 
        INumber(_numberAddress).setNumber(t);
    }
  }