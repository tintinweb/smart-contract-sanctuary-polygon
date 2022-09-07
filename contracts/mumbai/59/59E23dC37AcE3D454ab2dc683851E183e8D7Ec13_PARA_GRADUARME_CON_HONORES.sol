/**
 *Submitted for verification at polygonscan.com on 2022-09-06
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract PARA_GRADUARME_CON_HONORES {
    address public owner;

    // PARA EL DEPLOY DEL SMART CONTRACT SE REQUIERE MINIMO 1ETH
    // SE ASIGNA EL OWNER
    constructor() payable {
        require (msg.value >= 1 ether, "DEPLOY REQUIRES MINIMUM 1ETH");
        owner = msg.sender;
    }

    // SE PUEDE MANDAR MAS $$$ AL SMART CONTRACT, PERO CADA ENVIO ES DE 2ETH
    // SOLO EL OWNER PUEDE MANDAR $$$
    function send() external payable {
        require (msg.value == 2 ether, "YOU MUST SEND 2ETH");
        require (msg.sender == owner, "YOU ARE NOT THE OWNER");
    }

    // CUALQUIER USUARIO PUEDE RETIRAR $$$ SI EL SALDO DEL SMART CONTRACT ES MAYOR O IGUAL A 5ETH
    // CADA RETIRO ES DE 1ETH
    function request() external {
        address payable to = payable(msg.sender);

        if (address(this).balance >= 5 ether) {        
            to.transfer(1 ether);
        }
    }

    // CUALQUIERA PUEDE CHECAR EL SALDO DEL SMART
    function getBalance() external view returns (uint){
    return address(this).balance;
    }

    //SOLO EL OWNER PUEDE RETIRAR EL SALDO DEL SMART CONTRACT, SIEMPRE QUE EL SALDO SEA MAYOR O IGUAL A 7ETH
    function withdraw() external {
        require (msg.sender == owner, "YOU MUST BE THE OWNER");
       
       if (address(this).balance >= 7 ether) {
           address payable to = payable(msg.sender);
           uint balance = address(this).balance;
           to.transfer(balance);
       } 
    }
}