pragma solidity 0.8.2;

import "./Pool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IReferral {
    function set(address from, address to) external;

    function refOf(address to) external view returns (address);

    function reward(address addr) external payable;
}

contract MaxBet is Pool {
    using SafeMath for uint256;
    using Address for address payable;

    struct Bet {
        bool isFinished;
        bool isOver;
        uint64 number;
        uint64 luckyNumber;
        address payable player;
        uint256 amount;
        uint256 commitment;
        uint256 bh;
        uint256 blockHeight;
    }

    struct PlayerAmount {
        uint256 totalBet;
        uint256 totalPayout;
    }

    // SETTING
    uint256 public constant NUMBER_BLOCK_OF_LEADER_BOARD = 43200;
    uint256 public constant MAX_LEADER_BOARD = 10;
    uint256 public constant HOUSE_EDGE = 2;
    uint256 public MINIMUM_BET_AMOUNT = 0.1 ether;
    uint256 public PRIZE_PER_BET_LEVEL = 10;
    uint256 public REWARD_FOR_REFERRAL = 1000; // 1 / 1000 (0.1%) of bet amount for referral. max 0.2%

    address payable public referralContract;

    // Just for display on app
    uint256 public totalBetOfGame = 0;
    uint256 public totalWinAmountOfGame = 0;

    uint256 public oracleFee = 0.001 ether;

    // Properties for game
    mapping(address => uint256) public totalBetNumber; // Store all bet of player
    mapping(address => PlayerAmount) public amountOf; // Store all bet of player

    mapping(address => bool) public croupiers;

    // Properties for leader board
    uint256[] public leaderBoardRounds; // block will sent prize
    mapping(uint256 => mapping(address => uint256)) public totalBetOfPlayers; //Total bet of player in a round of board: leaderBoardBlock => address => total amount
    mapping(uint256 => address[]) public leaderBoards; //Leader board of a round of board: leaderBoardBlock => array of top players
    mapping(uint256 => mapping(address => uint256)) public leaderBoardWinners; // round => player => prize
    mapping(bytes32 => Bet) public commitmentBets;
    mapping(address => bytes32) public playerLastBet;

    event TransferWinner(address winner, uint256 amount);
    event TransferLeaderBoard(address winner, uint256 round, uint256 amount);
    event NewBet(
        address player,
        bytes32 commitment,
        uint64 number,
        bool isOver,
        uint256 amount
    );
    event DrawBet(
        address player,
        uint64 number,
        bool isOver,
        uint256 amount,
        bool isFinished,
        uint64 luckyNumber
    );

    constructor(address _croupier) public {
        croupiers[_croupier] = true;
        leaderBoardRounds.push(block.number + NUMBER_BLOCK_OF_LEADER_BOARD);

    }

    modifier onlyCroupier() {
        require(croupiers[msg.sender], "not croupier");
        _;
    }

    /**
    GET FUNCTION
     */

    function getCurrentLeaderBoard()
        public
        view
        returns (uint256 currentRound, address[] memory players)
    {
        currentRound = leaderBoardRounds[leaderBoardRounds.length - 1];
        players = leaderBoards[leaderBoardRounds[leaderBoardRounds.length - 1]];
    }

    function getRoundLeaderBoard(uint256 index, bool isFromTail)
        public
        view
        returns (uint256)
    {
        if (isFromTail) {
            return leaderBoardRounds[leaderBoardRounds.length - index - 1];
        } else {
            return leaderBoardRounds[index];
        }
    }

    function numberOfLeaderBoardRounds() public view returns (uint256) {
        return leaderBoardRounds.length;
    }

    /**
    BET RANGE
     */

    function calculatePrizeForBet(uint256 betAmount)
        public
        view
        returns (uint256)
    {
        uint256 bal = super.balanceForGame(betAmount);
        uint256 prize = 1 ether;
        if (bal > 1000000 ether) prize = 500 ether;
        else if (bal > 500000 ether) prize = 200 ether;
        else if (bal > 200000 ether) prize = 100 ether;
        else if (bal > 50000 ether) prize = 50 ether;
        else if (bal > 20000 ether) prize = 20 ether;
        else if (bal > 2000 ether) prize = 10 ether;
        else prize = 5 ether;

        if (PRIZE_PER_BET_LEVEL < 10) return prize;
        else return prize.mul(PRIZE_PER_BET_LEVEL).div(10);
    }

    function betRange(
        uint256 number,
        bool isOver,
        uint256 amount
    ) public view returns (uint256 min, uint256 max) {
        uint256 currentWinChance = calculateWinChance(number, isOver);
        uint256 prize = calculatePrizeForBet(amount);
        min = MINIMUM_BET_AMOUNT;
        max = prize.mul(currentWinChance).div(100);
        max = max > MINIMUM_BET_AMOUNT ? max : MINIMUM_BET_AMOUNT;
    }

    /**
    BET
     */

    function calculateWinChance(uint256 number, bool isOver)
        private
        pure
        returns (uint256)
    {
        return isOver ? 99 - number : number;
    }

    function calculateWinAmount(
        uint256 number,
        bool isOver,
        uint256 amount
    ) private pure returns (uint256) {
        return
            amount.mul(100 - HOUSE_EDGE).div(
                calculateWinChance(number, isOver)
            );
    }

    function addToLeaderBoard(address player, uint256 amount) private {
        uint256 round = leaderBoardRounds[leaderBoardRounds.length - 1];
        address[] storage boards = leaderBoards[round];
        mapping(address => uint256) storage totalBets = totalBetOfPlayers[
            round
        ];

        totalBets[player] = totalBets[player].add(amount);
        if (boards.length == 0) {
            boards.push(player);
        } else {
            // If found the player on list, set minIndex = MAX_LEADER_BOARD as a flag
            // to check it. if not found the play on array, minIndex is always
            // less than MAX_LEADER_BOARD
            uint256 minIndex = 0;
            for (uint256 i = 0; i < boards.length; i++) {
                if (boards[i] == player) {
                    minIndex = MAX_LEADER_BOARD;
                    break;
                } else if (totalBets[boards[i]] < totalBets[boards[minIndex]]) {
                    minIndex = i;
                }
            }
            if (minIndex < MAX_LEADER_BOARD) {
                if (boards.length < MAX_LEADER_BOARD) {
                    boards.push(player);
                } else if (totalBets[boards[minIndex]] < totalBets[player]) {
                    boards[minIndex] = player;
                }
            }
        }
    }

    /**
    DRAW WINNER
    */

    function checkWin(
        uint256 number,
        bool isOver,
        uint256 luckyNumber
    ) private pure returns (bool) {
        return
            (isOver && number < luckyNumber) ||
            (!isOver && number > luckyNumber);
    }

    function getLuckyNumber(bytes32 _commitment, uint256 secret)
        private
        view
        returns (uint64)
    {
        Bet memory bet = commitmentBets[_commitment];

        uint256 commitment = bet.commitment;
        if (uint256(keccak256(abi.encodePacked((secret)))) != commitment) {
            return 0;
        }

        return uint64(100 + ((secret ^ bet.bh) % 100));
    }

    /**
    WRITE & PUBLIC FUNCTION
     */

    function login(address ref) external notContract {
        if (referralContract != address(0x0)) {
            IReferral(referralContract).set(ref, msg.sender);
        }

        accounts[msg.sender] = block.number;
    }

    function checkSigner(bytes32 message, bytes32 r, bytes32 s, uint8 v) internal {
        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
            ),
            v,
            r,
            s
        );
        require(croupiers[signer], "!croupier");
    }

    function placeBet(
        uint64 number,
        bool isOver,
        bytes32 commitment,
        uint256 validTill,
        bytes32[2] memory rs,
        uint8 v
    ) public payable notStopped isLogon notContract {
        require(commitmentBets[commitment].amount == 0, "!invalid commitment");
        require(validTill > block.timestamp, "!invalid time");
        bytes32 message = keccak256(abi.encode(commitment, validTill));
        checkSigner(message, rs[0], rs[1], v);

        (uint256 minAmount, uint256 maxAmount) = betRange(
            number,
            isOver,
            msg.value
        );

        require(minAmount > 0 && maxAmount > 0, "!invalid bet amount");
        require(
            isOver ? number >= 4 && number <= 98 : number >= 1 && number <= 95, "!invalid number"
        );
        require(minAmount <= msg.value && msg.value <= maxAmount, "!invalid bet amount 2");
        bytes32 lastBet = playerLastBet[msg.sender];
        if (lastBet != bytes32(0)) {
            require(!commitmentBets[playerLastBet[msg.sender]].isFinished, "your last bet is not settle");
        }

        super.newBet(msg.value, calculateWinAmount(number, isOver, msg.value));

        totalBetOfGame += msg.value;

        totalBetNumber[msg.sender] += 1;

        Bet storage bet = commitmentBets[commitment];

        bet.number = number;
        bet.isOver = isOver;
        bet.amount = msg.value;
        bet.player = payable(msg.sender);
        bet.isFinished = false;
        bet.luckyNumber = 0;
        bet.commitment = uint256(commitment);
        bet.bh = uint256(blockhash(block.number - 1));
        bet.blockHeight = block.number;

        emit NewBet(msg.sender, commitment, number, isOver, msg.value);
    }

    //only refund when losing secret for commitment
    function refundBet(address payable add) external onlyOwner {
        Bet storage bet = commitmentBets[playerLastBet[add]];
        require(
            !bet.isFinished &&
                bet.player == add &&
                block.number - bet.blockHeight > 100000
        );

        uint256 winAmount = calculateWinAmount(
            bet.number,
            bet.isOver,
            bet.amount
        );

        payable(add).sendValue(bet.amount);
        super.finishBet(bet.amount, winAmount);

        bet.isFinished = true;
        bet.amount = 0;
    }

    function sendPrizeToWinners(
        uint256 round,
        address payable win1,
        address payable win2,
        address payable win3
    ) private {
        if (win1 == address(0x00)) return;

        uint256 prize1 = 0;
        uint256 prize2 = 0;
        uint256 prize3 = 0;

        if (win3 != address(0x00)) prize3 = totalPrize.mul(2).div(10);
        if (win2 != address(0x00)) prize2 = totalPrize.mul(3).div(10);
        prize1 = totalPrize.sub(prize2).sub(prize3);

        if (prize3 > 0) {
            super.sendPrizeToWinner(win3, prize3);
            leaderBoardWinners[round][win3] = prize3;
            emit TransferLeaderBoard(win3, round, prize3);
        }
        if (prize2 > 0) {
            super.sendPrizeToWinner(win2, prize2);
            leaderBoardWinners[round][win2] = prize2;
            emit TransferLeaderBoard(win2, round, prize2);
        }
        super.sendPrizeToWinner(win1, prize1);
        emit TransferLeaderBoard(win1, round, prize1);
        leaderBoardWinners[round][win1] = prize1;
    }

    function finishLeaderBoard() public {
        uint256 round = leaderBoardRounds[leaderBoardRounds.length - 1];
        address[] storage boards = leaderBoards[round];
        mapping(address => uint256) storage totalBets = totalBetOfPlayers[
            round
        ];

        if (round > block.number) return;
        if (boards.length == 0) return;

        if (totalPrize <= 0) {
            leaderBoardRounds.push(block.number + NUMBER_BLOCK_OF_LEADER_BOARD);
            return;
        }

        // boards have maximum 3 elements.
        for (uint256 i = 0; i < boards.length; i++) {
            for (uint256 j = i + 1; j < boards.length; j++) {
                if (totalBets[boards[j]] > totalBets[boards[i]]) {
                    address temp = boards[i];
                    boards[i] = boards[j];
                    boards[j] = temp;
                }
            }
        }

        address w1 = boards[0];
        address w2 = boards.length > 1 ? boards[1] : address(0x00);
        address w3 = boards.length > 2 ? boards[2] : address(0x00);

        sendPrizeToWinners(
            round,
            payable(w1),
            payable(w2),
            payable(w3)
        );
        leaderBoardRounds.push(block.number + NUMBER_BLOCK_OF_LEADER_BOARD);
    }

    /**
    FOR OPERATOR
     */

    function settleBet(
        bytes32 commitment,
        uint256 secret
    ) external {
        Bet storage bet = commitmentBets[commitment];

        require(!bet.isFinished);

        uint64 luckyNum = getLuckyNumber(commitment, secret);
        require(luckyNum > 0, "!settleBet lucky number");

        luckyNum -= 100;

        uint256 winAmount = calculateWinAmount(
            bet.number,
            bet.isOver,
            bet.amount
        );

        bet.luckyNumber = luckyNum;
        bet.isFinished = true;

        addToLeaderBoard(bet.player, bet.amount);
        if (referralContract != address(0x0)) {
            address ref = IReferral(referralContract).refOf(bet.player);
            if (ref != address(0x0)) {
                IReferral(referralContract).reward{value : bet.amount / REWARD_FOR_REFERRAL}(ref);
            }
        }

        if (checkWin(bet.number, bet.isOver, luckyNum)) {
            totalWinAmountOfGame += winAmount;
            if (winAmount > oracleFee) {
                if (croupiers[msg.sender]) {
                    payable(msg.sender).sendValue(oracleFee);
                } else {
                    payable(owner()).sendValue(oracleFee);
                }
                payable(bet.player).sendValue(winAmount - oracleFee);
            } else {
                payable(bet.player).sendValue(winAmount);
            }
            amountOf[bet.player].totalBet += bet.amount;
            amountOf[bet.player].totalPayout += winAmount;
            emit TransferWinner(bet.player, winAmount);
        } else {
            amountOf[bet.player].totalBet += bet.amount;
        }
        super.finishBet(bet.amount, winAmount);
        super.shareProfitForPrize(bet.amount);
        emit DrawBet(
            bet.player,
            bet.number,
            bet.isOver,
            bet.amount,
            bet.isFinished,
            bet.luckyNumber
        );
    }

    function changeOracleFee(uint256 _oracleFee) external onlyOwner {
        require(_oracleFee <= 0.01 ether, "too high fee");
        oracleFee = _oracleFee;
    }

    function addCroupier(address add) external onlyOwner {
        croupiers[add] = true;
    }

    function removeCroupier(address add) external onlyOwner {
        croupiers[add] = false;
    }

    function setPrizeLevel(uint256 level) external onlyOwner {
        require(PRIZE_PER_BET_LEVEL <= 1000);
        PRIZE_PER_BET_LEVEL = level;
    }

    function setMinBet(uint256 value) external onlyOwner {
        require(MINIMUM_BET_AMOUNT >= 0.1 ether);
        require(MINIMUM_BET_AMOUNT <= 10 ether);
        MINIMUM_BET_AMOUNT = value;
    }

    function setReferral(address payable _referral) external onlyOwner {
        referralContract = _referral;
    }

    function setReferralReward(uint256 value) external onlyOwner {
        require(value >= 500); // 0.2%
        require(value <= 1000); // 0.1%
        REWARD_FOR_REFERRAL = value;
    }
}

