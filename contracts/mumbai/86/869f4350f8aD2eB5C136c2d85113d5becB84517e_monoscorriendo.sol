/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}



contract monoscorriendo {
    address public owner;
    address public compensacionAddress;
    IERC20 public matic;
    string public cantidadco;
    string public direccionWeb;

    event TokensDepositados(address indexed remitente, uint256 cantidad);
    event TokensRetirados(address indexed destinatario, uint256 cantidad);

    constructor(address _maticAddress, address _compensacionAddress, string memory _cantidadco2, string memory _direccionWeb) {
        owner = msg.sender;
        matic = IERC20(_maticAddress);
        compensacionAddress = _compensacionAddress;
        cantidadco = _cantidadco2;
        direccionWeb = _direccionWeb; 
    }

    function depositarTokens(uint256 _cantidad) public {
        require(_cantidad > 0, "La cantidad debe ser mayor a cero");
        matic.transferFrom(msg.sender, address(this), _cantidad);
        emit TokensDepositados(msg.sender, _cantidad);
    }

    function retirarTokens(uint256 _cantidad) public {
        require(msg.sender == owner, "Solo el duenio puede retirar los tokens");
        require(_cantidad > 0, "La cantidad debe ser mayor a cero");
        matic.transfer(compensacionAddress, _cantidad);
        emit TokensRetirados(compensacionAddress, _cantidad);
    }
}