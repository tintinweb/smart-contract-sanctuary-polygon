/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

pragma solidity >=0.4.2 <0.9.0;

contract Casino {
    uint public nextRoundTimestamp;
    uint _interval;
    address payable _owner;

    enum BetType { Single, Odd, Even }
    struct Bet {
        BetType betType;
        address payable player;
        uint number;
        uint value;
    }
    Bet[] public bets;

    event Finished(uint number, uint nextRoundTimestamp);
    event NewSingleBet(uint bet, address payable player, uint number, uint value);
    event NewEvenBet(uint bet, address payable player, uint value);
    event NewOddBet(uint bet, address payable player, uint value);
    
    function Roulette(uint interval) public payable {
	    _interval = interval;
	    _owner = payable(msg.sender);
	    nextRoundTimestamp = block.timestamp + _interval;
    }

    function getNextRoundTimestamp() public view returns(uint) {
        return nextRoundTimestamp;
    }

    function getBetsCountAndValue() public view returns(uint, uint) {
        uint value = 0;
        for (uint i = 0; i < bets.length; i++) {
            value += bets[i].value;
        }
        return (bets.length, value);
    }

    function betSingle(uint number) payable public transactionMustContainEther() bankMustBeAbleToPayForBetType(BetType.Single) {
        if (number > 36) revert();
        bets.push(Bet({
            betType: BetType.Single,
            player: payable(msg.sender),
            number: number,
            value: msg.value
        }));
        emit NewSingleBet(bets.length,payable(msg.sender),number,msg.value);
    }

    function betEven() payable public transactionMustContainEther() bankMustBeAbleToPayForBetType(BetType.Even) {
        bets.push(Bet({
            betType: BetType.Even,
            player: payable(msg.sender),
            number: 0,
            value: msg.value
        }));
        emit NewEvenBet(bets.length,payable(msg.sender),msg.value);
    }

    function betOdd() payable public transactionMustContainEther() bankMustBeAbleToPayForBetType(BetType.Even) {
        bets.push(Bet({
            betType: BetType.Odd,
            player: payable(msg.sender),
            number: 0,
            value: msg.value
        }));
        emit NewOddBet(bets.length,payable(msg.sender),msg.value);
    }

    function launch() public {
        if (block.timestamp < nextRoundTimestamp) revert();

        uint number = uint(blockhash(block.number - 1)) % 37;
        
        for (uint i = 0; i < bets.length; i++) {
            bool won = false;
            uint payout = 0;
            if (bets[i].betType == BetType.Single) {
                if (bets[i].number == number) {
                    won = true;
                }
            } else if (bets[i].betType == BetType.Even) {
                if (number > 0 && number % 2 == 0) {
                    won = true;
                }
            } else if (bets[i].betType == BetType.Odd) {
                if (number > 0 && number % 2 == 1) {
                    won = true;
                }
            }
            if (won) {
                if (!bets[i].player.send(bets[i].value * getPayoutForType(bets[i].betType))) {
                    revert();
                }
            }
        }

        uint thisRoundTimestamp = nextRoundTimestamp;
        nextRoundTimestamp = thisRoundTimestamp + _interval;

        // bets.length = 0;
        for (uint i = 0; i <= bets.length; i++) {
            delete bets[i];
        }

        emit Finished(number, nextRoundTimestamp);
    }

    function getPayoutForType(BetType betType) public view returns(uint) {
        if (betType == BetType.Single) return 35;
        if (betType == BetType.Even || betType == BetType.Odd) return 2;
        return 0;
    }

    modifier transactionMustContainEther() {
        if (msg.value == 0) revert();
        _;
    }

    modifier bankMustBeAbleToPayForBetType(BetType betType) {
        uint necessaryBalance = 0;
        for (uint i = 0; i < bets.length; i++) {
            necessaryBalance += getPayoutForType(bets[i].betType) * bets[i].value;
        }
        necessaryBalance += getPayoutForType(betType) * msg.value;
        if (necessaryBalance > address(this).balance) revert();
        _;
    }
}