//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import { SafeTransferLib, ERC20 } from "solmate/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";


abstract contract FastLaneAuctionHandlerEvents {

    event RelayPausedStateSet(bool state);
    event RelayValidatorEnabled(address validator, address payee);
    event RelayValidatorDisabled(address validator);
    event RelayValidatorPayeeUpdated(address validator, address payee, address indexed initiator);
    event RelaySimulatorStateSet(bool state);

    event RelayInitialized(uint24 initialStakeShare, uint256 minAmount);

    event RelayShareSet(uint24 amount);
    event RelayShareProposed(uint24 amount, uint256 deadline);
    event RelayMinAmountSet(uint256 minAmount);

    event RelayFlashBid(address indexed sender, uint256 amount, bytes32 indexed oppTxHash, address indexed validator, address searcherContractAddress);
    event RelaySimulatedFlashBid(address indexed sender, uint256 amount, bytes32 indexed oppTxHash, address indexed validator, address searcherContractAddress);

    event RelayWithdrawDust(address indexed receiver, uint256 amount);
    event RelayWithdrawStuckERC20(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );
    event RelayWithdrawStuckNativeToken(address indexed receiver, uint256 amount);
   

    error RelayInequalityTooHigh();

    error RelayPermissionPaused();
    error RelayPermissionNotFastlaneValidator();
    error RelayPermissionSenderNotOrigin();
    error RelayPermissionUnauthorized();

    error RelayWrongInit();
    error RelaySearcherWrongParams();

    error RelaySearcherCallFailure(bytes retData);
    error RelaySimulatedSearcherCallFailure(bytes retData);
    error RelayNotRepaid(uint256 bidAmount, uint256 actualAmount);
    error RelaySimulatedNotRepaid(uint256 bidAmount, uint256 actualAmount);

    event RelayProcessingPaidValidator(address indexed validator, uint256 validatorPayment, address indexed initiator);
    event RelayProcessingWithdrewStakeShare(address indexed recipient, uint256 amountWithdrawn);
    error RelayProcessingNoBalancePayable();
    error RelayProcessingAmountExceedsBalance(uint256 amountRequested, uint256 balance);
    
    error RelayAuctionBidReceivedLate();
    error RelayAuctionSearcherNotWinner(uint256 current, uint256 existing);

    error RelayTimeUnsuitable();
    error RelayCannotBeZero();
    error RelayCannotBeSelf();
}

/// @notice Validator Data Struct
/// @dev Subject to BLOCK_TIMELOCK for changes
/// @param payee Who to pay for this validator
/// @param timeUpdated Last time a change was requested for this validator payee
struct ValidatorData {
    address payee;
    uint256 timeUpdated;
}

interface ISearcherContract {
    function fastLaneCall(address, uint256, bytes calldata) external payable returns (bool, bytes memory);
}

