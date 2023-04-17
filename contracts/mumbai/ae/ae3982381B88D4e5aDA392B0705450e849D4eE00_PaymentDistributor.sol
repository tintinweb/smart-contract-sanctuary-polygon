// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.2;

/// @dev Implementation of the zero-out balance distribution. Distribution will see the requested balance zeroed out.
contract PaymentDistributor {

    uint16 private _shareDenominator = 10000;
    uint16[] private _shares;
    address[] private _payees;

    /// @notice Adds a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function _addPayee(address payee, uint16 share) internal {
        require(_payees.length == _shares.length, "Payee and shares must be the same length.");
        require(totalShares() + share <= _shareDenominator, "Cannot overassign share distribution.");
        require(_indexOfPayee(payee) == _payees.length, "Payee has already been added.");
        _payees.push(payee);
        _shares.push(share);
    }

    /// @notice Updates a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function _updatePayee(address payee, uint16 share) internal {
        uint payeeIndex = _indexOfPayee(payee);
        require(payeeIndex < _payees.length, "Payee has not been added yet.");
        _shares[payeeIndex] = share;
        require(totalShares() <= _shareDenominator, "Cannot overassign share distribution.");
    }

    /// @notice Removes a payee from the distribution list
    /// @dev Sets a payees shares to zero, but does not remove them from the array. Payee will be ignored in the distributeFunds function
    function _removePayee(address payee) internal {
        uint payeeIndex = _indexOfPayee(payee);
        require(payeeIndex < _payees.length, "Payee has not been added yet.");
        _shares[payeeIndex] = 0;
    }

    /// @notice Gets the index of a payee
    /// @dev Returns the index of the payee from _payees or returns _payees.length if no payee was found
    function _indexOfPayee(address payee) internal view returns (uint) {
        for (uint i=0; i < _payees.length; i++) {
            if(_payees[i] == payee) return i;
        }
        return _payees.length;
    }

    /// @notice Gets the total number of shares assigned to payees
    /// @dev Calculates total shares from shares[] array.
    function totalShares() private view returns(uint16) {
        uint16 sharesTotal = 0;
        for (uint i=0; i < _shares.length; i++) {
            sharesTotal += _shares[i];
        }
        return sharesTotal;
    }

    /// @notice Fund distribution function.
    /// @dev Uses the payees and shares array to calculate. Will send all remaining funds to the msg.sender.
    function _distributeShares() internal {

        uint currentBalance = address(this).balance;

        for (uint i=0; i < _payees.length; i++) {
            if(_shares[i] == 0) continue;
            uint share = (_shares[i] * currentBalance) / _shareDenominator;
            (bool sent,) = payable(_payees[i]).call{value : share}("");
            require(sent, "Failed to distribute to payee.");
        }

        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }

    /// @notice ERC20 fund distribution function.
    /// @dev Uses the payees and shares array to calculate. Will send all remaining funds to the msg.sender.
    function _distributeERC20Shares(address tokenAddress) internal {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint currentBalance = tokenContract.balanceOf(address(this));

        for (uint i=0; i < _payees.length; i++) {
            if(_shares[i] == 0) continue;
            uint share = (_shares[i] * currentBalance) / _shareDenominator;
            tokenContract.transfer(_payees[i], share);
        }

        if(tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
        }
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