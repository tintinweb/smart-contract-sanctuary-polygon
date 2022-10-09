/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// La finalidad de este SC es:
// Que el SC siempre holdee una cantidad mínima de 0.02 ether
// poder injectar dinero al SC, cualquier user y cualquier cantidad
// poder enviar dinero a cualquier direccion, solo el owner
// poder retirar todo el dinero quedando siempre un remanente de 0.02 ether, solo el owner
// poder pedir que nos devuelva el balance en tiempo real, solo el owner

contract Ethersendernew {
    address payable owner = payable(msg.sender);
    address autorizados;

      // modificador solo el propietario puede operar
    modifier onlyOwner() {
        require(owner == msg.sender,"no autorizheid");
        _;
    }

    constructor() payable {
        if (getBalance() >= 0.02 ether) {
        } else { revert("como minimo debe haber 0.02 ether para las fees en el SC");
        }        
    }

    // para realizar ingresos
    function receiveMoney() external payable {
        require (msg.value > 0, "insuficient valor");
    }

    // para realizar pagos
    function sendMoney(address to, uint amount) external onlyOwner {
        if (amount < getBalance() - 0.02 ether) {  
        } else {
            revert("fondos insuficientes");
        }
        address payable _to = payable(to);
        _to.transfer(amount);
    }

    // para retirar todos los fondos y que quede un remanente de 0.02 ethers para las fees
    function retirarTodo() external onlyOwner {
        uint amount = getBalance() - 0.02 ether;
        if (amount < 0.02 ether) {
           revert("hay menos de 0.02 etehr");
        }
        owner.transfer(amount);
    }

    // Devuelve el balance en tiempo real del SC
    function getBalance() public view returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }
}