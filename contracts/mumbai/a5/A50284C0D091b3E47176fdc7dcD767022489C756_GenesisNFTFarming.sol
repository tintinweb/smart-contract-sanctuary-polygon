// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

// This is developed with OpenZeppelin Upgradeable Contracts v4.5.2
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Genesis NFT Farming -- Contract that provides rewards for Genesis Player NFT owners.
 *
 * @notice Rewards are awarded due to the use of player tokens by users during the draft for the Divisions and the
 * Genesis free agent purchase.
 *
 * This contract includes the following functionality:
 *  - Adding of rewards in ERC20 tokens for users via Genesis NF token card ID before the deadline.
 *  - Withdrawal of their rewards by the users via Genesis NF token ID before the deadline.
 *  - Withdrawal of all the balances by the owner of this contract after the deadline.
 *  - ERC20 reward token whitelist functionality.
 *
 * @dev Warning. This contract is not intended for inheritance. In case of inheritance, it is recommended to change the
 * access of all storage variables from public to private in order to avoid violating the integrity of the storage. In
 * addition, you will need to add functions for them to get values.
 */
contract GenesisNFTFarming is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // _______________ Storage _______________
    /**
     * @dev The time after which the user can no longer pick up rewards. After that, the remaining belongs to the
     * owner of this contract.
     */
    uint256 public deadline; // In seconds

    /// @dev The number of tokens that are considered not significant. Using to verify this
    uint256 public dust; // In wei

    /// @dev Interface of the Genesis ERC721 contract
    IGenesisERC721 public erc721;

    /// @dev Stores a reward for a Genesis NFT card ID in a specified token
    // (Genesis NFT card ID => (token => value))
    mapping(uint256 => mapping(address => uint256)) public rewards;

    /// @dev ERC20 tokens that is allowed by the owner of this contract
    mapping(address => bool) public isAllowedToken;
    /// @dev It exists for getting the list of all the allowed tokens
    address[] public allowedTokens;

    // _______________ Events _______________
    /**
     * @dev Emitted when `value` tokens of `token` are added to the reward for `cardID` and moved from the caller to
     * the contract.
     */
    event RewardAdding(uint256 indexed cardID, address indexed token, uint256 value);
    /**
     * @dev Emitted when `value` tokens of `token` are withdrawn for `cardID` and moved from the contract to
     * `recipient`.
     */
    event RewardWithdrawal(uint256 indexed cardID, address indexed recipient, address indexed token, uint256 value);
    /// @dev Emitted when `value` tokens of `token` are moved from the contract to `recipient`
    event BalanceWithdrawal(address indexed recipient, address indexed token, uint256 value);

    /// @dev Emitted when `token` is allowed
    event TokenAllowing(address indexed token);
    /// @dev Emitted when `token` is disallowed
    event TokenDisallowing(address indexed token);

    /// @dev Emitted when the dust is set to `dust`
    event DustSetting(uint256 dust);
    /// @dev Emitted when the Genesis ERC721 contract is set to `erc721`
    event ERC721Setting(address erc721);
    /// @dev Emitted when the deadline is extended to `deadline`
    event DeadlineExtensionTo(uint256 deadline);

    // _______________ Modifiers _______________
    /// @dev Throws if `token` is not allowed
    modifier onlyAllowedToken(address token) {
        require(isAllowedToken[token], "The token is not allowed");
        _;
    }

    /// @dev Throws if called before the deadline
    modifier beforeDeadline() {
        require(deadline >= block.timestamp, "Only available before the deadline");
        _;
    }

    /// @dev Throws if called after the deadline
    modifier afterDeadline() {
        require(deadline < block.timestamp, "Only available after the deadline");
        _;
    }

    /// @dev Throws if `addr` (the reward receiver) is not the owner of `tokenID`
    modifier onlyNFTOwner(uint256 tokenID, address addr) {
        require(erc721.ownerOf(tokenID) == addr, "The address is not the owner of the token ID");
        _;
    }

    // _______________ External functions _______________
    /**
     * @dev Initializes the contract by setting the deployer as the initial owner, the dust, deadline and Genesis
     * ERC721 contract address values. It is used as the constructor for upgradeable contracts.
     *
     * @param erc721_ Address of the Genesis ERC721 contract.
     * @param deadline_ Time (in seconds) after which the user can no longer pick up rewards.
     */
    function initialize(address erc721_, uint256 deadline_) external initializer {
        __Ownable_init();

        erc721 = IGenesisERC721(erc721_);
        emit ERC721Setting(erc721_);

        dust = 1e12; // 10 ** 12 wei
        emit DustSetting(1e12);

        extendDeadlineTo(deadline_);
    }

    /**
     * @dev Adds a reward for a Genesis NFT card ID.
     *
     * Requirements:
     * - The token should be allowed.
     * - The Genesis NFT card ID should exist.
     * - The caller should approve `value` tokens of `token` for the contract.
     *
     * @param cardID Identifier of a Genesis NFT card.
     * @param token Address of an allowed ERC20 token in which the reward will be.
     * @param value Amount of reward.
     */
    function addReward(
        uint256 cardID,
        address token,
        uint256 value
    ) external onlyAllowedToken(token) {
        require(erc721.cardImageToExistence(cardID), "Unknown card ID");

        rewards[cardID][token] += value;
        IERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), value);
        emit RewardAdding(cardID, token, value);
    }

    /**
     * @dev Transfers rewards for `tokenID` to the caller.
     *
     * Requirements:
     * - A user should call it before the deadline.
     * - The caller should be the owner of `tokenID`.
     *
     * @param tokenID The Genesis NF token ID.
     */
    function withdrawRewards(uint256 tokenID) external beforeDeadline onlyNFTOwner(tokenID, _msgSender()) {
        uint256 cardID = erc721.cardToCardImageID(tokenID);
        uint256 value;
        // Withdrawal from all the allowed tokens
        for (uint256 i = 0; i < allowedTokens.length; ++i) {
            value = rewards[cardID][allowedTokens[i]];
            if (value > dust) _withdrawReward(cardID, _msgSender(), allowedTokens[i], value);
        }
    }

    /**
     * @dev Transfers the reward in tokens of the specified `token` for `tokenID` to the caller.
     *
     * Requirements:
     * - A user should call it before the deadline.
     * - `token` should be allowed.
     * - The caller should be the owner of `tokenID`.
     *
     * @param tokenID The Genesis NF token ID.
     * @param token Allowed ERC20 token that is desired for reward withdrawal.
     */
    function withdrawReward(uint256 tokenID, address token)
        external
        beforeDeadline
        onlyAllowedToken(token)
        onlyNFTOwner(tokenID, _msgSender())
    {
        uint256 cardID = erc721.cardToCardImageID(tokenID);
        uint256 value = rewards[cardID][token];
        if (value > dust) _withdrawReward(cardID, _msgSender(), token, value);
    }

    /**
     * @dev Transfers rewards for `tokenID` to `recipient`.
     *
     * Requirements:
     * - The caller should be the owner of this contract.
     * - `recipient` should be the owner of `tokenID`.
     *
     * @param tokenID The Genesis NF token ID.
     * @param recipient The owner of the `tokenID`.
     */
    function withdrawRewardsFor(uint256 tokenID, address recipient)
        external
        onlyOwner
        onlyNFTOwner(tokenID, recipient)
    {
        uint256 cardID = erc721.cardToCardImageID(tokenID);
        uint256 value;
        // Withdrawal from all the allowed tokens
        for (uint256 i = 0; i < allowedTokens.length; ++i) {
            value = rewards[cardID][allowedTokens[i]];
            if (value > dust) _withdrawReward(cardID, recipient, allowedTokens[i], value);
        }
    }

    /**
     * @dev Transfers the reward in tokens of the specified `token` for `tokenID` to `recipient`.
     *
     * Requirements:
     * - The caller should be the owner of this contract.
     * - `token` should be allowed.
     * - `recipient` should be the owner of `tokenID`.
     *
     * @param tokenID The Genesis NF token ID.
     * @param recipient The owner of the `tokenID`.
     * @param token Allowed ERC20 token that is desired for reward withdrawal.
     */
    function withdrawRewardFor(
        uint256 tokenID,
        address recipient,
        address token
    ) external onlyOwner onlyAllowedToken(token) onlyNFTOwner(tokenID, recipient) {
        uint256 cardID = erc721.cardToCardImageID(tokenID);
        uint256 value = rewards[cardID][token];
        if (value > dust) _withdrawReward(cardID, recipient, token, value);
    }

    /**
     * @dev Transfers all the reward token balances of the contract to `recipient`.
     *
     * Requirements:
     *  - The caller should be the owner of this contract.
     *  - The deadline should be reached.
     *
     * @param recipient Account to which balances are transferred.
     *
     * Warning. This function, when called, violates the contract storage because it does not clear the mapping of
     * rewards. This is not implemented due to the absence of such a need. This function should be used only after all
     * interested users withdraw their rewards, and the use of the contract stops. It is still possible to restore
     * functionality by sending all tokens removed using this function or more to this contract.
     */
    function withdrawBalances(address recipient) external onlyOwner afterDeadline {
        uint256 value;
        // Withdrawal from all the allowed tokens
        for (uint256 i = 0; i < allowedTokens.length; ++i) {
            value = IERC20Upgradeable(allowedTokens[i]).balanceOf(address(this));
            if (value > dust) _withdrawBalance(recipient, allowedTokens[i], value);
        }
    }

    /**
     * @dev Transfers the balance of the specified `token` to `recipient`. Owner can withdraw any token using this function after the deadline, so we can ensure that no tokens are locked in this contract.
     *
     * Requirements:
     *  - The caller should be the owner of this contract.
     *  - The deadline should be reached.
     *
     * @param recipient Account to which balances are transferred.
     *
     * Warning. This function, when called, violates the contract storage. See `withdrawBalances()` description for
     * details.
     */
    function withdrawBalance(address recipient, address token) external onlyOwner afterDeadline {
        uint256 value = IERC20Upgradeable(token).balanceOf(address(this));
        if (value > dust) _withdrawBalance(recipient, token, value);
    }

    /**
     * @dev Allows `token` for reward adding.
     *
     * Requirements:
     * - The caller should be the owner of this contract.
     * - The token should be not allowed.
     *
     * @param token Address of a ERC20 token.
     */
    function allowToken(address token) external onlyOwner {
        require(!isAllowedToken[token], "The token has already allowed");

        isAllowedToken[token] = true;
        allowedTokens.push(token);
        emit TokenAllowing(token);
    }

    /**
     * @dev Disallows `token`.
     *
     * Requirements:
     * - The caller should be the owner of this contract.
     * - The token should be allowed.
     * - The balance of the token should be greater than the dust.
     *
     * @param token Address of an allowed ERC20 token.
     */
    function disallowToken(address token) external onlyOwner onlyAllowedToken(token) {
        require(IERC20Upgradeable(token).balanceOf(address(this)) <= dust, "There are someone else's rewards");

        delete isAllowedToken[token];
        // Find the token to remove in the array
        for (uint256 i = 0; i < allowedTokens.length - 1; ++i)
            // Replacing the deleted element with the last one
            if (allowedTokens[i] == token) {
                allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
                break;
            }
        allowedTokens.pop(); // Cutting off the last element
        emit TokenDisallowing(token);
    }

    // // See the ERC721 storage variable for details
    // function setERC721(address erc721_) external onlyOwner {
    //     require(erc721 == address(0), "Address of the ERC721 has already set");

    //     erc721 = IGenesisERC721(erc721_);
    //     emit ERC721Setting(erc721_);
    // }

    /**
     * @dev Sets the dust value to `newDust`.
     *
     * Requirements:
     * - The caller should be the owner of this contract.
     * - `newDust` should be less than 1e17.
     *
     * @param newDust The number of tokens in wei that are considered not significant.
     */
    function setDust(uint256 newDust) external onlyOwner {
        require(newDust < 1e17, "Uncorrect dust"); // 10 ** 17 wei

        dust = newDust;
        emit DustSetting(newDust);
    }

    /**
     * @dev Returns the reward value in tokens of the specified `token` for `cardID` if it is greater than the dust,
     * otherwise zero.
     *
     * @param cardID Identifier of a Genesis NFT card.
     * @param token Address of a ERC20 token.
     */
    function rewardValue(uint256 cardID, address token) external view returns (uint256) {
        uint256 reward = rewards[cardID][token];
        return reward > dust ? reward : 0;
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokens;
    }

    // _______________ Public functions _______________
    /**
     * @dev Extends the deadline value to `newDeadline`.
     *
     * Requirements:
     * - The caller should be the owner of this contract.
     * - `newDeadline` should be greater than the current block timestamp and less than or equal to
     *   (the_current_block_timestamp + 86400 * 366).
     * - `newDeadline` should be greater than the current deadline.
     *
     * @param newDeadline The time in seconds after which the user can no longer pick up rewards.
     */
    function extendDeadlineTo(uint256 newDeadline) public onlyOwner {
        require(
            newDeadline > block.timestamp && newDeadline <= block.timestamp + 86400 * 366, // 4 weeks
            "Uncorrect deadline"
        );
        require(deadline < newDeadline, "The deadline should be greater than the current deadline");

        deadline = newDeadline;
        emit DeadlineExtensionTo(newDeadline);
    }

    // _______________ Private functions _______________
    // Transfers a reward to the recipient
    function _withdrawReward(
        uint256 cardID,
        address recipient,
        address token,
        uint256 value
    ) private {
        // rewards[cardID][token] -= value; // Replace with this if adds the ability to withdraw a part of the value
        delete rewards[cardID][token];
        IERC20Upgradeable(token).safeTransfer(recipient, value);
        emit RewardWithdrawal(cardID, recipient, token, value);
    }

    /*
     * Transfers a balance to the recipient.
     *
     * Warning. This function, when called, violates the contract storage. See `withdrawBalances()` description for
     * details.
     */
    function _withdrawBalance(
        address recipient,
        address token,
        uint256 value
    ) private {
        IERC20Upgradeable(token).safeTransfer(recipient, value);
        emit BalanceWithdrawal(recipient, token, value);
    }
}

// This is here because the interface (interfaces/INomoNFT.sol) does not contain required declarations
interface IGenesisERC721 {
    /// @dev Returns "true" if `cardID` exists, otherwise "false"
    function cardImageToExistence(uint256 cardID) external view returns (bool exists);

    /// @dev Returns `cardID` that corresponds to `tokenID`
    function cardToCardImageID(uint256 tokenID) external view returns (uint256 cardID);

    // __________ From the OpenZeppelin ERC721 interface __________
    /**
     * @dev Returns `owner` of `tokenID` token.
     *
     * Requirements:
     * - `tokenID` should exist.
     */
    function ownerOf(uint256 tokenID) external view returns (address owner);
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