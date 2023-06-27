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

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Origami contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);
    error IsPaused();
    error UnknownExecuteError(bytes returndata);
    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/chainlink/IAggregatorV3Interface.sol)

interface IAggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function decimals() external view returns (uint8);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later

import {IAggregatorV3Interface} from "../../interfaces/external/chainlink/IAggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommonEventsAndErrors} from "../../common/CommonEventsAndErrors.sol";

contract DummyDex {
    IERC20 public gmxToken;
    IERC20 public wrappedNativeToken;
    uint256 public gmxPrice;
    uint256 public wrappedNativePrice;

    constructor(
        address _gmxToken, 
        address _wrappedNativeToken, 
        uint256 _gmxPrice, 
        uint256 _wrappedNativePrice
    ) {
        gmxToken = IERC20(_gmxToken);
        wrappedNativeToken = IERC20(_wrappedNativeToken);
        gmxPrice = _gmxPrice;
        wrappedNativePrice = _wrappedNativePrice;
    }

    function setPrices(uint256 _gmxPrice, uint256 _wrappedNativePrice) external {
        gmxPrice = _gmxPrice;
        wrappedNativePrice = _wrappedNativePrice;
    }

    function swapToGMX(uint256 _amount) external {
        gmxToken.transfer(msg.sender, _amount * wrappedNativePrice / gmxPrice);
        wrappedNativeToken.transferFrom(msg.sender, address(this), _amount);
    }

    function swapToWrappedNative(uint256 _amount) external {
        wrappedNativeToken.transfer(msg.sender, _amount * gmxPrice / wrappedNativePrice);
        gmxToken.transferFrom(msg.sender, address(this), _amount);
    }

    function revertNoMessage() external pure {
        assembly {
            revert(0,0)
        }
    }

    function revertCustom() external pure {
        revert CommonEventsAndErrors.InvalidParam();
    }
}