pragma solidity ^0.8.15;

import {FastLaneAuction} from "./FastLaneAuction.sol";


contract FastLaneFactory {

    address public fastlane;

    mapping(uint256 => address) public gelatoOpsAddresses;
    mapping(uint256 => address) public wrappedNativeAddresses;

    bytes32 private constant INIT_CODEHASH = keccak256(type(FastLaneAuction).creationCode);

    event FastLaneCreated(address fastlaneContract);

    function _createFastLane(bytes32 _salt, address _initial_bid_token, address _ops) internal {
        
        // use CREATE2 so we can get a deterministic address based on the salt
        fastlane = address(new FastLaneAuction{salt: _salt}());

        // CREATE2 can return address(0), add a check to verify this isn't the case
        // See: https://eips.ethereum.org/EIPS/eip-1014
        require(fastlane != address(0), "Wrong init");
        emit FastLaneCreated(fastlane);

        FastLaneAuction(fastlane).init(_initial_bid_token, _ops);
        // Give back to deployer
        FastLaneAuction(fastlane).transferOwnership(msg.sender);
    }

    function getArgs() public view returns (address initial_bid_token, address ops) {
        ops = gelatoOpsAddresses[block.chainid];
        initial_bid_token = wrappedNativeAddresses[block.chainid];
    }

    constructor(bytes32 _salt) {
        gelatoOpsAddresses[1] = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
        gelatoOpsAddresses[137] = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;
        gelatoOpsAddresses[80001] = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
        gelatoOpsAddresses[31337] = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

        wrappedNativeAddresses[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        wrappedNativeAddresses[137] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        wrappedNativeAddresses[80001] = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
        wrappedNativeAddresses[31337] = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

        (address initial_bid_token, address ops) = getArgs();

        require(ops != address(0), "O(o)ps");
        require(initial_bid_token != address(0), "Wrapped");

        _createFastLane(_salt, initial_bid_token, ops);
    }

    function getFastLaneContractBySalt(bytes32 _salt) external view returns(address predictedAddress, bool isDeployed){
        
        (address initial_bid_token, address ops) = getArgs();

        require(ops != address(0), "O(o)ps");
        require(initial_bid_token != address(0), "Wrapped");

        predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            _salt,
            keccak256(abi.encodePacked(
                type(FastLaneAuction).creationCode
            )
        ))))));
        isDeployed = predictedAddress.code.length != 0;
    }

}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import { SafeTransferLib, ERC20 } from "solmate/utils/SafeTransferLib.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

struct Bid {
    address validatorAddress;
    address opportunityAddress;
    address searcherContractAddress;
    address searcherPayableAddress;
    uint256 bidAmount;
}

enum statusType {
    INVALID, // 0
    VALIDATOR, // 1 
    OPPORTUNITY // 2
}


struct Status {
    uint128 activeAtAuction;
    uint128 inactiveAtAuction;
    statusType kind;  
}

struct ValidatorBalanceCheckpoint {
    // Deposits at {lastBidReceivedAuction}
    uint256 pendingBalanceAtlastBid;

    // Balance accumulated between {lastWithdrawnAuction} and {lastBidReceivedAuction}
    uint256 outstandingBalance;
    uint128 lastWithdrawnAuction;

    // Last auction a bid was received for this validator
    uint128 lastBidReceivedAuction;
}

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

    // error GeneralFailure();                         // E-000

    // error PermissionPaused();                       // E-101
    // error PermissionNotOwner();                     // E-102
    // error PermissionOnlyFromPayorEoa();             // E-103
    // error PermissionMustBeValidator();              // E-104
    // error PermissionInvalidOpportunityAddress();    // E-105
    // error PermissionOnlyGelato();                   // E-106

    // error InequalityInvalidIndex();                 // E-201
    // error InequalityAddressMismatch();              // E-202
    // error InequalityBidTooLow();                    // E-203
    // error InequalityAlreadyTopBidder();             // E-205
    // error InequalityNotEnoughFunds();               // E-206
    // error InequalityNothingToRedeem();              // E-207
    // error InequalityWrongBatchSize();               // E-208
    // error InequalityValidatorDisabledAtTime();      // E-209
    // error InequalityOpportunityDisabledAtTime();    // E-210
    // error InequalityValidatorNotEnabledYet();       // E-211
    // error InequalityOpportunityNotEnabledYet();     // E-212
    // error InequalityTooHigh();                      // E-213

    // error TimeNotWhenAuctionIsLive();               // E-301
    // error TimeNotWhenAuctionIsStopped();            // E-302
    // error TimeGasNotSuitable();                     // E-307

    // error FundsTransferFailed();                    // E-401
    // error FundsRemain();                            // E-402
}   

