// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRandomizer {
    function requestRandomWords() external;

    function s_randomWords(uint256) external view returns (uint256);
}

contract PritamRandomSpinner {
    IRandomizer random;
    mapping(address => uint256) public playerBalance;

    event AfterSpin(uint256 _firstNum, uint256 _secondNum, uint256 _thirdNum);

    constructor(address _randomizerAddress) {
        random = IRandomizer(_randomizerAddress);
    }

    uint256 public minBetAmount = 0.0001 ether;

    function spin(uint256 _amount) public {
        require(
            _amount <= playerBalance[msg.sender],
            "Sorry, You have not sent enough funds to the contract to perform this operation"
        );
        require(
            _amount >= minBetAmount,
            "You need to send at least 0.0001 ether to bet"
        );
        playerBalance[msg.sender] -= _amount;
        random.requestRandomWords();
        uint256 amountToSend;
        uint256 firstNum = (random.s_randomWords(0) % 6) + 1;
        uint256 secondNum = (random.s_randomWords(1) % 6) + 1;
        uint256 thirdNum = (random.s_randomWords(2) % 6) + 1;
        emit AfterSpin(firstNum, secondNum, thirdNum);
        //Jackpot - when all the three are 7
        if (firstNum == 7 && secondNum == 7 && thirdNum == 7) {
            amountToSend = ((_amount * 50) / 100) + _amount;
            (bool sent, ) = msg.sender.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
            // When all the three are the same
        } else if (
            firstNum == secondNum &&
            secondNum == thirdNum &&
            thirdNum == firstNum
        ) {
            amountToSend = ((_amount * 30) / 100) + _amount;
            (bool sent, ) = msg.sender.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
            //When any two are the same
        } else if (
            firstNum == secondNum ||
            secondNum == thirdNum ||
            thirdNum == firstNum
        ) {
            amountToSend = ((_amount * 20) / 100) + _amount;
            (bool sent, ) = msg.sender.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
        }
    }

    function sendFundsToContract() public payable {
        playerBalance[msg.sender] += msg.value;
    }

    function withdrawFunds() public {
        uint256 amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}