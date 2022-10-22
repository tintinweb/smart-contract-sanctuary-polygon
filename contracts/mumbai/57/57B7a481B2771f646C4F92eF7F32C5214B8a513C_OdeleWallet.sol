// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import {IERC20} from "IERC20.sol";
import {IOdeleWallet} from "IOdeleWallet.sol";

/**
* @title Odele Wallet.
* @author Daccred.
* @dev Odele Wallet, a pay-to-promote service.
*/
contract OdeleWallet is IOdeleWallet {
    /// @dev Address of calling API [contract owner].
    address internal API;
    /// @dev    Map of all supported tokens, which can be set
    ///         or unset by API.
    mapping(IERC20 => bool) private supportedTokens;

    /// @dev    Modifier to validate that all calls 
    ///         will be made from the API.
    modifier onlyOwner() {
        require(msg.sender == API, "ODELE_WALLET: Call not from API.");
        _;
    }

    /// @dev Set API address.
    constructor(address _API) {
        require(_API != address(0), "0x0 API.");
        API = _API;
    }

    /// @dev    Adds support for a token.
    ///         Emits the {AddSupportForToken} event.
    /// @param _token Desired token. 
    function addSupportForToken(IERC20 _token) public onlyOwner {
        supportedTokens[_token] = true;
        emit AddSupportForToken(_token);
    }

    /// @dev    Removes support for a token.
    ///         Emits the {RemoveSupportForToken} event.
    /// @param _token Desired token. 
    function removeSupportForToken(IERC20 _token) public onlyOwner {
        supportedTokens[_token] = false;
        emit RemoveSupportForToken(_token);
    }

    /// @inheritdoc IOdeleWallet
    /// @notice `msg.sender` must approve `OdeleWallet` contract.
    function withdrawTokensForPromotion(
        IERC20 _token,
        address _owner,
        address _receiver,
        uint256 _amount
    ) public override onlyOwner
    {
        /// @dev Run checks.
        _beforeWithdrawal(
            _token, 
            _owner, 
            _receiver, 
            _amount
        );

        /// @dev    Revert if the allowance of this contract is less
        ///         than the amount to be withdrawn.
        if (
            IERC20(_token).allowance(_owner, address(this)) < _amount
        ) revert InsufficientFundsError();

        /// @dev Send tokens to `_receiver`.
        bool sent = IERC20(_token).transferFrom(
            _owner,
            _receiver, // [or should it be `API`?],
            _amount
        );

        /// @dev Ensure funds were sent.
        require(sent, "Funds not collected.");
    }

    /**
    * @dev  Run basic checks.
    *
    * @param _token     ERC20 token.
    * @param _owner     Caller [Who must approve the contract to spend his tokens].
    * @param _amount    Amount to be withdrawn per call.
    */
    function _beforeWithdrawal(
        IERC20 _token,
        address _owner,
        address _receiver,
        uint256 _amount
    ) private view
    {
        if (!supportedTokens[_token]) revert UnsupportedToken();
        if (_owner == address(0)) revert OwnershipByZeroAddressError();
        if (_receiver == address(0)) revert WithdrawalToZeroAddressError();
        if (_amount == 0) revert ZeroWithdrawalError();
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import {IERC20} from "IERC20.sol";

/**
* @title Odele Wallet Interface.
* @author Daccred.
* @dev Interface for Odele wallet.
*/
interface IOdeleWallet {
    /// @dev Emitted if 0 is to be withdrawn.
    error ZeroWithdrawalError();
    /// @dev Emitted if the address owning tokens is a zero address.
    error OwnershipByZeroAddressError();
    /// @dev Emitted if passed receiver address is a zero address.
    error WithdrawalToZeroAddressError();
    /// @dev Emitted if the token to be withdrawn is not supported.
    error UnsupportedToken();
    /// @dev Emitted if the contract allowance is GT `_amount`.
    error InsufficientFundsError();

    /// @dev Emitted whenever support for a token is added.
    event AddSupportForToken(IERC20 _token);
    /// @dev Emitted whenever support for a token is removed.
    event RemoveSupportForToken(IERC20 _token);
    /// @dev    Emitted whenever a `withdrawTokensForPromotion()` 
    ///         call is successful.
    event WithdrawnForPromotion(
        IERC20 _token,
        address _owner,
        uint256 _amount
    );

    /**
    * @dev  Withdraws `_amount` amount of `_token` on behalf of the caller
    *       for promotions.
    *       Calls are made with the API as the msg.sender.
    *       If this contract's allowance is lower than the amount to be 
    *       withdrawn, it halts.
    *
    * @notice   `msg.sender` will approve this contract on the token contract.
    *           There's no way to approve tokens in another contract from another
    *           contract. [This @notice block will be removed on code approval.]
    *
    * @param _token     ERC20 token.
    * @param _owner     Caller [Who must approve the contract to spend his tokens].
    * @param _receiver  Address receiving tokens.
    * @param _amount    Amount to be withdrawn per call.
    */
    function withdrawTokensForPromotion(
        IERC20 _token,
        address _owner,
        address _receiver,
        uint256 _amount
    ) external;
}