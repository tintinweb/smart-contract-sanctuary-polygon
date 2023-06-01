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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOracleAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Primary Oracle Aggregator contract used to maintain price feeds for chainlink supported tokens.
 */
contract ChainlinkOracleAggregator is Ownable, IOracleAggregator {
    struct TokenInfo {
        /* Number of decimals represents the precision of the price returned by the feed. For example, 
     a price of $100.50 might be represented as 100500000000 in the contract, with 9 decimal places 
     of precision */
        uint8 decimals;
        // uint8 tokenDecimals;
        bool dataSigned;
        address callAddress;
        bytes callData;
    }

    mapping(address => TokenInfo) internal tokensInfo;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /**
     * @dev set price feed information for specific feed
     * @param callAddress price feed / derived price feed address to call
     * @param decimals decimals (precision) defined in this price feed
     * @param callData function selector which will be used to query price data
     * @param signed if the feed may return result as signed integrer
     */
    function setTokenOracle(
        address token,
        address callAddress,
        uint8 decimals,
        bytes calldata callData,
        bool signed
    ) external onlyOwner {
        require(
            callAddress != address(0),
            "ChainlinkOracleAggregator:: call address can not be zero"
        );
        require(
            token != address(0),
            "ChainlinkOracleAggregator:: token address can not be zero"
        );
        tokensInfo[token].callAddress = callAddress;
        tokensInfo[token].decimals = decimals;
        tokensInfo[token].callData = callData;
        tokensInfo[token].dataSigned = signed;
    }

    /**
     * @dev query deciamls used by set feed for specific token
     * @param token ERC20 token address
     */
    function getTokenOracleDecimals(
        address token
    ) external view returns (uint8 _tokenOracleDecimals) {
        _tokenOracleDecimals = tokensInfo[token].decimals;
    }

    /**
     * @dev query price feed
     * @param token ERC20 token address
     */
    function getTokenPrice(
        address token
    ) external view returns (uint256 tokenPrice) {
        // usually token / native (depends on price feed)
        tokenPrice = _getTokenPrice(token);
    }

    /**
     * @dev exchangeRate : each aggregator implements this method based on how it sources the quote/price
     * @notice here it is token / native sourced from chainlink so in order to get defined exchangeRate we inverse the feed
     * @param token ERC20 token address
     */
    function getTokenValueOfOneNativeToken(
        address token
    ) external view virtual returns (uint256 exchangeRate) {
        // we'd actually want eth / token
        uint256 tokenPriceUnadjusted = _getTokenPrice(token);
        uint8 _tokenOracleDecimals = tokensInfo[token].decimals;
        exchangeRate =
            ((10 ** _tokenOracleDecimals) *
                (10 ** IERC20Metadata(token).decimals())) /
            tokenPriceUnadjusted;
    }

    function _getTokenPrice(
        address token
    ) internal view returns (uint256 tokenPriceUnadjusted) {
        (bool success, bytes memory ret) = tokensInfo[token]
            .callAddress
            .staticcall(tokensInfo[token].callData);
        require(success, "ChainlinkOracleAggregator:: query failed");
        if (tokensInfo[token].dataSigned) {
            tokenPriceUnadjusted = uint256(abi.decode(ret, (int256)));
        } else {
            tokenPriceUnadjusted = abi.decode(ret, (uint256));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracleAggregator {
    function getTokenValueOfOneNativeToken(
        address _token
    ) external view returns (uint256 exchangeRate);
}