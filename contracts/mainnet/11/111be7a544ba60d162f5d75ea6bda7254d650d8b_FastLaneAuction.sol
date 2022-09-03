//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/utils/Address.sol";
import { SafeTransferLib, ERC20 } from "solmate/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";


/// @notice Auction bid struct
/// @dev Current owners need to allow opportunity and validator addresses to participate beforehands
/// @param validatorAddress Validator selected for the bid
/// @param opportunityAddress Opportunity selected for the bid
/// @param searcherContractAddress Contract that will be submitting transactions to `opportunityAddress`
/// @param searcherPayableAddress Searcher submitting the bid (currently restricted to msg.sender)
/// @param bidAmount Value of the bid
struct Bid {
    address validatorAddress;
    address opportunityAddress;
    address searcherContractAddress;
    address searcherPayableAddress;
    uint256 bidAmount;
}

/// @notice The type of a Status struct validator or opportunity
enum statusType {
    INVALID, // 0
    VALIDATOR, // 1 
    OPPORTUNITY // 2
}

/// @notice Status of validator or opportunity
/// @dev Status cannot be flipped for the current round, an opportunity or validator set up as inactive will always be able to receive bids until the end of the round it was triggered.
/// @param activeAtAuctionRound Auction round where entity will be enabled
/// @param inactiveAtAuctionRound Auction round at which entity will be disabled
/// @param kind From {statusType} 
struct Status {
    uint128 activeAtAuctionRound;
    uint128 inactiveAtAuctionRound;
    statusType kind;  
}


/// @notice Validator Balance Checkpoint
/// @dev By default checkpoints are checked every block by ops to see if there is amount to be paid ( > minAmount or > minAmoutForValidator)
/// @param pendingBalanceAtlastBid Deposits at `lastBidReceivedAuction`
/// @param outstandingBalance Balance accumulated between `lastWithdrawnAuction` and `lastBidReceivedAuction`
/// @param lastWithdrawnAuction Round when the validator withdrew
/// @param lastBidReceivedAuction Last auction around a bid was received for this validator
struct ValidatorBalanceCheckpoint {
    uint256 pendingBalanceAtlastBid;
    uint256 outstandingBalance;
    uint128 lastWithdrawnAuction;
    uint128 lastBidReceivedAuction;
}

/// @notice Validator Balances Shipping Preferences
/// @dev minAutoshipAmount will always be superseeded by contract level minAutoShipThreshold if lower
/// @param minAutoshipAmount Validator desired autoship threshold 
/// @param validatorPayableAddress Validator desired payable address
struct ValidatorPreferences {
    uint256 minAutoshipAmount;
    address validatorPayableAddress;
}


abstract contract FastLaneEvents {
    /***********************************|
    |             Events                |
    |__________________________________*/

    event MinimumBidIncrementSet(uint256 amount);
    event FastLaneFeeSet(uint256 amount);
    event BidTokenSet(address indexed token);
    event PausedStateSet(bool state);
    event OpsSet(address ops);
    event MinimumAutoshipThresholdSet(uint128 amount);
    event ResolverMaxGasPriceSet(uint128 amount);
    event AutopayBatchSizeSet(uint16 batch_size);
    event OpportunityAddressEnabled(
        address indexed opportunity,
        uint128 indexed auction_number
    );
    event OpportunityAddressDisabled(
        address indexed opportunity,
        uint128 indexed auction_number
    );
    event ValidatorAddressEnabled(
        address indexed validator,
        uint128 indexed auction_number
    );
    event ValidatorAddressDisabled(
        address indexed validator,
        uint128 indexed auction_number
    );
    event ValidatorWithdrawnBalance(
        address indexed validator,
        uint128 indexed auction_number,
        uint256 amount,
        address destination,
        address indexed caller

    );
    event AuctionStarted(uint128 indexed auction_number);

    event AuctionEnded(uint128 indexed auction_number);

    event AuctionStarterSet(address indexed starter);

    event WithdrawStuckERC20(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );
    event WithdrawStuckNativeToken(address indexed receiver, uint256 amount);
   
    event BidAdded(
        address bidder,
        address indexed validator,
        address indexed opportunity,
        uint256 amount,
        uint256 indexed auction_number
    );

    event ValidatorPreferencesSet(address indexed validator, uint256 minAutoshipAmount, address validatorPayableAddress);

    error GeneralFailure();                            // E-000 // 0x2192efec

    error PermissionPaused();                          // E-101 // 0xeaa8b1af
    error PermissionNotOwner();                        // E-102 // 0xf599ea9e
    error PermissionOnlyFromPayorEoa();                // E-103 // 0x13272381
    error PermissionMustBeValidator();                 // E-104 // 0x4f4e9f3f
    error PermissionInvalidOpportunityAddress();       // E-105 // 0xcf440a8e
    error PermissionOnlyOps();                         // E-106 // 0x68da148f
    error PermissionNotOwnerNorStarter();              // E-107 // 0x8b4fb0bf
    error PermissionNotAllowed();                      // E-108 // 0xba6c5093

    error InequalityInvalidIndex();                    // E-201 // 0x102bd785
    error InequalityAddressMismatch();                 // E-202 // 0x17de231a
    error InequalityTooLow();                          // E-203 // 0x470b0adc
    error InequalityAlreadyTopBidder();                // E-204 // 0xeb14a775
    error InequalityNotEnoughFunds();                  // E-206 // 0x4587f24a
    error InequalityNothingToRedeem();                 // E-207 // 0x77a3b272
    error InequalityValidatorDisabledAtTime();         // E-209 // 0xa1ec46e6
    error InequalityOpportunityDisabledAtTime();       // E-210 // 0x8c81d8e9
    error InequalityValidatorNotEnabledYet();          // E-211 // 0x7a956c2e
    error InequalityOpportunityNotEnabledYet();        // E-212 // 0x333108d7
    error InequalityTooHigh();                         // E-213 // 0xfd11d092
    error InequalityWrongToken();                      // E-214 // 0xc9db890c

    error TimeNotWhenAuctionIsLive();                  // E-301 // 0x76a79c50
    error TimeNotWhenAuctionIsStopped();               // E-302 // 0x4eaf4896
    error TimeGasNotSuitable();                        // E-307 // 0xdd980aae
    error TimeAlreadyInit();                           // E-308 // 0xef34ca5c

}   

