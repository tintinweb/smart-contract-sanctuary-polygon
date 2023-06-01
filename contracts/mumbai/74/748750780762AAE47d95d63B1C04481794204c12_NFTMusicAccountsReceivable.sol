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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMusicAccountsReceivable is Ownable {
    struct Recipient {
        address payable recipient;
        uint256 share;
    }

    Recipient[] public recipients;

    event PaymentSplit(address indexed payee, uint256 amount);
    event RecipientsUpdated(Recipient[]);

    constructor(address payable[] memory _recipients, uint256[] memory _shares) {
        updateRecipients(_recipients, _shares);
    }

    ////////////////////
    // CORE FUNCTIONS //
    ////////////////////

    function updateRecipients(
        address payable[] memory _recipients,
        uint256[] memory _shares
    ) public onlyOwner {
        require(_recipients.length == _shares.length, "Recipients and shares length mismatch");

        delete recipients;
        uint256 totalShares = 0;

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_shares[i] > 0, "Cannot add a recipient with 0 shares");
            totalShares += _shares[i];
            recipients.push(Recipient(_recipients[i], _shares[i]));
        }

        require(totalShares == 100, "Total shares must be 100"); //could increase for percision

        emit RecipientsUpdated(recipients);
    }

    /////////////////////
    // GETTER FUCNTIONS//
    /////////////////////

    function getTotalRecipients() public view returns (uint256) {
        return recipients.length;
    }

    function getRecipientData() public view returns (Recipient[] memory) {
        return recipients;
    }

    ///////////////////////
    // PAYMENT FUNCTIONS //
    ///////////////////////

    //this is here for edge cases
    function withdraw(address payable recipient) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    //truncation issue -- common behavior of uint256's due to not having a floating point
    receive() external payable {
        uint256 totalReceived = msg.value;

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = (totalReceived * recipients[i].share) / 100;
            (bool success, ) = recipients[i].recipient.call{value: amount}("");
            require(success, "Transfer failed");

            emit PaymentSplit(recipients[i].recipient, amount);
        }
    }
}