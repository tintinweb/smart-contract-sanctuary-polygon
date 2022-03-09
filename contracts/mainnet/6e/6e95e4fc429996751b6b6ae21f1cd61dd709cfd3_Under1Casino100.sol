/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

pragma solidity 0.8.3;

interface IAgg {
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
}

contract Under1Casino100 {
    address public constant OPERATOR = 0x0661eE3542CfffBBEFCA7F83cfaD2E9D006d61a2;
    address public constant LOADER = 0x3D90BfB95c399414254CA6F6159A45927f017895;
    address public constant FEED = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    uint public BetMax = address(this).balance / 1000;
    uint public CountWins;
    uint public CountLoss;
    mapping(address => uint) public addPlayer;
    mapping(address => uint) public ticketNum;
    mapping(address => uint) public betAmt;
    
    constructor() payable {}
    
    function safeDiv(uint a, uint b) public pure returns (uint c) {
	require(b > 0);
        c = a / b;
    }

    fallback() external payable {
        require(msg.value >= tx.gasprice);
        require(msg.value <= BetMax);
        if (msg.sender == OPERATOR) {
            // operator withdrawal
            (bool sent, ) = msg.sender.call{value: (msg.value * 1000)}("");
            require(sent, "Failed to send Ether");
        } else if (msg.sender == LOADER) {
        // load contract
        } else {
        IAgg(FEED).latestRound;
        IAgg(FEED).getAnswer;
        IAgg(FEED).getTimestamp;
        if (addPlayer[msg.sender] > 0) {
            require((addPlayer[msg.sender] + 1) < IAgg(FEED).latestRound());
        if (uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(ticketNum[msg.sender], IAgg(FEED).getTimestamp(addPlayer[msg.sender] + 2), IAgg(FEED).getAnswer(addPlayer[msg.sender] + 2)))))) < uint256(1147000000000000000000000000000000000000000000000000000000000000000000000000)) {
        // max uint value = 115792089237316195423570985008687907853269984665640564039457584007913129639935
            uint WinAmt;
            WinAmt = betAmt[msg.sender];
            CountWins +=1;
            addPlayer[msg.sender] = IAgg(FEED).latestRound();
            ticketNum[msg.sender] = uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice)))));
            betAmt[msg.sender] = msg.value;
            BetMax = safeDiv((address(this).balance - (WinAmt * 100)), 1000);
            (bool sent, ) = msg.sender.call{value: (WinAmt * 100)}("");
            require(sent, "Failed to send Ether");
        } else {
            CountLoss +=1;
            addPlayer[msg.sender] = IAgg(FEED).latestRound();
            ticketNum[msg.sender] = uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice)))));
            betAmt[msg.sender] = msg.value;
            BetMax = safeDiv(address(this).balance , 1000);
        }
        } else {
        addPlayer[msg.sender] = IAgg(FEED).latestRound();
        ticketNum[msg.sender] = uint256(sha256(abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, block.number, msg.sender, tx.gasprice)))));
        betAmt[msg.sender] = msg.value;
        BetMax = safeDiv(address(this).balance , 1000);
        }
    }
    }
}