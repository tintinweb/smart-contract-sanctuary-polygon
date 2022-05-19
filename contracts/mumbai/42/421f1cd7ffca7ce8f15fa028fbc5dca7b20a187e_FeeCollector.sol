// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// constants
import { FEE_SCALE } from "./constants.sol";

// libs
import "./RoyaltySharesLib.sol";

// interfaces
import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/extensions/ILSP7CompatibilityForERC20.sol";
import "./IFeeCollector.sol";
import "./IFeeCollectorRevenueShareCallback.sol";

// modules
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../security/LockGuard.sol";

// a pull based fee collection for creators / platform / referrers of CardToken sales
contract FeeCollector is Context, Ownable, LockGuard, IFeeCollector {
    //
    // --- Errors
    //

    error FeeCollectorPlatformFeeReceiverRequired();
    error FeeCollectorRevenueShareFeesRequired(
        uint16 platform,
        uint16 creator,
        uint16 referral
    );
    error FeeCollectorRevenueShareFeesTooHigh(uint256 maxFeeSum);
    error FeeCollectorShareRevenuePaymentFailed(
        uint256 expectedAmount,
        uint256 receivedAmount
    );

    //
    // --- Storage
    //

    RevenueShareFees private _revenueShareFees;

    // fees are capped at 5% = 500 basis points
    uint256 private constant MAX_REVENUE_SHARE_FEE_SUM = 5_00;
    // base revenue share fees
    uint256 private _baseRevenueShareFee;

    address private _platformFeeReceiver;

    // fee receive address => fee token address => fees available
    mapping(address => mapping(address => uint256)) public override feeBalance;

    //
    // --- Initialize
    //

    constructor(address platformFeeReceiver_) {
        setPlatformFeeReceiver(platformFeeReceiver_);

        // fees are measured in basis points
        // 1% = 100 basis points
        setRevenueShareFees(1_00, 3_00, 1_00);
    }

    //
    // --- Fee queries
    //

    function revenueShareFees()
        public
        view
        override
        returns (RevenueShareFees memory)
    {
        return _revenueShareFees;
    }

    function baseRevenueShareFee() public view override returns (uint256) {
        return _baseRevenueShareFee;
    }

    function platformFeeReceiver() public view override returns (address) {
        return _platformFeeReceiver;
    }

    //
    // --- Revenue Share logic
    //

    function shareRevenue(
        address feeToken,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata creatorRoyalties,
        bytes calldata dataForCallback
    ) external override takeLock returns (uint256) {
        // if we are called with a zero amount to share then just return
        if (amount == 0) {
            return amount;
        }

        (
            uint256 platformFeeAmount,
            uint256 creatorFeeAmount,
            uint256 referralFeeAmount,
            uint256 totalFeeAmount
        ) = _calculateRevenueShare(amount, referrer);

        // take snapshots and perform callback
        uint256 preBalance;
        uint256 postBalance;

        if (feeToken == address(0)) {
            preBalance = address(this).balance;
            IFeeCollectorRevenueShareCallback(msg.sender).revenueShareCallback(
                totalFeeAmount,
                dataForCallback
            );
            postBalance = address(this).balance;
        } else {
            preBalance = ILSP7CompatibilityForERC20(feeToken).balanceOf(
                address(this)
            );
            IFeeCollectorRevenueShareCallback(msg.sender).revenueShareCallback(
                totalFeeAmount,
                dataForCallback
            );
            postBalance = ILSP7CompatibilityForERC20(feeToken).balanceOf(
                address(this)
            );
        }

        // ensure the expected amount of tokens was sent to cover revenue share fees
        uint256 feeReceived = postBalance - preBalance;
        if (feeReceived < totalFeeAmount) {
            revert FeeCollectorShareRevenuePaymentFailed(
                totalFeeAmount,
                postBalance - preBalance
            );
        }

        // if additional payment was received, in the case of FeeReceiver clearing any dust, add it
        // to the platformFee
        if (feeReceived > totalFeeAmount) {
            platformFeeAmount += feeReceived - totalFeeAmount;
        }

        // update fee balances
        _depositFee(feeToken, _platformFeeReceiver, platformFeeAmount);
        _depositRoyaltiesFee(feeToken, creatorFeeAmount, creatorRoyalties);
        _depositFee(feeToken, referrer, referralFeeAmount);

        return totalFeeAmount;
    }

    function _calculateRevenueShare(uint256 amount, address referrer)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 platformFeeAmount = _calculateFee(
            amount,
            _revenueShareFees.platform
        );
        uint256 creatorFeeAmount = _calculateFee(
            amount,
            _revenueShareFees.creator
        );
        uint256 referralFeeAmount = 0;
        if (referrer != address(0)) {
            referralFeeAmount = _calculateFee(
                amount,
                _revenueShareFees.referral
            );
        }

        uint256 totalFeeAmount = platformFeeAmount +
            creatorFeeAmount +
            referralFeeAmount;

        return (
            platformFeeAmount,
            creatorFeeAmount,
            referralFeeAmount,
            totalFeeAmount
        );
    }

    function _depositFee(
        address feeToken,
        address receiver,
        uint256 amount
    ) internal {
        if (amount > 0) {
            feeBalance[receiver][feeToken] += amount;
        }
    }

    function _depositRoyaltiesFee(
        address feeToken,
        uint256 amountForRoyalty,
        RoyaltySharesLib.RoyaltyShare[] memory creatorRoyalties
    ) internal {
        uint256 royaltySum = 0;
        for (uint256 i = creatorRoyalties.length - 1; i > 0; i--) {
            RoyaltySharesLib.RoyaltyShare
                memory creatorRoyalty = creatorRoyalties[i];
            uint256 royaltyAmountForCreator = _calculateFee(
                amountForRoyalty,
                creatorRoyalty.share
            );
            _depositFee(
                feeToken,
                creatorRoyalty.receiver,
                royaltyAmountForCreator
            );
            royaltySum += royaltyAmountForCreator;
        }

        // the first creator entry will receive any dust from royalty fee calculation
        _depositFee(
            feeToken,
            creatorRoyalties[0].receiver,
            amountForRoyalty - royaltySum
        );
    }

    function _calculateFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_SCALE;
    }

    //
    // --- Withdrawl logic
    //

    // allow the _msgSender to receive tokens
    function withdrawTokens(address[] calldata feeTokenList) public override {
        _withdrawTokens(_msgSender(), feeTokenList);
    }

    // allow anyone to have many addresses receive many tokens
    function withdrawTokensForMany(
        address[] calldata accountList,
        address[] calldata feeTokenList
    ) public override {
        for (uint256 i = 0; i < accountList.length; i++) {
            _withdrawTokens(accountList[i], feeTokenList);
        }
    }

    function _withdrawTokens(address receiver, address[] calldata feeTokenList)
        internal
    {
        for (uint256 i = 0; i < feeTokenList.length; i++) {
            address feeToken = feeTokenList[i];
            uint256 amount = feeBalance[receiver][feeToken];

            if (amount > 0) {
                delete feeBalance[receiver][feeToken];
                if (feeToken == address(0)) {
                    // solhint-disable-next-line avoid-low-level-calls
                    (bool success, ) = payable(receiver).call{ value: amount }(
                        ""
                    );
                    require(success, "FeeCollector: transfer failed");
                } else {
                    ILSP7CompatibilityForERC20(feeToken).transfer(
                        receiver,
                        amount
                    );
                }
            }
        }
    }

    //
    // --- Storage updates
    //

    function setPlatformFeeReceiver(address platformFeeReceiver_)
        public
        onlyOwner
    {
        if (platformFeeReceiver_ == address(0)) {
            revert FeeCollectorPlatformFeeReceiverRequired();
        }

        _platformFeeReceiver = platformFeeReceiver_;
    }

    function setRevenueShareFees(
        uint16 platformFee,
        uint16 creatorFee,
        uint16 referralFee
    ) public onlyOwner {
        _revenueShareFees = _validateRevenueShareFees(
            platformFee,
            creatorFee,
            referralFee
        );

        _baseRevenueShareFee = platformFee + creatorFee;
    }

    function _validateRevenueShareFees(
        uint16 platformFee,
        uint16 creatorFee,
        uint16 referralFee
    ) internal pure returns (RevenueShareFees memory) {
        if (platformFee == 0 || creatorFee == 0 || referralFee == 0) {
            revert FeeCollectorRevenueShareFeesRequired(
                platformFee,
                creatorFee,
                referralFee
            );
        }

        if (
            platformFee + creatorFee + referralFee > MAX_REVENUE_SHARE_FEE_SUM
        ) {
            revert FeeCollectorRevenueShareFeesTooHigh(
                MAX_REVENUE_SHARE_FEE_SUM
            );
        }

        return
            RevenueShareFees({
                platform: platformFee,
                creator: creatorFee,
                referral: referralFee
            });
    }

    //
    // --- Fallbacks
    //

    // solhint-disable-next-line no-empty-blocks
    receive() external payable onlyWithLock {}
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/*
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// using basis points to describe fees
uint256 constant FEE_SCALE = 100_00;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

library RoyaltySharesLib {
    struct RoyaltyShare {
        address receiver;
        // using basis points to describe shares
        uint96 share;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "../ILSP7DigitalAsset.sol";

/**
 * @dev LSP8 extension, for compatibility for clients / tools that expect ERC20.
 */
