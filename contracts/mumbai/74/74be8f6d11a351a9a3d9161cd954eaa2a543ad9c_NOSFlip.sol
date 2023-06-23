/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
/*

    .-----------------. .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
    | | ____  _____  | || |     ____     | || |    _______   | || |  _________   | || |   _____      | || |     _____    | || |   ______     | |
    | ||_   \|_   _| | || |   .'    `.   | || |   /  ___  |  | || | |_   ___  |  | || |  |_   _|     | || |    |_   _|   | || |  |_   __ \   | |
    | |  |   \ | |   | || |  /  .--.  \  | || |  |  (__ \_|  | || |   | |_  \_|  | || |    | |       | || |      | |     | || |    | |__) |  | |
    | |  | |\ \| |   | || |  | |    | |  | || |   '.___`-.   | || |   |  _|      | || |    | |   _   | || |      | |     | || |    |  ___/   | |
    | | _| |_\   |_  | || |  \  `--'  /  | || |  |`\____) |  | || |  _| |_       | || |   _| |__/ |  | || |     _| |_    | || |   _| |_      | |
    | ||_____|\____| | || |   `.____.'   | || |  |_______.'  | || | |_____|      | || |  |________|  | || |    |_____|   | || |  |_____|     | |
    | |              | || |              | || |              | || |              | || |              | || |              | || |              | |
    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
    '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

*/

pragma solidity 0.8.17;
/**
 * @title NOS Flip
 * @author BitVegas
 */
contract NOSFlip {
    struct Bet {
        address player;
        uint amount;
        bool isTails; 
        bool won;
    }
    
    Bet[] public bets;
    address public owner;
    uint public MAX_BET_PERCENTAGE = 20;
    
    event BetPlaced(address indexed player, uint betId, uint amount, bool isTails); 
    event BetResult(address indexed player, uint betId, uint amount, bool won);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() external  onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function setMaxBetPercentage(uint _percentage) external onlyOwner{
        require(_percentage<=50,"Invalid percentage");
        MAX_BET_PERCENTAGE = _percentage;
    }

    function getMaxBetAmount() public view returns(uint){
        return ((address(this).balance * MAX_BET_PERCENTAGE*100) / 10000);
    }

    
    function flip(bool _isTails) external payable returns(uint){ 
        uint maxBetAmount = (((address(this).balance-msg.value) * MAX_BET_PERCENTAGE*100) / 10000);
        uint betId = bets.length;
        require((msg.value >= 10000 && msg.value <= maxBetAmount), "Invalid bet");
        bool result = generateRandomResult();

        Bet memory newBet = Bet({
            player: msg.sender,
            amount: msg.value,
            isTails: _isTails,
            won: (_isTails == result)
        });

        bets.push(newBet);
        emit BetPlaced(msg.sender, betId, msg.value, _isTails);

        if (newBet.won) {
            uint winnings = msg.value * 2;
            bool _success = payable(msg.sender).send(winnings);
            require(_success, "Failed to send amount");
            emit BetResult(msg.sender, betId, winnings, true);
        } else {
            emit BetResult(msg.sender, betId, newBet.amount, false);
        }
        return betId;
    }
    

    function generateRandomResult() private view returns (bool) {
        uint seed = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            blockhash(block.number - 1)
        )));
        return (seed % 2 == 0);
    }


    /*
        @notice: returns recent 20 bets and results
    */
    function getLatestBets() external view returns (Bet[] memory) {
        uint startIndex = (bets.length > 20) ? (bets.length - 20) : 0;
        uint length = bets.length - startIndex;
        Bet[] memory lastBets = new Bet[](length);

        for (uint i = 0; i < length; i++) {
            lastBets[i] = bets[startIndex + i];
        }
        
        return lastBets;
    }


    function withdraw(uint _amount) external onlyOwner{
        if(_amount>address(this).balance){
            bool _success = payable(owner).send(address(this).balance);
            require(_success, "Failed to send amount");
        }else{
            bool _success = payable(owner).send(_amount);
            require(_success, "Failed to send amount");
        }
    }

    
    receive() external payable {}
}