// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {State, Score, RatingStore, Parameters} from  "./utils/DataTypes.sol";

contract ONDC is Ownable, Pausable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 public lastSync;

    mapping (string TransactionId => Score) public ScoreInfo;
    mapping (string SellerId => RatingStore) public SellerTotalScore;
    mapping (string SellerId => mapping(string DateKey => RatingStore)) public SellerDayScore;

    error Transaction_Already_Exist();
    error Transaction_Not_Exist();
    error Transaction_Is_Invalid();

    event ScoreAdded(string indexed tx,string indexed  sellerId,string indexed dateKey,uint256 timestamp);
    event ScoreUpdated(string indexed tx,string indexed sellerId,string indexed dateKey,uint256 timestamp);

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Recover the all coins from the contract. 
     *
     * NOTE: Can only be called by the current owner.
     */
    function getLeftOverCoin(address to) external onlyOwner {
        to.safeTransferETH(address(this).balance);
    }

    /**
     * @dev Recover the all coins from the contract. 
     *
     * NOTE: Can only be called by the current owner.
     */
    function getLeftOverToken(address token,address to,uint256 amount) external onlyOwner {
        ERC20(token).safeTransfer(to,amount);
    }

    /**
     * @dev Adding the rating records into the smart contract.
     * It will updated based on day and seller basics.
     *
     * NOTE: Can only be called by the current owner.
     */
    function CreateScore(Parameters memory params) external whenNotPaused onlyOwner {
        if (ScoreInfo[params.transactionID].createdAt != 0) revert Transaction_Already_Exist(); 
        if (params.countOfTxn == 0) revert Transaction_Is_Invalid();

        ScoreInfo[params.transactionID] = Score({
            sellerId:  params.sellerId,          
            gstin:  params.gstin,          
            pan:  params.pan,          
            shopLicenceNumber:  params.shopLicenceNumber,          
            sellerNpID:  params.sellerNpID,     
            storeType:  params.storeType,     
            action:  params.action,
            countOfTxn:  params.countOfTxn,
            totalRating:  params.totalRating,
            timestamp:  params.timestamp,
            docType:  State.Rating,
            createdAt:  uint64(block.timestamp),
            updatedAt:  uint64(block.timestamp)
        });

        RatingStore memory Ratingdata = SellerDayScore[params.sellerId][params.timestampFormat];
        Ratingdata.countOfTxn =  Ratingdata.countOfTxn + params.countOfTxn;
        Ratingdata.totalRating =  Ratingdata.totalRating + params.totalRating;
        Ratingdata.score = Ratingdata.totalRating / Ratingdata.countOfTxn;

        if (Ratingdata.createdAt == 0) {
            Ratingdata.docType = State.DayScore;
            Ratingdata.createdAt = uint64(block.timestamp);
            Ratingdata.updatedAt = uint64(block.timestamp);
        } 

        SellerDayScore[params.sellerId][params.timestampFormat] = Ratingdata;

        RatingStore memory TotalScoredata = SellerTotalScore[params.sellerId];
        TotalScoredata.countOfTxn =  TotalScoredata.countOfTxn + params.countOfTxn;
        TotalScoredata.totalRating =  TotalScoredata.totalRating + params.totalRating;
        TotalScoredata.score = TotalScoredata.totalRating / TotalScoredata.countOfTxn;

        if (TotalScoredata.createdAt == 0) {
            TotalScoredata.docType = State.TotalScore;
            TotalScoredata.createdAt = uint64(block.timestamp);
            TotalScoredata.updatedAt = uint64(block.timestamp);
        } 

        SellerTotalScore[params.sellerId] = TotalScoredata;

        lastSync = uint256(params.lastSync);
        emit ScoreAdded(params.transactionID,params.sellerId,params.timestampFormat,block.timestamp);
    }

    /**
     * @dev Updating the rating records into the smart contract.
     * It will updated based on day and seller basics.
     *
     * NOTE: Can only be called by the current owner.
     */
    function CorrectScore(Parameters memory params) external whenNotPaused onlyOwner {
        if (ScoreInfo[params.transactionID].createdAt == 0) revert Transaction_Not_Exist(); 

        uint64 previousTxnCount = ScoreInfo[params.transactionID].countOfTxn;
        uint64 previousTotalRating = ScoreInfo[params.transactionID].totalRating;

        ScoreInfo[params.transactionID] = Score({
            sellerId:  params.sellerId,          
            gstin:  params.gstin,          
            pan:  params.pan,          
            shopLicenceNumber:  params.shopLicenceNumber,          
            sellerNpID:  params.sellerNpID,     
            storeType:  params.storeType,     
            action:  params.action,
            countOfTxn:  params.countOfTxn,
            totalRating:  params.totalRating,
            timestamp:  params.timestamp,
            docType:  State.Rating,
            createdAt:  ScoreInfo[params.transactionID].createdAt,
            updatedAt:  uint64(block.timestamp)
        });

        RatingStore memory Ratingdata = SellerDayScore[params.sellerId][params.timestampFormat];
        Ratingdata.countOfTxn =  Ratingdata.countOfTxn - previousTxnCount;
        Ratingdata.totalRating =  Ratingdata.totalRating - previousTotalRating;

        Ratingdata.countOfTxn =  Ratingdata.countOfTxn + params.countOfTxn;
        Ratingdata.totalRating =  Ratingdata.totalRating + params.totalRating;
        Ratingdata.score = Ratingdata.totalRating / Ratingdata.countOfTxn;
        Ratingdata.updatedAt = uint64(block.timestamp);

        SellerDayScore[params.sellerId][params.timestampFormat] = Ratingdata;

        RatingStore memory TotalScoredata = SellerTotalScore[params.sellerId];
        TotalScoredata.countOfTxn =  TotalScoredata.countOfTxn - previousTxnCount;
        TotalScoredata.totalRating =  TotalScoredata.totalRating - previousTotalRating;

        TotalScoredata.countOfTxn =  TotalScoredata.countOfTxn + params.countOfTxn;
        TotalScoredata.totalRating =  TotalScoredata.totalRating + params.totalRating;
        TotalScoredata.score = TotalScoredata.totalRating / TotalScoredata.countOfTxn;
        TotalScoredata.updatedAt = uint64(block.timestamp); 

        SellerTotalScore[params.sellerId] = TotalScoredata;

        emit ScoreUpdated(params.transactionID,params.sellerId,params.timestampFormat,block.timestamp);
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

enum State {
    Rating,
    DayScore,
    TotalScore
}

struct Score  {
    string sellerId;          
    string gstin;          
    string pan;          
    string shopLicenceNumber;          
    string sellerNpID;     
    string storeType;     
    string action;
    uint64 countOfTxn;
    uint64 totalRating;
    uint64 timestamp;
    State docType;
    uint64 createdAt;
    uint64 updatedAt;
}

struct RatingStore  {        
    uint64 countOfTxn; 
    uint64 totalRating; 
    uint64 score;     
    State docType; 
    uint64 createdAt;
    uint64 updatedAt;  
}

struct Parameters  {
    string transactionID;
    string sellerId;          
    string gstin;          
    string pan;          
    string shopLicenceNumber;          
    string sellerNpID;     
    string storeType;     
    string action;
    uint64 countOfTxn;
    uint64 totalRating;
    uint64 lastSync;
    uint64 timestamp;
    string timestampFormat;
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