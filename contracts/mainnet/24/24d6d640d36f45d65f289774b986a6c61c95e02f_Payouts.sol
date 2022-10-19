// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Owned} from "../lib/solmate/src/auth/Owned.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/// @title Payouts
/// @author Oleanji
/// @notice A contract to pay editors

contract Payouts is Owned {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error PayoutsContract__PayoutFailed();
    error PayoutsContract__AddressCannotMakePayouts();
    error PayoutsContract__BalanceNotEnough();

    /// -----------------------------------------------------------------------
    /// Mapping
    /// -----------------------------------------------------------------------
    mapping(address => bool) public payerAddresses;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor() Owned(msg.sender) {}

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Add address to payers
    /// @param payer The address to add
    function addAddress(address payer) external onlyOwner {
        payerAddresses[payer] = true;
        emit AddressToPayersList(payer, true);
    }

    /// @notice Remove address from payers
    /// @param payer The address to remove
    function removeAddress(address payer) external onlyOwner {
        payerAddresses[payer] = false;
        emit AddressToPayersList(payer, false);
    }

    /// @notice Single Payout
    /// @param receiver The address being transferred to
    function singlePayout(
        address token,
        address receiver,
        uint amount
    ) public {
        if (payerAddresses[msg.sender] == false)
            revert PayoutsContract__AddressCannotMakePayouts();
        if (IERC20(token).balanceOf(address(this)) < amount)
            revert PayoutsContract__BalanceNotEnough();
        bool success = IERC20(token).transfer(receiver, amount);
        if (!success) revert PayoutsContract__PayoutFailed();

        emit TokenPayout(address(this), receiver, amount, token);
    }

    /// @notice Multiple Payout
    /// @param receivers The addresses being transferred to
    function multiplePayout(
        address token,
        address[] calldata receivers,
        uint[] calldata amounts
    ) external {
        uint totalAmount;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        if (IERC20(token).balanceOf(address(this)) < totalAmount)
            revert PayoutsContract__BalanceNotEnough();

        for (uint i = 0; i < receivers.length; i++) {
            singlePayout(token, receivers[i], amounts[i]);
        }
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------
    event AddressToPayersList(address indexed _account, bool _action);

    event TokenPayout(
        address indexed _from,
        address _receiver,
        uint _amount,
        address _token
    );
}