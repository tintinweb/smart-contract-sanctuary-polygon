//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import { IFastLaneAuction } from "../interfaces/IFastLaneAuction.sol";
import "openzeppelin-contracts/contracts//access/Ownable.sol";



import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";


abstract contract FastLaneRelayEvents {

    event RelayPausedStateSet(bool state);
    event RelayValidatorEnabled(address validator);
    event RelayValidatorDisabled(address validator);
    event RelayInitialized(address vault);
    event RelayFeeSet(uint24 amount);
    event RelayFlashBid(address indexed sender, uint256 amount, bytes32 indexed oppTxHash, address indexed validator, address searcherContractAddress);

    error RelayInequalityTooHigh();

    error RelayPermissionPaused();
    error RelayPermissionNotFastlaneValidator();

    error RelayWrongInit();
    error RelayWrongSpecifiedValidator();
    error RelaySearcherWrongParams();

    error RelaySearcherCallFailure(bytes retData);
    error RelayNotRepaid(uint256 missingAmount);
    

}
contract FastLaneRelay is FastLaneRelayEvents, Ownable, ReentrancyGuard {

    using SafeTransferLib for address payable;

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    address public fastlaneAddress;
    address public vaultAddress;

    mapping(address => bool) internal validatorsMap;

    bool public paused = false;

    uint24 public fastlaneRelayFee;

    constructor(address _vaultAddress, uint24 _fee) {
        if (_vaultAddress == address(0) || _fee == 0) revert RelayWrongInit();
        
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();


        vaultAddress = _vaultAddress;
        
        setFastlaneRelayFee(_fee);

        emit RelayInitialized(_vaultAddress);
    }


    function submitFlashBid(
        uint256 _bidAmount, // Value commited to be repaid at the end of execution
        bytes32 _oppTxHash, // Target TX
        address _validator, // Set to address(0) if any PFL validator works
        address _searcherToAddress,
        bytes calldata _toForwardExecData 
        // _toForwardExecData should contain _bidAmount somewhere in the data to be decoded on the receiving searcher contract
        ) external payable nonReentrant whenNotPaused onlyParticipatingValidators {

            if (_validator != address(0) && _validator != block.coinbase) revert RelayWrongSpecifiedValidator();
            if (_searcherToAddress == address(0) || _bidAmount == 0) revert RelaySearcherWrongParams();
            
            
            uint256 balanceBefore = vaultAddress.balance;
      
            //(uint256 vCut, uint256 flCut) = _calculateRelayCuts(_bidAmount, _fee);

            (bool success, bytes memory retData) = _searcherToAddress.call{value: msg.value}(abi.encodePacked(_toForwardExecData, msg.sender));
            if (!success) revert RelaySearcherCallFailure(retData);

            uint256 expected = balanceBefore + _bidAmount;
            uint256 balanceAfter = vaultAddress.balance;
            if (balanceAfter < expected) revert RelayNotRepaid(expected - balanceAfter);
            emit RelayFlashBid(msg.sender, _bidAmount, _oppTxHash, _validator, _searcherToAddress);
    }


    /// @notice Internal, calculates cuts
    /// @dev vCut 
    /// @param _amount Amount to calculates cuts from
    /// @param _fee Fee bps
    /// @return vCut validator cut
    /// @return flCut protocol cut
    function _calculateRelayCuts(uint256 _amount, uint24 _fee) internal pure returns (uint256 vCut, uint256 flCut) {
        vCut = (_amount * (1000000 - _fee)) / 1000000;
        flCut = _amount - vCut;
    }

    // Unused
    function checkAllowedInAuction(address _coinbase) public view returns (bool) {
        uint128 auction_number = IFastLaneAuction(fastlaneAddress).auction_number();
        IFastLaneAuction.Status memory coinbaseStatus = IFastLaneAuction(fastlaneAddress).getStatus(_coinbase);
        if (coinbaseStatus.kind != IFastLaneAuction.statusType.VALIDATOR) return false;

        // Validator is past his inactivation round number
        if (auction_number >= coinbaseStatus.inactiveAtAuctionRound) return false;
        // Validator is not yet at his activation round number
        if (auction_number < coinbaseStatus.activeAtAuctionRound) return false;
        return true;
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("FastLaneRelay")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

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


    /// @notice Sets the protocol fee (out of 1000000 (ie v2 fee decimals))
    /// @dev Initially set to 50000 (5%) For now we can't change the fee during an ongoing auction since the bids do not store the fee value at bidding time
    /// @param _fastLaneRelayFee Protocol fee on bids
    function setFastlaneRelayFee(uint24 _fastLaneRelayFee)
        public
        onlyOwner
    {
        if (_fastLaneRelayFee > 1000000) revert RelayInequalityTooHigh();
        fastlaneRelayFee = _fastLaneRelayFee;
        emit RelayFeeSet(_fastLaneRelayFee);
    }
    

    function enableRelayValidatorAddress(address _validator) external onlyOwner {
        validatorsMap[_validator] = true;
        emit RelayValidatorEnabled(_validator);
    }

    function disableRelayValidatorAddress(address _validator) external onlyOwner {
        validatorsMap[_validator] = false;
        emit RelayValidatorDisabled(_validator);
    }

    /***********************************|
    |             Modifiers             |
    |__________________________________*/

    modifier whenNotPaused() {
        if (paused) revert RelayPermissionPaused();
        _;
    }

    modifier onlyParticipatingValidators() {
        if (!validatorsMap[block.coinbase]) revert RelayPermissionNotFastlaneValidator();
        _;
    }
}

pragma solidity ^0.8.10;

interface IFastLaneAuction {
    event AuctionEnded(uint128 indexed auction_number);
    event AuctionStarted(uint128 indexed auction_number);
    event AuctionStarterSet(address indexed starter);
    event AutopayBatchSizeSet(uint16 batch_size);
    event BidAdded(
        address bidder,
        address indexed validator,
        address indexed opportunity,
        uint256 amount,
        uint256 indexed auction_number
    );
    event BidTokenSet(address indexed token);
    event FastLaneFeeSet(uint256 amount);
    event MinimumAutoshipThresholdSet(uint128 amount);
    event MinimumBidIncrementSet(uint256 amount);
    event OpportunityAddressDisabled(address indexed opportunity, uint128 indexed auction_number);
    event OpportunityAddressEnabled(address indexed opportunity, uint128 indexed auction_number);
    event OpsSet(address ops);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PausedStateSet(bool state);
    event ResolverMaxGasPriceSet(uint128 amount);
    event ValidatorAddressDisabled(address indexed validator, uint128 indexed auction_number);
    event ValidatorAddressEnabled(address indexed validator, uint128 indexed auction_number);
    event ValidatorPreferencesSet(address indexed validator, uint256 minAutoshipAmount, address validatorPayableAddress);
    event ValidatorWithdrawnBalance(
        address indexed validator,
        uint128 indexed auction_number,
        uint256 amount,
        address destination,
        address indexed caller
    );
    event WithdrawStuckERC20(address indexed receiver, address indexed token, uint256 amount);
    event WithdrawStuckNativeToken(address indexed receiver, uint256 amount);

    struct Bid {
        address a;
        address b;
        address c;
        address d;
        uint256 e;
    }

    enum statusType {
        INVALID, // 0
        VALIDATOR, // 1 
        OPPORTUNITY // 2
    }
    struct Status {
        uint128 activeAtAuctionRound;
        uint128 inactiveAtAuctionRound;
        statusType kind;  
    }

    struct ValidatorBalanceCheckpoint {
        uint256 a;
        uint256 b;
        uint128 c;
        uint128 d;
    }

    struct ValidatorPreferences {
        uint256 a;
        address b;
    }

    function MAX_AUCTION_VALUE() external view returns (uint128);
    function auctionInitialized() external view returns (bool);
    function auctionStarter() external view returns (address);
    function auction_live() external view returns (bool);
    function auction_number() external view returns (uint128);
    function autopay_batch_size() external view returns (uint16);
    function bid_increment() external view returns (uint256);
    function bid_token() external view returns (address);
    function checker() external view returns (bool canExec, bytes memory execPayload);
    function disableOpportunityAddress(address _opportunityAddress) external;
    function disableValidatorAddress(address _validatorAddress) external;
    function enableOpportunityAddress(address _opportunityAddress) external;
    function enableValidatorAddress(address _validatorAddress) external;
    function enableValidatorAddressWithPreferences(
        address _validatorAddress,
        uint128 _minAutoshipAmount,
        address _validatorPayableAddress
    )
        external;
    function endAuction() external returns (bool);
    function fast_lane_fee() external view returns (uint24);
    function findFinalizedAuctionWinnerAtAuction(
        uint128 auction_index,
        address validatorAddress,
        address opportunityAddress
    )
        external
        view
        returns (bool, address, uint128);
    function findLastFinalizedAuctionWinner(address validatorAddress, address opportunityAddress)
        external
        view
        returns (bool, address, uint128);
    function findLiveAuctionTopBid(address validatorAddress, address opportunityAddress)
        external
        view
        returns (uint256, uint128);
    function getActivePrivilegesAuctionNumber() external view returns (uint128);
    function getAutopayJobs(uint16 batch_size, uint128 auction_index)
        external
        view
        returns (bool hasJobs, address[] memory autopayRecipients);
    function getCheckpoint(address who) external view returns (ValidatorBalanceCheckpoint memory);
    function getPreferences(address who) external view returns (ValidatorPreferences memory);
    function getStatus(address who) external view returns (Status memory);
    function getValidatorsactiveAtAuctionRound(uint128 auction_index) external view returns (address[] memory);
    function initialSetupAuction(address _initial_bid_token, address _ops, address _starter) external;
    function max_gas_price() external view returns (uint128);
    function minAutoShipThreshold() external view returns (uint128);
    function ops() external view returns (address);
    function outstandingFLBalance() external view returns (uint256);
    function owner() external view returns (address);
    function processAutopayJobs(address[] memory autopayRecipients) external;
    function redeemOutstandingBalance(address _outstandingValidatorWithBalance) external;
    function renounceOwnership() external;
    function setAutopayBatchSize(uint16 _size) external;
    function setBidToken(address _bid_token_address) external;
    function setFastlaneFee(uint24 _fastLaneFee) external;
    function setMinimumAutoShipThreshold(uint128 _minAmount) external;
    function setMinimumBidIncrement(uint256 _bid_increment) external;
    function setOffchainCheckerDisabledState(bool _state) external;
    function setOps(address _ops) external;
    function setPausedState(bool _state) external;
    function setResolverMaxGasPrice(uint128 _maxgas) external;
    function setStarter(address _starter) external;
    function setValidatorPreferences(uint128 _minAutoshipAmount, address _validatorPayableAddress) external;
    function startAuction() external;
    function submitBid(Bid memory bid) external;
    function transferOwnership(address newOwner) external;
    function withdrawStuckERC20(address _tokenAddress) external;
    function withdrawStuckNativeToken(uint256 _amount) external;
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