/// @title FastLaneAuction
/// @author Elyx0
/// @notice Fastlane.finance auction contract
contract FastLaneAuction is Initializable, OwnableUpgradeable , UUPSUpgradeable, ReentrancyGuard, FastLaneEvents {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeTransferLib for ERC20;

    ERC20 public bid_token;

    constructor(address _newOwner) {
        _transferOwnership(_newOwner);
        _disableInitializers();
    }

    function initialize(address _newOwner) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _transferOwnership(_newOwner);
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner() {}


    /// @notice Initializes the auction
    /// @dev Also sets bid increment, resolver max gas, fee, autoship and batch size.
    /// @param _initial_bid_token ERC20 address to use for the auction
    /// @param _ops Operators address for crontabs
    /// @param _starter Address allowed to start/stop rounds
    function initialSetupAuction(address _initial_bid_token, address _ops, address _starter) external onlyOwner {
        if (auctionInitialized) revert TimeAlreadyInit();
        setBidToken(_initial_bid_token);
        setOps(_ops);
        auction_number = 1;
        setMinimumBidIncrement(10* (10**18));
        setMinimumAutoShipThreshold(2000* (10**18));
        setResolverMaxGasPrice(200 gwei);
        setFastlaneFee(50000);
        setAutopayBatchSize(10); 
        setStarter(_starter);
        auctionInitialized = true;
    }

    /// @notice Gelato Ops Address
    address public ops;

    // Variables mutable by owner via function calls

    /// @notice Minimum bid increment required on top of from the current top bid for a pair
    uint256 public bid_increment = 10 * (10**18);


    /// @notice Minimum amount for Validator Preferences to get the profits airdropped
    uint128 public minAutoShipThreshold = 2000 * (10**18); // Validators balances > 2k should get auto-transfered

    /// @notice Current auction round, 
    /// @dev Offset by 1 so payouts are at 0. In general payouts are for round n-1.
    uint128 public auction_number = 1;

    uint128 public constant MAX_AUCTION_VALUE = type(uint128).max; // 2**128 - 1

    /// @notice Max gas price for ops to attempt autopaying pending balances over threshold
    uint128 public max_gas_price = 200 gwei;

    /// @notice Fee (out of one million)
    uint24 public fast_lane_fee = 50000; 

    /// @notice Number of validators to pay per gelato action
    uint16 public autopay_batch_size = 10;

    /// @notice Auction live status
    bool public auction_live = false;

    bool internal paused = false;

    /// @notice Ops crontab disabled
    bool internal _offchain_checker_disabled = false;

    /// @notice Tracks status of seen addresses and when they become eligible for bidding
    mapping(address => Status) internal statusMap;

    /// @notice Tracks bids per auction_number per pair
    mapping(uint256 => mapping(address => mapping(address => Bid)))
        internal auctionsMap;

    /// @notice Validators participating in the auction for a round
    mapping(uint128 => EnumerableSet.AddressSet) internal validatorsactiveAtAuctionRound;

    /// @notice Validators cuts to be withdraw or dispatched regularly
    mapping(address => ValidatorBalanceCheckpoint) internal validatorsCheckpoints;

    /// @notice Validator preferences for payment and min autoship amount
    mapping(address => ValidatorPreferences) internal validatorsPreferences;

    /// @notice Auto cleared by EndAuction every round
    uint256 public outstandingFLBalance = 0;

    /// @notice Start & Stop auction role
    address public auctionStarter;

    /// @notice Auction was initialized
    bool public auctionInitialized = false;

    /// @notice Internally updates a validator preference
    /// @dev Only callable by an already setup validator, and only for themselves via {setValidatorPreferences}
    /// @param _target Validator to update
    /// @param _minAutoshipAmount Amount desired before autoship kicks in
    /// @param _validatorPayableAddress Address the auction proceeds will go to for this validator
    function _updateValidatorPreferences(address _target, uint128 _minAutoshipAmount, address _validatorPayableAddress) internal {
        if(_minAutoshipAmount < minAutoShipThreshold) revert InequalityTooLow();
        if((_validatorPayableAddress == address(0)) || (_validatorPayableAddress == address(this))) revert InequalityAddressMismatch();
        
        validatorsPreferences[_target] = ValidatorPreferences(_minAutoshipAmount, _validatorPayableAddress);
        emit ValidatorPreferencesSet(_target,_minAutoshipAmount, _validatorPayableAddress);
    }

    /***********************************|
    |         Validator-only            |
    |__________________________________*/

    /// @notice Internally updates a validator preference
    /// @dev Only callable by an already setup validator via {onlyValidator}
    /// @param _minAutoshipAmount Amount desired before autoship kicks in
    /// @param _validatorPayableAddress Address the auction proceeds will go to for this validator
    function setValidatorPreferences(uint128 _minAutoshipAmount, address _validatorPayableAddress) external onlyValidator {
        _updateValidatorPreferences(msg.sender, _minAutoshipAmount, _validatorPayableAddress);
    }

    /***********************************|
    |             Owner-only            |
    |__________________________________*/

    /// @notice Defines the paused state of the Auction
    /// @dev Only owner
    /// @param _state New state
    function setPausedState(bool _state) external onlyOwner {
        paused = _state;
        emit PausedStateSet(_state);
    }

    /// @notice Sets minimum bid increment 
    /// @dev Used to avoid people micro-bidding up by .000000001
    /// @param _bid_increment New increment
    function setMinimumBidIncrement(uint256 _bid_increment) public onlyOwner {
        bid_increment = _bid_increment;
        emit MinimumBidIncrementSet(_bid_increment);
    }

    /// @notice Sets address of Ops
    /// @dev Ops is allowed to call {processAutopayJobs}
    /// @param _ops New operator of crontabs
    function setOps(address _ops) public onlyOwner {
        ops = _ops;
        emit OpsSet(_ops);
    }

    /// @notice Sets minimum balance a checkpoint must meet to be considered for autoship
    /// @dev This amount will always override validator preferences if greater
    /// @param _minAmount Minimum amount
    function setMinimumAutoShipThreshold(uint128 _minAmount) public onlyOwner {
        minAutoShipThreshold = _minAmount;
        emit MinimumAutoshipThresholdSet(_minAmount);
    }

    /// @notice Sets maximum network gas for autoship
    /// @dev Past this value autoship will have to be manually called until gwei goes lower or this gets upped
    /// @param _maxgas Maximum gas
    function setResolverMaxGasPrice(uint128 _maxgas) public onlyOwner {
        max_gas_price = _maxgas;
        emit ResolverMaxGasPriceSet(_maxgas);
    }

    /// @notice Sets the protocol fee (out of 1000000 (ie v2 fee decimals))
    /// @dev Initially set to 50000 (5%) For now we can't change the fee during an ongoing auction since the bids do not store the fee value at bidding time
    /// @param _fastLaneFee Protocl fee on bids
    function setFastlaneFee(uint24 _fastLaneFee)
        public
        onlyOwner
        notLiveStage
    {
        if (_fastLaneFee > 1000000) revert InequalityTooHigh();
        fast_lane_fee = _fastLaneFee;
        emit FastLaneFeeSet(_fastLaneFee);
    }

    /// @notice Sets the ERC20 token that is treated as the base currency for bidding purposes
    /// @dev Initially set to WMATIC, changing it is not allowed during auctions, special considerations must be taken care of if changing this value, such as paying all outstanding validators first to not mix ERC's.
    /// @param _bid_token_address Address of the bid token
    function setBidToken(address _bid_token_address)
        public
        onlyOwner
        notLiveStage
    {
        // Prevent QBridge Finance issues
        if (_bid_token_address == address(0)) revert GeneralFailure();
        bid_token = ERC20(_bid_token_address);
        emit BidTokenSet(_bid_token_address);
    }


    /// @notice Sets the auction starter role
    /// @dev Both owner and starter will be able to trigger starts/stops
    /// @param _starter Address of the starter role
    function setStarter(address _starter) public onlyOwner {
        auctionStarter = _starter;
        emit AuctionStarterSet(auctionStarter);
    }


    /// @notice Adds an address to the allowed entity mapping as opportunity
    /// @dev Should be a router/aggregator etc. Opportunities are queued to the next auction
    /// @dev Do not use on already enabled opportunity or it will be stopped for current auction round
    /// @param _opportunityAddress Address of the opportunity
    function enableOpportunityAddress(address _opportunityAddress)
        external
        onlyOwner
    {
        // Enable for after auction ends if live
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;
        statusMap[_opportunityAddress] = Status(target_auction_number, MAX_AUCTION_VALUE, statusType.OPPORTUNITY);
        emit OpportunityAddressEnabled(_opportunityAddress, target_auction_number);
    }

    /// @notice Disables an opportunity
    /// @dev If auction is live, only takes effect at next round
    /// @param _opportunityAddress Address of the opportunity
    function disableOpportunityAddress(address _opportunityAddress)
        external
        onlyOwner
    {
        Status storage existingStatus = statusMap[_opportunityAddress];
        if (existingStatus.kind != statusType.OPPORTUNITY) revert PermissionInvalidOpportunityAddress();
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;

        existingStatus.inactiveAtAuctionRound = target_auction_number;
        emit OpportunityAddressDisabled(_opportunityAddress, target_auction_number);
    }

    /// @notice Internal, enables a validator checkpoint
    /// @dev If auction is live, only takes effect at next round
    /// @param _validatorAddress Address of the validator
    function _enableValidatorCheckpoint(address _validatorAddress) internal {
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;
        statusMap[_validatorAddress] = Status(target_auction_number, MAX_AUCTION_VALUE, statusType.VALIDATOR);
        
        // Create the checkpoint for the Validator
        ValidatorBalanceCheckpoint memory valCheckpoint = validatorsCheckpoints[_validatorAddress];
        if (valCheckpoint.lastBidReceivedAuction == 0) {
            validatorsCheckpoints[_validatorAddress] = ValidatorBalanceCheckpoint(0, 0, 0, 0);
        } 
        emit ValidatorAddressEnabled(_validatorAddress, target_auction_number);
    }

    /// @notice Enables a validator checkpoint
    /// @dev If auction is live, only takes effect at next round
    /// @param _validatorAddress Address of the validator
    function enableValidatorAddress(address _validatorAddress)
        external
        onlyOwner
    {
       _enableValidatorCheckpoint(_validatorAddress);
    }

    /// @notice Enables a validator checkpoint and sets preferences
    /// @dev If auction is live, only takes effect at next round
    /// @param _validatorAddress Address of the validator
    /// @param _minAutoshipAmount Amount desired before autoship kicks in
    /// @param _validatorPayableAddress Address the auction proceeds will go to for this validator
    function enableValidatorAddressWithPreferences(address _validatorAddress, uint128 _minAutoshipAmount, address _validatorPayableAddress) 
        external
        onlyOwner
    {
            _enableValidatorCheckpoint(_validatorAddress);
            _updateValidatorPreferences(_validatorAddress, _minAutoshipAmount, _validatorPayableAddress);
    }

    /// @notice Disables a validator
    /// @dev If auction is live, only takes effect at next round
    /// @param _validatorAddress Address of the validator
    function disableValidatorAddress(address _validatorAddress)
        external
        onlyOwner
    {
        Status storage existingStatus = statusMap[_validatorAddress];
        if (existingStatus.kind != statusType.VALIDATOR) revert PermissionMustBeValidator();
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;

        existingStatus.inactiveAtAuctionRound = target_auction_number;
        emit ValidatorAddressDisabled(_validatorAddress, target_auction_number);
    }

    /// @notice Start auction round / Enable bidding
    /// @dev Both starter and owner roles are allowed to start
    function startAuction() external onlyStarterOrOwner notLiveStage {
        auction_live = true;
        emit AuctionStarted(auction_number);
    }

    /// @notice Ends an auction round
    /// @dev Ending an auction round transfers the cuts to PFL and enables validators to collect theirs from the auction that ended
    /// @dev Also enables fastlane privileges of pairs winners until endAuction gets called again at next auction round
    function endAuction()
        external
        onlyStarterOrOwner
        atLiveStage
        nonReentrant
        returns (bool)
    {

        auction_live = false;

        emit AuctionEnded(auction_number);

        // Increment auction_number so the checkpoints are available.
        ++auction_number;

        uint256 ownerBalance = outstandingFLBalance;
        outstandingFLBalance = 0;

        // Last for C-E-I.
        bid_token.safeTransfer(owner(), ownerBalance);

        return true;
    }

    /// @notice Sets autopay batch size
    /// @dev Defines the maximum number of addresses the ops will try to pay outstanding balances per block
    /// @param _size Size of the batch
    function setAutopayBatchSize(uint16 _size) public onlyOwner {
        autopay_batch_size = _size;
        emit AutopayBatchSizeSet(autopay_batch_size);
    }

    /// @notice Defines if the offchain checked is disabled
    /// @dev If true autoship will be disabled
    /// @param _state Disabled state
    function setOffchainCheckerDisabledState(bool _state) external onlyOwner {
        _offchain_checker_disabled = _state;
    }

    /// @notice Withdraws stuck matic
    /// @dev In the event people send matic instead of WMATIC we can send it back 
    /// @param _amount Amount to send to owner
    function withdrawStuckNativeToken(uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        if (address(this).balance >= _amount) {
            payable(owner()).sendValue(_amount);
            emit WithdrawStuckNativeToken(owner(), _amount);
        }
    }

    /// @notice Withdraws stuck ERC20
    /// @dev In the event people send ERC20 instead of bid_token ERC20 we can send them back 
    /// @param _tokenAddress Address of the stuck token
    function withdrawStuckERC20(address _tokenAddress)
        external
        onlyOwner
        nonReentrant
    {
        if (_tokenAddress == address(bid_token)) revert InequalityWrongToken();
        ERC20 oopsToken = ERC20(_tokenAddress);
        uint256 oopsTokenBalance = oopsToken.balanceOf(address(this));

        if (oopsTokenBalance > 0) {
            oopsToken.safeTransfer(owner(), oopsTokenBalance);
            emit WithdrawStuckERC20(address(this), owner(), oopsTokenBalance);
        }
    }

    /// @notice Internal, receives a bid
    /// @dev Requires approval of this contract beforehands
    /// @param _currentTopBidAmount Value of the current top bid
    /// @param _currentTopBidSearcherPayableAddress Address of the current top bidder for that bid pair
    function _receiveBid(
        Bid memory bid,
        uint256 _currentTopBidAmount,
        address _currentTopBidSearcherPayableAddress
    ) internal {
        // Verify the bid exceeds previous bid + minimum increment
        if (bid.bidAmount < _currentTopBidAmount + bid_increment) revert InequalityTooLow();

        // Verify the new bidder isnt the previous bidder as self-spam protection
        if (bid.searcherPayableAddress == _currentTopBidSearcherPayableAddress) revert InequalityAlreadyTopBidder();

        // Verify the bidder has the balance.
        if (bid_token.balanceOf(bid.searcherPayableAddress) < bid.bidAmount) revert InequalityNotEnoughFunds();

        // Transfer the bid amount (requires approval)
        bid_token.safeTransferFrom(
            bid.searcherPayableAddress,
            address(this),
            bid.bidAmount
        );
    }

    /// @notice Internal, refunds previous top bidder
    /// @dev Be very careful about changing bid token to any ERC777
    /// @param bid Bid to refund
    function _refundPreviousBidder(Bid memory bid) internal {
        bid_token.safeTransfer(
            bid.searcherPayableAddress,
            bid.bidAmount
        );
    }

    /// @notice Internal, calculates cuts
    /// @dev vCut 
    /// @param amount Amount to calculates cuts from
    /// @return vCut validator cut
    /// @return flCut protocol cut
    function _calculateCuts(uint256 amount) internal view returns (uint256 vCut, uint256 flCut) {
        vCut = (amount * (1000000 - fast_lane_fee)) / 1000000;
        flCut = amount - vCut;
    }

    /// @notice Internal, calculates if a validator balance checkpoint is redeemable as of current auction_number against a certain amount
    /// @dev Not pure, depends of global auction_number, could be only outstandingBalance or outstandingBalance + pendingBalanceAtlastBid if last bid was at an oldest round than auction_number
    /// @param valCheckpoint Validator checkpoint to validate against `minAmount`
    /// @param minAmount Amount to calculates cuts from
    /// @return bool Is there balance to redeem for validator and amount at current auction_number
    function _checkRedeemableOutstanding(ValidatorBalanceCheckpoint memory valCheckpoint,uint256 minAmount) internal view returns (bool) {
        return valCheckpoint.outstandingBalance >= minAmount || ((valCheckpoint.lastBidReceivedAuction < auction_number) && ((valCheckpoint.pendingBalanceAtlastBid + valCheckpoint.outstandingBalance) >= minAmount));    
    }

    /// @notice Internal, attemps to redeem a validator outstanding balance to its validatorPayableAddress
    /// @dev Must be owed at least 1 of `bid_token`
    /// @param _outstandingValidatorWithBalance Validator address
    function _redeemOutstanding(address _outstandingValidatorWithBalance) internal {
        if (statusMap[_outstandingValidatorWithBalance].kind != statusType.VALIDATOR) revert PermissionMustBeValidator();
        ValidatorBalanceCheckpoint storage valCheckpoint = validatorsCheckpoints[_outstandingValidatorWithBalance];
       
        // Either we have outstandingBalance or we have pendingBalanceAtlastBid from previous auctions.
        if (!_checkRedeemableOutstanding(valCheckpoint, 1)) revert InequalityNothingToRedeem();

        uint256 redeemable = 0;
        if (valCheckpoint.lastBidReceivedAuction < auction_number) {
            // We can redeem both
            redeemable = valCheckpoint.pendingBalanceAtlastBid + valCheckpoint.outstandingBalance;
            valCheckpoint.pendingBalanceAtlastBid = 0;
        } else {
            // Another bid was received in the current auction, profits were already moved
            // to outstandingBalance by the bidder
            redeemable = valCheckpoint.outstandingBalance;
        }

        // Clear outstanding in any case.
        valCheckpoint.outstandingBalance = 0;
        valCheckpoint.lastWithdrawnAuction = auction_number;

        address dst = _outstandingValidatorWithBalance;
        ValidatorPreferences memory valPrefs = validatorsPreferences[dst];
        if (valPrefs.validatorPayableAddress != address(0)) {
            dst = valPrefs.validatorPayableAddress;
        }

        bid_token.safeTransfer(
            dst,
            redeemable
        );

        emit ValidatorWithdrawnBalance(
            _outstandingValidatorWithBalance,
            auction_number,
            redeemable,
            dst,
            msg.sender
        );
    }

    /***********************************|
    |             Public                |
    |__________________________________*/


    /// @notice Bidding function for searchers to submit their bids
    /// @dev Each bid pulls funds on submission and searchers are refunded when they are outbid
    /// @param bid Bid struct as tuple (validatorAddress, opportunityAddress, searcherContractAddress ,searcherPayableAddress, bidAmount)
    function submitBid(Bid calldata bid)
        external
        atLiveStage
        whenNotPaused
        nonReentrant
    {
        // Verify that the bid is coming from the EOA that's paying
        if (msg.sender != bid.searcherPayableAddress) revert PermissionOnlyFromPayorEoa();

        Status memory validatorStatus = statusMap[bid.validatorAddress];
        Status memory opportunityStatus = statusMap[bid.opportunityAddress];

        // Verify that the opportunity and the validator are both participating addresses
        if (validatorStatus.kind != statusType.VALIDATOR) revert PermissionMustBeValidator();
        if (opportunityStatus.kind != statusType.OPPORTUNITY) revert PermissionInvalidOpportunityAddress();

        // We want auction_number be in the [activeAtAuctionRound - inactiveAtAuctionRound] window.
        // Verify not flagged as inactive
        if (validatorStatus.inactiveAtAuctionRound <= auction_number) revert InequalityValidatorDisabledAtTime();
        if (opportunityStatus.inactiveAtAuctionRound <= auction_number) revert InequalityOpportunityDisabledAtTime();

        // Verify still flagged active
        if (validatorStatus.activeAtAuctionRound > auction_number) revert InequalityValidatorNotEnabledYet();
        if (opportunityStatus.activeAtAuctionRound > auction_number) revert InequalityOpportunityNotEnabledYet();


        // Figure out if we have an existing bid 
        Bid memory current_top_bid = auctionsMap[auction_number][
                bid.validatorAddress
            ][bid.opportunityAddress];

        ValidatorBalanceCheckpoint storage valCheckpoint = validatorsCheckpoints[bid.validatorAddress];

        if ((valCheckpoint.lastBidReceivedAuction != auction_number) && (valCheckpoint.pendingBalanceAtlastBid > 0)) {
            // Need to move pending to outstanding
            valCheckpoint.outstandingBalance += valCheckpoint.pendingBalanceAtlastBid;
            valCheckpoint.pendingBalanceAtlastBid = 0;
        }
 
        // Update bid for pair
        auctionsMap[auction_number][bid.validatorAddress][
                bid.opportunityAddress
            ] = bid;

        if (current_top_bid.bidAmount > 0) {
            // Existing bid for this auction number && pair combo
            // Handle checkpoint cuts replacement
            (uint256 vCutPrevious, uint256 flCutPrevious) = _calculateCuts(current_top_bid.bidAmount);
            (uint256 vCut, uint256 flCut) = _calculateCuts(bid.bidAmount);

            outstandingFLBalance = outstandingFLBalance + flCut - flCutPrevious;
            valCheckpoint.pendingBalanceAtlastBid =  valCheckpoint.pendingBalanceAtlastBid + vCut - vCutPrevious;


            // Update the existing Bid mapping
            _receiveBid(
                bid,
                current_top_bid.bidAmount,
                current_top_bid.searcherPayableAddress
            );
            _refundPreviousBidder(current_top_bid);

           
        } else {
            // First bid on pair for this auction number
            // Update checkpoint if needed as another pair could have bid already for this auction number
            
            if (valCheckpoint.lastBidReceivedAuction != auction_number) {
                valCheckpoint.lastBidReceivedAuction = auction_number;
            }

            (uint256 vCutFirst, uint256 flCutFirst) = _calculateCuts(bid.bidAmount);

            // Handle cuts
            outstandingFLBalance += flCutFirst;
            valCheckpoint.pendingBalanceAtlastBid += vCutFirst;

             // Check balance
            _receiveBid(bid, 0, address(0));
            

        }

        // Try adding to the validatorsactiveAtAuctionRound so the keeper can loop on it
        // EnumerableSet already checks key pre-existence
        validatorsactiveAtAuctionRound[auction_number].add(bid.validatorAddress);

        emit BidAdded(
            bid.searcherContractAddress,
            bid.validatorAddress,
            bid.opportunityAddress,
            bid.bidAmount,
            auction_number
        );
    }

    /// @notice Validators can always withdraw right after an amount is due
    /// @dev It can be during an ongoing auction with pendingBalanceAtlastBid being the current auction
    /// @dev Or lastBidReceivedAuction being a previous auction, in which case outstanding+pending can be withdrawn
    /// @dev _Anyone_ can initiate a validator to be paid what it's owed
    /// @param _outstandingValidatorWithBalance Redeems outstanding balance for a validator
    function redeemOutstandingBalance(address _outstandingValidatorWithBalance)
        external
        whenNotPaused
        nonReentrant
    {
        _redeemOutstanding(_outstandingValidatorWithBalance);
    }

    /***********************************|
    |       Public Resolvers            |
    |__________________________________*/

    /// @notice Gelato Offchain Resolver
    /// @dev Automated function checked each block offchain by Gelato Network if there is outstanding payments to process
    /// @return canExec Should the worker trigger
    /// @return execPayload The payload if canExec is true
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (_offchain_checker_disabled || paused  || tx.gasprice > max_gas_price) return (false, "");
            // Go workers go
            canExec = false;
            (
                bool hasJobs,
                address[] memory autopayRecipients
            ) = getAutopayJobs(autopay_batch_size, auction_number - 1);
            if (hasJobs) {
                canExec = true;
                execPayload = abi.encodeWithSelector(
                    this.processAutopayJobs.selector,
                    autopayRecipients
                );
                return (canExec, execPayload);
            }
        return (false, "");
    }

    /// @notice Processes a list of addresses to transfer their outstanding balance
    /// @dev Genrally called by Ops with array length of autopay_batch_size
    /// @param autopayRecipients Array of recipents to consider for autopay
    function processAutopayJobs(address[] calldata autopayRecipients) external nonReentrant onlyOwnerStarterOps {
        // Reassert checks if insane spike between gelato trigger and tx picked up
        if (_offchain_checker_disabled || paused) revert PermissionPaused();
        if (tx.gasprice > max_gas_price) revert TimeGasNotSuitable();

        uint length = autopayRecipients.length;
        for (uint i = 0;i < length;) {
            if (autopayRecipients[i] != address(0)) {
                _redeemOutstanding(autopayRecipients[i]);
            }
            unchecked { ++i; }
        }
    }

    /***********************************|
    |             Views                 |
    |__________________________________*/

    /// @notice Returns if there is autopays to be done for given `_auction_index`
    /// @dev  Most likely called off chain by Gelato
    /// @param _batch_size Max recipients to return
    /// @param _auction_index Auction round
    /// @return hasJobs If there was jobs found to be done by ops
    /// @return autopayRecipients List of addresses eligible to be paid
    function getAutopayJobs(uint16 _batch_size, uint128 _auction_index) public view returns (bool hasJobs, address[] memory autopayRecipients) {
        autopayRecipients = new address[](_batch_size); // Filled with 0x0
        // An active validator means a bid happened so potentially balances were moved to outstanding while the bid happened
        EnumerableSet.AddressSet storage prevRoundAddrSet = validatorsactiveAtAuctionRound[_auction_index];
        uint16 assigned = 0;
        uint256 len = prevRoundAddrSet.length();
        for (uint256 i = 0; i < len; i++) {
            address current_validator = prevRoundAddrSet.at(i);
            ValidatorBalanceCheckpoint memory valCheckpoint = validatorsCheckpoints[current_validator];
            uint256 minAmountForValidator = minAutoShipThreshold >= validatorsPreferences[current_validator].minAutoshipAmount ? minAutoShipThreshold : validatorsPreferences[current_validator].minAutoshipAmount;
            if (_checkRedeemableOutstanding(valCheckpoint, minAmountForValidator)) {
                autopayRecipients[assigned] = current_validator;
                ++assigned;
            }
            if (assigned >= _batch_size) {
                break;
            }
        }
        hasJobs = assigned > 0;
    }

    /// @notice Gets the status of an address
    /// @dev Contains (activeAtAuctionRound, inactiveAtAuctionRound, statusType)
    /// @param _who Address we want the status of
    /// @return Status Status of the given address
    function getStatus(address _who) external view returns (Status memory) {
        return statusMap[_who];
    }

    /// @notice Gets the validators involved with a given auction
    /// @dev validatorsactiveAtAuctionRound being an EnumerableSet
    /// @param _auction_index Auction Round
    /// @return Array of validator addresses that received a bid during round `_auction_index`
    function getValidatorsactiveAtAuctionRound(uint128 _auction_index) external view returns (address[] memory) {
        return validatorsactiveAtAuctionRound[_auction_index].values();
    }


    /// @notice Gets the auction number for which the fast lane privileges are active
    /// @return auction round
    function getActivePrivilegesAuctionNumber() public view returns (uint128) {
        return auction_number - 1;
    }

    /// @notice Gets the checkpoint of an address
    /// @param _who Address we want the checkpoint of
    /// @return Validator checkpoint
    function getCheckpoint(address _who) external view returns (ValidatorBalanceCheckpoint memory) {
        return validatorsCheckpoints[_who];
    }
 
    /// @notice Gets the preferences of an address
    /// @param _who Address we want the preferences of
    /// @return Validator preferences
    function getPreferences(address _who) external view returns (ValidatorPreferences memory) {
        return validatorsPreferences[_who];
    }

    /// @notice Determines the current top bid of a pair for the current ongoing (live) auction
    /// @param _validatorAddress Validator for the given pair
    /// @param _opportunityAddress Opportunity for the given pair
    /// @return Tuple (bidAmount, auction_round)
    function findLiveAuctionTopBid(address _validatorAddress, address _opportunityAddress)
        external
        view
        atLiveStage
        returns (uint256, uint128)
    {
            Bid memory topBid = auctionsMap[auction_number][
                _validatorAddress
            ][_opportunityAddress];
            return (topBid.bidAmount, auction_number);
    }

    /// @notice Returns the top bid of a past auction round for a given pair
    /// @param _auction_index Auction round
    /// @param _validatorAddress Validator for the given pair
    /// @param _opportunityAddress Opportunity for the given pair
    /// @return Tuple (true|false, winningSearcher, auction_index)
    function findFinalizedAuctionWinnerAtAuction(
        uint128 _auction_index,
        address _validatorAddress,
        address _opportunityAddress
    ) public view
                returns (
            bool,
            address,
            uint128
        )
    {
        if (_auction_index >= auction_number) revert InequalityInvalidIndex();
        // Get the winning searcher
        address winningSearcher = auctionsMap[_auction_index][
            _validatorAddress
        ][_opportunityAddress].searcherContractAddress;

        // Check if there is a winning searcher (no bids mean the winner is address(0))
        if (winningSearcher != address(0)) {
            return (true, winningSearcher, _auction_index);
        } else {
            return (false, winningSearcher, _auction_index);
        }
    }

    /// @notice Returns the the winner of the last completed auction for a given pair
    /// @param _validatorAddress Validator for the given pair
    /// @param _opportunityAddress Opportunity for the given pair
    /// @return Tuple (true|false, winningSearcher, auction_index)
    function findLastFinalizedAuctionWinner(
        address _validatorAddress,
        address _opportunityAddress
    )
        external
        view
        returns (
            bool,
            address,
            uint128
        )
    {
        return findFinalizedAuctionWinnerAtAuction(getActivePrivilegesAuctionNumber(), _validatorAddress, _opportunityAddress);
    }

  /***********************************|
  |             Modifiers             |
  |__________________________________*/

    modifier notLiveStage() {
        if (auction_live) revert TimeNotWhenAuctionIsLive();
        _;
    }

    modifier atLiveStage() {
        if (!auction_live) revert TimeNotWhenAuctionIsStopped();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert PermissionPaused();
        _;
    }

    modifier onlyValidator() {
        if(statusMap[msg.sender].kind != statusType.VALIDATOR) revert PermissionMustBeValidator();
        _;
    }

    modifier onlyOwnerStarterOps() {
        if (msg.sender != ops && msg.sender != auctionStarter && msg.sender != owner()) revert PermissionOnlyOps();
        _;
    }

    modifier onlyStarterOrOwner() {
        if (msg.sender != auctionStarter && msg.sender != owner()) revert PermissionNotOwnerNorStarter();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}