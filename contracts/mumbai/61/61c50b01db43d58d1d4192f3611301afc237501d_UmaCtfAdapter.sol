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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity 0.8.15;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/security/ReentrancyGuard.sol";

import { Auth } from "./mixins/Auth.sol";
import { BulletinBoard } from "./mixins/BulletinBoard.sol";

import { TransferHelper } from "./libraries/TransferHelper.sol";
import { AncillaryDataLib } from "./libraries/AncillaryDataLib.sol";

import { IFinder } from "./interfaces/IFinder.sol";
import { IAddressWhitelist } from "./interfaces/IAddressWhitelist.sol";
import { IConditionalTokens } from "./interfaces/IConditionalTokens.sol";
import { IOptimisticOracleV2 } from "./interfaces/IOptimisticOracleV2.sol";
import { IOptimisticRequester } from "./interfaces/IOptimisticRequester.sol";

import { QuestionData, IUmaCtfAdapter } from "./interfaces/IUmaCtfAdapter.sol";

/// @title UmaCtfAdapter
/// @notice Enables resolution of Polymarket CTF markets via UMA's Optimistic Oracle
contract UmaCtfAdapter is IUmaCtfAdapter, Auth, BulletinBoard, IOptimisticRequester, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////////
                            IMMUTABLES 
    //////////////////////////////////////////////////////////////////*/

    /// @notice Conditional Tokens Framework
    IConditionalTokens public immutable ctf;

    /// @notice Optimistic Oracle
    IOptimisticOracleV2 public immutable optimisticOracle;

    /// @notice Collateral Whitelist
    IAddressWhitelist public immutable collateralWhitelist;

    /// @notice Time period after which an admin can emergency resolve a condition
    uint256 public constant emergencySafetyPeriod = 2 days;

    /// @notice Unique query identifier for the Optimistic Oracle
    bytes32 public constant yesOrNoIdentifier = "YES_OR_NO_QUERY";

    /// @notice Maximum ancillary data length
    uint256 public constant maxAncillaryData = 8139;

    /// @notice Mapping of questionID to QuestionData
    mapping(bytes32 => QuestionData) public questions;

    modifier onlyOptimisticOracle() {
        if (msg.sender != address(optimisticOracle)) revert NotOptimisticOracle();
        _;
    }

    constructor(address _ctf, address _finder) {
        ctf = IConditionalTokens(_ctf);
        IFinder finder = IFinder(_finder);
        optimisticOracle = IOptimisticOracleV2(finder.getImplementationAddress("OptimisticOracleV2"));
        collateralWhitelist = IAddressWhitelist(finder.getImplementationAddress("CollateralWhitelist"));
    }

    /*///////////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS 
    //////////////////////////////////////////////////////////////////*/

    /// @notice Initializes a question
    /// Atomically adds the question to the Adapter, prepares it on the ConditionalTokens Framework and requests a price from the OO.
    /// If a reward is provided, the caller must have approved the Adapter as spender and have enough rewardToken
    /// to pay for the price request.
    /// Prepares the condition using the Adapter as the oracle and a fixed outcome slot count = 2.
    /// @param ancillaryData - Data used to resolve a question
    /// @param rewardToken   - ERC20 token address used for payment of rewards and fees
    /// @param reward        - Reward offered to a successful proposer
    /// @param proposalBond  - Bond required to be posted by OO proposers/disputers. If 0, the default OO bond is used.
    function initialize(bytes memory ancillaryData, address rewardToken, uint256 reward, uint256 proposalBond)
        external
        returns (bytes32 questionID)
    {
        if (!collateralWhitelist.isOnWhitelist(rewardToken)) revert UnsupportedToken();

        bytes memory data = AncillaryDataLib._appendAncillaryData(msg.sender, ancillaryData);
        if (ancillaryData.length == 0 || data.length > maxAncillaryData) revert InvalidAncillaryData();

        questionID = keccak256(data);

        if (_isInitialized(questions[questionID])) revert Initialized();

        uint256 timestamp = block.timestamp;

        // Persist the question parameters in storage
        _saveQuestion(msg.sender, questionID, data, timestamp, rewardToken, reward, proposalBond);

        // Prepare the question on the CTF
        ctf.prepareCondition(address(this), questionID, 2);

        // Request a price for the question from the OO
        _requestPrice(msg.sender, timestamp, data, rewardToken, reward, proposalBond);

        emit QuestionInitialized(questionID, timestamp, msg.sender, data, rewardToken, reward, proposalBond);
    }

    /// @notice Checks whether a questionID is ready to be resolved
    /// @param questionID - The unique questionID
    function ready(bytes32 questionID) public view returns (bool) {
        return _ready(questions[questionID]);
    }

    /// @notice Resolves a question
    /// Pulls price information from the OO and resolves the underlying CTF market.
    /// Reverts if price is not available on the OO
    /// Resets the question if the price returned by the OO is the Ignore price
    /// @param questionID - The unique questionID of the question
    function resolve(bytes32 questionID) external {
        QuestionData storage questionData = questions[questionID];

        if (!_isInitialized(questionData)) revert NotInitialized();
        if (questionData.paused) revert Paused();
        if (questionData.resolved) revert Resolved();
        if (!_hasPrice(questionData)) revert NotReadyToResolve();

        // Resolve the underlying market
        return _resolve(questionID, questionData);
    }

    /// @notice Retrieves the expected payout array of the question
    /// @param questionID - The unique questionID of the question
    function getExpectedPayouts(bytes32 questionID) public view returns (uint256[] memory) {
        QuestionData storage questionData = questions[questionID];

        if (!_isInitialized(questionData)) revert NotInitialized();
        if (!_hasPrice(questionData)) revert PriceNotAvailable();

        // Fetches price from OO
        int256 price = optimisticOracle.getRequest(
            address(this), yesOrNoIdentifier, questionData.requestTimestamp, questionData.ancillaryData
        ).resolvedPrice;

        return _constructPayouts(price);
    }

    /// @notice Callback which is executed on dispute
    /// Resets the question and sends out a new price request to the OO
    /// @param ancillaryData    - Ancillary data of the request
    function priceDisputed(bytes32, uint256, bytes memory ancillaryData, uint256) external onlyOptimisticOracle {
        bytes32 questionID = keccak256(ancillaryData);
        QuestionData storage questionData = questions[questionID];

        if (questionData.reset) return;

        // If the question has not been reset previously, reset the question
        // Ensures that there are at most 2 OO Requests at a time for a question
        _reset(address(this), questionID, questionData);
    }

    /// @notice Checks if a question is initialized
    /// @param questionID - The unique questionID
    function isInitialized(bytes32 questionID) public view returns (bool) {
        return _isInitialized(questions[questionID]);
    }

    /// @notice Checks if a question has been flagged for emergency resolution
    /// @param questionID - The unique questionID
    function isFlagged(bytes32 questionID) public view returns (bool) {
        return _isFlagged(questions[questionID]);
    }

    /// @notice Gets the QuestionData for the given questionID
    /// @param questionID - The unique questionID
    function getQuestion(bytes32 questionID) external view returns (QuestionData memory) {
        return questions[questionID];
    }

    /*////////////////////////////////////////////////////////////////////
                            ADMIN ONLY FUNCTIONS 
    ///////////////////////////////////////////////////////////////////*/

    /// @notice Flags a market for emergency resolution
    /// @param questionID - The unique questionID of the question
    function flag(bytes32 questionID) external onlyAdmin {
        QuestionData storage questionData = questions[questionID];

        if (!_isInitialized(questionData)) revert NotInitialized();
        if (_isFlagged(questionData)) revert Flagged();

        questionData.emergencyResolutionTimestamp = block.timestamp + emergencySafetyPeriod;
        questionData.paused = true;

        emit QuestionFlagged(questionID);
    }

    /// @notice Allows an admin to reset a question, sending out a new price request to the OO.
    /// Failsafe to be used if the priceDisputed callback reverts during execution.
    /// @param questionID - The unique questionID
    function reset(bytes32 questionID) external onlyAdmin {
        QuestionData storage questionData = questions[questionID];
        if (!_isInitialized(questionData)) revert NotInitialized();
        if (questionData.resolved) revert Resolved();

        // Reset the question, paying for the price request from the caller
        _reset(msg.sender, questionID, questionData);
    }

    /// @notice Allows an admin to resolve a CTF market in an emergency
    /// @param questionID   - The unique questionID of the question
    /// @param payouts      - Array of position payouts for the referenced question
    function emergencyResolve(bytes32 questionID, uint256[] calldata payouts) external onlyAdmin {
        QuestionData storage questionData = questions[questionID];

        if (payouts.length != 2) revert InvalidPayouts();
        if (!_isInitialized(questionData)) revert NotInitialized();
        if (!_isFlagged(questionData)) revert NotFlagged();
        if (block.timestamp < questionData.emergencyResolutionTimestamp) revert SafetyPeriodNotPassed();

        questionData.resolved = true;
        ctf.reportPayouts(questionID, payouts);
        emit QuestionEmergencyResolved(questionID, payouts);
    }

    /// @notice Allows an admin to pause market resolution in an emergency
    /// @param questionID - The unique questionID of the question
    function pause(bytes32 questionID) external onlyAdmin {
        QuestionData storage questionData = questions[questionID];

        if (!_isInitialized(questionData)) revert NotInitialized();

        questionData.paused = true;
        emit QuestionPaused(questionID);
    }

    /// @notice Allows an admin to unpause market resolution in an emergency
    /// @param questionID - The unique questionID of the question
    function unpause(bytes32 questionID) external onlyAdmin {
        QuestionData storage questionData = questions[questionID];
        if (!_isInitialized(questionData)) revert NotInitialized();

        questionData.paused = false;
        emit QuestionUnpaused(questionID);
    }

    /*///////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS 
    //////////////////////////////////////////////////////////////////*/

    function _ready(QuestionData storage questionData) internal view returns (bool) {
        if (!_isInitialized(questionData)) return false;
        if (questionData.paused) return false;
        if (questionData.resolved) return false;
        return _hasPrice(questionData);
    }

    function _saveQuestion(
        address creator,
        bytes32 questionID,
        bytes memory ancillaryData,
        uint256 requestTimestamp,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond
    ) internal {
        questions[questionID] = QuestionData({
            requestTimestamp: requestTimestamp,
            reward: reward,
            proposalBond: proposalBond,
            emergencyResolutionTimestamp: 0,
            resolved: false,
            paused: false,
            reset: false,
            rewardToken: rewardToken,
            creator: creator,
            ancillaryData: ancillaryData
        });
    }

    /// @notice Request a price from the Optimistic Oracle
    /// Transfers reward token from the requestor if non-zero reward is specified
    /// @param requestor        - Address of the requestor
    /// @param requestTimestamp - Timestamp used in the OO request
    /// @param ancillaryData    - Data used to resolve a question
    /// @param rewardToken      - Address of the reward token
    /// @param reward           - Reward amount, denominated in rewardToken
    /// @param bond             - Bond amount used, denominated in rewardToken
    function _requestPrice(
        address requestor,
        uint256 requestTimestamp,
        bytes memory ancillaryData,
        address rewardToken,
        uint256 reward,
        uint256 bond
    ) internal {
        if (reward > 0) {
            // If the requestor is not the Adapter, the requestor pays for the price request
            // If not, the Adapter pays for the price request
            if (requestor != address(this)) {
                TransferHelper._transferFromERC20(rewardToken, requestor, address(this), reward);
            }

            // Approve the OO as spender on the reward token from the Adapter
            if (IERC20(rewardToken).allowance(address(this), address(optimisticOracle)) < reward) {
                IERC20(rewardToken).approve(address(optimisticOracle), type(uint256).max);
            }
        }

        // Send a price request to the Optimistic oracle
        optimisticOracle.requestPrice(yesOrNoIdentifier, requestTimestamp, ancillaryData, IERC20(rewardToken), reward);

        // Ensure the price request is event based
        optimisticOracle.setEventBased(yesOrNoIdentifier, requestTimestamp, ancillaryData);

        // Ensure that the dispute callback flag is set
        optimisticOracle.setCallbacks(
            yesOrNoIdentifier,
            requestTimestamp,
            ancillaryData,
            false, // DO NOT set callback on priceProposed
            true, // DO set callback on priceDisputed
            false // DO NOT set callback on priceSettled
        );

        // Update the proposal bond on the Optimistic oracle if necessary
        if (bond > 0) optimisticOracle.setBond(yesOrNoIdentifier, requestTimestamp, ancillaryData, bond);
    }

    /// @notice Reset the question by updating the requestTimestamp field and sending a new price request to the OO
    /// @param questionID - The unique questionID
    function _reset(address requestor, bytes32 questionID, QuestionData storage questionData) internal {
        uint256 requestTimestamp = block.timestamp;
        // Update the question parameters in storage
        questionData.requestTimestamp = requestTimestamp;
        questionData.reset = true;

        // Send out a new price request with the new timestamp
        _requestPrice(
            requestor,
            requestTimestamp,
            questionData.ancillaryData,
            questionData.rewardToken,
            questionData.reward,
            questionData.proposalBond
        );

        emit QuestionReset(questionID);
    }

    /// @notice Resolves the underlying CTF market
    /// @param questionID   - The unique questionID of the question
    /// @param questionData - The question data parameters
    function _resolve(bytes32 questionID, QuestionData storage questionData) internal {
        // Get the price from the OO
        int256 price = optimisticOracle.settleAndGetPrice(
            yesOrNoIdentifier, questionData.requestTimestamp, questionData.ancillaryData
        );

        // If the OO returns the ignore price, reset the question
        if (price == _ignorePrice()) return _reset(address(this), questionID, questionData);

        // Construct the payout array for the question
        uint256[] memory payouts = _constructPayouts(price);

        // Set resolved flag
        questionData.resolved = true;

        // Resolve the underlying CTF market
        ctf.reportPayouts(questionID, payouts);

        emit QuestionResolved(questionID, price, payouts);
    }

    function _hasPrice(QuestionData storage questionData) internal view returns (bool) {
        return optimisticOracle.hasPrice(
            address(this), yesOrNoIdentifier, questionData.requestTimestamp, questionData.ancillaryData
        );
    }

    function _isFlagged(QuestionData storage questionData) internal view returns (bool) {
        return questionData.emergencyResolutionTimestamp > 0;
    }

    function _isInitialized(QuestionData storage questionData) internal view returns (bool) {
        return questionData.ancillaryData.length > 0;
    }

    /// @notice Construct the payout array given the price
    /// @param price - The price retrieved from the OO
    function _constructPayouts(int256 price) internal pure returns (uint256[] memory) {
        // Payouts: [YES, NO]
        uint256[] memory payouts = new uint256[](2);
        // Valid prices are 0, 0.5 and 1
        if (price != 0 && price != 0.5 ether && price != 1 ether) revert InvalidOOPrice();

        if (price == 0) {
            // NO: Report [Yes, No] as [0, 1]
            payouts[0] = 0;
            payouts[1] = 1;
        } else if (price == 0.5 ether) {
            // UNKNOWN: Report [Yes, No] as [1, 1], 50/50
            payouts[0] = 1;
            payouts[1] = 1;
        } else {
            // YES: Report [Yes, No] as [1, 0]
            payouts[0] = 1;
            payouts[1] = 0;
        }
        return payouts;
    }

    function _ignorePrice() internal pure returns (int256) {
        return type(int256).min;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

interface IAddressWhitelist {
    function addToWhitelist(address) external;

    function removeFromWhitelist(address) external;

    function isOnWhitelist(address) external view returns (bool);

    function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAuthEE {
    error NotAdmin();

    /// @notice Emitted when a new admin is added
    event NewAdmin(address indexed admin, address indexed newAdminAddress);

    /// @notice Emitted when an admin is removed
    event RemovedAdmin(address indexed admin, address indexed removedAdmin);
}

interface IAuth is IAuthEE {
    function isAdmin(address) external view returns (bool);

    function addAdmin(address) external;

    function removeAdmin(address) external;

    function renounceAdmin() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IConditionalTokens {
    /// Mapping key is an condition ID. Value represents numerators of the payout vector associated with the condition. This array is initialized with a length equal to the outcome slot count. E.g. Condition with 3 outcomes [A, B, C] and two of those correct [0.5, 0.5, 0]. In Ethereum there are no decimal values, so here, 0.5 is represented by fractions like 1/2 == 0.5. That's why we need numerator and denominator values. Payout numerators are also used as a check of initialization. If the numerators array is empty (has length zero), the condition was not created/prepared. See getOutcomeSlotCount.
    function payoutNumerators(bytes32) external returns (uint256[] memory);

    /// Denominator is also used for checking if the condition has been resolved. If the denominator is non-zero, then the condition has been resolved.
    function payoutDenominator(bytes32) external returns (uint256);

    /// @dev This function prepares a condition by initializing a payout vector associated with the condition.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function prepareCondition(address oracle, bytes32 questionId, uint256 outcomeSlotCount) external;

    /// @dev Called by the oracle for reporting results of conditions. Will set the payout vector for the condition with the ID ``keccak256(abi.encodePacked(oracle, questionId, outcomeSlotCount))``, where oracle is the message sender, questionId is one of the parameters of this function, and outcomeSlotCount is the length of the payouts parameter, which contains the payoutNumerators for each outcome slot of the condition.
    /// @param questionId The question ID the oracle is answering for
    /// @param payouts The oracle's answer
    function reportPayouts(bytes32 questionId, uint256[] calldata payouts) external;

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function mergePositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function redeemPositions(
        IERC20 collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata indexSets
    ) external;

    /// @dev Gets the outcome slot count of a condition.
    /// @param conditionId ID of the condition.
    /// @return Number of outcome slots associated with a condition, or zero if condition has not been prepared yet.
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint256);

    /// @dev Constructs a condition ID from an oracle, a question ID, and the outcome slot count for the question.
    /// @param oracle The account assigned to report the result for the prepared condition.
    /// @param questionId An identifier for the question to be answered by the oracle.
    /// @param outcomeSlotCount The number of outcome slots which should be used for this condition. Must not exceed 256.
    function getConditionId(address oracle, bytes32 questionId, uint256 outcomeSlotCount)
        external
        pure
        returns (bytes32);

    /// @dev Constructs an outcome collection ID from a parent collection and an outcome collection.
    /// @param parentCollectionId Collection ID of the parent outcome collection, or bytes32(0) if there's no parent.
    /// @param conditionId Condition ID of the outcome collection to combine with the parent outcome collection.
    /// @param indexSet Index set of the outcome collection to combine with the parent outcome collection.
    function getCollectionId(bytes32 parentCollectionId, bytes32 conditionId, uint256 indexSet)
        external
        view
        returns (bytes32);

    /// @dev Constructs a position ID from a collateral token and an outcome collection. These IDs are used as the ERC-1155 ID for this contract.
    /// @param collateralToken Collateral token which backs the position.
    /// @param collectionId ID of the outcome collection associated with this position.
    function getPositionId(IERC20 collateralToken, bytes32 collectionId) external pure returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface IFinder {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

struct RequestSettings {
    bool eventBased; // True if the request is set to be event-based.
    bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
    bool callbackOnPriceProposed; // True if callbackOnPriceProposed callback is required.
    bool callbackOnPriceDisputed; // True if callbackOnPriceDisputed callback is required.
    bool callbackOnPriceSettled; // True if callbackOnPriceSettled callback is required.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
}

// Struct representing a price request.
struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    RequestSettings requestSettings; // Custom settings associated with a request.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
}

/// @title Optimistic Oracle V2 Interface
interface IOptimisticOracleV2 {
    /// @notice Requests a new price.
    /// @param identifier price identifier being requested.
    /// @param timestamp timestamp of the price being requested.
    /// @param ancillaryData ancillary data representing additional args being passed with the price request.
    /// @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
    /// @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
    ///               which could make sense if the contract requests and proposes the value in the same call or
    ///               provides its own reward system.
    /// @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
    /// This can be changed with a subsequent call to setBond().
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(address requester, bytes32 identifier, uint256 timestamp, bytes memory ancillaryData)
        external
        returns (uint256 totalBond);

    /// @notice Set the proposal bond associated with a price request.
    /// @param identifier price identifier to identify the existing request.
    /// @param timestamp timestamp to identify the existing request.
    /// @param ancillaryData ancillary data of the price being requested.
    /// @param bond custom bond amount to set.
    /// @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
    /// changed again with a subsequent call to setBond().
    function setBond(bytes32 identifier, uint256 timestamp, bytes memory ancillaryData, uint256 bond)
        external
        returns (uint256 totalBond);

    /// @notice Sets the request to be an "event-based" request.
    /// @dev Calling this method has a few impacts on the request:
    ///
    /// 1. The timestamp at which the request is evaluated is the time of the proposal, not the timestamp associated
    ///    with the request.
    ///
    /// 2. The proposer cannot propose the "too early" value (TOO_EARLY_RESPONSE). This is to ensure that a proposer who
    ///    prematurely proposes a response loses their bond.
    ///
    /// 3. RefundoOnDispute is automatically set, meaning disputes trigger the reward to be automatically refunded to
    ///    the requesting contract.
    ///
    /// @param identifier price identifier to identify the existing request.
    /// @param timestamp timestamp to identify the existing request.
    /// @param ancillaryData ancillary data of the price being requested.
    function setEventBased(bytes32 identifier, uint256 timestamp, bytes memory ancillaryData) external;

    /// @notice Sets which callbacks should be enabled for the request.
    /// @param identifier price identifier to identify the existing request.
    /// @param timestamp timestamp to identify the existing request.
    /// @param ancillaryData ancillary data of the price being requested.
    /// @param callbackOnPriceProposed whether to enable the callback onPriceProposed.
    /// @param callbackOnPriceDisputed whether to enable the callback onPriceDisputed.
    /// @param callbackOnPriceSettled whether to enable the callback onPriceSettled.
    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external;

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(address requester, bytes32 identifier, uint256 timestamp, bytes memory ancillaryData)
        external
        returns (uint256 payout);

    /// @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
    /// or settleable. Note: this method is not view so that this call may actually settle the price request if it
    /// hasn't been settled.
    /// @param identifier price identifier to identify the existing request.
    /// @param timestamp timestamp to identify the existing request.
    /// @param ancillaryData ancillary data of the price being requested.
    /// @return resolved price.
    ////
    function settleAndGetPrice(bytes32 identifier, uint256 timestamp, bytes memory ancillaryData)
        external
        returns (int256);

    /// @notice Gets the current data structure containing all information about a price request.
    /// @param requester sender of the initial price request.
    /// @param identifier price identifier to identify the existing request.
    /// @param timestamp timestamp to identify the existing request.
    /// @param ancillaryData ancillary data of the price being requested.
    /// @return the Request data structure.
    ////
    function getRequest(address requester, bytes32 identifier, uint256 timestamp, bytes memory ancillaryData)
        external
        view
        returns (Request memory);

    /// @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
    /// @param requester sender of the initial price request.
    /// @param identifier price identifier to identify the existing request.
    /// @param timestamp timestamp to identify the existing request.
    /// @param ancillaryData ancillary data of the price being requested.
    /// @return true if price has resolved or settled, false otherwise.
    function hasPrice(address requester, bytes32 identifier, uint256 timestamp, bytes memory ancillaryData)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Optimistic Requester
interface IOptimisticRequester {
    /// @notice Callback for disputes.
    /// @param identifier price identifier being requested.
    /// @param timestamp timestamp of the price being requested.
    /// @param ancillaryData ancillary data of the price being requested.
    /// @param refund refund received in the case that refundOnDispute was enabled.
    function priceDisputed(bytes32 identifier, uint256 timestamp, bytes memory ancillaryData, uint256 refund)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct QuestionData {
    /// @notice Request timestamp, set when a request is made to the Optimistic Oracle
    /// @dev Used to identify the request and NOT used by the DVM to determine validity
    uint256 requestTimestamp;
    /// @notice Reward offered to a successful proposer
    uint256 reward;
    /// @notice Additional bond required by Optimistic oracle proposers/disputers
    uint256 proposalBond;
    /// @notice Emergency resolution timestamp, set when a market is flagged for emergency resolution
    uint256 emergencyResolutionTimestamp;
    /// @notice Flag marking whether a question is resolved
    bool resolved;
    /// @notice Flag marking whether a question is paused
    bool paused;
    /// @notice Flag marking whether a question has been reset. A question can only be reset once
    bool reset;
    /// @notice ERC20 token address used for payment of rewards, proposal bonds and fees
    address rewardToken;
    /// @notice The address of the question creator
    address creator;
    /// @notice Data used to resolve a condition
    bytes ancillaryData;
}

interface IUmaCtfAdapterEE {
    error NotInitialized();
    error NotFlagged();
    error NotReadyToResolve();
    error Resolved();
    error Initialized();
    error UnsupportedToken();
    error Flagged();
    error Paused();
    error SafetyPeriodNotPassed();
    error PriceNotAvailable();
    error InvalidAncillaryData();
    error NotOptimisticOracle();
    error InvalidOOPrice();
    error InvalidPayouts();

    /// @notice Emitted when a questionID is initialized
    event QuestionInitialized(
        bytes32 indexed questionID,
        uint256 indexed requestTimestamp,
        address indexed creator,
        bytes ancillaryData,
        address rewardToken,
        uint256 reward,
        uint256 proposalBond
    );

    /// @notice Emitted when a question is paused by an authorized user
    event QuestionPaused(bytes32 indexed questionID);

    /// @notice Emitted when a question is unpaused by an authorized user
    event QuestionUnpaused(bytes32 indexed questionID);

    /// @notice Emitted when a question is flagged by an admin for emergency resolution
    event QuestionFlagged(bytes32 indexed questionID);

    /// @notice Emitted when a question is reset
    event QuestionReset(bytes32 indexed questionID);

    /// @notice Emitted when a question is resolved
    event QuestionResolved(bytes32 indexed questionID, int256 indexed settledPrice, uint256[] payouts);

    /// @notice Emitted when a question is emergency resolved
    event QuestionEmergencyResolved(bytes32 indexed questionID, uint256[] payouts);
}

interface IUmaCtfAdapter is IUmaCtfAdapterEE {
    function initialize(bytes memory, address, uint256, uint256) external returns (bytes32);

    function resolve(bytes32) external;

    function flag(bytes32) external;

    function reset(bytes32) external;

    function pause(bytes32) external;

    function unpause(bytes32) external;

    function getQuestion(bytes32) external returns (QuestionData memory);

    function ready(bytes32) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library AncillaryDataLib {
    string private constant initializerPrefix = ",initializer:";

    /// @notice Appends the initializer address to the ancillaryData
    /// @param initializer      - The initializer address
    /// @param ancillaryData    - The ancillary data
    function _appendAncillaryData(address initializer, bytes memory ancillaryData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(ancillaryData, initializerPrefix, _toUtf8BytesAddress(initializer));
    }

    /// @notice Returns a UTF8-encoded address
    /// Source: UMA Protocol's AncillaryDataLib
    /// https://github.com/UMAprotocol/protocol/blob/9967e70e7db3f262fde0dc9d89ea04d4cd11ed97/packages/core/contracts/common/implementation/AncillaryData.sol
    /// Will return address in all lower case characters and without the leading 0x.
    /// @param addr - The address to encode.
    function _toUtf8BytesAddress(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _toUtf8Bytes32Bottom(bytes32(bytes20(addr)) >> 128), bytes8(_toUtf8Bytes32Bottom(bytes20(addr)))
        );
    }

    /// @notice Converts the bottom half of a bytes32 input to hex in a highly gas-optimized way.
    /// Source: the brilliant implementation at https://gitter.im/ethereum/solidity?at=5840d23416207f7b0ed08c9b.
    function _toUtf8Bytes32Bottom(bytes32 bytesIn) private pure returns (bytes32) {
        unchecked {
            uint256 x = uint256(bytesIn);

            // Nibble interleave
            x = x & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
            x = (x | (x * 2 ** 64)) & 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
            x = (x | (x * 2 ** 32)) & 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
            x = (x | (x * 2 ** 16)) & 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
            x = (x | (x * 2 ** 8)) & 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
            x = (x | (x * 2 ** 4)) & 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;

            // Hex encode
            uint256 h = (x & 0x0808080808080808080808080808080808080808080808080808080808080808) / 8;
            uint256 i = (x & 0x0404040404040404040404040404040404040404040404040404040404040404) / 4;
            uint256 j = (x & 0x0202020202020202020202020202020202020202020202020202020202020202) / 2;
            x = x + (h & (i | j)) * 0x27 + 0x3030303030303030303030303030303030303030303030303030303030303030;

            // Return the result.
            return bytes32(x);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { SafeTransferLib, ERC20 } from "solmate/utils/SafeTransferLib.sol";

/// @title TransferHelper
/// @notice Helper library to transfer tokens
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param amount   - The amount to be transferred
    function _transferFromERC20(address token, address from, address to, uint256 amount) internal {
        SafeTransferLib.safeTransferFrom(ERC20(token), from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IAuth } from "../interfaces/IAuth.sol";

/// @title Auth
/// @notice Provides access control modifiers
abstract contract Auth is IAuth {
    /// @notice Auth
    mapping(address => uint256) public admins;

    modifier onlyAdmin() {
        if (admins[msg.sender] != 1) revert NotAdmin();
        _;
    }

    constructor() {
        admins[msg.sender] = 1;
    }

    /// @notice Adds an Admin
    /// @param admin - The address of the admin
    function addAdmin(address admin) external onlyAdmin {
        admins[admin] = 1;
        emit NewAdmin(msg.sender, admin);
    }

    /// @notice Removes an admin
    /// @param admin - The address of the admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = 0;
        emit RemovedAdmin(msg.sender, admin);
    }

    /// @notice Renounces Admin privileges from the caller
    function renounceAdmin() external onlyAdmin {
        admins[msg.sender] = 0;
        emit RemovedAdmin(msg.sender, msg.sender);
    }

    /// @notice Checks if an address is an admin
    /// @param addr - The address to be checked
    function isAdmin(address addr) external view returns (bool) {
        return admins[addr] == 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Bulletin Board
/// @notice A registry containing ancillary data updates
abstract contract BulletinBoard {
    struct AncillaryDataUpdate {
        uint256 timestamp;
        bytes update;
    }

    /// @notice Mapping to an array of Ancillary data updates for questions
    mapping(bytes32 => AncillaryDataUpdate[]) public updates;

    /// @notice Emitted when an ancillary data update is posted
    event AncillaryDataUpdated(bytes32 indexed questionID, address indexed owner, bytes update);

    /// @notice Post an update for the question
    /// Anyone can post an update for any questionID, but users should only consider updates posted by the question creator
    /// @param questionID   - The unique questionID
    /// @param update       - The update for the question
    function postUpdate(bytes32 questionID, bytes memory update) external {
        bytes32 id = keccak256(abi.encode(questionID, msg.sender));
        updates[id].push(AncillaryDataUpdate({timestamp: block.timestamp, update: update}));
    }

    /// @notice Gets all updates for a questionID and owner
    /// @param questionID   - The unique questionID
    /// @param owner        - The address of the question initializer
    function getUpdates(bytes32 questionID, address owner) public view returns (AncillaryDataUpdate[] memory) {
        return updates[keccak256(abi.encode(questionID, owner))];
    }

    /// @notice Gets the latest update for a questionID and owner
    /// @param questionID   - The unique questionID
    /// @param owner        - The address of the question initializer
    function getLatestUpdate(bytes32 questionID, address owner) external view returns (AncillaryDataUpdate memory) {
        AncillaryDataUpdate[] memory currentUpdates = getUpdates(questionID, owner);
        if (currentUpdates.length == 0) return AncillaryDataUpdate({timestamp: 0, update: ""});
        return currentUpdates[currentUpdates.length - 1];
    }
}