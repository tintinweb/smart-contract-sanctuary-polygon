/**
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

// File: openzeppelin-solidity/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/staking.sol

pragma solidity ^0.7.0;

contract IERC721 {
    function transferFrom(address, address, uint) public {}
    function safeTransferFrom(address, address, uint) public {}
    function getMultiplier(uint) public returns (uint) {}
}

contract IERC20 {
    function transferFrom(address, address, uint) public {}
    function safeTransferFrom(address, address, uint) public {}
    function safeTransfer(address, uint) public {}
}

struct MetaData {
    uint tokenId;
    bool claimed;
}

contract Staking is Ownable {
    IERC721 keyNft;
    IERC20 ctzn;

    uint baseReward = 180; // ctzn reward
    mapping(address => MetaData) staked;
    uint public stakedAmount;
    bool claimable;

    constructor(address _key, address _ctzn) {
        keyNft = IERC721(_key);
        ctzn = IERC20(_ctzn);
        claimable = false;
    }

    function setClaimable(bool _claimable) public onlyOwner {
        claimable = _claimable;
    }
 
    function deposit(uint tokenId) public {
        keyNft.safeTransferFrom(msg.sender, address(this), tokenId);
        stakedAmount++;
        staked[msg.sender] = MetaData({
            tokenId: tokenId,
            claimed: false
        });
    }

    function claim() external {
        MetaData storage metaData = staked[msg.sender];
        require(claimable, "You cannot claim your reward yet.");
        require(metaData.tokenId == 0, "You have already staked!");
        require(!metaData.claimed, "You have already claimed!");

        // get multiplier
        uint multiplier = keyNft.getMultiplier(metaData.tokenId);
        uint reward = baseReward * multiplier;
        reward *= (10 ** 18);

        ctzn.safeTransfer(payable(msg.sender), reward);
        metaData.claimed = true;
    }
}