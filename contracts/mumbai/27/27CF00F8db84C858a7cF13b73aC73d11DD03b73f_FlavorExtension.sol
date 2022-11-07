// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFlavorExtension} from "../../interfaces/IFlavorExtension.sol";
import {IScoreModule} from "../../interfaces/IScoreModule.sol";
import {IGlobals} from "../../interfaces/IGlobals.sol";
import {ExtensionBase} from "../bases/ExtensionBase.sol";
import {ExtensionLogic} from "../../libraries/ExtensionLogic.sol";

contract FlavorExtension is IFlavorExtension, ExtensionBase {
    mapping(uint256 => mapping(uint256 => FlavorStruct)) internal _flavors;
    mapping(uint256 => uint256) internal _flavorCount;

    constructor(address owner) ExtensionBase(owner) {}

    function addFlavor(uint256 profileId) external override onlyIceCandy {
        FlavorType[] memory flavorTypes = ExtensionLogic.judgeFlavorExtension(
            IScoreModule(IGlobals(_globals).getScoreModule()).getScore(profileId)
        );
        for (uint256 i = 0; i < flavorTypes.length; i++) {
            bool hasFlavor = false;
            for (uint256 j = 0; j < _flavorCount[profileId]; j++) {
                if (_flavors[profileId][j + 1].flavorType == flavorTypes[i]) {
                    hasFlavor = true;
                    break;
                }
            }
            if (!hasFlavor) {
                ++_flavorCount[profileId];
                _flavors[profileId][_flavorCount[profileId]] = FlavorStruct(flavorTypes[i], false);
                emit FlavorAdded(profileId, _flavorCount[profileId], flavorTypes[i], block.number);
            }
        }
    }

    function activate(uint256 profileId, uint256 extensionId) external override onlyProfile {
        _flavors[profileId][extensionId].active = true;
        emit FlavorActivated(profileId, extensionId, block.number);
    }

    function deactivate(uint256 profileId, uint256 extensionId) external override onlyProfile {
        _flavors[profileId][extensionId].active = false;
        emit FlavorDeactivated(profileId, extensionId, block.number);
    }

    function getFlavor(uint256 profileId) external view override returns (FlavorStruct[] memory) {
        FlavorStruct[] memory flavorArray = new FlavorStruct[](_flavorCount[profileId]);
        for (uint256 i = 0; i < _flavorCount[profileId]; i++) {
            flavorArray[i] = _flavors[profileId][i + 1];
        }
        return flavorArray;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFlavorExtension {
    struct FlavorStruct {
        FlavorType flavorType;
        bool active;
    }

    enum FlavorType {
        RICH,
        REFRESHING,
        CHOCOLATE,
        FRUITY,
        ELEGANT
    }

    function addFlavor(uint256 profileId) external;

    function activate(uint256 profileId, uint256 moduleId) external;

    function deactivate(uint256 profileId, uint256 moduleId) external;

    function getFlavor(uint256 profileId) external view returns (FlavorStruct[] memory);

    event FlavorAdded(uint256 indexed profileId, uint256 indexed extensionId, FlavorType flavorType, uint256 blockNumber);

    event FlavorActivated(uint256 indexed profileId, uint256 indexed extensionId, uint256 blockNumber);

    event FlavorDeactivated(uint256 indexed profileId, uint256 indexed extensionId, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IScoreModule {
    enum ScoreType {
        PROFILE,
        NFT,
        POAP
    }

    struct ScoreStruct {
        ScoreType scoreType;
        uint256 point;
    }

    function createScore(uint256 profileId) external;

    function getScore(uint256 profileId) external view returns (ScoreStruct[] memory);

    event ScoreCreated(uint256 indexed profileId, uint256 blockNumber);
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
pragma solidity ^0.8.10;

import {IScoreModule} from "../interfaces/IScoreModule.sol";
import {IFlavorExtension} from "../interfaces/IFlavorExtension.sol";

library ExtensionLogic {
    function judgeFlavorExtension(IScoreModule.ScoreStruct[] memory score)
        internal
        pure
        returns (IFlavorExtension.FlavorType[] memory)
    {
        if (score[0].point >= 500) {
            IFlavorExtension.FlavorType[] memory flavorTypes = new IFlavorExtension.FlavorType[](5);
            flavorTypes[0] = IFlavorExtension.FlavorType.RICH;
            flavorTypes[1] = IFlavorExtension.FlavorType.REFRESHING;
            flavorTypes[2] = IFlavorExtension.FlavorType.CHOCOLATE;
            flavorTypes[3] = IFlavorExtension.FlavorType.FRUITY;
            flavorTypes[4] = IFlavorExtension.FlavorType.ELEGANT;
            return flavorTypes;
        } else if (score[0].point >= 400) {
            IFlavorExtension.FlavorType[] memory flavorTypes = new IFlavorExtension.FlavorType[](4);
            flavorTypes[0] = IFlavorExtension.FlavorType.RICH;
            flavorTypes[1] = IFlavorExtension.FlavorType.REFRESHING;
            flavorTypes[2] = IFlavorExtension.FlavorType.CHOCOLATE;
            flavorTypes[3] = IFlavorExtension.FlavorType.FRUITY;
            return flavorTypes;
        } else if (score[0].point >= 300) {
            IFlavorExtension.FlavorType[] memory flavorTypes = new IFlavorExtension.FlavorType[](3);
            flavorTypes[0] = IFlavorExtension.FlavorType.RICH;
            flavorTypes[1] = IFlavorExtension.FlavorType.REFRESHING;
            flavorTypes[2] = IFlavorExtension.FlavorType.CHOCOLATE;
            return flavorTypes;
        } else if (score[0].point >= 200) {
            IFlavorExtension.FlavorType[] memory flavorTypes = new IFlavorExtension.FlavorType[](2);
            flavorTypes[0] = IFlavorExtension.FlavorType.RICH;
            flavorTypes[1] = IFlavorExtension.FlavorType.REFRESHING;
            return flavorTypes;
        } else if (score[0].point >= 100) {
            IFlavorExtension.FlavorType[] memory flavorTypes = new IFlavorExtension.FlavorType[](1);
            flavorTypes[0] = IFlavorExtension.FlavorType.RICH;
            return flavorTypes;
        } else {
            return new IFlavorExtension.FlavorType[](0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IGlobals} from "../../interfaces/IGlobals.sol";

abstract contract ExtensionBase is Ownable {
    address internal _globals;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    modifier onlyProfile() {
        require(msg.sender == IGlobals(_globals).getProfile(), "ExtensionBase: only profile");
        _;
    }

    modifier onlyIceCandy() {
        require(msg.sender == IGlobals(_globals).getIceCandy(), "ExtensionBase: only icecandy");
        _;
    }

    function setGlobals(address globals) external onlyOwner {
        _globals = globals;
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