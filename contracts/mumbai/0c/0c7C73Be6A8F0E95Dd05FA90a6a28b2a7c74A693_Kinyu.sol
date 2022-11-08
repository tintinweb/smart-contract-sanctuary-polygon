// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./vendor/openzeppelin/token/ERC20/IERC20.sol";
import "./vendor/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20, IERC20Metadata {
    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./vendor/openzeppelin/token/ERC20/IERC20.sol";
import "./vendor/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IWETH9.sol";

error TransferAmountExceedsMax();
error TransferInFailed();

contract Kinyu is IERC20, IERC20Metadata {
    struct User {
        uint128 collateralsBitmap;
    }

    struct Collateral {
        address token;
    }

    uint64 internal constant BASE_TOKENS_PER_SHARE_SCALE = 1e9;

    address _baseToken;
    uint8 _baseTokenDecimals;
    address payable _wrappedNativeToken;

    uint128 _supplierBaseTokensPerShare = BASE_TOKENS_PER_SHARE_SCALE;
    uint128 _borrowerBaseTokensPerShare = BASE_TOKENS_PER_SHARE_SCALE;

    string _name;
    string _symbol;
    mapping(address => User) _users;
    mapping(address => int128) _userShares;
    mapping(address => mapping(address => uint128)) _userCollaterals;
    Collateral[] _collaterals;

    constructor(
        string memory name_,
        string memory symbol_,
        address baseToken,
        address payable wrappedNativeToken
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseToken = baseToken;
        _baseTokenDecimals = IERC20Metadata(baseToken).decimals();
        _wrappedNativeToken = wrappedNativeToken;
    }

    function supply(address token, uint amount) external {
        _supply(msg.sender, msg.sender, token, amount);
    }

    function supplyTo(
        address destination,
        address token,
        uint amount
    ) external {
        _supply(msg.sender, destination, token, amount);
    }

    function supplyNativeToken() external payable {
        IWETH9(_wrappedNativeToken).deposit{value: msg.value}();
        _supply(address(this), msg.sender, _wrappedNativeToken, msg.value);
    }

    function supplyNativeTokenTo(address destination) external payable {
        IWETH9(_wrappedNativeToken).deposit{value: msg.value}();
        _supply(address(this), destination, _wrappedNativeToken, msg.value);
    }

    function transfer(address to, uint amount)
        external
        override
        returns (bool)
    {}

    function approve(address spender, uint amount)
        external
        override
        returns (bool)
    {}

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external override returns (bool) {}

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _baseTokenDecimals;
    }

    function totalSupply() external view override returns (uint) {}

    function balanceOf(address account) external view override returns (uint) {
        if (_userShares[account] <= 0) {
            return 0;
        } else {
            return uint(_sharesToBaseTokens(_userShares[account]));
        }
    }

    function collateralBalanceOf(address account, address token)
        external
        view
        returns (uint)
    {
        return _userCollaterals[account][token];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint)
    {}

    function _supply(
        address source,
        address destination,
        address token,
        uint amount
    ) private {
        if (token == _baseToken) {
            return _supplyBaseToken(source, destination, token, amount);
        } else {
            return _supplyCollateralToken(source, destination, token, amount);
        }
    }

    function _supplyBaseToken(
        address source,
        address destination,
        address token,
        uint amount
    ) private {
        // Transfer first to prevent reentering this contract while state is
        // updated but tokens have not been received yet.
        _transferTokenIn(token, source, amount);

        int existingBaseTokens = _sharesToBaseTokens(_userShares[destination]);
        int128 updatedShares = _baseTokensToShares(
            existingBaseTokens + int(amount)
        );
        int128 newShares = _userShares[destination] + updatedShares;
        (uint128 repayShares, uint128 supplyShares) = _repayAndSupplyShares(
            _userShares[destination],
            newShares
        );
        _userShares[destination] = newShares;

        emit Transfer(
            address(0),
            destination,
            uint(_sharesToBaseTokens(int128(supplyShares)))
        );
    }

    function _supplyCollateralToken(
        address source,
        address destination,
        address token,
        uint amount
    ) private {
        // Transfer first to prevent reentering this contract while state is
        // updated but tokens have not been received yet.
        _transferTokenIn(token, source, amount);

        _userCollaterals[destination][token] += uint128(amount);
    }

    function _transferTokenIn(
        address token,
        address source,
        uint amount
    ) private {
        if (amount > uint(int(type(int64).max))) {
            revert TransferAmountExceedsMax();
        }
        if (
            source == address(this) &&
            IERC20(token).balanceOf(address(this)) >= amount
        ) {
            return;
        }
        bool transferInSuccess = IERC20(token).transferFrom(
            source,
            address(this),
            amount
        );
        if (!transferInSuccess) {
            revert TransferInFailed();
        }
    }

    function _baseTokensToShares(int baseTokens)
        private
        view
        returns (int128 shares)
    {
        if (baseTokens < 0) {
            return
                int128(
                    (baseTokens * int64(BASE_TOKENS_PER_SHARE_SCALE)) /
                        int(uint(_borrowerBaseTokensPerShare))
                );
        } else {
            return
                int128(
                    (baseTokens * int64(BASE_TOKENS_PER_SHARE_SCALE)) /
                        int(uint(_supplierBaseTokensPerShare))
                );
        }
    }

    function _sharesToBaseTokens(int128 shares)
        private
        view
        returns (int baseTokens)
    {
        if (shares < 0) {
            return
                (shares * int(uint(_borrowerBaseTokensPerShare))) /
                int64(BASE_TOKENS_PER_SHARE_SCALE);
        } else {
            return
                (shares * int(uint(_supplierBaseTokensPerShare))) /
                int64(BASE_TOKENS_PER_SHARE_SCALE);
        }
    }

    function _repayAndSupplyShares(int128 existingShares, int128 updatedShares)
        private
        pure
        returns (uint128, uint128)
    {
        if (updatedShares <= existingShares) {
            return (0, 0);
        } else if (updatedShares <= 0) {
            // Shares is negative, so only repay
            return (uint128(updatedShares - existingShares), 0);
        } else if (existingShares >= 0) {
            // Shares is positive, previously positive, so only supply
            return (0, uint128(updatedShares - existingShares));
        } else {
            // Shares is positive, previously negative, so repay and supply
            return (uint128(-existingShares), uint128(updatedShares));
        }
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