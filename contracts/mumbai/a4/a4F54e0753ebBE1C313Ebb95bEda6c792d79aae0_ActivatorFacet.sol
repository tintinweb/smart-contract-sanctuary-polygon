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

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../libraries/TransferToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ActivatorFacet {
    function deposit(address _token, uint256 amount) external {
        IERC20 token = IERC20(_token);
        TransferToken.depositToken(token, msg.sender, address(this), amount);
    }
}

// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import {LibDiamond} from "../libraries/LibDiamond.sol";
// import "../libraries/TokenUtils.sol";
// import "../base/Error.sol";
// import "../libraries/SafeCast.sol";
// import "../libraries/AppStorage.sol";

// /**
//  * @title Activator
//  * @notice A contract which facilitates the exchange of synthetic assets for their underlying
//  * asset. This contract guarantees that synthetic assets are exchanged exactly 1:1
//  * for the underlying asset.
//  */

// contract ActivatorFacet is Initializable, ReentrancyGuardUpgradeable {
//     AppStorage s;

//     struct UpdateActivatorAccount {
//         // The owner address whose account will be modified
//         address user;
//         // The amount to change the account's unexchanged balance by
//         int256 unexchangedBalance;
//         // The amount to change the account's exchanged balance by
//         int256 exchangedBalance;
//     }

//     /**
//      * @notice Emitted when the system is paused or unpaused.
//      * @param flag `true` if the system has been paused, `false` otherwise.
//      */
//     event Paused(bool flag);

//     event Deposit(address indexed user, uint256 unexchangedBalance);

//     event Withdraw(
//         address indexed user,
//         uint256 unexchangedBalance,
//         uint256 exchangedBalance
//     );

//     event Claim(
//         address indexed user,
//         uint256 unexchangedBalance,
//         uint256 exchangedBalance
//     );

//     constructor() {}

//     function initialize(address _syntheticToken, address _underlyingToken)
//         external
//         initializer
//     {
//         LibDiamond.enforceIsContractOwner();
//         s.syntheticToken = _syntheticToken;
//         s.underlyingToken = _underlyingToken;
//         s.isPaused = false;
//     }

//     // @dev A modifier which checks whether the Activator is unpaused.
//     modifier notPaused() {
//         if (s.isPaused) {
//             revert IllegalState();
//         }
//         _;
//     }

//     function setPause(bool pauseState) external {
//         LibDiamond.enforceIsContractOwner();
//         s.isPaused = pauseState;
//         emit Paused(s.isPaused);
//     }

//     function depositSynthetic(uint256 amount) external nonReentrant {
//         _updateAccount(
//             UpdateActivatorAccount({
//                 user: msg.sender,
//                 unexchangedBalance: SafeCast.toInt256(amount),
//                 exchangedBalance: 0
//             })
//         );
//         TokenUtils.safeTransferFrom(
//             s.syntheticToken,
//             msg.sender,
//             address(this),
//             amount
//         );
//         emit Deposit(msg.sender, amount);
//     }

//     function withdrawSynthetic(uint256 amount) external nonReentrant {
//         _updateAccount(
//             UpdateActivatorAccount({
//                 user: msg.sender,
//                 unexchangedBalance: -SafeCast.toInt256(amount),
//                 exchangedBalance: 0
//             })
//         );
//         TokenUtils.safeTransfer(s.syntheticToken, msg.sender, amount);
//         emit Withdraw(
//             msg.sender,
//             s.accounts[msg.sender].unexchangedBalance,
//             s.accounts[msg.sender].exchangedBalance
//         );
//     }

//     function claimUnderlying(uint256 amount) external nonReentrant {
//         _updateAccount(
//             UpdateActivatorAccount({
//                 user: msg.sender,
//                 unexchangedBalance: -SafeCast.toInt256(amount),
//                 exchangedBalance: SafeCast.toInt256(amount)
//             })
//         );
//         TokenUtils.safeTransfer(s.underlyingToken, msg.sender, amount);
//         TokenUtils.safeBurn(s.syntheticToken, amount);
//         emit Claim(
//             msg.sender,
//             s.accounts[msg.sender].unexchangedBalance,
//             s.accounts[msg.sender].exchangedBalance
//         );
//     }

//     function _updateAccount(UpdateActivatorAccount memory param) internal {
//         ActivatorAccount storage _account = s.accounts[param.user];
//         int256 updateUnexchange = int256(_account.unexchangedBalance) +
//             param.unexchangedBalance;
//         int256 updateExchange = int256(_account.exchangedBalance) +
//             param.exchangedBalance;
//         if (updateUnexchange < 0 || updateExchange < 0) {
//             revert IllegalState();
//         }
//         _account.unexchangedBalance = uint256(updateUnexchange);
//         _account.exchangedBalance = uint256(updateExchange);
//     }

//     function getSyntheticToken() external view returns (address) {
//         return s.syntheticToken;
//     }

//     function getUnderlyingToken() external view returns (address) {
//         return s.underlyingToken;
//     }

//     function getUserData(address user)
//         external
//         view
//         returns (uint256, uint256)
//     {
//         ActivatorAccount storage _account = s.accounts[user];
//         uint256 unexchange = _account.unexchangedBalance;
//         uint256 exchange = _account.exchangedBalance;
//         return (unexchange, exchange);
//     }

//     function getBalance(address token, address account)
//         external
//         view
//         returns (uint256)
//     {
//         return TokenUtils.safeBalanceOf(token, account);
//     }
// }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferToken {
    function depositToken(
        IERC20 token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        token.transferFrom(sender, receiver, amount);
    }
}