/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/*
 * @title: Token
 * @dev: Interface contract for ERC20 tokens
 */
interface Token {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract RefereReachBounty is Ownable, ReentrancyGuard {
    struct Bounty {
        uint8 status;
        uint256 amount;
        address payable client;
    }
    mapping(uint256 => Bounty) bountyList;
    uint256 totalBounty;
    event BountyCreated(address client, uint8 status, uint256 amount, uint256 index);
    event BountyCancelled(address client, uint8 status, uint256 amount, uint256 index);
    event BountyEditted(address client, uint8 status, uint256 amount, uint256 index);

    function createBounty() external payable {
        require(msg.value > 0);
        totalBounty = totalBounty + 1;
        bountyList[totalBounty].status = 0;
        bountyList[totalBounty].amount = msg.value;
        bountyList[totalBounty].client = msg.sender;
        emit BountyCreated(msg.sender, 0, msg.value, totalBounty);
    }

    function cancelBounty(uint256 _bountyIndex) external {
        require(bountyList[_bountyIndex].status == 0);
        require(bountyList[_bountyIndex].client == msg.sender);
        bountyList[_bountyIndex].status = 1;
        bountyList[_bountyIndex].client.transfer(bountyList[_bountyIndex].amount);
        emit BountyCancelled(msg.sender, 1, bountyList[_bountyIndex].amount, _bountyIndex);
    }

    function completeBounty(uint256 _bountyIndex, address payable hunter) external {
        require(bountyList[_bountyIndex].status == 0);
        require(bountyList[_bountyIndex].client == msg.sender);
        bountyList[_bountyIndex].status = 2;
        hunter.transfer(bountyList[_bountyIndex].amount);
        emit BountyCancelled(msg.sender, 1, bountyList[_bountyIndex].amount, _bountyIndex);
    }

    function editBounty(uint256 _bountyIndex, uint256 _amount) external payable {
        require(bountyList[_bountyIndex].status == 0);
        require(bountyList[_bountyIndex].client == msg.sender);
        require(_amount < bountyList[_bountyIndex].amount);
        if(_amount > 0) {
            bountyList[_bountyIndex].client.transfer(bountyList[_bountyIndex].amount - _amount);
            bountyList[_bountyIndex].amount = _amount;
        } else {
            require(msg.value > 0);
            bountyList[_bountyIndex].amount = bountyList[_bountyIndex].amount + msg.value;
        }
        emit BountyEditted(msg.sender, 0, bountyList[_bountyIndex].amount, _bountyIndex);
    }

    function getBounty(uint256 _bountyIndex)
        public
        view
        returns (
        address client, 
        uint256 amount, 
        uint8 status
        )
    {
        client = bountyList[_bountyIndex].client;
        amount = bountyList[_bountyIndex].amount;
        status = bountyList[_bountyIndex].status;
    }

}