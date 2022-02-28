// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IRandomGenerator.sol";

contract Roulette is 
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Round {
        uint256 roundId;
        uint256 epoch;
        Bet[] bets;
        uint256 totalAmountBet;
        uint256 totalRewardAmount;
        uint256 treasuryCollections;
        bool oracleCalled;
        uint8 winningNumber;
        bool claimed;
        // the amount put on a number with a slab
        // totalAmountInSlabs[number][slab] = total amount bet on that number in a slab
        mapping(uint8 => mapping(uint8 => uint256)) totalAmountInSlabs;
    }

    /** 
    * @dev BetTypes
    * 0 for RedBlack, OddEven, HighLow => 18 numbers and reward = 1x the amount bet
    * 1 for Columns, Dozens => 12 numbers and reward = 2x the amount bet
    * 2 for Line => 6 numbers and reward = 5x the amount bet
    * 3 for Corner => 4 numbers and reward = 8x the amount bet
    * 4 for Street, ThreeNumBetsWithZero => 3 numbers and reward = 11x the amount bet
    * 5 for Split => 2 numbers and reward = 17x the amount bet
    * 6 for Number => 1 number and reward = 35x the amount bet
    */
    
    struct Bet{
        /**
        * @dev Differentiator 
        * for betType 0 => diff 0 for RedBlack, 1 for OddEven and 2 for HighLow
        * for betType 1 => diff 0 for columns and 1 for Dozens
        * for betType 2 => diff 0 for Line
        * for betType 3 => diff 0 for Corner
        * for betType 4 => diff 0 for Street and 1 for ThreeNumBetsWithZero
        * for betType 5 => diff 0 for Split
        * for betType 6 => diff 0 for Number
        */
        
        uint8 betType;
        uint8 differentiator;
        uint8[] numbers;
        uint256 amount;
    }

    struct RoundInfo{
        address user;
        uint256 epoch;
    }

    //Payout, MinBetAmount, MaxBetAmount by BetType
    mapping(uint8 => uint8) public payout;
    mapping(uint8 => uint256) public minBetAmount;
    mapping(uint8 => uint256) public maxBetAmount;
    //For each kind of bet, the required number of numbers to be bet on
    mapping(uint8 => uint8) public numbersByKindOfBet;
    //RoundInfo by roundId
    mapping(uint256 => RoundInfo) public roundInfo;
    //Round by userAddress amd Epoch 
    mapping(address => mapping(uint256 => Round)) public rounds;
    mapping(address => uint256) public currentUserEpoch;
    mapping(address => uint256) public claimCheckpoint;

    address public admin;
    address public operator;
    uint256 public counter;
    uint256 public treasuryAmount;
    uint256 private randomRoundId;
    uint256 public totalVolume;

    uint256 public randomNumUpdateAllowance; // seconds
    IRandomGenerator private randomGenerator;

    //Token which is used for betting
    address public tokenStaked;
    uint8 public tokenDecimals;

    event ExecuteRound(
        uint256 indexed roundId,
        address indexed user,
        uint256 indexed epoch,
        uint8 winningNumber,
        uint256 prevRoundIdForUser,
        uint256 totalAmountBet,
        uint256 totalRewards,
        uint256 treasuryCollections
        );
    event Claim(
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );
    event ClaimAll(
        address indexed user, 
        uint256 claimCheckpoint, 
        uint256 reward
        );
    event ClaimTreasury(uint256 amount);
    event PayoutUpdated(
        uint256 indexed epoch,
        uint8[] indexed betType,
        uint8[] payout
    );
    event MinBetAmountUpdated(
        uint256 indexed epoch,
        uint8[] indexed betType, 
        uint256[] minBetAmount
        );
    event MaxBetAmountUpdated(
        uint256 indexed epoch,
        uint8[] indexed betType, 
        uint256[] maxBetAmount
        );
    event Pause(uint256 epoch);
    event Unpause(uint256 epoch);
    event OperatorChanged(address previousOperator, address newOperator);
    event OracleUpdateAllowanceUpdated(
        uint256 currentEpoch, 
        uint256 _randomNumUpdateAllowance
        );
    event TokenWithdrawal(address to, address token, uint256 amount);
    event NativeWithdrawal(address to, uint256 amount);
    event TokenStakedUpdated(uint256 epoch, address token, uint8 decimals);

    function initialize(
        bytes calldata data,
        address[] calldata _ownerAdminOperator
    ) public initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        transferOwnership(_ownerAdminOperator[0]);
        admin = _ownerAdminOperator[1];
        operator = _ownerAdminOperator[2];

        numbersByKindOfBet[0] = 18;
        numbersByKindOfBet[1] = 12;
        numbersByKindOfBet[2] = 6;
        numbersByKindOfBet[3] = 4;
        numbersByKindOfBet[4] = 3;
        numbersByKindOfBet[5] = 2;
        numbersByKindOfBet[6] = 1;

        //Setting the bet payouts for different kinds of bets
        payout[0] = 1;
        payout[1] = 2;
        payout[2] = 5;
        payout[3] = 8;
        payout[4] = 11;
        payout[5] = 17;
        payout[6] = 35;        

        address _tokenStaked;
        uint8 _decimals;
        uint256 _randomNumUpdateAllowance;
        address _randomGenerator;
        
        (_tokenStaked, _decimals, _randomNumUpdateAllowance, _randomGenerator) 
            = abi.decode(
                    data, 
                    (address, uint8, uint256, address)
                );

        tokenStaked = _tokenStaked;
        tokenDecimals = _decimals;
        randomGenerator = IRandomGenerator(_randomGenerator);
        randomNumUpdateAllowance = _randomNumUpdateAllowance;

        //Setting min bet amounts and max bet amounts for each bet type
        //Min Bet is 1 token
        minBetAmount[0] = 10 ** _decimals;
        minBetAmount[1] = 10 ** _decimals;
        minBetAmount[2] = 10 ** _decimals;
        minBetAmount[3] = 10 ** _decimals;
        minBetAmount[4] = 10 ** _decimals;
        minBetAmount[5] = 10 ** _decimals;
        minBetAmount[6] = 10 ** _decimals;

        //Max bets for outside bets are 100 USDC
        //Max bets for inside bets are according to the payout!
        maxBetAmount[0] = 100 * 10 ** _decimals;
        maxBetAmount[1] = 80 * 10 ** _decimals;
        maxBetAmount[2] = 70 * 10 ** _decimals;
        maxBetAmount[3] = 60 * 10 ** _decimals;
        maxBetAmount[4] = 50 * 10 ** _decimals;
        maxBetAmount[5] = 40 * 10 ** _decimals;
        maxBetAmount[6] = 20 * 10 ** _decimals;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner(){}

    modifier onlyAdmin{
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    modifier onlyOperator{
        require(msg.sender == operator, "operator: wut?");
        _;
    }

    modifier notContract{
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @dev set admin address
     * callable by owner
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        address previousAdmin = admin;
        admin = _admin;
        emit AdminChanged(previousAdmin, admin);
    }

    /**
     * @dev set operator address
     * callable by admin
     */
    function setOperator(address _operator) external onlyAdmin {
        require(_operator != address(0), "Cannot be zero address");
        address previousOperator = operator;
        operator = _operator;
        emit OperatorChanged(previousOperator, operator);
    }

    
    /**
     * @dev set token staked and its decimals
     * Callable by admin
     */
    function changeTokenStaked(address token, uint8 _decimals) 
        external 
        onlyAdmin 
    {
        tokenStaked = token;
        tokenDecimals = _decimals;

        emit TokenStakedUpdated(counter, token, _decimals);
    }
    
    
    /**
     * @dev get all the payouts
     */
    function getPayouts() external view returns(uint8[] memory){
        uint8[] memory payouts = new uint8[](7);
        for(uint8 i = 0; i < 7; i++){
            payouts[i] = payout[i];
        }
        return payouts;
    }

    /**
     * @dev get random number address
     * callable by owner, admin and operator
     */
    function getRandomNumberOracleAdd() external view returns(address){
        require(
            msg.sender == owner() || msg.sender == admin || msg.sender == operator,
            "Roulette: unauthorized access" 
            );
        return address(randomGenerator);
    }


    /**
     * @dev set random number address
     * callable by admin
     */
    function setRandomNumberOracleAdd(address _randomGenerator) external onlyAdmin {
        require(_randomGenerator != address(0), "Cannot be zero address");
        randomGenerator = IRandomGenerator(_randomGenerator);
    }


    /**
     * @dev set random number update allowance
     * callable by admin
     */
    function setRandomNumUpdateAllowance(uint256 _randomNumUpdateAllowance)
        external
        onlyAdmin
    {
        randomNumUpdateAllowance = _randomNumUpdateAllowance;
        emit OracleUpdateAllowanceUpdated(counter, _randomNumUpdateAllowance);
    }

    /**
     * @dev set payout rate
     * callable by admin
     */
    function setPayout(uint8[] calldata betType, uint8[] calldata _payout) external onlyAdmin {
        require(
            betType.length == _payout.length && betType.length <= 7,
            "Roulette: Array lengths mismatch"
            );

        for(uint8 i = 0; i < betType.length; i++){
            require(
                betType[i] < 7,
                "Roulette: betTypes can range between 0 and 6(included) only"
                );
            payout[betType[i]] = _payout[i];
        }

        emit PayoutUpdated(counter, betType, _payout);
    }

    /**
     * @dev set minBetAmount
     * callable by admin
     */
    function setMinBetAmount(
        uint8[] calldata betType, 
        uint256[] calldata _minBetAmount
        ) external 
        onlyAdmin 
    {
        require(
            betType.length == _minBetAmount.length && betType.length <= 7,
            "Roulette: Array lengths mismatch"
            );
        
        for(uint8 i = 0; i < betType.length; i++){
            
            require(
                betType[i] < 7,
                "Roulette: betTypes can range between 0 and 6(included) only"
                );

            require(
                _minBetAmount[i] <= maxBetAmount[betType[i]],
                "Roulette: minBetAmount should be <= maxBetAmount"
                );

            minBetAmount[betType[i]] = _minBetAmount[i];
        }

        emit MinBetAmountUpdated(counter, betType, _minBetAmount);
    }

    /**
     * @dev set maxBetAmount
     * callable by admin
     */
    function setMaxBetAmount(
        uint8[] calldata betType, 
        uint256[] calldata _maxBetAmount
        ) external 
        onlyAdmin 
    {
        require(
            betType.length == _maxBetAmount.length && betType.length <= 7,
            "Roulette: Array lengths mismatch"
            );
        
        for(uint8 i = 0; i < betType.length; i++){

            require(
                betType[i] < 7,
                "Roulette: betTypes can range between 0 and 6(included) only"
                );

            require(
                minBetAmount[betType[i]] <= _maxBetAmount[i],
                "Roulette: maxBetAmount should be >= minBetAmount"
                );
            
            maxBetAmount[betType[i]] = _maxBetAmount[i];
        }

        emit MaxBetAmountUpdated(counter, betType, _maxBetAmount);
    }

    /**
     * @dev gets random round id
     * callable by admin
     */
    function getRandomRoundId() public view returns(uint256){
        require(
            msg.sender == owner() || msg.sender == admin || msg.sender == operator,
            "Roulette: Unauthorized function call"
        );
        return randomRoundId;
    }


    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2
     */
    function executeRound(
        Bet[] calldata bets
        ) 
        external 
        virtual 
        nonReentrant
        whenNotPaused 
    {
        counter = counter.add(1);
        currentUserEpoch[msg.sender] = currentUserEpoch[msg.sender].add(1);

        _startRound(msg.sender, currentUserEpoch[msg.sender]);

        uint8 randomNum = _getNumberFromOracle();
        _bet(msg.sender, bets);
        _endRound(msg.sender, currentUserEpoch[msg.sender], randomNum);
        _calculateRewards(msg.sender, currentUserEpoch[msg.sender]);

        roundInfo[counter] = RoundInfo(msg.sender, currentUserEpoch[msg.sender]);

        uint256 prevRoundIdForUser = 0;
        if(currentUserEpoch[msg.sender] > 1){
            prevRoundIdForUser = rounds[msg.sender][currentUserEpoch[msg.sender].sub(1)].roundId;
        }

        emit ExecuteRound(
            counter,
            msg.sender, 
            currentUserEpoch[msg.sender], 
            randomNum, 
            prevRoundIdForUser,
            rounds[msg.sender][currentUserEpoch[msg.sender]].totalAmountBet,
            rounds[msg.sender][currentUserEpoch[msg.sender]].totalRewardAmount,
            rounds[msg.sender][currentUserEpoch[msg.sender]].treasuryCollections
            );
    }

    function _startRound(address user, uint256 epoch) internal virtual{
        Round storage round = rounds[user][epoch];
        round.roundId = counter;
        round.epoch = epoch;
        round.totalAmountBet = 0;
    }


    /**
     * @dev End round
     */
    function _endRound(address user, uint256 epoch, uint8 winningNum) internal virtual{
        Round storage round = rounds[user][epoch];
        round.winningNumber = winningNum;
        round.oracleCalled = true;
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(address user, uint256 epoch) internal virtual{
        require(
            rounds[user][epoch].totalRewardAmount == 0,
            "Rewards calculated"
        );
        Round storage round = rounds[user][epoch];
        uint8 winner = round.winningNumber;
        uint256 totalRewards = 0;
        uint256 treasuryAmt = 0;

        for(uint8 i = 0; i < 7; i++){
            totalRewards = totalRewards.add(round.totalAmountInSlabs[winner][payout[i]].mul(payout[i] + 1));
        }

        round.totalRewardAmount = totalRewards;
        if(totalRewards < round.totalAmountBet){
            treasuryAmt = (round.totalAmountBet).sub(totalRewards);
        }
        // Add to treasury
        round.treasuryCollections = treasuryAmt;
        treasuryAmount = treasuryAmount.add(treasuryAmt);

    }


    /**
     * @dev User bets
     */
    function _bet(
        address user,
        Bet[] calldata bets
        ) 
        internal 
        virtual
        whenNotPaused 
        notContract 
    {
        Round storage round = rounds[user][currentUserEpoch[msg.sender]];

        for(uint8 i = 0; i< bets.length; i++){
            
            round.bets.push(bets[i]);
            uint8 betType = bets[i].betType;
            uint8 differentiator = bets[i].differentiator;

            if(betType == 0){
                require(
                    differentiator == 0 || differentiator == 1 || differentiator == 2,
                    'Roulette: Invalid differentiator'
                    );
            }

            else if(betType == 1 || betType == 4){
                require(
                    differentiator == 0 || differentiator == 1,
                    'Roulette: Invalid differentiator'
                    );
            }

            else{
                require(
                    differentiator == 0,
                    'Roulette: Invalid differentiator'
                    );
            }

            require(betType < 7, "Roulette: betTypes can range between 0 and 6(included) only");

            require(
                bets[i].amount >= minBetAmount[betType] && bets[i].amount <= maxBetAmount[betType],
                "Roulette: Amount < MinBetAmount or Amount > MaxBetAmount for atleast one of the bets"
            );
            
            require(
                bets[i].numbers.length == numbersByKindOfBet[betType],
                "Roulette: invalid entry of numbers in atleast one bet"
                );

            uint8 slab = payout[betType];
            
            for(uint8 j = 0; j < bets[i].numbers.length; j++){
                round.totalAmountInSlabs[bets[i].numbers[j]][slab] = 
                    (round.totalAmountInSlabs[bets[i].numbers[j]][slab]).add(bets[i].amount);
            }
            round.totalAmountBet = (round.totalAmountBet).add(bets[i].amount);
            totalVolume = totalVolume.add(bets[i].amount);
        }

        IERC20Upgradeable(tokenStaked).safeTransferFrom(user, address(this), round.totalAmountBet);
        
    }

   
    function claim(uint256 epoch) external virtual notContract nonReentrant{
        require(!rounds[msg.sender][epoch].claimed, "Rewards claimed");

        (bool canClaim, uint256 reward) = claimable(msg.sender, epoch);
        
        require(canClaim || refundable(msg.sender, epoch), "Not claimable or refundable");
        
        if(refundable(msg.sender, epoch)){
            reward = rounds[msg.sender][epoch].totalAmountBet;
        }

        rounds[msg.sender][epoch].claimed = true;
        _safeTransferToken(address(msg.sender), reward);

        emit Claim(msg.sender, epoch, reward);
    }

    function claimAll() external virtual notContract nonReentrant{
        (bool isClaimable, uint256 reward) = totalClaimable(msg.sender);
        require(isClaimable, "Not claimable");
        _safeTransferToken(address(msg.sender), reward);
        claimCheckpoint[msg.sender] = currentUserEpoch[msg.sender];
        emit ClaimAll(msg.sender, currentUserEpoch[msg.sender], reward);
    }


    
    /**
     * @dev Claim all rewards in treasury
     * callable by admin
     */
    function claimTreasury() external virtual onlyAdmin{
        require(treasuryAmount > 0, "Zero treasury amount");
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransferToken(admin, currentTreasuryAmount);
        emit ClaimTreasury(currentTreasuryAmount);
    }

    /**
     * @dev called by the admin to pause, triggers stopped state
     */
    function pause() public onlyAdmin whenNotPaused returns(bool){
        _pause();

        emit Pause(counter);
        return true;
    }

    /**
     * @dev called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() public onlyAdmin whenPaused returns(bool){
        _unpause();

        emit Unpause(counter);
        return true;
    }

    /**
     * @dev Get the claimable stats of specific epoch and user account
     */
    function claimable(address user, uint256 epoch) 
        public 
        virtual
        view 
        returns (bool, uint256) 
    {
        Round storage round = rounds[user][epoch];
        if(round.claimed){
            return (false, 0);
        }
        
        uint8 winningNum = round.winningNumber;
        uint256 winAmount = 0;
        for(uint8 i = 0; i < 7; i++){
            winAmount = winAmount.add((round.totalAmountInSlabs[winningNum][payout[i]]).mul(payout[i] + 1));
        }

        return
            ((
                round.oracleCalled && 
                winAmount > 0
            ),
             winAmount);
    }

    function totalClaimable(
        address user
        ) 
        public 
        virtual
        view 
        returns (bool, uint256) 
    {
        uint256 totalAmount;

        for(uint256 i = claimCheckpoint[user].add(1); i <= currentUserEpoch[user]; i++){
            if(!rounds[user][i].claimed){
                (bool canClaim, uint256 reward) = claimable(user, i);

                if(canClaim){
                    totalAmount = totalAmount.add(reward);
                }

                else if(refundable(user, i)){
                    totalAmount = totalAmount.add(rounds[user][i].totalAmountBet);
                }
            }
            
        }

        if(totalAmount == 0){
            return (false, 0);
        }
        
        return (true, totalAmount);
    }
    
    function refundable(address user, uint256 epoch) 
    public 
    virtual
    view 
    returns(bool){
        Round storage round = rounds[user][epoch];
        return 
            (round.totalAmountBet != 0) &&
            (!round.oracleCalled);
    }
    /**
     * @dev Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid
     */
    function _getNumberFromOracle() internal returns (uint8) {
        uint256 allowedTime = block.timestamp.add(
            randomNumUpdateAllowance
        );
        (uint256 roundId, uint256 winner, uint256 timestamp) = 
            randomGenerator.latestRoundData(37);
        require(
            timestamp <= allowedTime,
            "Oracle update exceeded max allowance"
        );
        require(
            roundId >= randomRoundId,
            "Oracle update roundId < old id"
        );
        randomRoundId = roundId;
        return uint8(winner);
    }

    function _safeTransferToken(address to, uint256 value) internal {
        IERC20Upgradeable(tokenStaked).safeTransfer(to, value);
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }


    //If someone accidently sends tokens or native currency to this contract
    function withdrawAllTokens(address token) external onlyAdmin{
        uint256 bal = IERC20Upgradeable(token).balanceOf(address(this));
        withdrawToken(token, bal);
    }

    
    function withdrawToken(address token, uint256 amount) public virtual onlyAdmin{
        // require(token != tokenStaked, "Cannot withdraw the token staked");
        uint256 bal = IERC20Upgradeable(token).balanceOf(address(this));
        require(bal >= amount, "balanace of token in contract too low");
        IERC20Upgradeable(token).safeTransfer(admin, amount);
        emit TokenWithdrawal(admin, token, amount);
    }

    function withdrawAllNative() external onlyAdmin{
        uint256 bal = address(this).balance;
        withdrawNative(bal);
    } 

    function withdrawNative(uint256 amount) public virtual onlyAdmin{
        uint256 bal = address(this).balance;
        require(bal >= amount, "balanace of native token in contract too low");
        (bool sent, ) = admin.call{value: amount}("");
        require(sent, "Failure in native token transfer");
        emit NativeWithdrawal(admin, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
interface IRandomGenerator{
    
    function latestRoundData(uint256 modulus) external returns (uint256, uint256, uint256);
    
    function getSeed() external view returns(uint256);

    function setSeed(uint256 _seed) external; 

    function getCounter() external view returns(uint256);

    function addViewRole(address account) external;

    function removeFromViewRole(address account) external;

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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}