interface ILSP7CompatibilityForERC20 is ILSP7DigitalAsset {
    /**
     * @notice To provide compatibility with indexing ERC20 events.
     * @dev Emitted when `amount` tokens is transferred from `from` to `to`.
     * @param from The sending address
     * @param to The receiving address
     * @param value The amount of tokens transfered.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice To provide compatibility with indexing ERC20 events.
     * @dev Emitted when `owner` enables `spender` for `value` tokens.
     * @param owner The account giving approval
     * @param spender The account receiving approval
     * @param value The amount of tokens `spender` has access to from `owner`
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*
     * @dev Compatible with ERC20 transfer
     * @param to The receiving address
     * @param amount The amount of tokens to transfer
     */
    function transfer(address to, uint256 amount) external;

    /*
     * @dev Compatible with ERC20 transferFrom
     * @param from The sending address
     * @param to The receiving address
     * @param amount The amount of tokens to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    /*
     * @dev Compatible with ERC20 approve
     * @param operator The address to approve for `amount`
     * @param amount The amount to approve
     */
    function approve(address operator, uint256 amount) external;

    /*
     * @dev Compatible with ERC20 allowance
     * @param tokenOwner The address of the token owner
     * @param operator The address approved by the `tokenOwner`
     * @return The amount `operator` is approved by `tokenOwner`
     */
    function allowance(address tokenOwner, address operator)
        external
        returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

// libs
import "./RoyaltySharesLib.sol";

interface IFeeCollector {
    //
    // --- Struct
    //

