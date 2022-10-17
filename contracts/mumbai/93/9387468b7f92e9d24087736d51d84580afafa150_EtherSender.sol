/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Ejercicio 3:  Crear un Smart Contract llamado “EtherSender” que:

contract EtherSender {
    
    address payable owner = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

    // Tenga una función llamada “getBalance” que nos devuelva el balance del Smart Contract:
        function getBalance() public view returns (uint256) {
            uint256 balance = address(this).balance;
            return balance;
        }

    // Tenga una función para inyectar dinero al Smart Contract:
        function income() external payable {  
        }

    // Tenga una función para enviar 0.01 ether del Smart Contract a la EOA que lo llame:
        function getReward() external returns (bool) {
            address payable to = payable(msg.sender);
            uint256 amount = 0.01 ether;
            bool result = to.send(amount);
            return result;
        }
    
    // Tenga una función para enviar la mitad del balance total del Smart Contract a la EOA que lo llame:
        function withdrawHalfBalance() external returns (bool) {
            address payable to = payable(msg.sender);
            uint256 amount = getBalance()/2;
            bool result = to.send(amount);
            return result;
        }
    // Tenga una función para enviar todo el balance al “owner” del Smart contract:
        function RugPull() external returns (bool) {
            address payable to = payable(owner);
            uint256 amount = getBalance();
            bool result = to.send(amount);
            return result;
        }
    //El smart contract debe estar verificado y publicado en Mumbai. Además, debe haber una tx modificando el maxTotalSupply.

}