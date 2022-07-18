/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract VoteTimer is Ownable {
    uint256 public start;
    uint256 public timeSpan;
    uint256 public executionWindow;

    string public name;

    constructor(
        uint256 _start,
        uint256 _timeSpan,
        uint256 _executionWindow,
        string memory _name
    ) {
        start = _start;
        timeSpan = _timeSpan;
        executionWindow = _executionWindow;
        name = _name;

        // owner is gnosis wallet
        _transferOwnership(0x2580f9954529853Ca5aC5543cE39E9B5B1145135);
    }

    function changeParams(
        uint256 _start,
        uint256 _timeSpan,
        uint256 _executionWindow
    ) external onlyOwner {
        start = _start;
        timeSpan = _timeSpan;
        executionWindow = _executionWindow;
    }

    function canExecute2WeekVote() public view returns (bool) {
        // ---|------------------------- timeSpan -------------------------|---
        //    |--- executionWindow ---|
        //               true                          false
        return (block.timestamp - start) % timeSpan <= executionWindow;
    }
}