    // NOTE: packed into one storage slot
    struct RevenueShareFees {
        uint16 platform;
        uint16 creator;
        uint16 referral;
    }

    //
    // --- Fee queries
    //

    function feeBalance(address receiver, address token)
        external
        view
        returns (uint256);

    function revenueShareFees() external view returns (RevenueShareFees memory);

    function baseRevenueShareFee() external view returns (uint256);

    function platformFeeReceiver() external view returns (address);

    //
    // --- Fee logic
    //

    function shareRevenue(
        address token,
        uint256 amount,
        address referrer,
        RoyaltySharesLib.RoyaltyShare[] calldata creatorRoyalties,
        bytes calldata dataForCallback
    ) external returns (uint256);

    function withdrawTokens(address[] calldata tokenList) external;

    function withdrawTokensForMany(
        address[] calldata addressList,
        address[] calldata tokenList
    ) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

interface IFeeCollectorRevenueShareCallback {
    error RevenueShareCallbackInvalidSender();

    // @notice Called to `msg.sender` after FeeCollector.revenueShare is called.
    // @param totalFee The amount expected to be transfered to the FeeCollector after the callback is complete
    // @param dataForCallback The data provided when calling FeeCollector.revenueShare to process the callback
    function revenueShareCallback(
        uint256 totalFee,
        bytes memory dataForCallback
    ) external;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * FANZONE.io NFT implementation of the LUKSO LSP-8-IdentifiableDigitalAsset standard
 * for more see https://fanzone.io/nfts
 */

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `LockGuard` will make the {takeLock} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them. The {withLock} modifier can be used to ensure that the
 * lock has been taken, for functions that should only be called when a lock has been taken.
 *
 * Note that because there is a single `takeLock` guard, functions marked as
 * `takeLock` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract LockGuard {
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
    uint256 private constant _NOT_LOCKED = 1;
    uint256 private constant _LOCKED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_LOCKED;
    }

    modifier takeLock() {
        require(_status == _NOT_LOCKED, "LockGuard: already locked");

        // Any calls to takeLock after this point will fail
        _status = _LOCKED;
        _;

        _status = _NOT_LOCKED;
    }

