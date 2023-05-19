// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev RolaGame functions implementation.
 * @author The Systango Team
 */

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./RolaGameInternalUpgradeable.sol";

contract RolaGameUpgradeable is RolaGameInternalUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // MAX treasury fees of 10%
    uint256 public constant MAX_TREASURY_FEE = 1000;

    // Address of the ROLA token
    address public rolaAddress;

    // Address of the admin
    address public adminAddress;

    // Address of the operator
    address public operatorAddress;

    // Minimum betting amount
    uint256 public minBetAmount; 

    // Ledger of the bet info of the round for address
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    
    // Details of the user rounds
    mapping(uint256 => mapping(address => uint256[])) public userRounds;

    modifier onlyAdmin() {
        require(_msgSender() == adminAddress, "RolaGame: Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(_msgSender() == adminAddress || _msgSender() == owner(), "RolaGame: Not admin or owner");
        _;
    }

    modifier onlyOperator() {
        require(_msgSender() == operatorAddress, "RolaGame: Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(_msgSender()), "RolaGame: Contract not allowed");
        require(_msgSender() == tx.origin, "RolaGame: Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor 
     * @param _adminAddress: admin address
     * @param _operatorAddress: operator address
     * @param _rolaAddress: ROLA token address
     * @param _bufferSeconds: buffer of time for resolution of price
     * @param _minBetAmount: minimum bet amounts (in wei)
     * @param _treasuryFee: treasury fee (1000 = 10%)
     */
    function initialize(
        address _adminAddress,
        address _operatorAddress,
        address _rolaAddress,
        uint256 _bufferSeconds,
        uint256 _minBetAmount,
        uint256 _treasuryFee
    ) initializer external {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        // __DexPriceCalculationEnabled_init();
        __ChainlinkOraclePriceCalculationEnabled_init();
        require(_treasuryFee <= MAX_TREASURY_FEE, "RolaGame: Treasury fee too high");
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        rolaAddress = _rolaAddress;
        bufferSeconds = _bufferSeconds;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Bet bear position
     * @param roundId: roundId
     * @param amount: bet amount
     */
    function betBear(uint256 roundId, uint256 amount) external override whenNotPaused nonReentrant notContract {
        IERC20Upgradeable rolaCoaster = IERC20Upgradeable(rolaAddress);
        
        require(amount <= rolaCoaster.balanceOf(_msgSender()), "RolaGame: Insufficient ROLA tokens");
        require(_bettable(roundId), "RolaGame: Round not bettable");
        require(amount >= minBetAmount, "RolaGame: Bet amount must be greater than minBetAmount");
        require(ledger[roundId][_msgSender()].amount == 0, "RolaGame: Can only bet once per round");

        rolaCoaster.transferFrom(_msgSender(), address(this), amount);

        // Update round data
        Round storage round = roundData[roundId];
        round.totalAmount = round.totalAmount + amount;
        round.bearAmount = round.bearAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[roundId][_msgSender()];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[roundId][_msgSender()].push(roundId);

        emit BetBear(_msgSender(), roundId, amount);
    }

    /**
     * @notice Bet bull position
     * @param roundId: roundId
     * @param amount: amount
     */
    function betBull(uint256 roundId, uint256 amount) external override whenNotPaused nonReentrant notContract {
        IERC20Upgradeable rolaCoaster = IERC20Upgradeable(rolaAddress);
        
        require(amount <= rolaCoaster.balanceOf(_msgSender()), "RolaGame: Insufficient ROLA tokens");
        require(_bettable(roundId), "RolaGame: Round not bettable");
        require(amount >= minBetAmount, "RolaGame: Bet amount must be greater than minBetAmount");
        require(ledger[roundId][_msgSender()].amount == 0, "RolaGame: Can only bet once per round");

        rolaCoaster.transferFrom(_msgSender(), address(this), amount);

        // Update round data
        Round storage round = roundData[roundId];
        round.totalAmount = round.totalAmount + amount;
        round.bullAmount = round.bullAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[roundId][_msgSender()];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[roundId][_msgSender()].push(roundId);

        emit BetBull(_msgSender(), roundId, amount);
    }

    /**
     * @notice Claim reward for an array of roundIds
     * @param roundIds: array of roundIds
     * @param account: address to claim
     */
    function claim(uint256[] calldata roundIds, address account) external override nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < roundIds.length; i++) {
            require(roundData[roundIds[i]].startTimestamp != 0, "RolaGame: Round has not started");
            uint256 closeTimestamp = roundData[roundIds[i]].startTimestamp + (2 * roundData[roundIds[i]].roundExecutionTime);
            require(block.timestamp > closeTimestamp, "RolaGame: Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (genesisRound[roundIds[i]].DexCalled) {
                require(claimable(roundIds[i], account), "RolaGame: Not eligible for claim");
                Round memory round = roundData[roundIds[i]];
                addedReward = (ledger[roundIds[i]][account].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(roundIds[i], account), "RolaGame: Not eligible for refund");
                addedReward = ledger[roundIds[i]][account].amount;
            }
            ledger[roundIds[i]][account].claimed = true;
            reward += addedReward;

            emit Claim(account, roundIds[i], addedReward);
        }
        if (reward > 0) {
            IERC20Upgradeable(rolaAddress).safeTransfer(address(account), reward);
        }
    }

    /**
     * @notice Get claimable reward for an array of roundIds
     * @param roundIds: array of roundIds
     * @param account: address to claim
     */
    function getClaimableAmount (uint256[] calldata roundIds, address account) external override view returns (uint256) {
        uint256 reward = 0; // Initializes reward
        for (uint256 i = 0; i < roundIds.length; i++) {
            require(roundData[roundIds[i]].startTimestamp != 0, "RolaGame: Round has not started");
            uint256 closeTimestamp = roundData[roundIds[i]].startTimestamp + (2 * roundData[roundIds[i]].roundExecutionTime);
            require(block.timestamp > closeTimestamp, "RolaGame: Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (genesisRound[roundIds[i]].DexCalled) {
                require(claimable(roundIds[i], account), "RolaGame: Not eligible for claim");
                Round memory round = roundData[roundIds[i]];
                addedReward = (ledger[roundIds[i]][account].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(roundIds[i], account), "RolaGame: Not eligible for refund");
                addedReward = ledger[roundIds[i]][account].amount;
            }
            reward += addedReward;
        }
        return reward;
    }

    /**
     * @notice Start the next round n, lock price for round n-1, end round for round n-2
     * @dev Callable by operator
     * @param oracleAddress: Chainlink oracle address for price calculation
     * @param roundId: Round Id to start
     * @param startRoundTime: Time in seconds or block.timestamp
     * @param roundExecutionTime: execution time in seconds
     * @param preRoundId: Previous round id to lock
     * @param endRoundId: Round id to end round
     */
    function executeRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preRoundId, uint256 endRoundId) external override whenNotPaused onlyOperator {
        require(
            genesisRound[preRoundId].genesisStartOnce && genesisRound[endRoundId].genesisLockOnce,
            "RolaGame: Can only run after genesisStartRound and genesisLockRound is triggered"
        );

        Round memory round = roundData[preRoundId];
        (int currentPrice) = _getPriceFromChainlinkOracleAddress(round.oracleAddress);
        _safeLockRound(preRoundId, currentPrice);

        Round memory roundEnd = roundData[endRoundId];
        (int currentPriceEndRound) = _getPriceFromChainlinkOracleAddress(roundEnd.oracleAddress);
        _safeEndRound(endRoundId, currentPriceEndRound);
        _calculateRewards(endRoundId);
        
        _safeStartRound(oracleAddress, roundId, startRoundTime, roundExecutionTime, endRoundId);
        
        genesisRound[preRoundId].genesisLockOnce = true;
        genesisRound[roundId].genesisStartOnce = true;
    }

    /**
     * @notice Lock genesis round
     * @dev Callable by operator
     * @param oracleAddress: Chainlink oracle address for price calculation
     * @param roundId: Round Id to start
     * @param startRoundTime: Time in seconds or block.timestamp
     * @param roundExecutionTime: execution time in seconds
     * @param preRoundId: Previous round id to lock
     */
    function genesisLockRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preRoundId) external override whenNotPaused onlyOperator {
        require(genesisRound[preRoundId].genesisStartOnce, "RolaGame: Can only run after genesisStartRound is triggered");
        require(!genesisRound[preRoundId].genesisLockOnce, "RolaGame: Can only run genesisLockRound once");
        require(!genesisRound[roundId].genesisStartOnce, "RolaGame: Round ID already taken");

        Round memory round = roundData[preRoundId];
        (int currentPrice) = _getPriceFromChainlinkOracleAddress(round.oracleAddress);
        _safeLockRound(preRoundId, currentPrice);
        _startRound(oracleAddress, roundId, startRoundTime, roundExecutionTime);
        genesisRound[preRoundId].genesisLockOnce = true;
        genesisRound[roundId].genesisStartOnce = true;
    }

    /**
     * @notice Start genesis round
     * @dev Callable by operator
     * @param oracleAddress: Chainlink oracle address for price calculation
     * @param roundId: Round Id to start
     * @param startRoundTime: Time in seconds or block.timestamp
     * @param roundExecutionTime: execution time in seconds
     */
    function genesisStartRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime) external override whenNotPaused onlyOperator {
        require(!genesisRound[roundId].genesisStartOnce, "RolaGame: Can only run genesisStartRound once");        
        _startRound(oracleAddress, roundId, startRoundTime, roundExecutionTime);
        genesisRound[roundId].genesisStartOnce = true;
    }

    /**
     * @notice End Previous round (n-2)
     * @dev Callable by operator
     * @param roundId: Round id to end round
     */
    function endRound(uint256 roundId) external override whenNotPaused onlyOperator {
        require(
            genesisRound[roundId].genesisStartOnce && genesisRound[roundId].genesisLockOnce,
            "RolaGame: Can only run after genesisStartRound and genesisLockRound is triggered"
        );
        Round memory roundEnd = roundData[roundId];
        (int currentPriceEndRound) = _getPriceFromChainlinkOracleAddress(roundEnd.oracleAddress);
        _safeEndRound(roundId, currentPriceEndRound);
        _calculateRewards(roundId);
    }

    /**
     * @notice Lock Previous round (n-1)
     * @dev Callable by operator
     * @param roundId: Round id to lock round
     */
    function lockRound(uint256 roundId) external override whenNotPaused onlyOperator {
        require(genesisRound[roundId].genesisStartOnce, "RolaGame: Can only run after genesisStartRound is triggered");
        require(!genesisRound[roundId].genesisLockOnce, "RolaGame: Can only run genesisLockRound once");

        Round memory round = roundData[roundId];
        (int currentPrice) = _getPriceFromChainlinkOracleAddress(round.oracleAddress);
        _safeLockRound(roundId, currentPrice);
        genesisRound[roundId].genesisLockOnce = true;
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external override nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        recoverToken(rolaAddress, currentTreasuryAmount);
        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice Set buffer (in seconds)
     * @dev Callable by admin
     * @param _bufferSeconds: New buffer time to set
     */
    function setBufferTime(uint256 _bufferSeconds) external override whenPaused onlyAdmin {
        require(_bufferSeconds != 0, "RolaGame: bufferSeconds must be superior to 0");
        bufferSeconds = _bufferSeconds;
        emit NewBufferSeconds(_bufferSeconds);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     * @param _minBetAmount: New minimum bet amount to set
     */
    function setMinBetAmount(uint256 _minBetAmount) external override whenPaused onlyAdmin {
        require(_minBetAmount != 0, "RolaGame: minBetAmount must be superior to 0");
        minBetAmount = _minBetAmount;
        emit NewMinBetAmount(minBetAmount);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     * @param _treasuryFee: New treasury fee to set
     */
    function setTreasuryFee(uint256 _treasuryFee) external override whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "RolaGame: Treasury fee too high");
        treasuryFee = _treasuryFee;
        emit NewTreasuryFee(treasuryFee);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     * @param _adminAddress: New admin address to set
     */
    function setAdmin(address _adminAddress) external override onlyOwner {
        require(_adminAddress != address(0), "RolaGame: Cannot be zero address");
        adminAddress = _adminAddress;
        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     * @param _operatorAddress: New operator address to set
     */
    function setOperator(address _operatorAddress) external override onlyAdmin {
        require(_operatorAddress != address(0), "RolaGame: Cannot be zero address");
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Get the claimable stats of specific roundId and user account
     * @param roundId: roundId
     * @param user: user address
     * @return bool: claimable stats of specific roundId and user account
     */
    function claimable(uint256 roundId, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[roundId][user];
        Round memory round = roundData[roundId];
        GenesisRoundBlock storage genesisRoundData = genesisRound[roundId];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            genesisRoundData.DexCalled &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @notice Get the refundable stats of specific roundId and user account
     * @param roundId: roundId
     * @param user: user address
     * @return bool: refundable stats of specific roundId and user account
     */
    function refundable(uint256 roundId, address user) internal view returns (bool) {
        BetInfo memory betInfo = ledger[roundId][user];
        Round memory round = roundData[roundId];
        GenesisRoundBlock storage genesisRoundData = genesisRound[roundId];
        uint256 closeTimestamp = round.startTimestamp + (2 * round.roundExecutionTime);
        return
            !genesisRoundData.DexCalled &&
            !betInfo.claimed &&
            block.timestamp > closeTimestamp + bufferSeconds &&
            betInfo.amount != 0;
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param token: token address
     * @param amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address token, uint256 amount) public override onlyAdminOrOwner {
        IERC20Upgradeable(token).safeTransfer(address(_msgSender()), amount);
        emit TokenRecovery(token, amount);
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin
     */
    function pause() external override whenNotPaused onlyAdmin {
        _pause();
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * @dev Callable by admin
     */
    function unpause() external override whenPaused onlyAdmin {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev RolaGame Internal functions implementation.
 * @author The Systango Team
 */

import "./DexPriceCalculationUpgradeable.sol";
import "./ChainlinkOraclePriceCalculationUpgradeable.sol";
import "./IRolaGameUpgradeable.sol";

abstract contract RolaGameInternalUpgradeable is DexPriceCalculationUpgradeable, ChainlinkOraclePriceCalculationUpgradeable, IRolaGameUpgradeable {

    // Treasury rate in percentage (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryFee;

    // Treasury amount that was not claimed
    uint256 public treasuryAmount;

    // Number of seconds for valid execution of a prediction round
    uint256 public bufferSeconds;

    // Mapping of round ID to round functional details structure
    mapping(uint256 => Round) public roundData;

    // Mapping of round ID to round state details structure
    mapping(uint256 => GenesisRoundBlock) public genesisRound;

    // Enum for possible betting positions
    enum Position {
        Bull,
        Bear
    }

    // Structure of betting information
    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed;
    }

    // Structure of round for functional details
    struct Round {
        uint256 roundId;
        uint256 startTimestamp;
        uint256 roundExecutionTime;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        int256 lockPrice;
        int256 closePrice;
        address oracleAddress;
    }

    // Structure of round for state details
    struct GenesisRoundBlock {
        bool genesisLockOnce;
        bool genesisStartOnce;
        bool DexCalled;
    }

    /**
     * @notice Calculating the rewards of round
     * @param roundId: Round Id
     */
    function _calculateRewards(uint256 roundId) internal {
        require(
            roundData[roundId].rewardBaseCalAmount == 0 &&
                roundData[roundId].rewardAmount == 0,
            "RolaGame: Rewards calculated"
        );
        Round storage round = roundData[roundId];
        uint256 rewardBaseCalAmount;
        uint256 calculateTreasuryAmount;
        uint256 calculateRewardAmount;

        // Bear wins
        if (round.closePrice < round.lockPrice) {
            rewardBaseCalAmount = round.bearAmount;
            calculateTreasuryAmount = (round.totalAmount * treasuryFee) / 10000;
            calculateRewardAmount = round.totalAmount - calculateTreasuryAmount;
        }
        // Bull wins
        else if (round.closePrice > round.lockPrice) {
            rewardBaseCalAmount = round.bullAmount;
            calculateTreasuryAmount = (round.totalAmount * treasuryFee) / 10000;
            calculateRewardAmount = round.totalAmount - calculateTreasuryAmount;
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            calculateRewardAmount = 0;
            calculateTreasuryAmount = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = calculateRewardAmount;

        // Add to treasury
        treasuryAmount += calculateTreasuryAmount;

        emit RewardsCalculated(roundId, rewardBaseCalAmount, calculateRewardAmount, calculateTreasuryAmount);
    }

    /**
     * @notice safe end round by passing parameters.
     * @param roundId: Round Id.
     * @param price: Round Close Price.
     */
    function _safeEndRound(uint256 roundId, int256 price) internal {
        uint256 closeTimestamp = roundData[roundId].startTimestamp + (2 * roundData[roundId].roundExecutionTime);
        uint256 lockTimestamp = roundData[roundId].startTimestamp + roundData[roundId].roundExecutionTime;
        require(
            lockTimestamp != 0,
            "RolaGame: Can only end round after round has locked"
        );
        require(
            block.timestamp >= closeTimestamp,
            "RolaGame: Can only end round after closeTimestamp"
        );
        require(
            block.timestamp <=
                closeTimestamp + bufferSeconds,
            "RolaGame: Can only end round within bufferSeconds"
        );
        Round storage round = roundData[roundId];
        GenesisRoundBlock storage genesisRoundData = genesisRound[roundId];
        round.closePrice = price;
        genesisRoundData.DexCalled = true;

        emit EndRound(roundId, round.closePrice);
    }

    /**
     * @notice safe lock round by passing parameters
     * @param roundId: Round Id
     * @param price: Round Lock Price.
     */
    function _safeLockRound(uint256 roundId, int256 price) internal {
        uint256 lockTimestamp = roundData[roundId].startTimestamp + roundData[roundId].roundExecutionTime;
        require(
            roundData[roundId].startTimestamp != 0,
            "RolaGame: Can only lock round after round has started"
        );
        require(
            block.timestamp >= lockTimestamp,
            "RolaGame: Can only lock round after lockTimestamp"
        );
        require(
            block.timestamp <=
                lockTimestamp + bufferSeconds,
            "RolaGame: Can only lock round within bufferSeconds"
        );
        Round storage round = roundData[roundId];
        round.lockPrice = price;

        emit LockRound(roundId, round.lockPrice);
    }

    /**
     * @notice Start round by passing parameters
     * @param oracleAddress: Chainlink oracle address
     * @param roundId: Round Id
     * @param startRoundTime: Start Round Time
     * @param roundExecutionTime: Round execution time
     * @param endroundId: End round id
     */
    function _safeStartRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 endroundId) internal {
        uint256 closeTimestamp = roundData[endroundId].startTimestamp + (2 * roundData[endroundId].roundExecutionTime);
        require(
            genesisRound[endroundId].genesisStartOnce,
            "RolaGame: Can only run after genesisStartRound is triggered"
        );
        require(
            closeTimestamp != 0,
            "RolaGame: Can only start round after round has ended"
        );
        require(
            block.timestamp >= closeTimestamp,
            "RolaGame: Can only start new round after round n-2 closeTimestamp"
        );
        _startRound(oracleAddress, roundId, startRoundTime, roundExecutionTime);
    }

    /**
     * @notice Start round by passing parameters
     * @param oracleAddress: chainlink oracle address
     * @param roundId: Round Id
     * @param startRoundTime: Start Round Time
     * @param roundExecutionTime: Round execution time
     */
    function _startRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime) internal {
        uint256 lockTimeStamp = startRoundTime + roundExecutionTime;
        require(
            block.timestamp <= lockTimeStamp,
            "RolaGame: Can only start new round before round lockTimestamp"
        );
        Round storage round = roundData[roundId];
        round.oracleAddress = oracleAddress;
        round.roundExecutionTime = roundExecutionTime;
        round.startTimestamp = startRoundTime;
        round.roundId = roundId;
        round.totalAmount = 0;
        emit StartRound(roundId, round.oracleAddress);
    }

    /**
     * @notice Checking the round is bettable
     * @dev Checking the the round id bettable or not
     * @param roundId: Round Id
     * @return bool: If timestamp and lock timestamp will retun bool
     */
    function _bettable(uint256 roundId) internal view returns (bool) {
        uint256 lockTimestamp = roundData[roundId].startTimestamp + roundData[roundId].roundExecutionTime;
        return
            roundData[roundId].startTimestamp != 0 &&
            lockTimestamp != 0 &&
            block.timestamp > roundData[roundId].startTimestamp &&
            block.timestamp < lockTimestamp;
    }

    /**
     * @notice Checking get price from the Dex
     * @param baseAddress: Base Address for getting dex price
     * @param dexAddress: Pair Address for dex pair
     * @return currentPrice: Get Current Price after passing Dex address
     */
    function _getPriceFromDex(address baseAddress,address dexAddress) internal view returns (int) {
        (int currentPrice) = getTokenPriceInBaseToken(baseAddress, dexAddress);
        return (currentPrice);
    }

    /**
     * @notice Checking get price from the Oracle
     * @param oracleAddress: chainlink oracle address
     * @return currentPrice: Get Current Price after passing Oracle address
     */
    function _getPriceFromChainlinkOracleAddress(address oracleAddress) internal view returns (int) {
        (int currentPrice) = getTokenPriceByChainlinkOracleAddress(oracleAddress);
        return (currentPrice);
    }

    /**
     * @notice Checking the contract
     * @param account: Account address
     * @return size: check the size of contract
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the RolaGame implementation.
 * @author The Systango Team
 */

interface IRolaGameUpgradeable {

    /**
     * @dev Event generated when Bet will happen at BetBear
     */
    event BetBear(address indexed sender, uint256 indexed roundId, uint256 amount);

    /**
     * @dev Event generated when Bet will happen at BetBull
     */
    event BetBull(address indexed sender, uint256 indexed roundId, uint256 amount);

    /**
     * @dev Event generated when user will claim
     */
    event Claim(address indexed sender, uint256 indexed roundId, uint256 amount);

    /**
     * @dev Event generated when Round will lock
     */
    event LockRound(uint256 indexed roundId, int256 price);

    /**
     * @dev Event generated when Round will end
     */
    event EndRound(uint256 indexed roundId, int256 price);

    /**
     * @dev Event generated when a new Admin Address is set
     */
    event NewAdminAddress(address admin);

    /**
     * @dev Event generated when a new Buffer time is set
     */
    event NewBufferSeconds(uint256 bufferSeconds);

    /**
     * @dev Event generated when a new Mint Amount is set
     */
    event NewMinBetAmount(uint256 minBetAmount);

    /**
     * @dev Event generated when a new Treasury Fee is set
     */
    event NewTreasuryFee(uint256 treasuryFee);

    /**
     * @dev Event generated when a new Operator is set
     */
    event NewOperatorAddress(address operator);

    /**
     * @dev Event generated when Reward Calculation happen
     */
    event RewardsCalculated(uint256 indexed roundId, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount);

    /**
     * @dev Event generated when Round Start
     */
    event StartRound(uint256 indexed roundId, address oracleAddress);

    /**
     * @dev Event generated when token is recovered
     */
    event TokenRecovery(address indexed token, uint256 amount);

    /**
     * @dev Event generated when Claimed treasury account
     */
    event TreasuryClaim(uint256 amount);

    /**
     * @notice Start genesis round
     * @param oracleAddress: Chainlink oracle address for price calculation
     * @param roundId: Round Id to start
     * @param startRoundTime: Time in seconds or block.timestamp
     * @param roundExecutionTime: execution time in seconds
     */
    function genesisStartRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime) external;

    /**
     * @notice Bet bear position
     * @param roundId: roundId
     * @param amount: bet amount
     */
    function betBear(uint256 roundId, uint256 amount) external;

    /**
     * @notice Bet bull position
     * @param roundId: roundId
     * @param amount: amount
     */
    function betBull(uint256 roundId, uint256 amount) external;

    /**
     * @notice Lock genesis round
     * @param oracleAddress: Chainlink oracle address for price calculation
     * @param roundId: Round Id to start
     * @param startRoundTime: Time in seconds or block.timestamp
     * @param roundExecutionTime: execution time in seconds
     * @param preRoundId: Previous round id to lock
     */
    function genesisLockRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preRoundId) external;

    /**
     * @notice Start the next round n, lock price for round n-1, end round for round n-2
     * @param oracleAddress: Chainlink oracle address for price calculation
     * @param roundId: Round Id to start
     * @param startRoundTime: Time in seconds or block.timestamp
     * @param roundExecutionTime: execution time in seconds
     * @param preRoundId: Previous round id to lock
     * @param endRoundId: Round id to end round
     */
    function executeRound(address oracleAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preRoundId, uint256 endRoundId) external;

    /**
     * @notice Claim reward for an array of roundIds
     * @param roundIds: array of roundIds
     * @param account: address to claim
     */
    function claim(uint256[] calldata roundIds, address account) external;

    /**
     * @notice Get claimable reward for an array of roundIds
     * @param roundIds: array of roundIds
     * @param account: address to claim
     */
    function getClaimableAmount(uint256[] calldata roundIds, address account) external view returns (uint256);

    /**
     * @notice End Previous round (n-2)
     * @param roundId: Round id to end round
     */
    function endRound(uint256 roundId) external;

    /**
     * @notice Lock Previous round (n-1)
     * @param roundId: Round id to lock round
     */
    function lockRound(uint256 roundId) external;

    /**
     * @notice Claim all rewards in treasury
     */
    function claimTreasury() external;

    /**
     * @notice Set buffer (in seconds)
     * @param _bufferSeconds: New buffer time to set
     */
    function setBufferTime(uint256 _bufferSeconds) external;

    /**
     * @notice Set minBetAmount
     * @param _minBetAmount: New minimum bet amount to set
     */
    function setMinBetAmount(uint256 _minBetAmount) external;

    /**
     * @notice Set treasury fee
     * @param _treasuryFee: New treasury fee to set
     */
    function setTreasuryFee(uint256 _treasuryFee) external;

    /**
     * @notice Set admin address
     * @param _adminAddress: New admin address to set
     */
    function setAdmin(address _adminAddress) external;

    /**
     * @notice Set operator address
     * @param _operatorAddress: New operator address to set
     */
    function setOperator(address _operatorAddress) external;

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param token: token address
     * @param amount: token amount
     */
    function recoverToken(address token, uint256 amount) external;

    /**
     * @notice called by the admin to pause, triggers stopped state
     */
    function pause() external;

    /**
     * @notice called by the admin to unpause, returns to normal state
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DexPriceCalculationUpgradeable is Initializable {

    function __DexPriceCalculationEnabled_init() internal onlyInitializing {
        __DexPriceCalculationEnabled_init_unchained();
    }

    function __DexPriceCalculationEnabled_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Calculate price based on pair reserves
     * @param baseAddress: Base Address for getting dex price
     * @param dexAddress: Pair Address for dex pair
     */
    function getTokenPriceInBaseToken(address baseAddress,address dexAddress) public view returns(int res) {
        IUniswapV2Pair pair = IUniswapV2Pair(dexAddress);
        IUniswapV2ERC20 token1 = IUniswapV2ERC20(pair.token1());
        IUniswapV2ERC20 token0 = IUniswapV2ERC20(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();
        uint res0 = Res0*(10**token1.decimals());
        uint res1 = Res1*(10**token0.decimals());
        if(pair.token0() == baseAddress){
            res = int(((res0*(10**18))/res1));
            return (res);
        }
        if(pair.token1() == baseAddress){
            res = int(((res1*(10**18))/res0));
            return (res);
        }
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainlinkOraclePriceCalculationUpgradeable is Initializable {

    function __ChainlinkOraclePriceCalculationEnabled_init() internal onlyInitializing {
        __ChainlinkOraclePriceCalculationEnabled_init_unchained();
    }

    function __ChainlinkOraclePriceCalculationEnabled_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Calculate price based on chainlink oracle
     * @param oracleAddress: Chainlink oracle address
     */
    function getTokenPriceByChainlinkOracleAddress(address oracleAddress) public view returns(int price) {
        ( ,price, , , ) = AggregatorV3Interface(oracleAddress).latestRoundData();
    }  
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}