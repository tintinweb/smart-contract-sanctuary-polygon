/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Ethersendernew {
    address payable owner = payable(msg.sender);

      // modificador solo el propietario puede operar
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() payable {
        if (getBalance() >= 0.02 ether) {
        } else { revert("como minimo debe haber 0.02 ether para las fees en el SC");
        }        
    }

    // para realizar ingresos
    function receiveMoney() external payable {
        //require(amount == msg.value);
        //revert("error amount");
    }

    // para realizar pagos
    function sendMoney(address to, uint amount) external onlyOwner {
        if (amount < getBalance() - 0.02 ether) {  
        } else {
            revert("fondos insuficientes");
        }
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }

    // para retirar todos los fondos y que quede un remanente de 0.02 ethers para las fees
    function retirarTodo() external {
        uint amount = getBalance() - 0.02 ether;
        if (amount < 0.02 ether) {
           revert("hay menos de 0.02 etehr");
        }
        owner.transfer(amount);
    }

    // Devuelve el balance en tiempo real del SC
    function getBalance() public view onlyOwner returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }
}


// poder injectar dinero al SC, cualquier user
// poder enviar dinero a cualquier direccion, solo el owner
// poder retirar todo el dinero quedando siempre u nremanente de 0.02 etehr, solo el owner
// poder pedir que nos devuelva el balance en tiempo real, solo el owner