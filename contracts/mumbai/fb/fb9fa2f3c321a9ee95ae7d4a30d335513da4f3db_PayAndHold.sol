/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// Interfaz ERC20 mínima para interactuar con otros contratos
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract PayAndHold {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    // Función para recibir pagos
    receive() external payable {}

    // Función para retirar los fondos del contrato
    function withdraw() public {
        require(msg.sender == owner, "Solo el propietario puede retirar fondos");
        owner.transfer(address(this).balance);
    }

    // Función para retirar tokens ERC20
    function withdrawToken(address tokenAddress) public {
        require(msg.sender == owner, "Solo el propietario puede retirar tokens");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "El saldo de tokens es 0");
        token.transfer(owner, balance);
    }
}