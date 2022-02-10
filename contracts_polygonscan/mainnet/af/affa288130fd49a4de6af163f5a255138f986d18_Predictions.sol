pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract Predictions {
    using SafeMath for uint256;

    address public owner;
    uint256 public currentRound;
    bool public paused;
    address public betTokenAddress;
    uint256 public minBetAmount;
    mapping(uint256 => Round) public round;
    mapping (uint => mapping(address => BetInfo)) public roundInfo;
    uint256 public currentFee;

    event BetBear(address indexed sender, uint256 indexed round, uint256 amount);
    event BetBull(address indexed sender, uint256 indexed round, uint256 amount);
    event Claim(address indexed sender, uint256 indexed round, uint256 amount);
    event StartRound(uint256 indexed round, uint256 price, uint256 lockTimestamp, uint256 closeTimestamp);
    event LockRound(uint256 indexed round, uint256 price);

    event NewAdminAddress(address admin);
    event NewMinBetAmount(uint256 minBetAmount);

    event ChangedFee(uint256 fee);
    event Pause(uint256 indexed round);
    event TreasuryClaim(uint256 amount);
    event Unpause(uint256 indexed round);

    enum Position {
        Bull,
        Bear
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    struct Round {
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 bullAmount;
        uint256 bearAmount;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "Not admin");
        _;
    }

    modifier notPaused() {
        require(paused == false, "Rounds paused.");
        _;
    }

    constructor(uint256 lockPrice, address baseTokenAddress) {
        owner = msg.sender;
        betTokenAddress = baseTokenAddress;
        startNewRound(lockPrice);
        minBetAmount = 5 ** ERC20(baseTokenAddress).decimals();
        changeTransactionFee(200);
    }

    function totalLocked(uint256 roundNumber) public view returns (uint256) {
        return round[roundNumber].bearAmount.add(round[roundNumber].bullAmount);
    }

    function setAdmin(address _owner) public onlyAdmin {
        owner = _owner;
        emit NewAdminAddress(_owner);
    }

    function changeTransactionFee(uint256 fee) public onlyAdmin {
        currentFee = fee;
        emit ChangedFee(fee);
    }

    function changeMinBetAmount(uint256 amount) public onlyAdmin {
        minBetAmount = amount;
        emit NewMinBetAmount(amount);
    }

    function pauseMarket(bool pause) public onlyAdmin {
        paused = pause;
        if (pause) {
            emit Unpause(currentRound);
            return;
        }
        emit Pause(currentRound);
    }

    function lockRound(uint256 lockPrice) public onlyAdmin {
        Round memory currentRoundInfo = round[currentRound];

        require(block.timestamp > currentRoundInfo.lockTimestamp, 'Too soon to lock round.');

        if (currentRound > 0) {
            round[currentRound.sub(1)].closePrice = lockPrice;
        }
        currentRoundInfo.lockPrice = lockPrice;
        currentRoundInfo.closeTimestamp = block.timestamp.add(300);

        round[currentRound] = currentRoundInfo;

        emit LockRound(currentRound, lockPrice);

        if (!paused) {
            startNewRound(lockPrice);
        }
    }

    function startNewRound(uint256 lockPrice) public onlyAdmin notPaused {
        currentRound += 1;

        Round memory newRoundInfo;
        newRoundInfo.startTimestamp = block.timestamp;
        newRoundInfo.lockTimestamp = newRoundInfo.startTimestamp.add(300);

        round[currentRound] = newRoundInfo;

        emit StartRound(currentRound, lockPrice, round[currentRound].lockTimestamp, round[currentRound].closeTimestamp);
    }

    function generateBetInfo(Position position, uint256 amount) internal pure returns (BetInfo memory betInfo) {
        BetInfo memory updatedBetInfo;

        updatedBetInfo.amount = amount;
        updatedBetInfo.position = position;
        updatedBetInfo.claimed = false;

        return updatedBetInfo;
    }

    function betBull(uint256 amount, uint256 roundNumber) public notPaused {
        bet(amount, roundNumber, Position.Bull);
        emit BetBull(msg.sender, currentRound, amount);
    }

    function betBear(uint256 amount, uint256 roundNumber) public notPaused {
        bet(amount, roundNumber, Position.Bear);
        emit BetBear(msg.sender, currentRound, amount);
    }

    function bet(uint256 amount, uint256 roundNumber, Position position) private {
        require(roundInfo[roundNumber][msg.sender].amount == 0, 'Bet already locked.');
        require(amount > minBetAmount, 'Amount too low.');

        uint256 fee = (amount.div(10000)).mul(currentFee);
        uint256 betAmount = amount - fee;

        ERC20 token = ERC20(betTokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        token.transfer(owner, fee);

        roundInfo[currentRound][msg.sender] = generateBetInfo(position, betAmount);

        Round memory currentRoundInfo = round[roundNumber];

        require(currentRoundInfo.lockTimestamp > block.timestamp, 'Round not bettable.');

        if (position == Position.Bull) {
            currentRoundInfo.bullAmount = currentRoundInfo.bullAmount.add(betAmount);
        } else {
            currentRoundInfo.bearAmount = currentRoundInfo.bearAmount.add(betAmount);
        }

        round[roundNumber] = currentRoundInfo;
    }

    function claim(uint256 roundNumber) public {
        ERC20 token = ERC20(betTokenAddress);
        Round memory roundClaim = round[roundNumber];
        BetInfo memory betInfo = roundInfo[roundNumber][msg.sender];

        if (roundClaim.bearAmount == 0 || roundClaim.bullAmount == 0) {
            if (!betInfo.claimed) {
                token.transfer(msg.sender, betInfo.amount);
                roundInfo[roundNumber][msg.sender].claimed = true;
                return;
            }
        }

        require(block.timestamp > roundClaim.closeTimestamp, 'Round not ended.');
        require(roundClaim.closePrice != 0, 'Lock price not set yet.');
        require(betInfo.amount > 0, 'Did not bet this round.');
        require(betInfo.claimed == false, 'Round claimed.');

        uint ratio;

        if (roundClaim.lockPrice > roundClaim.closePrice) {
            require(betInfo.position == Position.Bear, 'Round not won.');
            ratio = totalLocked(roundNumber).mul(1000).div(roundClaim.bearAmount);
        }

        if (roundClaim.lockPrice < roundClaim.closePrice) {
            require(betInfo.position == Position.Bull, 'Round not won.');
            ratio = totalLocked(roundNumber).mul(1000).div(roundClaim.bullAmount);
        }

        if (roundClaim.lockPrice == roundClaim.closePrice) {
            token.transfer(msg.sender, betInfo.amount);
            emit Claim(msg.sender, roundNumber, betInfo.amount);
        } else {
            uint256 claimAmount = betInfo.amount.mul(ratio).div(1000);
            token.transfer(msg.sender, claimAmount);
            emit Claim(msg.sender, roundNumber, claimAmount);
        }

        betInfo.claimed = true;

        roundInfo[roundNumber][msg.sender] = betInfo;

    }
}