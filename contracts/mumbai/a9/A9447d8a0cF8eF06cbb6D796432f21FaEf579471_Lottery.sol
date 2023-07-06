// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    event LotteryWinnerEvent(address winner, uint256 amount);

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        // Los numeros sin sufijo, se asumen que estan en wei
        require(msg.value == 0.001 ether);
        require(msg.sender != manager);
        // Como vamos a tener que transferirle el premio en caso de ser ganador
        // convertimos el address a payable.
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    // NO USAR ESTO EN PRODUCCION PORQUE SE PUEDE HACKEAR. PARA GENERAR RANDOMS USAR CHAINLINK
    function random() public view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 2);

        uint r = random();
        address payable winner;
        uint index = r % players.length;
        winner = players[index];

        winner.transfer(address(this).balance);

        emit LotteryWinnerEvent(winner, address(this).balance);

        // reset the lottery in order to be ready for the next round
        players = new address payable[](0);
    }
}