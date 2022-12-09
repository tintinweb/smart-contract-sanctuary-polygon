//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ILiquidator.sol";
import "./interfaces/IBentoBox.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ITokenLiquidationStrategy.sol";
import "./base/Withdrawals.sol";
import "./base/Multicall.sol";
import "./base/Address.sol";

contract Liquidator is ILiquidator, Multicall, Withdrawals {
    using SafeMath for uint256;
    using Address for address payable;
    using Address for address;

    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;
    uint256 private constant MAX_INT = 2**256 - 1;

    address immutable oneInchRouter;
    address immutable paraswapRouter;
    address immutable paraswapTokenTransferProxy;

    address immutable bentoBox;

    mapping(address => TokenLiquidationStrategy)
        private _tokenLiquidationStrategy;

    constructor(
        address _bentoBox,
        address _masterContract,
        address _oneInchRouter,
        address _paraswapRouter,
        address _paraswapTokenTransferProxy
    ) {
        bentoBox = _bentoBox;
        oneInchRouter = _oneInchRouter;
        paraswapRouter = _paraswapRouter;
        paraswapTokenTransferProxy = _paraswapTokenTransferProxy;
        IBentoBox(_bentoBox).setMasterContractApproval(
            address(this),
            _masterContract,
            true,
            uint8(0),
            bytes32(""),
            bytes32("")
        );
    }

    function _isSolvent(
        IPool _pool,
        address _user,
        uint256 _exchangeRate
    ) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = _pool.userBorrowPart(_user);
        if (borrowPart == 0) return true;
        uint256 collateralShare = _pool.userCollateralShare(_user);
        if (collateralShare == 0) return false;

        IPool.Rebase memory _totalBorrow = _pool.totalBorrow();

        return
            IBentoBox(bentoBox).toAmount(
                IERC20(_pool.collateral()),
                collateralShare
                    .mul(
                        EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION
                    )
                    .mul(_pool.COLLATERIZATION_RATE()),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) /
                _totalBorrow.base;
    }

    function getBatchUserData(IPool _pool, address[] calldata _users)
        external
        override
        returns (UserData[] memory)
    {
        UserData[] memory usersData = new UserData[](_users.length);
        (, uint256 rate) = IOracle(_pool.oracle()).get(_pool.oracleData());

        for (uint256 i = 0; i < _users.length; i++) {
            usersData[i].isSolvent = _isSolvent(_pool, _users[i], rate);
            usersData[i].borrowPart = _pool.userBorrowPart(_users[i]);
        }

        return usersData;
    }

    function balanceOf(address _user, address _token)
        public
        view
        override
        returns (uint256)
    {
        if (!_token.isContract()) {
            revert("INVALID_TOKEN");
        }
        return IERC20(_token).balanceOf(_user);
    }

    function batchBalanceOf(address[] calldata _tokens)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory usersBalances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            usersBalances[i] = balanceOf(address(this), _tokens[i]);
        }

        return usersBalances;
    }

    function getTokenLiquidationStrategy(address _token) external view returns(TokenLiquidationStrategy memory) {
        return _tokenLiquidationStrategy[_token];
    }

    /// @notice Allows to add token liquidation strategy
    /// @param token - token address to be handled
    /// @param shouldTransfer - indicates if tokens should be transferred or enough to approve
    /// @param strategy - address of token liquidation strategy
    function addTokenLiquidationStrategy(
        address token,
        bool shouldTransfer,
        address strategy
    ) external onlyOwner {
        require(
            token != address(0),
            "NereusLiquidator: token should be non zero address"
        );
        require(
            strategy != address(0),
            "NereusLiquidator: strategy should be non zero address"
        );

        _tokenLiquidationStrategy[token].strategy = strategy;
        _tokenLiquidationStrategy[token].shouldTransfer = shouldTransfer;
        _tokenLiquidationStrategy[token].active = true;

        emit TokenLiquidationStrategyAdded(token, strategy);
    }

    function removeTokenLiquidationStrategy(address token) external onlyOwner {
        require(_tokenLiquidationStrategy[token].strategy != address(0), "NereusLiquidator: could not delete strategy that was not set before");
        delete _tokenLiquidationStrategy[token];
        emit TokenLiquidationStrategyRemoved(token);
    }

    function switchLiquidationStrategy(address token, bool setActive) external onlyOwner {
        require(_tokenLiquidationStrategy[token].strategy != address(0), "NereusLiquidator: could not switch strategy that was not set before");
        _tokenLiquidationStrategy[token].active = setActive;
        emit TokenLiquidationStrategySwitched(token, setActive);
    }

    /// @notice Liquidates collateral for specified market
    /// @param _pool - cauldron address for specific market
    /// @param _users - addresses thats that should be liquidated
    /// @param _maxBorrowParts - parts of total borrow amount that should be liquidated (correlates to _users)
    function liquidate(
        address _pool,
        address[] calldata _users,
        uint256[] calldata _maxBorrowParts,
        address collateral,
        bool transferToOwnerAddress
    ) external payable override onlyManager {
        require(
            collateral != address(0),
            "NereusLiquidator: zero collateral specified."
        );
        TokenLiquidationStrategy memory liquidationStrategy = _tokenLiquidationStrategy[collateral];

        // calls liquidate method for Cauldron of specified POOL
        IPool(_pool).liquidate(
            _users,
            _maxBorrowParts,
            address(this),
            ISwapper(0x0000000000000000000000000000000000000000)
        );

        // get amount of specified collateral stored bentobox
        uint256 amount = IBentoBox(bentoBox).balanceOf(
            IERC20(collateral),
            address(this)
        );

        uint256 total = uint256(IBentoBox(bentoBox).totals(IERC20(collateral)).base);
        uint256 minimumBalanceInBentoBox = 1000;

        if (total != amount && total - amount < minimumBalanceInBentoBox) {
            amount = total - minimumBalanceInBentoBox;
        }

        address destinationAddress = address(this);

        if (transferToOwnerAddress) {
            destinationAddress = owner();
        }

        // apply token liquidation strategy
        if (liquidationStrategy.active) {

            IBentoBox(bentoBox).withdraw(
                IERC20(collateral),
                address(this),
                address(this),
                amount,
                uint256(0)
            );

            if (liquidationStrategy.shouldTransfer) {
                IERC20(collateral).transfer(
                    liquidationStrategy.strategy,
                    amount
                );
            }
            // approves tokens to strategy address
            else {
                IERC20(collateral).approve(
                    liquidationStrategy.strategy,
                    amount
                );
            }

            // apply token liquidation strategy
            (
                address[] memory tokenAddresses,
                uint256[] memory tokenAmounts
            ) = ITokenLiquidationStrategy(
                    liquidationStrategy.strategy
                ).applyStrategy(collateral, amount, destinationAddress);

            // emits liquidated event to be caught and handled to swap
            emit Liquidated(collateral, tokenAddresses, tokenAmounts, destinationAddress);
        } else {

            IBentoBox(bentoBox).withdraw(
                IERC20(collateral),
                address(this),
                destinationAddress,
                amount,
                uint256(0)
            );
            address[] memory handledTokens = new address[](1);
            handledTokens[0] = collateral;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            // we should still emit liquidated event for non token that not required liquidation strategy
            emit Liquidated(collateral, handledTokens, amounts, destinationAddress);
        }
    }

    function _safeSwap(
        bytes calldata data,
        address allowanceAddress,
        address swapper,
        address token,
        uint256 amount
    ) internal {
        require(
            token != address(0),
            "NereusLiquidator: invalid token address provided"
        );

        if (IERC20(token).allowance(address(this), allowanceAddress) < amount) {
            IERC20(token).approve(allowanceAddress, MAX_INT);
        }

        (bool success, bytes memory result) = swapper.call{value: msg.value}(
            data
        );
        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }

            revert(abi.decode(result, (string)));
        }
    }

    /// @notice Swaps specified tokens to destination tokens using pre-built swapper transaction
    /// @param token - erc20 that will be swapped as liquidated collateral
    /// @param amount - amount of liquidated collateral to be swapped
    function swapOneInch(
        bytes calldata data,
        address token,
        uint256 amount) external payable onlyManager {
        _safeSwap(data, oneInchRouter, oneInchRouter, token, amount);
    }

    /// @notice Swaps specified tokens to destination tokens using pre-built swapper transaction
    /// @param token - erc20 that will be swapped as liquidated collateral
    /// @param amount - amount of liquidated collateral to be swapped
    function swapParaswap(
        bytes calldata data,
        address token,
        uint256 amount
    ) external payable onlyManager {
        _safeSwap(data, paraswapTokenTransferProxy, paraswapRouter, token, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ISwapper.sol";

interface IPool {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }
    function COLLATERIZATION_RATE() external view returns (uint256);

    function totalBorrow() external view returns (Rebase memory); // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    function collateral() external view returns (address);

    function oracle() external view returns (address);
    function oracleData() external view returns (bytes memory);

    // User balances
    function userCollateralShare(address _a) external view returns (uint256);
    function userBorrowPart(address _a) external view returns (uint256);

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPool.sol";

interface ILiquidator {

    /**
    * Configuration for token liquidation strategy
    * For cases when as a liquidation collateral some staked or LP token received and some liquidation strategy
    * strategy - address of smart contract to that applies liquidation strategy
     */
    struct TokenLiquidationStrategy {
        address strategy;
        bool shouldTransfer;
        bool active;
    }

    struct UserData {
        bool isSolvent;
        uint256 borrowPart;
    }

    event Liquidated(address origin, address[] destinations, uint256[] amounts, address receiver);
    event TokenLiquidationStrategyAdded(address token, address strategy);
    event TokenLiquidationStrategyRemoved(address token);
    event TokenLiquidationStrategySwitched(address token, bool isActive);

    function getBatchUserData(IPool _pool, address[] calldata users)
        external
        returns (UserData[] memory);

    function batchBalanceOf(address[] calldata tokens)
        external
        view
        returns (uint256[] memory);

    function balanceOf(address user, address token)
        external
        view
        returns (uint256);

    function liquidate(
        address _pool,
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address collateral,
        bool transferToOwnerAddress
    ) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

interface IBentoBox {

    function totals(IERC20) external view returns (Rebase memory totals_);

    // functional representation of mapping for balanceOf of the BentoBox contract
    function balanceOf(IERC20, address) external view returns (uint256);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenLiquidationStrategy {
    /// @notice  Applies liquidation strategy for token
    /// @param token - token to handle
    /// @param amount - amount of tokens to handle
    /// @param backReceiver - address to send tokens back
    /// @return tokens tokens received after strategy applied
    /// @return amounts amount of each token received after strategy applied
    function applyStrategy(
        address token,
        uint256 amount,
        address backReceiver
    ) external returns (address[] memory tokens, uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "../interfaces/IBentoBox.sol";
import "./Manager.sol";

abstract contract Withdrawals is Manager {
    function withdraw(address token, address to, uint256 value) public onlyOwner {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= value, 'Insufficient token');

        if (balanceToken > 0) {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
        }
    }

    function withdrawETH(address to, uint256 value) public onlyOwner {
        if (address(this).balance > 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, 'STE');
        }
    }

    function withdrawBentoBox(address bentoBox, address token, address to, uint256 amount) public onlyOwner {
        IBentoBox(bentoBox).withdraw(IERC20(token), address(this), to, amount, uint256(0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import '../interfaces/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }

                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.7.6;

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
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Manager is Ownable {
    mapping(address => bool) public managers;

    event AddedManager(
        address manager
    );

    event RemovedManager(
        address manager
    );

    modifier onlyManager() {
        _onlyManager();
        _;
    }

    function _onlyManager() private view {
        require(
            managers[msg.sender] == true,
            "Must be a liquidator's manager"
        );
    }
    function addManager(address manager) public onlyOwner {
        managers[manager] = true;
        emit AddedManager(manager);
    }

    function removeManager(address manager) public onlyOwner {
        managers[manager] = false;
        emit RemovedManager(manager);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}