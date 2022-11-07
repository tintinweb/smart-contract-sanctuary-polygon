// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IGlobals} from "../interfaces/IGlobals.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Globals is IGlobals, Ownable {
    address private _iceCandy;
    address private _profile;
    address private _nftCollectionModule;
    address private _poapCollectionModule;
    address private _scoreModule;
    address private _mirrorModule;
    address private _skillModule;
    address private _snsAccountModule;
    address private _colorExtension;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    function setIceCandy(address icecandy) external override onlyOwner {
        _iceCandy = icecandy;
    }

    function setProfile(address profile) external override onlyOwner {
        _profile = profile;
    }

    function setNFTCollectionModule(address nftCollectionModule_) external override onlyOwner {
        _nftCollectionModule = nftCollectionModule_;
    }

    function setPOAPCollectionModule(address poapCollectionModule_) external override onlyOwner {
        _poapCollectionModule = poapCollectionModule_;
    }

    function setScoreModule(address scoreModule_) external override onlyOwner {
        _scoreModule = scoreModule_;
    }

    function setMirrorModule(address mirrorModule_) external override onlyOwner {
        _mirrorModule = mirrorModule_;
    }

    function setSkillModule(address skillModule_) external override onlyOwner {
        _skillModule = skillModule_;
    }

    function setSNSAccountModule(address snsAccountModule_) external override onlyOwner {
        _snsAccountModule = snsAccountModule_;
    }

    function setFlavorExtension(address colorExtension_) external override onlyOwner {
        _colorExtension = colorExtension_;
    }

    function getIceCandy() external view override returns (address) {
        return _iceCandy;
    }

    function getProfile() external view override returns (address) {
        return _profile;
    }

    function getNFTCollectionModule() external view override returns (address) {
        return _nftCollectionModule;
    }

    function getPOAPCollectionModule() external view override returns (address) {
        return _poapCollectionModule;
    }

    function getScoreModule() external view override returns (address) {
        return _scoreModule;
    }

    function getMirrorModule() external view override returns (address) {
        return _mirrorModule;
    }

    function getSkillModule() external view override returns (address) {
        return _skillModule;
    }

    function getSNSAccountModule() external view override returns (address) {
        return _snsAccountModule;
    }

    function getFlavorExtension() external view override returns (address) {
        return _colorExtension;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGlobals {
    function setIceCandy(address icecandy) external;

    function setProfile(address profile) external;

    function setNFTCollectionModule(address nftCollectionModule) external;

    function setPOAPCollectionModule(address poapCollectionModule) external;

    function setSNSAccountModule(address snsAccountModule) external;

    function setScoreModule(address scoreModule) external;

    function setMirrorModule(address mirrorModule) external;

    function setSkillModule(address skillModule) external;

    function setFlavorExtension(address flavorExtension) external;

    function getIceCandy() external view returns (address);

    function getProfile() external view returns (address);

    function getNFTCollectionModule() external view returns (address);

    function getPOAPCollectionModule() external view returns (address);

    function getSNSAccountModule() external view returns (address);

    function getScoreModule() external view returns (address);

    function getMirrorModule() external view returns (address);

    function getSkillModule() external view returns (address);

    function getFlavorExtension() external view returns (address);
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