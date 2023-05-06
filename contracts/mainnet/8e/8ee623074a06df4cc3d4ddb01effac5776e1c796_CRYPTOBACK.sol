/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

contract CRYPTOBACK {
    string public name = "Cryptoback";
    string public symbol = "CRYPTOBK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000000000000000000000;
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isFrozen;
    modifier onlyOwner() {
    require(owner == msg.sender, "Deve ser o proprietario para chamar");
        _;
    }
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(to != address(0), "Nao e possivel transferir para endereco zero");
        require(to != msg.sender, "Nao e possivel transferir para si mesmo");
        require(amount > 0, "O valor da transferencia deve ser > 0");
        require(!isFrozen[msg.sender], "O endereco do remetente esta congelado");
        require(!isFrozen[to], "O endereco do destinatario esta congelado");
        require(balanceOf[msg.sender] >= amount, "Tokens insuficientes");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

   
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Nao e possivel cunhar para endereco zero");

        totalSupply += amount;
        balanceOf[account] += amount;

        emit Transfer(address(0), account, amount);
    }
   
    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Nao e possivel gravar do endereco zero");
        require(balanceOf[account] >= amount, "O valor da queima excede o saldo");

        balanceOf[account] -= amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function freeze(address account) external onlyOwner {
        isFrozen[account] = true;
        emit Freeze(account);
    }

    function unfreeze(address account) external onlyOwner {
        isFrozen[account] = false;
        emit Unfreeze(account);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "O novo proprietario nao pode ser endereco zero");

        address oldOwner = owner;
        owner = newOwner;

        emit TransferOwnership(oldOwner, newOwner);
    }
}