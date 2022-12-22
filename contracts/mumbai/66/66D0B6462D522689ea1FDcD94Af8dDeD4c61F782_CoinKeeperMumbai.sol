// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICoinKeeper.sol";

interface IERC20MintableBurnable is IERC20 {
    function faucet(uint256 amount) external;

    function faucetTo(address receiver, uint256 amount) external;
}

contract CoinKeeperMumbai is ICoinKeeper{
    address[] public allTokens;

    mapping(string => address) public tokenBySymbol;
    mapping(address => bool) public isTokenMintable;
    mapping(address => bool) public isTokenExists;

    /// @notice Returns msg.sender's balance of token
    function myBalanceOf(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }

    /// @notice Gives amount of token to msg.sender
    function claim(address token, uint256 amount) public tokenExists(token) returns (bool) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > amount) {
            return IERC20(token).transfer(msg.sender, amount);
        }
        if (isTokenMintable[token]) {
            IERC20MintableBurnable(token).faucetTo(msg.sender, amount);
            return true;
        }
        return false;
    }

    /// @notice Gives 1000 of each token to msg.sender
    function claimAll() external returns (bool) {
        for (uint256 i = 0; i < allTokens.length; i++) {
            uint256 tokenDecimals = IERC20Metadata(allTokens[i]).decimals();
            uint256 amount = 1000 * 10**tokenDecimals;
            claim(allTokens[i], amount);
        }
        return true;
    }


    /// @notice Adds token to the list of tokens
    /// @param token Address of the token
    /// @param symbol Symbol of the token
    /// @param isMintable Whether the token is mintable
    function addTokenToList(
        address token,
        string calldata symbol,
        bool isMintable
    ) external returns (bool) {
        require(!isTokenExists[token], "Token already exists");
        require(tokenBySymbol[symbol] == address(0), "Symbol already exists");

        allTokens.push(token);

        isTokenMintable[token] = isMintable;
        isTokenExists[token] = true;
        tokenBySymbol[symbol] = token;

        return true;
    }

    /// @notice Mints token to msg.sender
    function mintTokenToMe(address token, uint256 amount)
        external
        returns (bool)
    {
        return mintTokenTo(token, msg.sender, amount);
    }

    /// @notice Mints token to 'to'
    function mintTokenTo(
        address token,
        address to,
        uint256 amount
    ) public tokenExists(token) returns (bool) {
        require(isTokenMintable[token], "Token is not mintable");
        IERC20MintableBurnable(token).faucetTo(to, amount);
        return true;
    }

    /// @notice Transfers token from this to msg.sender
    function transferTokenToMe(address token, uint256 amount)
        external
        tokenExists(token)
        returns (bool)
    {
        return transferTokenTo(token, msg.sender, amount);
    }

    /// @notice Transfers token from this to 'to'
    function transferTokenTo(
        address token,
        address to,
        uint256 amount
    ) public tokenExists(token) returns (bool) {
        return IERC20(token).transfer(to, amount);
    }

    /// @notice Transfers token from 'from' to 'to'
    function transferTokenFromTo(
        address token,
        address from,
        address to,
        uint256 amount
    ) external tokenExists(token) returns (bool) {
        return IERC20(token).transferFrom(from, to, amount);
    }

    /// @notice Transfers ownership of token to 'newOwner'
    function transferOwnershipOfToken(address token, address newOwner)
        external
        tokenExists(token)
    {
        Ownable(token).transferOwnership(newOwner);
    }

    modifier tokenExists(address token) {
        require(isTokenExists[token], "Token does not exist");
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICoinKeeper {
    function tokenBySymbol(string calldata symbol) external view returns (address);

    function isTokenMintable(address token) external view returns (bool);

    function isTokenExists(address token) external view returns (bool);

    /// @notice Returns msg.sender's balance of token
    function myBalanceOf(address token) external view returns (uint256);

    /// @notice Gives amount of token to msg.sender
    function claim(address token, uint256 amount) external returns (bool);

    /// @notice Adds token to the list of tokens
    /// @param token Address of the token
    /// @param symbol Symbol of the token
    /// @param isMintable Whether the token is mintable
    function addTokenToList(
        address token,
        string calldata symbol,
        bool isMintable
    ) external returns (bool);

    /// @notice Mints token to 'to'
    function mintTokenTo(address token, address to, uint256 amount) external returns (bool);

    /// @notice Transfers token amount from this to msg.sender
    function transferTokenToMe(address token, uint256 amount) external returns (bool);

    /// @notice Transfers token from this to 'to'
    function transferTokenTo(address token, address to, uint256 amount) external returns (bool);

    /// @notice Transfers token from 'from' to 'to'
    function transferTokenFromTo(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /// @notice Transfers ownership of token to 'newOwner'
    function transferOwnershipOfToken(address token, address newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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