pragma solidity 0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH

contract Pool is Ownable {
    using SafeMath for uint;
    using Address for address payable;

    uint constant public WITHDRAW_FEE = 10 ether;
    uint constant public MAX_STAKER_IN_POOL = 20;
    uint constant public MIN_STAKE_AMOUNT = 500 ether;
    uint constant public NUMBER_BLOCK_OF_TAKE_REVENUE = 900;

    uint public PERCENT_OF_REVENUE_FOR_OPERATOR = 10;
    uint public PERCENT_OF_REVENUE_FOR_LEADER_BOARD = 1000; // 1/1000 (0.1%) of bet amount for leader board, max 0.2%

    struct Stake {
        uint amount;
        bool isInPool;
        uint totalStake;
        uint profit;
    }

    bool public stopped = false;

    uint public balanceOfOperator = 0;     // Cannot use for bet
    uint public balanceOfStakerOut = 0;    // Cannot use for bet
    uint public balanceOfBet = 0;          // Total balance of are not finished
    uint public lockBalanceForGame = 0;    // Don't use share value
    uint public totalPrize = 0;            // Cannot use for bet, totalPrize for leader board

    // This store all of stakers and their current amount in the contract
    // contain both in/out of pool
    mapping(address => Stake) public stakes;
    address[] public stakersInPool;
    address[] public stakers;
    uint public takeProfitAtBlock = 0;

    mapping(address => uint) public accounts;

    event NewStake(address staker, uint amount);
    event QuitPool(address staker, uint amount);
    event Distribute(uint blockNumber, uint pool, uint totalProfitOrLoss, bool isLoss, address staker, uint stakeAmount, uint profitOrLoss);

    constructor() public {
        takeProfitAtBlock = block.number + NUMBER_BLOCK_OF_TAKE_REVENUE;
    }

    /**
    MODIFIER
     */

    modifier notStopped() { require(!stopped, "stopped"); _; }
    modifier isStopped() { require(stopped, "not stopped"); _; }
    modifier isLogon() {
        require(accounts[msg.sender] > 0);
        require(block.number > accounts[msg.sender]);
        _;
    }
    modifier notContract() {
        uint size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0);
        require(tx.origin == msg.sender);
        _;
    }

    /**
    GET FUNCTION
     */

    function getStakersInPool() public view returns (address[] memory) { return stakersInPool; }

    function getStakers() public view returns (address[] memory) { return stakers; }

    function getMinAmountForJoin(address add) public view returns (uint) {
        if (stakes[add].isInPool) return MIN_STAKE_AMOUNT;
        if (stakersInPool.length < MAX_STAKER_IN_POOL) return MIN_STAKE_AMOUNT;

        uint index = findIndexOfMinStakeInPool();
        if (stakes[stakersInPool[index]].amount > stakes[add].amount) {
            return (2 + uint((stakes[stakersInPool[index]].amount - stakes[add].amount) / MIN_STAKE_AMOUNT)) * MIN_STAKE_AMOUNT;
        }
        else {
            return MIN_STAKE_AMOUNT;
        }
    }

    function poolState() private view returns (uint pool, uint profit) {
        for (uint i = 0; i < stakersInPool.length; i++) {
            address add = stakersInPool[i];
            Stake memory stake = stakes[add];
            pool = pool.add(stake.amount);
            profit = profit.add(stake.profit);
        }
    }

    function balanceForGame(uint subAmount) public view returns (uint) {
        uint pool;
        uint profit;
        (pool, profit) = poolState();
        uint bal = address(this).balance
            .sub(subAmount)
            .sub(balanceOfOperator + balanceOfStakerOut)
            .sub(balanceOfBet)
            .sub(totalPrize + profit);
        return pool > bal ? bal : pool;
    }

    /**
    JOIN/QUIT POOL
     */

    function findIndexOfMinStakeInPool() private view returns (uint) {
        require(stakersInPool.length > 0);

        uint min = 0;
        for (uint i = 1; i < stakersInPool.length; i++) {
            if (stakes[stakersInPool[i]].amount < stakes[stakersInPool[min]].amount) {
                min = i;
            }
        }

        return min;
    }

    function updateStake(address add, uint value) private {
        Stake storage stake = stakes[add];
        stake.amount = stake.amount.add(value);
        stake.totalStake = stake.totalStake.add(value);
    }

    function removeFromPool(address staker) private {
        Stake storage stake = stakes[staker];
        if (stake.isInPool) {
            stake.amount = stake.amount.add(stake.profit);
            stake.profit = 0;
            balanceOfStakerOut = balanceOfStakerOut.add(stake.amount);

            stake.isInPool = false;

            for (uint i = 0; i < stakersInPool.length; i++) {
                if (stakersInPool[i] == staker) {
                    stakersInPool[i] = stakersInPool[stakersInPool.length - 1];
                    stakersInPool.pop();
                    break;
                }
            }
        }
    }

    function addToPool(address add, uint appendAmount) private {
        Stake storage stake = stakes[add];

        if (stake.isInPool || stakersInPool.length >= MAX_STAKER_IN_POOL) return;

        if (stake.amount > appendAmount && !stake.isInPool) {
            uint oldAmount = stake.amount.sub(appendAmount);
            balanceOfStakerOut = balanceOfStakerOut.sub(oldAmount);
        }

        stake.isInPool = true;
        stakersInPool.push(add);
    }

    function refundForStaker(address payable staker) private {
        Stake storage stake = stakes[staker];
        require(!stake.isInPool, "Cannot refund");
        require(stake.amount > 0 || stake.profit > 0, "Cannot refund");

        balanceOfStakerOut = balanceOfStakerOut.sub(stake.amount);

        uint transferAmount = stake.amount;
        if (transferAmount > stake.totalStake) {
            uint totalProfit = transferAmount.sub(stake.totalStake);
            uint forOperator =  totalProfit.mul(PERCENT_OF_REVENUE_FOR_OPERATOR).div(100);
            transferAmount = transferAmount.sub(forOperator);
            balanceOfOperator = balanceOfOperator.add(forOperator);
        }

        if (transferAmount > WITHDRAW_FEE) {
            transferAmount = transferAmount.sub(WITHDRAW_FEE);
            balanceOfOperator = balanceOfOperator.add(WITHDRAW_FEE);
        }

        resetStake(staker);
        payable(staker).sendValue(transferAmount);
    }

    function resetStake(address staker) private {
        Stake storage stake = stakes[staker];
        stake.amount = 0;
        stake.totalStake = 0;
        stake.profit = 0;
        stake.isInPool = false;
    }

    /**
    FOR GAME
     */

    function newBet(uint betAmount, uint winAmount) internal {
        require(lockBalanceForGame.add(winAmount) < balanceForGame(betAmount), "Balance is not enough for game");
        lockBalanceForGame = lockBalanceForGame.add(winAmount);
        balanceOfBet = balanceOfBet.add(betAmount);
    }

    function finishBet(uint betAmount, uint winAmount) internal {
        lockBalanceForGame = lockBalanceForGame.sub(winAmount);
        balanceOfBet = balanceOfBet.sub(betAmount);
    }

    /**
    DISTRIBUTE PROFIT
     */

    function calculateAmountStake(address staker) private {
        Stake storage stake = stakes[staker];

        if (stake.totalStake <= stake.amount) return;

        uint loss = stake.totalStake.sub(stake.amount);
        uint coverLoss = loss >= stake.profit ? stake.profit : loss;

        stake.amount = stake.amount.add(coverLoss);
        stake.profit = stake.profit.sub(coverLoss);
    }

    function distributeLoss(uint pool, uint poolLoss) private {
        uint restOfLoss = poolLoss;
        uint n = stakersInPool.length;
        for (uint i = 0; i < n; i++) {
            Stake storage stake = stakes[stakersInPool[i]];
            uint loss = i == n - 1 ? restOfLoss : poolLoss.mul(stake.amount).div(pool);
            restOfLoss = restOfLoss.sub(loss);

            emit Distribute(block.number, pool, poolLoss, true, stakersInPool[i], stake.amount, loss);

            if (loss <= stake.amount) {
                stake.amount = stake.amount.sub(loss);
            }
            else {
                uint takeFromProfit = loss - stake.amount;
                stake.amount = 0;
                stake.profit = takeFromProfit <= stake.profit ? stake.profit.sub(takeFromProfit) : 0;
            }

            calculateAmountStake(stakersInPool[i]);
        }
    }

    function distributeProfit(uint pool, uint poolProfit) private {
        uint restOfProfit = poolProfit;
        uint n = stakersInPool.length;
        for (uint i = 0; i < n; i++) {
            Stake storage stake = stakes[stakersInPool[i]];
            uint profit = i == n - 1 ? restOfProfit : poolProfit.mul(stake.amount).div(pool);
            restOfProfit = restOfProfit.sub(profit);

            emit Distribute(block.number, pool, poolProfit, false, stakersInPool[i], stake.amount, profit);

            stake.profit = stake.profit.add(profit);
            calculateAmountStake(stakersInPool[i]);
        }
    }

    function takeProfitInternal(bool force, uint subAmount) internal {
        if (!force && (takeProfitAtBlock >= block.number || stakersInPool.length == 0)) {
            return;
        }
        if (stopped) {
            return;
        }
        takeProfitAtBlock = block.number + NUMBER_BLOCK_OF_TAKE_REVENUE;
        (uint pool, uint profit) = poolState();

        uint currentPool = address(this).balance
            .sub(subAmount)
            .sub(balanceOfOperator + balanceOfStakerOut)
            .sub(balanceOfBet)
            .sub(totalPrize + profit);

        if (currentPool > pool) {
            distributeProfit(pool, currentPool - pool);
        }
        else if (currentPool < pool) {
            distributeLoss(pool, pool - currentPool);
        }
    }

    function shareProfitForPrize(uint amount) internal {
        uint prize = amount.div(PERCENT_OF_REVENUE_FOR_LEADER_BOARD);
        totalPrize = totalPrize.add(prize);
    }

    function sendPrizeToWinner(address payable winner, uint amount) internal {
        if (winner == address(0x00)) return;
        if (amount > totalPrize) return;
        totalPrize = totalPrize.sub(amount);
        payable(winner).sendValue(amount);
    }

    /**
    FOR POOL
     */

    function quitPool() external isLogon notContract {
        address payable staker = payable(msg.sender);
        Stake storage stake = stakes[staker];
        if (stake.amount == 0) return;

        if (!stake.isInPool || stopped) {
            refundForStaker(staker);
        }
        else {
            takeProfitInternal(true, 0);
            removeFromPool(staker);
            refundForStaker(staker);
        }
    }

    function joinPool() external payable notStopped isLogon notContract  {
        address staker = msg.sender;
        uint amount = msg.value;
        Stake storage stake = stakes[staker];

        require(amount >= getMinAmountForJoin(staker), "Not enought amount to join pool");

        stakers.push(staker);
        takeProfitInternal(true, amount);
        updateStake(staker, amount);

        if (stake.isInPool) return;
        if (stakersInPool.length >= MAX_STAKER_IN_POOL) {
            uint indexOfMinStake = findIndexOfMinStakeInPool();
            removeFromPool(stakersInPool[indexOfMinStake]);
        }
        addToPool(staker, amount);

        emit NewStake(staker, amount);
    }

    function rejoinPool(address add) external notStopped isLogon notContract {
        address staker = add == address(0x00) ? msg.sender : add;
        Stake storage stake = stakes[staker];
        require(stake.amount > 0, "don't have amount");
        require(!stake.isInPool, "in pool already");

        uint indexOfMinStake;

        if (stakersInPool.length < MAX_STAKER_IN_POOL) {
            require(stake.amount >= MIN_STAKE_AMOUNT, 'Your stake is too low');
        }
        else {
            indexOfMinStake = findIndexOfMinStakeInPool();
            Stake memory minStake = stakes[stakersInPool[indexOfMinStake]];
            require(minStake.amount < stake.amount, "Not enought amount to join pool");
        }

        takeProfitInternal(true, 0);
        if (stakersInPool.length >= MAX_STAKER_IN_POOL) {
            removeFromPool(stakersInPool[indexOfMinStake]);
        }
        addToPool(staker, 0);
        emit NewStake(staker, 0);
    }

    function withdrawProfit() external isLogon notContract {
        Stake storage stake = stakes[msg.sender];
        require(stake.profit > 0, "Don't have profit");
        uint transferAmount = stake.profit.mul(100 - PERCENT_OF_REVENUE_FOR_OPERATOR).div(100);
        balanceOfOperator = balanceOfOperator.add(stake.profit).sub(transferAmount);
        stake.profit = 0;
        payable(msg.sender).sendValue(transferAmount);
    }

    /**
    OPERATOR
     */

    function setRevenueForOperator(uint value) external onlyOwner {
        require(value >= 1);
        require(value <= 15);
        PERCENT_OF_REVENUE_FOR_OPERATOR = value;
    }

    function setPrizeForLeaderBoard(uint value) external onlyOwner {
        require(value >= 500); // 0.2%
        require(value <= 1000); // 0.1%
        PERCENT_OF_REVENUE_FOR_LEADER_BOARD = value;
    }

    function takeProfit() external {
        takeProfitInternal(false, 0);
    }

    function operatorWithdraw(address payable add, uint amount) external onlyOwner {
        require (amount <= balanceOfOperator, "Invalid amount");
        balanceOfOperator = balanceOfOperator.sub(amount);
        payable(add).sendValue(amount);
    }

    fallback () external payable {
        balanceOfOperator = balanceOfOperator.add(msg.value);
    }

    function emergencyToken(IERC20 token, uint amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    function prizeForLeaderBoard() external payable {
        totalPrize = totalPrize.add(msg.value);
    }

    function removeStaker(uint i) external {
        address staker = stakers[i];
        Stake storage stake = stakes[staker];
        require(stake.amount == 0 && stake.profit == 0, "Cannot remove");
        resetStake(staker);
        stakers[i] = stakers[stakers.length - 1];
        stakers.pop();
    }

    function removeDuplicateStaker(uint i, uint j) external {
        require(i != j, "Same element");
        require(stakers[i] == stakers[j], "diffirent address");
        stakers[j] = stakers[stakers.length - 1];
        stakers.pop();
    }

    /** FOR EMERGENCY */

    function prepareStopGame(uint confirm, bool isStopNow) external onlyOwner {
        require(confirm == 0x1, "Enter confirm code");
        takeProfitInternal(true, 0);
        for (uint i = 0; i < MAX_STAKER_IN_POOL && stakersInPool.length > 0; i++) {
            removeFromPool(stakersInPool[0]);
        }
        stopped = isStopNow ? true : stopped;
    }

    function forceStopGame(uint confirm) external onlyOwner {
        require(confirm == 0x1, "Enter confirm code");
        stopped = true;
    }

    function forceRefundForStaker(address payable staker) external onlyOwner isStopped {
        Stake storage stake = stakes[staker];
        payable(staker).sendValue(stake.amount + stake.profit);
        resetStake(staker);
    }

    function withdrawAllBalanceAfterRefundForAllStaker() external onlyOwner isStopped {
        uint sum = 0;
        for (uint i = 0; i < stakers.length; i++) {
            sum += stakes[stakers[i]].amount;
            sum += stakes[stakers[i]].profit;
        }
        if (sum == 0) {
            payable(owner()).sendValue(address(this).balance);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}