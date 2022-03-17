/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
contract Paybae is Ownable {
    // * paybae commission address
    address payable commissionAddress =
        payable(0x23377998352583Af31A1c0Dc5B21bE4cFEa9db1c);
    uint256 private commissionPercent = 10;

    // * total pool balance
    uint256 public poolBalance;
    // * each user balance
    mapping(address => uint256) public userBalances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        poolBalance = 0;
    }

    // * deposit to pool
    function deposit() public payable {
        require(msg.value >= 10, 'deposit amount must be greater than 10');
        poolBalance += msg.value;
        userBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // * withdraw from pool
    function withdraw(uint256 amount) public {
        require(userBalances[msg.sender] >= amount, 'Insufficient balance');

        // * divide the amount based on commissionPercent
        uint256 commission = (amount * commissionPercent) / 100;
        uint256 userAmount = amount - commission;

        // * send commission to commissionAddress
        commissionAddress.transfer(commission);

        // * send userAmount to user
        payable(msg.sender).transfer(userAmount);

        // * update userBalances
        userBalances[msg.sender] -= amount;
        poolBalance -= amount;

        emit Withdraw(msg.sender, amount);
    }
}