contract FastLaneAuctionHandler is FastLaneAuctionHandlerEvents, Ownable, ReentrancyGuard {

    /// @notice Constant delay before the stake share can be changed
    uint32 internal constant BLOCK_TIMELOCK = 6 days;

    /// @notice Constant base fee
    uint24 internal constant FEE_BASE = 1_000_000;




    /// @notice If a validator is active or not
    mapping(address => bool) public validatorsStatusMap;

    /// @notice Mapping to Validator Data Struct
    mapping(address => ValidatorData) internal validatorsDataMap;

    /// @notice Map[validator] = balance
    mapping(address => uint256) public validatorsBalanceMap;

    /// @notice Map key is keccak hash of opp tx's gasprice and tx hash
    mapping(bytes32 => uint256) public fulfilledAuctionsMap;

    uint256 public validatorsTotal;

    uint256 public flStakeSharePayable;
    uint24 public flStakeShareRatio;

    uint24 public proposalStakeShareRatio;
    uint256 public proposalDeadline;

    uint256 public minRelayBidAmount = 1 ether; // 1 Matic

    bool public pendingStakeShareUpdate;
    bool public paused;
    bool public bid_simulator_enabled = true;

    constructor(uint24 _initialStakeShare, uint256 _minRelayBidAmount) {
        flStakeShareRatio = _initialStakeShare;
        minRelayBidAmount = _minRelayBidAmount;
        emit RelayInitialized(_initialStakeShare, _minRelayBidAmount);
    }


    /// @notice Submits a flash bid
    /// @dev Will revert if: already won, minimum bid not respected, not from EOA, or current validator is not participating in PFL.
    /// @param _bidAmount Amount committed to be repaid
    /// @param _oppTxHash Target Transaction hash
    /// @param _searcherToAddress Searcher contract address to be called on its `fastLaneCall` function.
    /// @param _searcherCallData callData to be passed to `_searcherToAddress.fastLaneCall(_bidAmount,msg.sender,callData)`
    function submitFlashBid(
        uint256 _bidAmount, // Value commited to be repaid at the end of execution
        bytes32 _oppTxHash, // Target TX
        address _searcherToAddress,
        bytes calldata _searcherCallData 
        ) external payable checkBid(_oppTxHash, _bidAmount) onlyParticipatingValidators whenNotPaused onlyEOA nonReentrant {

            if (_searcherToAddress == address(0) || _bidAmount < minRelayBidAmount) revert RelaySearcherWrongParams();
            
            // Store the current balance, excluding msg.value
            uint256 balanceBefore = address(this).balance - msg.value;

            // Call the searcher's contract (see searcher_contract.sol for example of call receiver)
            // And forward msg.value
            (bool success, bytes memory retData) = ISearcherContract(_searcherToAddress).fastLaneCall{value: msg.value}(
                        msg.sender,
                        _bidAmount,
                        _searcherCallData
            );

            if (!success) revert RelaySearcherCallFailure(retData);

            // Verify that the searcher paid the amount they bid & emit the event
            _handleBalances(_bidAmount, balanceBefore);
            emit RelayFlashBid(msg.sender, _bidAmount, _oppTxHash, block.coinbase, _searcherToAddress);
    }


    /// @notice Submits a SIMULATED flash bid. THE HTTP RELAY won't accept calls for this function.
    /// @notice This is just a convenience function for you to test by simulating a call to simulateFlashBid 
    /// @notice To ensure your calldata correctly works when relayed to `_searcherToAddress`.fastLaneCall(_searcherCallData)
    /// @dev This does NOT check that current coinbase is participating in PFL.
    /// @dev Only use for testing _searcherCallData
    /// @dev You can submit any _bidAmount you like for testing
    /// @param _bidAmount Amount committed to be repaid
    /// @param _oppTxHash Target Transaction hash
    /// @param _searcherToAddress Searcher contract address to be called on its `fastLaneCall` function.
    /// @param _searcherCallData callData to be passed to `_searcherToAddress.fastLaneCall(_bidAmount,msg.sender,callData)`
    function simulateFlashBid(
        uint256 _bidAmount, // Value commited to be repaid at the end of execution, can be set very low in simulated
        bytes32 _oppTxHash, // Target TX
        address _searcherToAddress,
        bytes calldata _searcherCallData 
        ) external payable nonReentrant whenNotPaused onlyEOA {

            // Relax check on min bid amount for simulated
            if (_searcherToAddress == address(0) || bid_simulator_enabled == false /* || _bidAmount < minRelayBidAmount */) revert RelaySearcherWrongParams();
            
            // Store the current balance, excluding msg.value
            uint256 balanceBefore = address(this).balance - msg.value;

            // Call the searcher's contract (see searcher_contract.sol for example of call receiver)
            // And forward msg.value
            (bool success, bytes memory retData) = ISearcherContract(_searcherToAddress).fastLaneCall{value: msg.value}(
                        msg.sender,
                        _bidAmount,
                        _searcherCallData
            );

            if (!success) revert RelaySimulatedSearcherCallFailure(retData);

            // Verify that the searcher paid the amount they bid & emit the event
            if (address(this).balance < balanceBefore + _bidAmount) {
                revert RelaySimulatedNotRepaid(_bidAmount, address(this).balance - balanceBefore);
            }
            emit RelaySimulatedFlashBid(msg.sender, _bidAmount, _oppTxHash, block.coinbase, _searcherToAddress);
    }

    /***********************************|
    |    Internal Bid Helper Functions  |
    |__________________________________*/

    function _handleBalances(uint256 _bidAmount, uint256 balanceBefore) internal {
        if (address(this).balance < balanceBefore + _bidAmount) {
            revert RelayNotRepaid(_bidAmount, address(this).balance - balanceBefore);
        }

        (uint256 amtPayableToValidator, uint256 amtPayableToStakers) = _calculateStakeShare(_bidAmount, flStakeShareRatio);

        validatorsBalanceMap[block.coinbase] += amtPayableToValidator;
        validatorsTotal += amtPayableToValidator;
        flStakeSharePayable += amtPayableToStakers;
    }


    /// @notice Internal, calculates shares
    /// @param _amount Amount to calculates cuts from
    /// @param _share Share bps
    /// @return validatorCut Validator cut
    /// @return stakeCut Stake cut
    function _calculateStakeShare(uint256 _amount, uint24 _share) internal pure returns (uint256 validatorCut, uint256 stakeCut) {
        validatorCut = (_amount * (FEE_BASE - _share)) / FEE_BASE;
        stakeCut = _amount - validatorCut;
    }

    receive() external payable {}
    fallback() external payable {}


    /***********************************|
    |             Owner-only            |
    |__________________________________*/

    /// @notice Defines the paused state of the Auction
    /// @dev Only owner
    /// @param _state New state
    function setPausedState(bool _state) external onlyOwner {
        paused = _state;
        emit RelayPausedStateSet(_state);
    }

    /// @notice Defines the paused state of the Simulator
    /// @dev Only owner
    /// @param _state New state
    function setSimulatorState(bool _state) external onlyOwner {
        bid_simulator_enabled = _state;
        emit RelaySimulatorStateSet(_state);
    }

    /// @notice Defines the minimum bid
    /// @dev Only owner
    /// @param _minAmount New minimum amount
    function setMininumBidAmount(uint256 _minAmount) external onlyOwner {
        minRelayBidAmount = _minAmount;
        emit RelayMinAmountSet(_minAmount);
    }

    /// @notice Sets the stake revenue allocation (out of 1_000_000 (ie v2 fee decimals))
    /// @dev Initially set to 50_000 (5%), and pending for 6 days before a change
    /// @param _fastLaneStakeShare Protocol stake allocation on bids
    function setFastLaneStakeShare(uint24 _fastLaneStakeShare) public onlyOwner {
        if (pendingStakeShareUpdate) revert RelayTimeUnsuitable();
        if (_fastLaneStakeShare > FEE_BASE) revert RelayInequalityTooHigh();
        proposalStakeShareRatio = _fastLaneStakeShare;
        proposalDeadline = block.timestamp + BLOCK_TIMELOCK;
        pendingStakeShareUpdate = true;
        emit RelayShareProposed(_fastLaneStakeShare, proposalDeadline);
    }

    /// @notice Withdraws fl stake share
    /// @dev Owner only
    /// @param _recipient Recipient
    /// @param _amount Amount
    function withdrawStakeShare(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        if (_recipient == address(0) || _amount == 0) revert RelayCannotBeZero();
        flStakeSharePayable -= _amount;
        SafeTransferLib.safeTransferETH(
            _recipient, 
            _amount
        );
        emit RelayProcessingWithdrewStakeShare(_recipient, _amount);
    }
    

    /// @notice Enables an address as participating validator, and defining a payee for it
    /// @dev Owner only
    /// @param _validator Validator address that will be the coinbase of bids
    /// @param _payee Address that can withdraw for that validator
    function enableRelayValidator(address _validator, address _payee) external onlyOwner {
        if (_validator == address(0) || _payee == address(0)) revert RelayCannotBeZero();
        if (_payee == address(this)) revert RelayCannotBeSelf();
        validatorsStatusMap[_validator] = true;
        validatorsDataMap[_validator] = ValidatorData(_payee, block.timestamp - BLOCK_TIMELOCK);
        emit RelayValidatorEnabled(_validator, _payee);
    }

    /// @notice Disables an address as participating validator
    /// @dev Owner only
    /// @param _validator Validator address
    function disableRelayValidator(address _validator) external onlyOwner {
        if (_validator == address(0)) revert RelayCannotBeZero();
        validatorsStatusMap[_validator] = false;
        emit RelayValidatorDisabled(_validator);
    }

    /// @notice Recover bids repaid to the relay over bidAmount
    /// @dev Owner only, can never tap into validator balances nor flStake.
    /// @param _amount amount desired, capped to max
    function recoverDust(uint256 _amount) 
        external
        onlyOwner
        nonReentrant
    {
        uint256 maxDust = address(this).balance - validatorsTotal - flStakeSharePayable;
        if (_amount > maxDust) _amount = maxDust;
        SafeTransferLib.safeTransferETH(owner(), _amount);
        emit RelayWithdrawDust(owner(), _amount);
    }

    /// @notice Withdraws stuck matic
    /// @dev In the event something went really wrong / vuln report
    /// @dev When out of beta role will be moved to gnosis multisig for added safety
    /// @param _amount Amount to send to owner
    function withdrawStuckNativeToken(uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        if (address(this).balance >= _amount) {
            SafeTransferLib.safeTransferETH(owner(), _amount);
            emit RelayWithdrawStuckNativeToken(owner(), _amount);
        }
    }

    /// @notice Withdraws stuck ERC20
    /// @dev In the event people send ERC20 instead of Matic we can send them back 
    /// @param _tokenAddress Address of the stuck token
    function withdrawStuckERC20(address _tokenAddress)
        external
        onlyOwner
        nonReentrant
    {
        ERC20 oopsToken = ERC20(_tokenAddress);
        uint256 oopsTokenBalance = oopsToken.balanceOf(address(this));

        if (oopsTokenBalance > 0) {
            SafeTransferLib.safeTransferFrom(oopsToken, address(this), owner(), oopsTokenBalance);
            emit RelayWithdrawStuckERC20(address(this), owner(), oopsTokenBalance);
        }
    }

    /***********************************|
    |          Validator Functions      |
    |__________________________________*/

    /// @notice Pays the validator their outstanding balance
    /// @dev Callable by either validator address, their payee address (if not changed recently), or PFL.
    /// @param _validator Validator address
    function payValidator(address _validator) external whenNotPaused nonReentrant onlyValidatorProxy(_validator) returns (uint256) {        
        uint256 payableBalance = validatorsBalanceMap[_validator];
        if (payableBalance <= 0) revert RelayCannotBeZero();

        validatorsTotal -= validatorsBalanceMap[_validator];
        validatorsBalanceMap[_validator] = 0;
        SafeTransferLib.safeTransferETH(
                validatorPayee(_validator), 
                payableBalance
        );
        emit RelayProcessingPaidValidator(_validator, payableBalance, msg.sender);
        return payableBalance;
    }

    /// @notice Updates a validator payee
    /// @dev Callable by either validator address, their payee address (if not changed recently), or PFL.
    /// @param _validator Validator address
    function updateValidatorPayee(address _validator, address _payee) external onlyValidatorProxy(_validator) nonReentrant {
        if (_payee == address(0)) revert RelayCannotBeZero();
        if (_payee == address(this)) revert RelayCannotBeSelf();
        if (!validatorsStatusMap[_validator]) revert RelayPermissionNotFastlaneValidator();
        validatorsDataMap[_validator].payee = _payee;
        validatorsDataMap[_validator].timeUpdated = block.timestamp;

        emit RelayValidatorPayeeUpdated(_validator, _payee, msg.sender);   
    }

    /***********************************|
    |             Public                |
    |__________________________________*/

    /// @notice Activates a pending stake share update
    /// @dev Anyone can call it after a 6 days delay
    function triggerPendingStakeShareUpdate() external nonReentrant {
        if (!pendingStakeShareUpdate || block.timestamp < proposalDeadline) revert RelayTimeUnsuitable();
        flStakeShareRatio = proposalStakeShareRatio;
        pendingStakeShareUpdate = false;
        emit RelayShareSet(proposalStakeShareRatio);
    }

    /***********************************|
    |              Views                |
    |__________________________________*/

    function isPayeeTimeLocked(address _validator) public view returns (bool _isTimeLocked) {
        _isTimeLocked = block.timestamp < validatorsDataMap[_validator].timeUpdated + BLOCK_TIMELOCK;
    }

    function isValidPayee(address _validator, address _payee) public view returns (bool _valid) {
        _valid = !isPayeeTimeLocked(_validator) && _payee == validatorsDataMap[_validator].payee;
    }

    function validatorPayee(address _validator) internal view returns (address _recipient) {
        _recipient = !isPayeeTimeLocked(_validator) ? validatorsDataMap[_validator].payee : _validator;
    }

    /// @notice Returns validator pending balance
    function getValidatorBalance(address _validator) public view returns (uint256 _validatorBalance) {
        _validatorBalance = validatorsBalanceMap[_validator];
    }

    /// @notice Returns the listed payee address regardless of whether or not it has passed the time lock.
    function getValidatorPayee(address _validator) public view returns (address _payee) {
        _payee = validatorsDataMap[_validator].payee;
    }

    /// @notice For validators to determine where their payments will go
    /// @dev Will return the Payee if blockTimeLock has passed, will return Validator if not.
    /// @param _validator Address
    function getValidatorRecipient(address _validator) public view returns (address _recipient) {
        _recipient = validatorPayee(_validator);
    }

    function getCurrentStakeRatio() public view returns (uint24) {
        return flStakeShareRatio;
    }

    function getCurrentStakeBalance() public view returns (uint256) {
       return flStakeSharePayable;
    }

    function getPendingStakeRatio() public view returns (uint24 _fastLaneStakeShare) {
        _fastLaneStakeShare = pendingStakeShareUpdate ? proposalStakeShareRatio : flStakeShareRatio;
    }

    function getPendingDeadline() public view returns (uint256 _timeDeadline) {
        _timeDeadline = pendingStakeShareUpdate ? proposalDeadline : block.timestamp;
    }

    function getValidatorStatus(address _validator) public view returns (bool) {
        return validatorsStatusMap[_validator];
    }

    function humanizeError(bytes memory _errorData) public pure returns (string memory decoded) {
        uint256 len = _errorData.length;
        bytes memory firstPass = abi.decode(slice(_errorData, 4, len-4), (bytes));
        decoded = abi.decode(slice(firstPass, 4, firstPass.length-4), (string));
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /***********************************|
    |             Modifiers             |
    |__________________________________*/

    modifier whenNotPaused() {
        if (paused) revert RelayPermissionPaused();
        _;
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert RelayPermissionSenderNotOrigin();
        _;
    }

    modifier onlyParticipatingValidators() {
        if (!validatorsStatusMap[block.coinbase]) revert RelayPermissionNotFastlaneValidator();
        _;
    }

    modifier onlyValidatorProxy(address _validator) {
        // Address never seen before in validatorsDataMap -> impossible to have balance / proxy
        if (validatorsDataMap[_validator].payee == address(0)) revert RelayPermissionUnauthorized();

        // Validator or owner or valid payee
        if (msg.sender != _validator && msg.sender != owner() && !isValidPayee(_validator, msg.sender)) revert RelayPermissionUnauthorized();
        _;
    }

    /// @notice Validates incoming bid
    /// @dev 
    /// @param _oppTxHash Target Transaction hash
    /// @param _bidAmount Amount committed to be repaid
    modifier checkBid(bytes32 _oppTxHash, uint256 _bidAmount) {
        // Use hash of the opportunity tx hash and the transaction's gasprice as key for bid tracking
        // This is dependent on the PFL Relay verifying that the searcher's gasprice matches
        // the opportunity's gasprice, and that the searcher used the correct opportunity tx hash

        bytes32 auction_key = keccak256(abi.encode(_oppTxHash, tx.gasprice));
        uint256 existing_bid = fulfilledAuctionsMap[auction_key];

        if (existing_bid != 0) {
            if (_bidAmount >= existing_bid) {
                // This error message could also arise if the tx was sent via mempool
                revert RelayAuctionBidReceivedLate();
            } else {
                revert RelayAuctionSearcherNotWinner(_bidAmount, existing_bid);
            }
        }

        // Mark this auction as being complete to provide quicker reverts for subsequent searchers
        fulfilledAuctionsMap[auction_key] = _bidAmount;
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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