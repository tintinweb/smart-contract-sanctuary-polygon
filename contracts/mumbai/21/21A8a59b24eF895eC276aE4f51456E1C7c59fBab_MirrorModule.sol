// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IMirrorModule} from "../../interfaces/IMirrorModule.sol";
import {ModuleBase} from "../bases/ModuleBase.sol";

contract MirrorModule is IMirrorModule, ModuleBase {
    mapping(uint256 => mapping(uint256 => MirrorStruct)) internal _mirrors;
    mapping(uint256 => uint256) internal _mirrorCount;

    constructor(address owner) ModuleBase(owner) {}

    function addMirror(uint256 profileId, MirrorStruct calldata mirror)
        external
        override
        onlyProfile
    {
        ++_mirrorCount[profileId];
        _mirrors[profileId][_mirrorCount[profileId]] = mirror;
        
        emit MirrorAdded(profileId, _mirrorCount[profileId], block.number);
    }

    function getMirror(uint256 profileId) external view override returns (MirrorStruct[] memory) {
        MirrorStruct[] memory mirrorArray = new MirrorStruct[](_mirrorCount[profileId]);
        for (uint256 i = 0; i < _mirrorCount[profileId]; i++) {
            mirrorArray[i] = _mirrors[profileId][i + 1];
        }
        return mirrorArray;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMirrorModule {
    struct MirrorStruct {
        string hoge; // todo: add fields
    }

    function addMirror(uint256 profileId, MirrorStruct calldata mirror) external;

    function getMirror(uint256 profileId) external view returns (MirrorStruct[] memory);

    event MirrorAdded(uint256 indexed profileId, uint256 indexed moduleId, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IGlobals} from "../../interfaces/IGlobals.sol";

abstract contract ModuleBase is Ownable {
    address internal _globals;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    modifier onlyProfile() {
        require(msg.sender == IGlobals(_globals).getProfile(), "ModuleBase: only profile");
        _;
    }

    modifier onlyProfileAndIceCandy() {
        require(
            msg.sender == IGlobals(_globals).getProfile() || msg.sender == IGlobals(_globals).getIceCandy(),
            "ModuleBase: only profile"
        );
        _;
    }

    function setGlobals(address globals) external onlyOwner {
        _globals = globals;
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