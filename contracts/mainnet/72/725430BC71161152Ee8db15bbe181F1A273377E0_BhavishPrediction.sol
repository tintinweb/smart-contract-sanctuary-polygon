// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import ".././Interface/IBhavishAdministrator.sol";
import ".././Interface/IPriceManager.sol";
import ".././Interface/IBhavishPrediction.sol";
import "./BhavishPredictionStorage.sol";
import "./../Integrations/Swap/BhavishSwap.sol";

/**
 * @title BhavishPrediction
 */
contract BhavishPrediction is IBhavishPrediction, AccessControl, Pausable, ReentrancyGuard {
    using Address for address;
    uint256 public currentRoundId;
    uint256 public roundTime = 1800; //10 mintues of round
    uint256 public roundzeroStartTimestamp;

    PredictionMarketStatus public marketStatus;

    uint256 public treasuryFee;
    uint256 public constant MAX_TREASURY_FEE = 100; // 10%
    uint256 public minPredictAmount; // minimum prediction amount (denominated in wei)
    uint256 public treasuryAmount; // funds in treasury collected from fee
    uint256 public decimals = 3;

    // State variables for storing the underlying and strike asset names -- Need to revisit this logic in later versions
    AssetPair public assetPair;

    IBhavishAdministrator public bhavishAdmin;
    IPriceManager public bhavishPriceManager;
    BhavishPredictionStorage public bhavishPredictionStorage;
    BhavishSwap public bhavishSwap;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event PausedMarket(uint256 currentRoundId);
    event UnPausedMarket(uint256 currentRoundId);

    event CreateRound(uint256 indexed roundId);
    event StartRound(uint256 indexed roundId);
    event EndRound(uint256 indexed roundId);
    event CancelRound(uint256 indexed roundId);
    event PredictUp(address indexed sender, uint256 indexed roundId, uint256 amount);
    event PredictDown(address indexed sender, uint256 indexed roundId, uint256 amount);
    event RewardsCalculated(
        uint256 indexed roundId,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount
    );
    event Refund(uint256 indexed roundId, address indexed recipient, uint256 refundDispersed, uint256 timestamp);

    event NewMinPredictAmount(uint256 minPredictAmount);
    event NewTreasuryFee(uint256 treasuryFee);
    event NewOperator(address indexed operator);
    event NewAdmin(address indexed admin);
    event TransferToAdmin(address indexed bhavishAdmin, uint256 amount);
    event Claim(address indexed sender, uint256 indexed roundId, uint256 amount);

    /**
     * @notice Constructor
     * @param _minPredictAmount minimum bet amounts (in wei)
     * @param _treasuryFee treasury fee (1000 = 10%)
     * @param _bhavishAdmin Bhavish Administrator
     * @param _bhavishPriceManager Price Manager
     * @param _underlying Name of the underlying asset
     * @param _strike Name of the strike asset
     */
    constructor(
        uint256 _minPredictAmount,
        uint256 _treasuryFee,
        IBhavishAdministrator _bhavishAdmin,
        IPriceManager _bhavishPriceManager,
        BhavishPredictionStorage _bhavishPredictionStorage,
        bytes32 _underlying,
        bytes32 _strike
    ) {
        require(_minPredictAmount > 0, "Invalid Min Predict amount");
        require(_treasuryFee > 0 && _treasuryFee < MAX_TREASURY_FEE, "Treasury fee is too high");
        minPredictAmount = _minPredictAmount;
        treasuryFee = _treasuryFee;
        bhavishAdmin = _bhavishAdmin;
        bhavishPriceManager = _bhavishPriceManager;
        bhavishPredictionStorage = _bhavishPredictionStorage;
        AssetPair memory pair = AssetPair(_underlying, _strike);
        assetPair = pair;
        currentRoundId = bhavishPredictionStorage.latestRoundId();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Modifiers go here --------

    modifier onlyAdmin(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "Address not an admin");
        _;
    }

    modifier onlyOperator(address _address) {
        require(hasRole(OPERATOR_ROLE, _address), "Address not an operator");
        _;
    }

    // Roles granting goes here --------

    /**
     * @notice Set operator
     * @dev callable by Admin of the contract
     * @param _operator new operator address
     */
    function setOperator(address _operator) external onlyAdmin(msg.sender) {
        require(!address(_operator).isContract(), "Operator cannot be a contract");
        require(_operator != address(0), "Cannot be zero address");
        grantRole(OPERATOR_ROLE, _operator);

        emit NewOperator(_operator);
    }

    /**
     * @notice Set the bhavish administrator
     * @param _bhavishAdministrator Address of the bhavish admin contract
     */
    function setBhavishAdministrator(IBhavishAdministrator _bhavishAdministrator) external onlyAdmin(msg.sender) {
        require(address(_bhavishAdministrator).isContract(), "Not Bhavish Administrator");
        bhavishAdmin = _bhavishAdministrator;
    }

    /**
     * @notice Remove operator
     * @dev callable by Admin of the contract
     * @param _address current operator
     */
    function removeOperator(address _address) external onlyAdmin(msg.sender) {
        revokeRole(OPERATOR_ROLE, _address);
    }

    /**
     * @notice set the bhavish swap
     * @param _bhavishSwap bhavish swap address
     */
    function setBhavishSwap(BhavishSwap _bhavishSwap) external onlyAdmin(msg.sender) {
        require(address(_bhavishSwap).isContract(), "Swapper is not a contract");
        bhavishSwap = _bhavishSwap;
    }

    // This is need for this contract to accept native currency

    /**
     * @notice Add funds
     */
    receive() external payable {}

    // Pause/Unpause the contract logic goes here --------

    /**
     * @notice Pause the contract
     * @dev Callable by admin
     */
    function pause() external whenNotPaused onlyAdmin(msg.sender) {
        _pause();
        for (
            uint256 tempRoundId = currentRoundId;
            tempRoundId <= bhavishPredictionStorage.latestRoundId();
            tempRoundId++
        ) {
            Round memory round = bhavishPredictionStorage.getPredictionRound(tempRoundId);
            if (round.roundState != RoundState.CANCELLED) {
                _cancelRound(tempRoundId);
            }
        }

        emit PausedMarket(currentRoundId);
    }

    /**
     * @notice Unpuase the contract
     * @dev Callable by admin
     */
    function unPause() external whenPaused onlyAdmin(msg.sender) {
        marketStatus.createPredictionMarketOnce = false;
        marketStatus.startPredictionMarketOnce = false;
        currentRoundId = bhavishPredictionStorage.latestRoundId();
        _unpause();

        emit UnPausedMarket(currentRoundId);
    }

    // Set the min reqs for the contract goes here ---------

    /**
     * @notice Set minPredictAmount
     * @dev Callable by admin
     * @param _minPredictAmount minimum Predict amount to be set
     */
    function setMinPredictAmount(uint256 _minPredictAmount) external whenPaused onlyAdmin(msg.sender) {
        require(_minPredictAmount > 0, "Must be superior to 0");
        minPredictAmount = _minPredictAmount;

        emit NewMinPredictAmount(_minPredictAmount);
    }

    /**
     * @notice Set Treasury Fee
     * @dev Callable by admin
     * @param _treasuryFee new treasury fee
     */
    function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin(msg.sender) {
        require(_treasuryFee > 0 && _treasuryFee < MAX_TREASURY_FEE, "Treasury fee is too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(_treasuryFee);
    }

    /**
     * @notice Set the round time
     * @dev Callable by operator
     * @param _roundTime round time
     */
    function setRoundTime(uint256 _roundTime) external whenPaused onlyOperator(msg.sender) {
        require(0 <= _roundTime && _roundTime <= 3600, "Round Time should be between 1 sec to 3600 sec");
        roundTime = _roundTime;
    }

    // Prediction logic goes here --------

    /**
     * @notice Create Round
     * @param roundId round Id
     * @param _startTimestamp Round start timestamp
     */
    function _createRound(uint256 roundId, uint256 _startTimestamp) private {
        Round memory round = bhavishPredictionStorage.getPredictionRound(roundId);
        require(round.roundId == 0, "Round already exists");
        require(_startTimestamp - roundTime >= block.timestamp, "Round time is too short");
        round.roundId = roundId;
        round.roundStartTimestamp = _startTimestamp;
        round.roundEndTimestamp = round.roundStartTimestamp + roundTime;
        round.roundState = RoundState.CREATED;

        bhavishPredictionStorage.createPredictionRound(round);

        emit CreateRound(roundId);
    }

    /**
     * @notice Start Round
     * @param _predictRoundId round Id
     * @param _price Price of the asset
     */
    function _startRound(uint256 _predictRoundId, uint256 _price) private {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);
        if (_price == 0) {
            _cancelRound(_predictRoundId);
        } else {
            require(round.roundState == RoundState.CREATED, "Round should be created");
            require(round.roundStartTimestamp <= block.timestamp, "Too early to start the round");

            bhavishPredictionStorage.setRoundState(_predictRoundId, RoundState.STARTED, _price, true);

            emit StartRound(_predictRoundId);
        }
    }

    /**
     * @notice Cancel the round
     * @param _predictRoundId Round id of the round that needs to be cancelled
     */
    function _cancelRound(uint256 _predictRoundId) private {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);
        require(round.roundState != RoundState.CANCELLED, "Cannot cancel already cancelled round");

        bhavishPredictionStorage.cancelRound(_predictRoundId);
        emit CancelRound(_predictRoundId);
    }

    /**
     * @notice End Round
     * @param _predictRoundId round Id
     * @param _price Price of the asset
     */
    function _endRound(uint256 _predictRoundId, uint256 _price) private {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);
        require(round.roundState == RoundState.STARTED, "Round is not started yet");
        require(round.roundEndTimestamp <= block.timestamp, "Too early to end the round");

        bhavishPredictionStorage.setRoundState(_predictRoundId, RoundState.ENDED, _price, false);

        emit EndRound(_predictRoundId);
    }

    /**
     * @notice Calculate Rewards for the round
     * @param _predictRoundId round Id
     */
    function _calculateRewards(uint256 _predictRoundId) private {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);
        require(round.roundState == RoundState.ENDED, "Round is not ended");
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        treasuryAmt = (round.totalAmount * treasuryFee) / (10**decimals);

        // Bull wins
        if (round.endPrice > round.startPrice) {
            rewardBaseCalAmount = round.upPredictAmount;
            rewardAmount = round.totalAmount - treasuryAmt;
            // case when there are no bets on winning side. loosing side bets should be moved to treasury
            if (rewardBaseCalAmount == 0) treasuryAmt = round.downPredictAmount;
        }
        // Bear wins
        else if (round.endPrice < round.startPrice) {
            rewardBaseCalAmount = round.downPredictAmount;
            rewardAmount = round.totalAmount - treasuryAmt;
            // case when there are no bets on winning side. loosing side bets should be moved to treasury
            if (rewardBaseCalAmount == 0) treasuryAmt = round.upPredictAmount;
        }
        // draw or tie
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
        }

        treasuryAmount += treasuryAmt;
        bhavishPredictionStorage.setRewardAmountForRound(_predictRoundId, rewardAmount, rewardBaseCalAmount);

        emit RewardsCalculated(_predictRoundId, rewardBaseCalAmount, rewardAmount, treasuryAmount);
    }

    /**
     * @notice Transfer
     * @param to recipient address
     * @param value value
     */
    function _safeTransfer(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    /**
     * @notice Check whether the round is refundable
     * @param _predictRound round details
     */
    function _refundable(Round memory _predictRound) private pure returns (bool) {
        return
            _predictRound.rewardBaseCalAmount == 0 &&
            _predictRound.rewardAmount == 0 &&
            _predictRound.startPrice == _predictRound.endPrice;
    }

    /**
     * @notice Transfer the funds to bhavish admin contract_predictRound
     * @param _amount Amount to be transfered
     */
    function transferToAdmin(uint256 _amount) external payable nonReentrant onlyAdmin(msg.sender) {
        require(_amount <= treasuryAmount, "Transfer amount is too large");
        treasuryAmount -= _amount;
        address bhavishAdminAddress = address(bhavishAdmin);
        (bool success, ) = payable(bhavishAdminAddress).call{ value: _amount }("");
        require(success, "TransferHelper: TRANSFER_FAILED");

        emit TransferToAdmin(bhavishAdminAddress, _amount);
    }

    /**
     * @notice Bet Bull position
     * @param _predictRoundId Round Id
     * @param _userAddress Address of the user
     */
    function predictUp(uint256 _predictRoundId, address _userAddress)
        external
        payable
        override
        whenNotPaused
        nonReentrant
    {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);

        require(round.roundState == RoundState.CREATED && round.roundId != 0, "Bet is too early/late");
        require(block.timestamp <= round.roundStartTimestamp, "round already started");
        require(msg.value >= minPredictAmount, "Bet amount must be greater than minBetAmount");

        // Update round data
        uint256 amount = msg.value;
        bhavishPredictionStorage.setAmount(_predictRoundId, amount, true);

        BetInfo memory betInfo = bhavishPredictionStorage.getBetInfo(_predictRoundId, _userAddress);
        // Update user data
        if (betInfo.upPredictAmount == 0 && betInfo.downPredictAmount == 0) {
            bhavishPredictionStorage.setLedgerInfo(_userAddress, _predictRoundId);
        }
        bhavishPredictionStorage.setBetInfo(amount, _predictRoundId, _userAddress, true);

        emit PredictUp(_userAddress, _predictRoundId, msg.value);
    }

    /**
     * @notice Bet Bear position
     * @param _predictRoundId Round Id
     * @param _userAddress Address of the user
     */
    function predictDown(uint256 _predictRoundId, address _userAddress)
        external
        payable
        override
        whenNotPaused
        nonReentrant
    {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);

        require(block.timestamp <= round.roundStartTimestamp, "round already started");
        require(round.roundState == RoundState.CREATED && round.roundId != 0, "Bet is too early/late");
        require(msg.value >= minPredictAmount, "Bet amount must be greater than minBetAmount");

        // Update round data
        uint256 amount = msg.value;
        bhavishPredictionStorage.setAmount(_predictRoundId, amount, false);

        // Update user data
        BetInfo memory betInfo = bhavishPredictionStorage.getBetInfo(_predictRoundId, _userAddress);

        if (betInfo.upPredictAmount == 0 && betInfo.downPredictAmount == 0) {
            bhavishPredictionStorage.setLedgerInfo(_userAddress, _predictRoundId);
        }

        bhavishPredictionStorage.setBetInfo(amount, _predictRoundId, _userAddress, false);

        emit PredictDown(_userAddress, _predictRoundId, msg.value);
    }

    /**
     * @notice Create Round Zero round
     * @dev callable by Operator
     * @param _roundzeroStartTimestamp round zero round start timestamp
     */
    function createPredictionMarket(uint256 _roundzeroStartTimestamp)
        external
        override
        whenNotPaused
        onlyOperator(msg.sender)
    {
        require(!marketStatus.createPredictionMarketOnce, "Can only run roundzeroCreateRound once");
        currentRoundId = currentRoundId + 1;
        roundzeroStartTimestamp = _roundzeroStartTimestamp;
        _createRound(currentRoundId, _roundzeroStartTimestamp);
        marketStatus.createPredictionMarketOnce = true;

        //create next 3 rounds to be able to bet by users
        _createRound(currentRoundId + 1, roundzeroStartTimestamp + roundTime);
        _createRound(currentRoundId + 2, roundzeroStartTimestamp + roundTime + roundTime);
        _createRound(currentRoundId + 3, roundzeroStartTimestamp + roundTime + roundTime + roundTime);
    }

    /**
     * @notice Start Zero round
     * @dev callable by Operator
     */
    function startPredictionMarket() external override whenNotPaused onlyOperator(msg.sender) {
        require(marketStatus.createPredictionMarketOnce, "Can only run after roundzeroCreateRound is triggered");
        require(!marketStatus.startPredictionMarketOnce, "Can only run roundzeroStartRound once");

        require(block.timestamp >= roundzeroStartTimestamp, "Round cannot be started early");

        (uint256 price, ) = bhavishPriceManager.getPrice(
            assetPair.underlying,
            assetPair.strike,
            roundzeroStartTimestamp
        );

        _startRound(currentRoundId, price);

        marketStatus.startPredictionMarketOnce = true;
    }

    /**
     * @notice Get the _claimable stats of specific round id and user account
     * @param _round: round details
     * @param _betInfo: bet info of a user
     */
    function _claimable(Round memory _round, BetInfo memory _betInfo) public pure returns (bool) {
        if (_round.startPrice == _round.endPrice) {
            return true;
        }
        return
            (_betInfo.upPredictAmount != 0 || _betInfo.downPredictAmount != 0) &&
            _betInfo.amountDispersed == 0 &&
            ((_round.endPrice > _round.startPrice && _betInfo.upPredictAmount != 0) ||
                (_round.endPrice < _round.startPrice && _betInfo.downPredictAmount != 0));
    }

    /**
     * @notice claim reward
     * @param roundIds: round Ids
     */
    function claim(
        uint256[] calldata roundIds,
        bytes32 toAsset,
        bool convert,
        uint256 slippage
    ) external nonReentrant {
        uint256 reward = 0;
        for (uint256 i = 0; i < roundIds.length; i++) {
            Round memory round = bhavishPredictionStorage.getPredictionRound(roundIds[i]);
            BetInfo memory betInfo = bhavishPredictionStorage.getBetInfo(roundIds[i], msg.sender);

            require(round.roundState == RoundState.ENDED, "Round not eligible for rewards");
            require(round.totalAmount > 0, "No bets in the round");

            if (!_claimable(round, betInfo)) {
                continue;
            }
            if (round.startPrice == round.endPrice) {
                require(_refundable(round), "Not eligible for refund");
            }

            uint256 addedReward = _calcRewardsForUser(round, betInfo);

            bhavishPredictionStorage.setBetAmountDispersed(round.roundId, msg.sender, addedReward);
            reward += addedReward;
            emit Claim(msg.sender, roundIds[i], addedReward);
        }

        if (convert && reward > 0) {
            BhavishSwap.SwapStruct memory swapStruct = BhavishSwap.SwapStruct({
                deadline: block.timestamp + (roundTime * 2),
                fromAsset: bytes32("MATIC"),
                toAsset: toAsset,
                amountIn: 0
            });
            bhavishSwap.swapExactETHForTokens{ value: reward }(swapStruct, msg.sender, slippage);
        } else if (reward > 0) {
            _safeTransfer(address(msg.sender), reward);
        }
    }

    /**
     * @notice getRewards reward
     * @param roundIds: round Ids
     */
    function getRewards(uint256[] calldata roundIds) public view returns (uint256) {
        uint256 reward = 0;
        for (uint256 i = 0; i < roundIds.length; i++) {
            Round memory round = bhavishPredictionStorage.getPredictionRound(roundIds[i]);
            BetInfo memory betInfo = bhavishPredictionStorage.getBetInfo(roundIds[i], msg.sender);

            if (!_claimable(round, betInfo)) {
                continue;
            }

            reward += _calcRewardsForUser(round, betInfo);
        }

        return reward;
    }

    function _calcRewardsForUser(Round memory _round, BetInfo memory _betInfo)
        private
        view
        returns (uint256 addedReward)
    {
        addedReward = 0;
        //check's for a tie
        if (_round.endPrice == _round.startPrice) {
            if (_refundable(_round)) {
                uint256 userTotalBetAmount = _betInfo.upPredictAmount + _betInfo.downPredictAmount;
                addedReward = userTotalBetAmount - ((userTotalBetAmount * treasuryFee) / 10**decimals);
            }
        } else if (_round.rewardBaseCalAmount == _round.upPredictAmount) {
            addedReward = (_betInfo.upPredictAmount * _round.rewardAmount) / _round.rewardBaseCalAmount;
        } else if (_round.rewardBaseCalAmount == _round.downPredictAmount) {
            addedReward = (_betInfo.downPredictAmount * _round.rewardAmount) / _round.rewardBaseCalAmount;
        }
    }

    /**
     * @notice Refund to users if a round is cancelled
     * @param _predictRoundId Round id of the cancelled round
     */
    function refundUsers(uint256 _predictRoundId) public nonReentrant {
        Round memory round = bhavishPredictionStorage.getPredictionRound(_predictRoundId);
        require(round.roundState == RoundState.CANCELLED, "User not eligible for refund");

        BetInfo memory betInfo = bhavishPredictionStorage.getBetInfo(_predictRoundId, msg.sender);
        uint256 amtInvested = betInfo.upPredictAmount + betInfo.downPredictAmount;
        uint256 tresFeeAmount = 0;
        if (amtInvested > 0) {
            tresFeeAmount = (amtInvested * treasuryFee) / 10**decimals;
            amtInvested -= tresFeeAmount;
            _safeTransfer(msg.sender, amtInvested);
            emit Refund(_predictRoundId, msg.sender, amtInvested, block.timestamp);
        }
        treasuryAmount += tresFeeAmount;
    }

    /**
     * @notice Execute round
     * @dev Callable by Operator
     */
    function executeRound() external override whenNotPaused {
        require(
            marketStatus.createPredictionMarketOnce && marketStatus.startPredictionMarketOnce,
            "Can only run after roundzeroStartRound"
        );
        Round memory curRound = bhavishPredictionStorage.getPredictionRound(currentRoundId);
        Round memory roundPlusThree = bhavishPredictionStorage.getPredictionRound(currentRoundId + 3);

        // currentRoundId refers to current round n
        // fetch price to end current round and start new round
        (uint256 price, ) = bhavishPriceManager.getPrice(
            assetPair.underlying,
            assetPair.strike,
            curRound.roundEndTimestamp
        );

        // End and Disperse current round
        if (curRound.roundState != RoundState.CANCELLED && price != 0) {
            _endRound(currentRoundId, price);

            _calculateRewards(currentRoundId);
        } else if (curRound.roundState != RoundState.CANCELLED && price == 0) {
            _cancelRound(currentRoundId);
        }

        // Start next round
        _startRound(currentRoundId + 1, price);

        // Create a new round n+3
        _createRound(currentRoundId + 4, roundPlusThree.roundEndTimestamp);

        // Point currentRoundId to next round
        currentRoundId = currentRoundId + 1;
    }

    function getCurrentRoundDetails() external view returns (IBhavishPrediction.Round memory round) {
        round = bhavishPredictionStorage.getPredictionRound(currentRoundId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

/**
 * @title IBhavishAdministrator
 */

interface IBhavishAdministrator {
    /**
     * @dev Emitted when Treasury is claimed by the admin
     * @param admin Address of the admin
     * @param amount Amount claimed by the admin
     */
    event TreasuryClaim(address indexed admin, uint256 amount);

    /**
     * @dev Claim the treasury amount. Can be performed only by admin
     * @param _amount  Amount that admin wants to claim
     */
    function claimTreasury(uint256 _amount) external;
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IPriceManager {
    /**
     * @dev Emitted when the new Oracle aggregator data has been added.
     * @param _underlying Address of the underlying asset.
     * @param _strike Address of the strike asset.
     * @param _bhavishAggregator Address of the bhavish aggregator.
     * @param _aggregator Address of the aggregator.
     */
    event AddAssetPairAggregator(
        bytes32 indexed _underlying,
        bytes32 indexed _strike,
        address _bhavishAggregator,
        address _aggregator
    );

    /**
     * @notice Function to add the price for an underlying, strike asset pair
     * @param _underlying Underlying Asset
     * @param _strike Strike Asset
     * @param _aggregator Address of the aggregator.
     */
    function setPairContract(
        bytes32 _underlying,
        bytes32 _strike,
        address _aggregator
    ) external;

    /**
     * @notice Function to get the price for an underlying asset
     * @param _underlying Underlying Asset
     * @param _strike Strike Asset
     * @param _timestamp    Timestamp
     * @return price asset price
     * @return decimals asset price decimals
     */
    function getPrice(
        bytes32 _underlying,
        bytes32 _strike,
        uint256 _timestamp
    ) external view returns (uint256 price, uint8 decimals);
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IBhavishPrediction {
    enum RoundState {
        CREATED,
        STARTED,
        ENDED,
        CANCELLED
    }

    struct Round {
        uint256 roundId;
        RoundState roundState;
        uint256 upPredictAmount;
        uint256 downPredictAmount;
        uint256 totalAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 roundStartTimestamp;
        uint256 roundEndTimestamp;
    }

    struct BetInfo {
        uint256 upPredictAmount;
        uint256 downPredictAmount;
        uint256 amountDispersed;
    }

    struct AssetPair {
        bytes32 underlying;
        bytes32 strike;
    }

    struct PredictionMarketStatus {
        bool startPredictionMarketOnce;
        bool createPredictionMarketOnce;
    }

    /**
     * @notice Create Round Zero round
     * @dev callable by Operator
     * @param _roundzeroStartTimestamp: round zero round start timestamp
     */
    function createPredictionMarket(uint256 _roundzeroStartTimestamp) external;

    /**
     * @notice Start Zero round
     * @dev callable by Operator
     */
    function startPredictionMarket() external;

    /**
     * @notice Execute round
     * @dev Callable by Operator
     */
    function executeRound() external;

    /**
     * @notice Bet Bull position
     * @param roundId: Round Id
     * @param userAddress: Address of the user
     */
    function predictUp(uint256 roundId, address userAddress) external payable;

    /**
     * @notice Bet Bear position
     * @param roundId: Round Id
     * @param userAddress: Address of the user
     */
    function predictDown(uint256 roundId, address userAddress) external payable;

    function getCurrentRoundDetails() external view returns (IBhavishPrediction.Round memory);
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import ".././Interface/IBhavishPrediction.sol";

contract BhavishPredictionStorage is AccessControl {
    using Address for address;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(uint256 => IBhavishPrediction.Round) public rounds;
    mapping(uint256 => mapping(address => IBhavishPrediction.BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;
    mapping(uint256 => address[]) public usersInRounds;

    uint256 public latestRoundId;

    modifier onlyManager(address _address) {
        require(hasRole(MANAGER_ROLE, _address), "caller has no access to the method");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setManager(address _address) external {
        require(_address != address(0) && _address.isContract(), "Invalid manager address");
        grantRole(MANAGER_ROLE, _address);
    }

    function createPredictionRound(IBhavishPrediction.Round memory round) external onlyManager(msg.sender) {
        rounds[round.roundId] = round;
        latestRoundId = round.roundId;
    }

    function updatePredictionRound(IBhavishPrediction.Round memory round) external onlyManager(msg.sender) {
        require(rounds[round.roundId].roundId != 0, "Cannot overwrite non existing round");
        rounds[round.roundId] = round;
    }

    function getUsersInRounds(uint256 _predictRoundId) external view returns (address[] memory userAddresses) {
        userAddresses = usersInRounds[_predictRoundId];
    }

    function getPredictionRound(uint256 roundId) external view returns (IBhavishPrediction.Round memory round) {
        round = rounds[roundId];
    }

    function getArrayRounds(uint256 from, uint256 to)
        external
        view
        returns (IBhavishPrediction.Round[] memory arrayOfRounds)
    {
        require(to <= latestRoundId, "Index out of bound");
        require(from < to, "From < To");
        uint256 len = to - from;
        arrayOfRounds = new IBhavishPrediction.Round[](to - from);

        for (uint256 i = 0; i < len; i++) {
            arrayOfRounds[i] = rounds[from];
            from += 1;
        }
    }

    function setRoundState(
        uint256 roundId,
        IBhavishPrediction.RoundState state,
        uint256 price,
        bool start
    ) external onlyManager(msg.sender) {
        IBhavishPrediction.Round storage round = rounds[roundId];
        round.roundState = state;
        if (start) round.startPrice = price;
        else round.endPrice = price;
    }

    function cancelRound(uint256 roundId) external onlyManager(msg.sender) {
        IBhavishPrediction.Round storage round = rounds[roundId];
        round.roundState = IBhavishPrediction.RoundState.CANCELLED;
    }

    function setRewardAmountForRound(
        uint256 roundId,
        uint256 rewardAmount,
        uint256 rewardBaseCalAmount
    ) external onlyManager(msg.sender) {
        IBhavishPrediction.Round storage round = rounds[roundId];
        round.rewardAmount = rewardAmount;
        round.rewardBaseCalAmount = rewardBaseCalAmount;
    }

    function setAmount(
        uint256 roundId,
        uint256 amount,
        bool directionUp
    ) external onlyManager(msg.sender) {
        IBhavishPrediction.Round storage round = rounds[roundId];
        round.totalAmount = round.totalAmount + amount;
        if (directionUp) round.upPredictAmount += amount;
        else round.downPredictAmount += amount;
    }

    function createBet(
        IBhavishPrediction.BetInfo memory betInfo,
        uint256 roundId,
        address userAddress
    ) external onlyManager(msg.sender) {
        ledger[roundId][userAddress] = betInfo;
    }

    function getBetInfo(uint256 roundId, address userAddress)
        external
        view
        returns (IBhavishPrediction.BetInfo memory betInfo)
    {
        betInfo = ledger[roundId][userAddress];
    }

    function setBetAmountDispersed(
        uint256 roundId,
        address userAddress,
        uint256 amountDispersed
    ) external onlyManager(msg.sender) {
        IBhavishPrediction.BetInfo storage betInfo = ledger[roundId][userAddress];
        betInfo.amountDispersed += amountDispersed;
    }

    function setBetInfo(
        uint256 amount,
        uint256 roundId,
        address userAddress,
        bool directionUp
    ) external onlyManager(msg.sender) {
        IBhavishPrediction.BetInfo storage betInfo = ledger[roundId][userAddress];
        if (directionUp) betInfo.upPredictAmount += amount;
        else betInfo.downPredictAmount += amount;
    }

    function setLedgerInfo(address userAddress, uint256 roundId) external onlyManager(msg.sender) {
        userRounds[userAddress].push(roundId);
        usersInRounds[roundId].push(userAddress);
    }

    function getUserRoundHistory(address userAddress)
        external
        view
        returns (IBhavishPrediction.BetInfo[] memory userRoundHistory)
    {
        userRoundHistory = new IBhavishPrediction.BetInfo[](userRounds[userAddress].length);
        for (uint256 i = 0; i < userRounds[userAddress].length; i++) {
            uint256 roundId = userRounds[userAddress][i];
            userRoundHistory[i] = ledger[roundId][userAddress];
        }
    }

    function getUserRounds(address userAddress) external view returns (uint256[] memory) {
        return userRounds[userAddress];
    }

    function getUserInRounds(uint256 roundId) external view returns (address[] memory) {
        return usersInRounds[roundId];
    }
}

// SPDX-License-Identifier: BSD-4-Clause

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../Interface/IBhavishSDK.sol";

pragma solidity ^0.8.13;

contract BhavishSwap is AccessControl {
    using SafeERC20 for IERC20;

    address public UNISWAP_FACTORY;
    address public UNISWAP_ROUTER;
    mapping(bytes32 => address[]) public pathMapper;
    uint256 public decimals = 3;

    struct SwapStruct {
        uint256 amountIn;
        uint256 deadline;
        bytes32 fromAsset;
        bytes32 toAsset;
    }

    modifier onlyAsset(bytes32 fromAsset, bytes32 toAsset) {
        address[] memory path = getPath(fromAsset, toAsset);
        require(path.length > 1, "Asset swap not supported");
        _;
    }

    modifier onlyAdmin(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "Address not an admin");
        _;
    }

    constructor(address uniswapFactory, address uniswapRouter) {
        UNISWAP_FACTORY = uniswapFactory;
        UNISWAP_ROUTER = uniswapRouter;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Add funds
     */
    receive() external payable {}

    function setPath(
        bytes32 fromAsset,
        bytes32 toAsset,
        address[] memory path
    ) external onlyAdmin(msg.sender) {
        require(path.length > 1, "Path cannot be empty or 1");
        pathMapper[keccak256((abi.encode(fromAsset, toAsset)))] = path;
    }

    function getPath(bytes32 fromAsset, bytes32 toAsset) public view returns (address[] memory) {
        return pathMapper[keccak256(abi.encode(fromAsset, toAsset))];
    }

    // Get the amounts out for the specified path
    function getAmountsOut(
        uint256 amountIn,
        bytes32 fromAsset,
        bytes32 toAsset
    ) public view onlyAsset(fromAsset, toAsset) returns (uint256[] memory amounts) {
        address[] memory path = getPath(fromAsset, toAsset);
        amounts = new uint256[](path.length);
        amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(amountIn, path);
    }

    function swapExactTokensForETH(
        SwapStruct memory _swapStruct,
        address to,
        uint256 slippage
    ) external onlyAsset(_swapStruct.fromAsset, _swapStruct.toAsset) returns (uint256[] memory amounts) {
        address[] memory path = getPath(_swapStruct.fromAsset, _swapStruct.toAsset);
        uint256[] memory amountsOut = getAmountsOut(_swapStruct.amountIn, _swapStruct.fromAsset, _swapStruct.toAsset);
        uint256 amountOut = amountsOut[amountsOut.length - 1] -
            ((amountsOut[amountsOut.length - 1] * slippage) / 10**decimals);
        IERC20(path[0]).safeApprove(UNISWAP_ROUTER, _swapStruct.amountIn);
        amounts = IUniswapV2Router02(UNISWAP_ROUTER).swapExactTokensForETH(
            _swapStruct.amountIn,
            amountOut,
            path,
            to,
            _swapStruct.deadline
        );
    }

    function swapExactETHForTokens(
        SwapStruct memory _swapStruct,
        address to,
        uint256 slippage
    ) external payable onlyAsset(_swapStruct.fromAsset, _swapStruct.toAsset) returns (uint256[] memory amounts) {
        address[] memory path = getPath(_swapStruct.fromAsset, _swapStruct.toAsset);
        uint256[] memory amountsOut = getAmountsOut(msg.value, _swapStruct.fromAsset, _swapStruct.toAsset);
        uint256 amountOut = amountsOut[amountsOut.length - 1] -
            ((amountsOut[amountsOut.length - 1] * slippage) / 10**decimals);
        amounts = IUniswapV2Router02(UNISWAP_ROUTER).swapExactETHForTokens{ value: msg.value }(
            amountOut,
            path,
            to,
            _swapStruct.deadline
        );
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import "./../Integrations/Swap/BhavishSwap.sol";

interface IBhavishSDK {
    event PredictionMarketProvider(uint256 indexed _month, address indexed _provider);

    struct PredictionStruct {
        bytes32 underlying;
        bytes32 strike;
        uint256 roundId;
        bool directionUp;
    }

    function predict(
        PredictionStruct memory _predStruct,
        address _userAddress,
        address _provider
    ) external payable;

    function predictWithGasless(PredictionStruct memory _predStruct, address _provider) external payable;

    function minimumGaslessBetAmount() external returns (uint256);

    function swapAndPredict(
        BhavishSwap.SwapStruct memory _swapStruct,
        PredictionStruct memory _predStruct,
        uint256 slippage,
        address _provider
    ) external;

    function swapAndPredictWithGasless(
        BhavishSwap.SwapStruct memory _swapStruct,
        PredictionStruct memory _predStruct,
        uint256 slippage,
        address _provider
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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