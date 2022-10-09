/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// La finalidad de este SC es:
// Que el SC siempre holdee una cantidad mínima de 0.02 ether.
// poder injectar dinero al SC, cualquier user y cualquier cantidad, con la funcion (ClientToSc).
// poder enviar dinero a cualquier direccion, solo el owner, con la funcion (ScToClient).
// poder retirar todo el dinero quedando siempre un remanente de 0.02 ether, solo el owner, Con la funcion (withdraw).
// poder pedir que nos devuelva el balance en tiempo real, solo el owner.

contract Ethersendernew {
    address payable owner = payable(msg.sender);
    address autorizados;

    // modificador que obliga a que solo el propietario puede operar
    modifier onlyOwner() {
        require(owner == msg.sender,"no estas autorizado");
        _;
    }    

    // comprueba que se ingrese un mínimo de 0.02 ether en el SC
    constructor() payable {
        if (getBalance() >= 0.02 ether) {
        } else { revert("como minimo debe haber 0.02 ether para las fees en el SC");
        }        
    }

    // para ingresar activos al SC
    function ClientToSc() external payable {
        require (msg.value > 0, "valor incorrecto");
    }

    // para realizar pagos
    function ScToClient(address to, uint amount) external onlyOwner {
        if (amount < getBalance() - 0.02 ether) {  
        } else {
            revert("fondos insuficientes");
        }
        address payable _to = payable(to);
        _to.transfer(amount);
    }

    // para retirar todos los fondos y que quede un remanente de 0.02 ethers para las fees
    function withdraw() external onlyOwner {
        uint amount = getBalance() - 0.02 ether;
        if (amount < 0.02 ether) {
           revert("hay menos de 0.02 ether");
        }
        owner.transfer(amount);
    }

    // Devuelve el balance en tiempo real del SC
    function getBalance() public view onlyOwner returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }
}