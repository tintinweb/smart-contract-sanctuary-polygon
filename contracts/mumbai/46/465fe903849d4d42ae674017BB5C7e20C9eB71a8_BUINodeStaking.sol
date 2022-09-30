// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BUINodeStaking is Ownable {

    uint256 public stakingCost = 0.1 ether;

    struct Node {
        address payable owner;
        uint256 stake;
        bytes4 ip;
    }

    mapping(address => Node) private _nodeByAddress;
    Node[] private _nodes;

    event NodeRegistrationChanged(Node node, string status);

    // TODO: add more security to prevent anyone from joining the stake pool and gaining access to the decryption keys in LitProtocol

    constructor(uint256 stakingCost_) {
        stakingCost = stakingCost_;
    }

    function withdraw() external onlyOwner() {
        uint256 balance = address(this).balance;
        uint256 staked = totalStaked();

        if (balance > staked) {
            payable(owner()).transfer(balance - staked);
        }
    }

    function totalStaked() public view returns (uint256 total) {
        for (uint i = 0; i < _nodes.length; i++) {
            total += _nodes[i].stake;
        }
    }

    function register(bytes4 ip) external payable {
        Node storage node = _nodeByAddress[msg.sender];

        if (node.owner == address(0)) {
            node.owner = payable(msg.sender);
        }

        if (node.stake < stakingCost) {
            require(msg.value >= (stakingCost - node.stake), "Not enough stake");
            node.stake += msg.value;
        }

        node.ip = ip;
        _nodes.push(node);

        emit NodeRegistrationChanged(node, "registered");
    }

    function unregister() external {
        require(_nodeByAddress[msg.sender].stake > 0, "No stake found");

        Node storage node = _nodeByAddress[msg.sender];
        uint256 stake = node.stake;

        for (uint i = 0; i < _nodes.length; i++) {
            if (_nodes[i].owner == msg.sender) {
                for (uint j = i; j < _nodes.length-1; j++) {
                    _nodes[j] = _nodes[j+1];
                }
                _nodes.pop();
            }
        }

        _nodeByAddress[msg.sender].stake = 0;
        _nodeByAddress[msg.sender].ip = 0;
        payable(msg.sender).transfer(stake);

        emit NodeRegistrationChanged(node, "unregistered");
    }

    function balance(address node) external view returns (uint256) {
        return _nodeByAddress[node].stake;
    }

    function verify(address node) external view returns (bool) {
        return _nodeByAddress[node].stake > 0 && _nodeByAddress[node].ip != 0;
    }

    function setStakingCost(uint256 stakingCost_) external onlyOwner {
        stakingCost = stakingCost_;
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