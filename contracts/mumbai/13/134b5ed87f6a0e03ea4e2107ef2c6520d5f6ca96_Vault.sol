/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.12;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Vault is Context, Pausable {
    address[] public _owner;

    mapping(address => bool) public authorized;

    event SpenderAccessGranted(address);

    event SpenderAccessRevoked(address);

    constructor() {
        _owner.push(address(0x3BC14f7b6c5871994CAAfDcc5Fd42d436b6f4286));
        _owner.push(address(0x616A9B8bfAf2189f7B896EDC75C9AF67af89Df93));
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()) , " caller is not the owner");
        _;
    }


    modifier requiresAuthorization() {
        require(
            authorized[msg.sender],
            "Vault#requiresAuthorization: Sender not authorized"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address[] memory) {
        return _owner;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) internal view virtual returns (bool) {
        for (uint i=0;i<_owner.length;i++){
            if(caller == _owner[i]){
                return true;
            }
        }
        return false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function authorizeSpender(address spender, bool val) public onlyOwner {
        authorized[spender] = val;
        if (val) {
            emit SpenderAccessGranted(spender);
        } else {
            emit SpenderAccessRevoked(spender);
        }
    }

    function transferFromVault(address to, uint256 amount)
        public
        requiresAuthorization
        returns (bool)
    {
        (bool success, ) = payable(to).call{value: amount}("");
        return success;
    }
}