/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library RNG{
        function generate(uint _nounce) internal view returns(uint16){
            return uint16(uint(keccak256(abi.encodePacked(_nounce, block.number-1, block.difficulty,  
            msg.sender))) % 1001);
        }
}

contract TossGame {    
    event Returned(address sender, uint value);
    event Won(address winner, uint value);
    event Lost(address loser, uint value);

    address immutable public admin;
    uint256 public treasuryBalance;
    uint256 private nounce;
    uint16 private generated;

    constructor() payable {
        require(msg.value > 0, "Contract must have initial balance");
        treasuryBalance = msg.value;
        admin = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == admin, "Only owner can deposit in treasury");
        _;
    }

    function deposit() external onlyOwner payable returns(uint){
        treasuryBalance += msg.value;
        return treasuryBalance;
    }

    function withdraw(uint _value) external onlyOwner returns(uint){
        require(_value <= treasuryBalance, "You can't withdraw more than treasury balance");
        treasuryBalance -= _value;
        payable(admin).transfer(_value);
        return treasuryBalance;
    }

    function toss() private {
        require(msg.value > 0, "Send a none zero value Ether.");
        generated = RNG.generate(nounce);
        nounce++;
        if(msg.value <= treasuryBalance){
            if(generated > 499){
                treasuryBalance += msg.value;
                emit Lost(msg.sender, msg.value);
            } else {
                treasuryBalance -= 2 * msg.value;
                payable(msg.sender).transfer(2 * msg.value);
                emit Won(msg.sender, 2 * msg.value);
            }
        } else {
            payable(msg.sender).transfer(msg.value);
            emit Returned(msg.sender, msg.value);
        }
    }

    receive() external payable {
        toss();
    }
}