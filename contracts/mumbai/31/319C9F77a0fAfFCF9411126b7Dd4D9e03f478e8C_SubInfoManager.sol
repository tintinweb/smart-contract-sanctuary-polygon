// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISubInfoManager.sol";

contract SubInfoManager is ISubInfoManager, Ownable {


    mapping(uint => mapping(uint => SubInfo)) private subInfos; // merchant_code(tokenId) to (tokenId to SubInfo)
    mapping(uint => uint) private subTokenToMerchantToken;
    address public manager;

    modifier onlyManager {
        require(msg.sender == manager, "only can call by s10n contract");
        _;
    }

    function setManager(address _manager) external onlyOwner override {
        require(_manager != address(0), "manager address invalid");
        manager = _manager;
    }

    function createSubInfo(uint merchantCode, uint tokenId, uint planIndex, uint startTime, uint endTime, uint billTime) external onlyManager override {
        require(subInfos[merchantCode][tokenId].subStartTime == 0, "sub info already exist!");
        SubInfo memory info = SubInfo(merchantCode, tokenId, planIndex, startTime, endTime, billTime, true);
        subInfos[merchantCode][tokenId] = info;
        subTokenToMerchantToken[tokenId] = merchantCode;
    }

    function getSubInfo(uint tokenId) external view override returns (SubInfo memory subInfo) {
        uint merchantCode = subTokenToMerchantToken[tokenId];
        subInfo = subInfos[merchantCode][tokenId];
    }

    function updateSubInfo(uint merchantTokenId, uint subTokenId, SubInfo memory subInfo) external onlyManager override {
        subInfos[merchantTokenId][subTokenId] = subInfo;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

interface ISubInfoManager {
    struct SubInfo {
        uint256 merchantTokenId;
        uint256 subTokenId;
        uint256 planIndex; // plan Index (name?)
        uint256 subStartTime; // sub valid start time subStartTime
        uint256 subEndTime; // sub valid end time subEndTime
        uint256 nextBillingTime; // next bill time nextBillingTime
//        uint256 termEndTime; // term end time termEndTime
        bool enabled; // if sub valid
    }

    function setManager(address _manager) external;

    function createSubInfo(
        uint256 merchantTokenId,
        uint256 subTokenId,
        uint256 planIndex,
        uint256 subStartTime,
        uint256 subEndTime,
        uint256 nextBillingTime
//        uint256 termEndTime
    ) external;

    function getSubInfo(uint256 subTokenId)
        external
        view
        returns (SubInfo memory subInfo);

    function updateSubInfo(
        uint256 merchantTokenId,
        uint256 tokenId,
        SubInfo memory subInfo
    ) external;
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