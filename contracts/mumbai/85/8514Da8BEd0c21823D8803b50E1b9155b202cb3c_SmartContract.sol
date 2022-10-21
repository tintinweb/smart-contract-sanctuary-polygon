// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SmartContract is Ownable {
    uint256 public _counter;

    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        _counter = 0;
    }

    uint256 private comisionlvl1 = 20;
    uint256 private comisionlvl2 = 20;
    uint256 private comisionlvl3 = 40;

    mapping(uint256 => address) internal addressLevel1;
    mapping(uint256 => address) internal addressLevel2;
    mapping(uint256 => address) internal addressLevel3;

    address payable[] public _addressLevel1;
    address payable[] public _addressLevel2;
    address payable[] public _addressLevel3;

    event Staked(address indexed user, uint256 amount);

    mapping(address => uint256) public ownerPayableCount;

    struct Stakeholder {
        address user;
        uint256 lvl;
        uint256 sinceBlock;
    }

    mapping(uint256 => Stakeholder) public stakeInfo;

    Stakeholder[] public stakeholders;

    receive() external payable {
        require(msg.value > 0, "Required that value be up than 0");

        uint256 amount = (address(this).balance) * 10**18;

        for (uint256 i = 0; i < _addressLevel1.length; i++) {
            uint256 percentlvl1 = (comisionlvl1 / 100) * amount;
            uint256 share = percentlvl1 / _addressLevel1.length;

            _addressLevel1[i].transfer(1 ether);

            emit Staked(_addressLevel1[i], share);
        }

        for (uint256 i = 0; i < _addressLevel2.length; i++) {
            uint256 percentlvl2 = (comisionlvl1 / 100) * amount;
            uint256 share = percentlvl2 / _addressLevel2.length;
            _addressLevel2[i].transfer(1 ether);
            emit Staked(_addressLevel2[i], share);
        }

        for (uint256 i = 0; i < _addressLevel3.length; i++) {
            uint256 percentlvl3 = (comisionlvl3 / 100) * amount;
            uint256 share = percentlvl3 / _addressLevel3.length;
            _addressLevel3[i].transfer(1 ether);
            emit Staked(_addressLevel3[i], share);
        }
    }

    function registerMember(uint256 lvl, address payable wallet)
        external
        onlyOwner
        returns (bool)
    {
        require(
            lvl > 0 && lvl < 4,
            "Required that value stablished be a level between 1 and 3"
        );

        ownerPayableCount[_msgSender()] = _counter;
        stakeholders.push();
        stakeholders[_counter].user = _msgSender();
        stakeholders[_counter].lvl = lvl;
        stakeInfo[_counter] = Stakeholder(_msgSender(), lvl, block.timestamp);

        if (lvl == 1) {
            addressLevel1[_counter] = _msgSender();
            _addressLevel1.push(wallet);
        }

        if (lvl == 2) {
            addressLevel2[_counter] = _msgSender();
            _addressLevel2.push(wallet);
        }

        if (lvl == 3) {
            addressLevel3[_counter] = _msgSender();
            _addressLevel3.push(wallet);
        }

        _counter++;
        return true;
    }

    function verifyAmount() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function _withDraw() external onlyOwner returns (bool) {
        uint256 amount = address(this).balance;
        require(
            payable(address(_msgSender())).send(amount),
            "WithdrawOwner: Failed to transfer token to fee contract"
        );
        return true;
    }

    function _withDrawWallet(address payable sendTokens)
        external
        onlyOwner
        returns (bool)
    {
        uint256 amount = address(this).balance;
        require(
            payable(address(sendTokens)).send(amount),
            "WithdrawOwner: Failed to transfer token to fee contract"
        );
        return true;
    }

    function payToUsers() public onlyOwner {
        uint256 amount = (address(this).balance) * 10**18;

        for (uint256 i = 0; i < _addressLevel1.length; i++) {
            uint256 percentlvl1 = (comisionlvl1 / 100) * amount;
            uint256 share = percentlvl1 / _addressLevel1.length;

            _addressLevel1[i].transfer(share);
            emit Staked(_addressLevel1[i], share);
        }

        for (uint256 i = 0; i < _addressLevel2.length; i++) {
            uint256 percentlvl2 = (comisionlvl1 / 100) * amount;
            uint256 share = percentlvl2 / _addressLevel2.length;
            _addressLevel2[i].transfer(share);
            emit Staked(_addressLevel2[i], share);
        }

        for (uint256 i = 0; i < _addressLevel3.length; i++) {
            uint256 percentlvl3 = (comisionlvl3 / 100) * amount;
            uint256 share = percentlvl3 / _addressLevel3.length;
            _addressLevel3[i].transfer(share);
            emit Staked(_addressLevel3[i], share);
        }
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