contract FastLaneAuction is FastLaneEvents, Ownable, ReentrancyGuard {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeTransferLib for ERC20;

    ERC20 public bid_token;

    constructor() {
    }

    function init(address _initial_bid_token, address _ops) external onlyOwner {
        setBidToken(_initial_bid_token);
        setOps(_ops);
        auction_number = 1;
        setMinimumBidIncrement(10* (10**18)); // external onlyOwner {
        setMinimumAutoShipThreshold(2000* (10**18));
        setResolverMaxGasPrice(200 gwei);
        setFastlaneFee(50000);
        setAutopayBatchSize(10); 
    }

    // Gelato Ops Address
    address public ops;

    //Variables mutable by owner via function calls
    uint256 public bid_increment = 10 * (10**18); //minimum bid increment in WMATIC


    // Minimum for Validator Preferences
    uint128 public minAutoShipThreshold = 2000 * (10**18); // Validators balances > 2k should get auto-transfered

    // Offset by 1 so payouts are at 0
    uint128 public auction_number = 1;

    uint128 public constant MAX_AUCTION_VALUE = type(uint128).max; // 2**128 - 1

    uint128 public max_gas_price = 200 gwei;

    // Out of one million
    uint24 public fast_lane_fee = 50000; 

    // Number of validators to pay per gelato action
    uint16 public autopay_batch_size = 10;

    bool public auction_live = false;
    bool internal _paused = false;
    bool internal _offchain_checker_disabled = false;

    // Tracks status of seen addresses and when they become eligible for bidding
    mapping(address => Status) internal statusMap;

    // Tracks bids per auction_number per pair
    mapping(uint256 => mapping(address => mapping(address => Bid)))
        internal auctionsMap;

    // Validators participating in the auction for a round
    mapping(uint128 => EnumerableSet.AddressSet) internal validatorsActiveAtAuction;

    // Validators cuts to be withdraw or dispatched regularly
    mapping(address => ValidatorBalanceCheckpoint) internal validatorsCheckpoints;

    // Validator preferences for payment and min autoship amount
    mapping(address => ValidatorPreferences) internal validatorsPreferences;

    // Auto cleared by EndAuction every round
    uint256 public outstandingFLBalance = 0;



    function _updateValidatorPreferences(address _target, uint128 _minAutoshipAmount, address _validatorPayableAddress) internal {
        require(_minAutoshipAmount >= minAutoShipThreshold, "FL:E-203");
        require((_validatorPayableAddress != address(0)) && (_validatorPayableAddress != address(this)), "FL:E-202");
        
        validatorsPreferences[_target] = ValidatorPreferences(_minAutoshipAmount, _validatorPayableAddress);
        emit ValidatorPreferencesSet(_target,_minAutoshipAmount, _validatorPayableAddress);
    }

    /***********************************|
    |         Validator-only            |
    |__________________________________*/

    function setValidatorPreferences(uint128 _minAutoshipAmount, address _validatorPayableAddress) external onlyValidator {
        _updateValidatorPreferences(msg.sender, _minAutoshipAmount, _validatorPayableAddress);
    }

    /***********************************|
    |             Owner-only            |
    |__________________________________*/

    function setPausedState(bool state) external onlyOwner {
        _paused = state;
        emit PausedStateSet(state);
    }

    // Set minimum bid increment to avoid people bidding up by .000000001
    function setMinimumBidIncrement(uint256 _bid_increment) public onlyOwner {
        bid_increment = _bid_increment;
        emit MinimumBidIncrementSet(_bid_increment);
    }

    // Set Gelato Ops in case it ever changes
    function setOps(address _ops) public onlyOwner {
        ops = _ops;
        emit OpsSet(_ops);
    }

    // Set minimum balance
    function setMinimumAutoShipThreshold(uint128 _minAmount) public onlyOwner {
        minAutoShipThreshold = _minAmount;
        emit MinimumAutoshipThresholdSet(_minAmount);
    }

    // Set max gwei for resolver
    function setResolverMaxGasPrice(uint128 _maxgas) public onlyOwner {
        max_gas_price = _maxgas;
        emit ResolverMaxGasPriceSet(_maxgas);
    }

    // Set the protocol fee (out of 1000000 (ie v2 fee decimals)).
    // Initially set to 50000 (5%)
    // For now we can't change the fee during an ongoing auction since the bids
    // do not store the fee value at bidding time
    function setFastlaneFee(uint24 _fastLaneFee)
        public
        onlyOwner
        notLiveStage
    {
        require(_fastLaneFee < 1000000,"FL:E-213");
        fast_lane_fee = _fastLaneFee;
        emit FastLaneFeeSet(_fastLaneFee);
    }

    // Set the ERC20 token that is treated as the base currency for bidding purposes.
    // Initially set to WMATIC
    function setBidToken(address _bid_token_address)
        public
        onlyOwner
        notLiveStage
    {
        // Prevent QBridge Finance issues
        require(_bid_token_address != address(0),"FL:E-000");
        bid_token = ERC20(_bid_token_address);
        emit BidTokenSet(_bid_token_address);
    }




    // Add an address to the opportunity address array.
    // Should be a router/aggregator etc.
    // Opportunities are queued to the next auction
    // Do not use on already enabled opportunity or it will be stopped for current auction round
    function enableOpportunityAddress(address opportunityAddress)
        external
        onlyOwner
    {
        // Enable for after auction ends if live
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;
        statusMap[opportunityAddress] = Status(target_auction_number, MAX_AUCTION_VALUE, statusType.OPPORTUNITY);
        emit OpportunityAddressEnabled(opportunityAddress, target_auction_number);
    }

    function disableOpportunityAddress(address opportunityAddress)
        external
        onlyOwner
    {
        Status storage existingStatus = statusMap[opportunityAddress];
        require(existingStatus.kind == statusType.OPPORTUNITY, "FL:E-105");
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;

        existingStatus.inactiveAtAuction = target_auction_number;
        emit OpportunityAddressDisabled(opportunityAddress, target_auction_number);
    }

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

    // Do not use on already enabled validator or it will be stopped for current auction round
    function enableValidatorAddress(address _validatorAddress)
        external
        onlyOwner
    {
       _enableValidatorCheckpoint(_validatorAddress);
    }

    function enableValidatorAddressWithPreferences(address _validatorAddress, uint128 _minAutoshipAmount, address _validatorPayableAddress) 
        external
        onlyOwner
    {
            _enableValidatorCheckpoint(_validatorAddress);
            _updateValidatorPreferences(_validatorAddress, _minAutoshipAmount, _validatorPayableAddress);
    }

    //remove an address from the participating validator address array
    function disableValidatorAddress(address _validatorAddress)
        external
        onlyOwner
    {
        Status storage existingStatus = statusMap[_validatorAddress];
        require(existingStatus.kind == statusType.VALIDATOR, "FL:E-104");
        uint128 target_auction_number = auction_live ? auction_number + 1 : auction_number;

        existingStatus.inactiveAtAuction = target_auction_number;
        emit ValidatorAddressDisabled(_validatorAddress, target_auction_number);
    }

    // Start auction / Enable bidding
    function startAuction() external onlyOwner notLiveStage {
        //enable bidding
        auction_live = true;
        emit AuctionStarted(auction_number);
    }

    function endAuction()
        external
        onlyOwner
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

        //transfer to PFL the sorely needed $ to cover our high infra costs
        bid_token.safeTransfer(owner(), ownerBalance);

        return true;
    }

    function setAutopayBatchSize(uint16 size) public onlyOwner {
        autopay_batch_size = size;
        emit AutopayBatchSizeSet(autopay_batch_size);
    }

    function setOffchainCheckerDisabledState(bool state) external onlyOwner {
        _offchain_checker_disabled = state;
    }

    function withdrawStuckNativeToken(uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        if (address(this).balance >= amount) {
            payable(owner()).sendValue(amount);
            emit WithdrawStuckNativeToken(owner(), amount);
        }
    }

    function withdrawStuckERC20(address _tokenAddress)
        external
        onlyOwner
        nonReentrant
    {
        require(_tokenAddress != address(bid_token), "FL:E-102");
        ERC20 oopsToken = ERC20(_tokenAddress);
        uint256 oopsTokenBalance = oopsToken.balanceOf(address(this));

        if (oopsTokenBalance > 0) {
            oopsToken.safeTransfer(owner(), oopsTokenBalance);
            emit WithdrawStuckERC20(address(this), owner(), oopsTokenBalance);
        }
    }

    function _receiveBid(
        Bid memory bid,
        uint256 currentTopBidAmount,
        address currentTopBidSearcherPayableAddress
    ) internal {
        // Verify the bid exceeds previous bid + minimum increment
        require(
            bid.bidAmount >= currentTopBidAmount + bid_increment,
            "FL:E-203"
        );

        // Verify the new bidder isnt the previous bidder as self-spam protection
        require(
            bid.searcherPayableAddress != currentTopBidSearcherPayableAddress,
            "FL:E-204"
        );

        // Verify the bidder has the balance.
        require(
            bid_token.balanceOf(bid.searcherPayableAddress) >= bid.bidAmount,
            "FL:E-206"
        );

        // Transfer the bid amount (requires approval)
        bid_token.safeTransferFrom(
            bid.searcherPayableAddress,
            address(this),
            bid.bidAmount
        );
    }

    function _refundPreviousBidder(Bid memory bid) internal {
        // Be very careful about changing bid token to any ERC777
        // Refund the previous top bid
        bid_token.safeTransfer(
            bid.searcherPayableAddress,
            bid.bidAmount
        );
    }

    function _calculateCuts(uint256 amount) internal view returns (uint256 vCut, uint256 flCut) {
        vCut = (amount * (1000000 - fast_lane_fee)) / 1000000;
        flCut = amount - vCut;
    }

    function _checkRedeemableOutstanding(ValidatorBalanceCheckpoint memory valCheckpoint,uint256 minAmount) internal view returns (bool) {
        return valCheckpoint.outstandingBalance >= minAmount || (((valCheckpoint.pendingBalanceAtlastBid + valCheckpoint.outstandingBalance) >= minAmount) && (valCheckpoint.lastBidReceivedAuction < auction_number));
    }

    function _redeemOutstanding(address outstandingValidatorWithBalance) internal {
        require(statusMap[outstandingValidatorWithBalance].kind == statusType.VALIDATOR, "FL:E-104");
        ValidatorBalanceCheckpoint storage valCheckpoint = validatorsCheckpoints[outstandingValidatorWithBalance];
       
        // Either we have outstandingBalance or we have pendingBalanceAtlastBid from previous auctions.
        require(
               _checkRedeemableOutstanding(valCheckpoint, 1),
            "FL:E-207"
        );

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

        address dst = outstandingValidatorWithBalance;
        ValidatorPreferences memory valPrefs = validatorsPreferences[dst];
        if (valPrefs.validatorPayableAddress != address(0)) {
            dst = valPrefs.validatorPayableAddress;
        }

        bid_token.safeTransfer(
            dst,
            redeemable
        );

        emit ValidatorWithdrawnBalance(
            outstandingValidatorWithBalance,
            auction_number,
            redeemable,
            dst,
            msg.sender
        );
    }

    /***********************************|
    |             Public                |
    |__________________________________*/

    // Bidding function for searchers to submit their bids
    // Each bid pulls funds on submission and searchers are refunded when they are outbid
    function submitBid(Bid calldata bid)
        external
        atLiveStage
        whenNotPaused
        nonReentrant
    {
        // Verify that the bid is coming from the EOA that's paying
        require(msg.sender == bid.searcherPayableAddress, "FL:E-103");

        Status memory validatorStatus = statusMap[bid.validatorAddress];
        Status memory opportunityStatus = statusMap[bid.opportunityAddress];

        // Verify that the opportunity and the validator are both participating addresses
        require(validatorStatus.kind == statusType.VALIDATOR, "FL:E-104");
        require(opportunityStatus.kind == statusType.OPPORTUNITY, "FL:E-105");

        // Verify not flagged as inactive
        require(validatorStatus.inactiveAtAuction > auction_number, "FL:E-209");
        require(opportunityStatus.inactiveAtAuction > auction_number, "FL:E-210");

        // Verify still flagged active
        require(validatorStatus.activeAtAuction <= auction_number, "FL:E-211");
        require(opportunityStatus.activeAtAuction <= auction_number, "FL:E-212");

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

        // Try adding to the validatorsActiveAtAuction so the keeper can loop on it
        // EnumerableSet already checks key pre-existence
        validatorsActiveAtAuction[auction_number].add(bid.validatorAddress);

        emit BidAdded(
            bid.searcherContractAddress,
            bid.validatorAddress,
            bid.opportunityAddress,
            bid.bidAmount,
            auction_number
        );
    }


    // Validators can always withdraw right after an amount is due
    // It can be during an ongoing auction with pendingBalanceAtlastBid being the current auction
    // Or lastBidReceivedAuction being a previous auction, in which case outstanding+pending can be withdrawn
    function redeemOutstandingBalance(address outstandingValidatorWithBalance)
        external
        nonReentrant
    {
        _redeemOutstanding(outstandingValidatorWithBalance);
    }

    /***********************************|
    |       Public Resolvers            |
    |__________________________________*/

    /// @notice Gelato Offchain Resolver
    /// @dev Automated function checked each block offchain by Gelato Network if there is outstanding payments to process
    /// @return canExec - should the worker trigger
    /// @return execPayload - the payload if canExec is true
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (_offchain_checker_disabled || _paused  || tx.gasprice > max_gas_price) return (false, "");
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

    function processAutopayJobs(address[] calldata autopayRecipients) external nonReentrant onlyGelato {
        // Reassert checks if insane spike between gelato trigger and tx picked up
        require(!_offchain_checker_disabled && !_paused, "FL:E-101");
        require(tx.gasprice <= max_gas_price, "FL:E-307");
        uint length = autopayRecipients.length;
        for (uint i = 0;i<length;) {
            if (autopayRecipients[i] != address(0)) {
                _redeemOutstanding(autopayRecipients[i]);
            }
            unchecked { ++i; }
        }
    }

    /***********************************|
    |             Views                 |
    |__________________________________*/

    // Most likely called off chain by Gelato
    function getAutopayJobs(uint16 batch_size, uint128 auction_index) public view returns (bool hasJobs, address[] memory autopayRecipients) {
        autopayRecipients = new address[](batch_size); // Filled with 0x0
        // An active validator means a bid happened so potentially balances were moved to outstanding while the bid happened
        EnumerableSet.AddressSet storage prevRoundAddrSet = validatorsActiveAtAuction[auction_index];
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
            if (assigned >= batch_size) {
                break;
            }
        }
        hasJobs = assigned > 0;
    }

    // Gets the status of an address
    function getStatus(address who) external view returns (Status memory) {
        return statusMap[who];
    }

    // Gets the validators involved with a given auction
    function getValidatorsActiveAtAuction(uint128 auction_index) external view returns (address[] memory) {
        return validatorsActiveAtAuction[auction_index].values();
    }

    // Gets the auction number for which the fast lane privileges are active
    function getActivePrivilegesAuctionNumber() public view returns (uint128) {
        return auction_number - 1;
    }

    // Gets the checkpoint of an address
    function getCheckpoint(address who) external view returns (ValidatorBalanceCheckpoint memory) {
        return validatorsCheckpoints[who];
    }

    // Gets the preferences of an address
    function getPreferences(address who) external view returns (ValidatorPreferences memory) {
        return validatorsPreferences[who];
    }

    //function for determining the current top bid for an ongoing (live) auction
    function findLiveAuctionTopBid(address validatorAddress, address opportunityAddress)
        external
        view
        atLiveStage
        returns (uint256, uint128)
    {
            Bid memory topBid = auctionsMap[auction_number][
                validatorAddress
            ][opportunityAddress];
            return (topBid.bidAmount, auction_number);
    }

    function findFinalizedAuctionWinnerAtAuction(
        uint128 auction_index,
        address validatorAddress,
        address opportunityAddress
    ) public view
                returns (
            bool,
            address,
            uint128
        )
    {
        require(auction_index < auction_number,"FL-E:201");
        //get the winning searcher
        address winningSearcher = auctionsMap[auction_index][
            validatorAddress
        ][opportunityAddress].searcherContractAddress;

        //check if there is a winning searcher (no bids mean the winner is address(0))
        if (winningSearcher != address(0)) {
            return (true, winningSearcher, auction_index);
        } else {
            return (false, winningSearcher, auction_index);
        }
    }

    // Function for determining the winner of the last completed auction
    function findLastFinalizedAuctionWinner(
        address validatorAddress,
        address opportunityAddress
    )
        external
        view
        returns (
            bool,
            address,
            uint128
        )
    {
        return findFinalizedAuctionWinnerAtAuction(getActivePrivilegesAuctionNumber(), validatorAddress, opportunityAddress);
    }

  /***********************************|
  |             Modifiers             |
  |__________________________________*/

    modifier notLiveStage() {
        require(!auction_live, "FL:E-301");
        _;
    }

    modifier atLiveStage() {
        require(auction_live, "FL:E-302");
        _;
    }

    modifier whenNotPaused() {
        require(_paused == false, "FL:E-101");
        _;
    }

    modifier onlyValidator() {
        require(statusMap[msg.sender].kind == statusType.VALIDATOR, "FL:E-104");
        _;
    }

    modifier onlyGelato() {
        require(msg.sender == ops, "FL:E-106");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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