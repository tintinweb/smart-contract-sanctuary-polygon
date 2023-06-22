// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Lottery {
    string public winner;
    mapping(address => string) public participants;

    address public immutable dedicatedMsgSender;

    event AddParticipant(address participant, string name);

    modifier onlyDedicatedMsgSender() {
        require(
            msg.sender == dedicatedMsgSender,
            "LensGelatoGPT.onlyDedicatedMsgSender"
        );
        _;
    }

    constructor(address _dedicatedMsgSender) {
        dedicatedMsgSender = _dedicatedMsgSender;
    }

    function addName(string memory _name) external {
        emit AddParticipant(msg.sender,_name);
        participants[msg.sender] = _name;
    }

    function getLastWinner() external view returns (string memory) {
        return winner;
    }

    function updateWinner(address _winnerAddress) public {
        winner = participants[_winnerAddress];
    }
}