    modifier onlyWithLock() {
        require(_status == _LOCKED, "LockGuard: need lock");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @dev Required interface of a LSP8 compliant contract.
 */
interface ILSP7DigitalAsset is IERC165, IERC725Y {
    // --- Events

    /**
     * @dev Emitted when `amount` tokens is transferred from `from` to `to`.
     * @param operator The address of operator sending tokens
     * @param from The address which tokens are sent
     * @param to The receiving address
     * @param amount The amount of tokens transferred
     * @param force When set to TRUE, `to` may be any address but
     * when set to FALSE `to` must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses
     */
    event Transfer(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bool force,
        bytes data
    );

    /**
     * @dev Emitted when `tokenOwner` enables `operator` for `amount` tokens.
     * @param operator The address authorized as an operator
     * @param tokenOwner The token owner
     * @param amount The amount of tokens `operator` address has access to from `tokenOwner`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenOwner,
        uint256 indexed amount
    );

    /**
     * @dev Emitted when `tokenOwner` disables `operator` for `amount` tokens.
     * @param operator The address revoked from operating
     * @param tokenOwner The token owner
     */
    event RevokedOperator(address indexed operator, address indexed tokenOwner);

    // --- Token queries

    /**
     * @dev Returns the number of decimals used to get its user representation
     * If the contract represents a NFT then 0 SHOULD be used, otherwise 18 is the common value
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the number of existing tokens.
     * @return The number of existing tokens
     */
    function totalSupply() external view returns (uint256);

    // --- Token owner queries

    /**
     * @dev Returns the number of tokens owned by `tokenOwner`.
     * @param tokenOwner The address to query
     * @return The number of tokens owned by this address
     */
    function balanceOf(address tokenOwner) external view returns (uint256);

    // --- Operator functionality

    /**
     * @param operator The address to authorize as an operator.
     * @param amount The amount of tokens operator has access to.
     * @dev Sets `amount` as the amount of tokens `operator` address has access to from callers tokens.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     *
     * Emits an {AuthorizedOperator} event.
     */
    function authorizeOperator(address operator, uint256 amount) external;

    /**
     * @param operator The address to revoke as an operator.
     * @dev Removes `operator` address as an operator of callers tokens.
     *
     * See {isOperatorFor}.
     *
     * Requirements
     *
     * - `operator` cannot be the zero address.
     *
     * Emits a {RevokedOperator} event.
     */
    function revokeOperator(address operator) external;

    /**
     * @param operator The address to query operator status for.
     * @param tokenOwner The token owner.
     * @return The amount of tokens `operator` address has access to from `tokenOwner`.
     * @dev Returns amount of tokens `operator` address has access to from `tokenOwner`.
     * Operators can send and burn tokens on behalf of their owners. The tokenOwner is their own
     * operator.
     */
    function isOperatorFor(address operator, address tokenOwner)
        external
        view
        returns (uint256);

    // --- Transfer functionality

    /**
     * @param from The sending address.
     * @param to The receiving address.
     * @param amount The amount of tokens to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers `amount` of tokens from `from` to `to`. The `force` parameter will be used
     * when notifying the token sender and receiver.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `amount` tokens must be owned by `from`.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address from,
        address to,
        uint256 amount,
        bool force,
        bytes memory data
    ) external;

    /**
     * @param from The list of sending addresses.
     * @param to The list of receiving addresses.
     * @param amount The amount of tokens to transfer.
     * @param force When set to TRUE, to may be any address but
     * when set to FALSE to must be a contract that supports LSP1 UniversalReceiver
     * @param data Additional data the caller wants included in the emitted event, and sent in the hooks to `from` and `to` addresses.
     *
     * @dev Transfers many tokens based on the list `from`, `to`, `amount`. If any transfer fails
     * the call will revert.
     *
     * Requirements:
     *
     * - `from`, `to`, `amount` lists are the same length.
     * - no values in `from` can be the zero address.
     * - no values in `to` can be the zero address.
     * - each `amount` tokens must be owned by `from`.
     * - If the caller is not `from`, it must be an operator for `from` with access to at least
     * `amount` tokens.
     *
     * Emits {Transfer} events.
     */
    function transferBatch(
        address[] memory from,
        address[] memory to,
        uint256[] memory amount,
        bool force,
        bytes[] memory data
    ) external;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
 * @title The interface for ERC725Y General key/value store
 * @dev ERC725Y provides the ability to set arbitrary key value sets that can be changed over time
 * It is intended to standardise certain keys value pairs to allow automated retrievals and interactions
 * from interfaces and other smart contracts
 */
interface IERC725Y {
    /**
     * @notice Emitted when data at a key is changed
     * @param key The key which value is set
     * @param value The value to set
     */
    event DataChanged(bytes32 indexed key, bytes value);

    /**
     * @notice Gets array of data at multiple given keys
     * @param keys The array of keys which values to retrieve
     * @return values The array of data stored at multiple keys
     */
    function getData(bytes32[] memory keys) external view returns (bytes[] memory values);

    /**
     * @param keys The array of keys which values to set
     * @param values The array of values to set
     * @dev Sets array of data at multiple given `key`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(bytes32[] memory keys, bytes[] memory values) external;
}