// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IScoreModule} from "../../interfaces/IScoreModule.sol";
import {ModuleBase} from "../bases/ModuleBase.sol";
import {IGlobals} from "../../interfaces/IGlobals.sol";
import {IIceCandy} from "../../interfaces/IIceCandy.sol";
import {IProfile} from "../../interfaces/IProfile.sol";
import {ScoreLogic} from "../../libraries/ScoreLogic.sol";

contract ScoreModule is IScoreModule, ModuleBase {
    mapping(uint256 => mapping(address => ScoreStruct)) internal _scores;

    constructor(address owner) ModuleBase(owner) {}

    function createScore(uint256 profileId) external override onlyProfileAndIceCandy {
        _scores[profileId][address(0)].scoreType = IScoreModule.ScoreType.PROFILE;
        _scores[profileId][address(0)].point = _getProfileScore(profileId);
        _scores[profileId][IGlobals(_globals).getNFTCollectionModule()].scoreType = IScoreModule.ScoreType.NFT;
        _scores[profileId][IGlobals(_globals).getNFTCollectionModule()].point = _getNFTScore(profileId);
        _scores[profileId][IGlobals(_globals).getPOAPCollectionModule()].scoreType = IScoreModule.ScoreType.POAP;
        _scores[profileId][IGlobals(_globals).getPOAPCollectionModule()].point = _getPOAPScore(profileId);

        emit ScoreCreated(profileId, block.number);
    }

    function getScore(uint256 profileId) external view override returns (ScoreStruct[] memory) {
        ScoreStruct[] memory scoreArray = new ScoreStruct[](3);
        scoreArray[0] = _scores[profileId][address(0)];
        scoreArray[1] = _scores[profileId][IGlobals(_globals).getNFTCollectionModule()];
        scoreArray[2] = _scores[profileId][IGlobals(_globals).getPOAPCollectionModule()];
        return scoreArray;
    }

    function _getProfileScore(uint256 profileId) internal view returns (uint256) {
        return
            ScoreLogic.calcProfileScore(
                IIceCandy(IGlobals(_globals).getIceCandy()).numberOfSentProfiles(profileId),
                IIceCandy(IGlobals(_globals).getIceCandy()).numberOfReceivedProfiles(profileId),
                IIceCandy(IGlobals(_globals).getIceCandy()).numberOfSentIceCandies(profileId),
                IIceCandy(IGlobals(_globals).getIceCandy()).numberOfReceivedIceCandies(profileId)
            );
    }

    function _getNFTScore(uint256 profileId) internal view returns (uint256) {
        return ScoreLogic.calcNFTScore(IProfile(IGlobals(_globals).getProfile()).getNFTCollection(profileId).length);
    }

    function _getPOAPScore(uint256 profileId) internal view returns (uint256) {
        return ScoreLogic.calcNFTScore(IProfile(IGlobals(_globals).getProfile()).getPOAPCollection(profileId).length);
    }
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

interface IIceCandy {
    enum IceCandyType {
        NOT_REVEALED,
        REVEALED,
        LUCKY,
        UNLUCKY
    }

    struct IceCandyStruct {
        IceCandyType iceCandyType;
        uint256 sentProfileId;
        address sentModule;
        uint256 sentModuleId;
    }

    struct SentIceCandyStruct {
        uint256 tokenId;
        uint256 profileId; // on _sentHistories it means to, on _receivedHistories it means from
        address module;
        uint256 moduleId;
    }

    function setGlobals(address globals) external;

    function send(
        uint256 profileId,
        address module,
        uint256 moduleId
    ) external;

    function mint(address to) external;

    function getIceCandy(uint256 tokenId) external view returns (IceCandyStruct memory);

    function balanceOfRevealed(address owner) external view returns (uint256);

    function balanceOfNotRevealed(address owner) external view returns (uint256);

    function balanceOfLucky(address owner) external view returns (uint256);

    function balanceOfUnlucky(address owner) external view returns (uint256);

    function numberOfSentProfiles(uint256 profileId) external view returns (uint256);

    function numberOfReceivedProfiles(uint256 profileId) external view returns (uint256);

    function numberOfSentIceCandies(uint256 profileId) external view returns (uint256);

    function numberOfReceivedIceCandies(uint256 profileId) external view returns (uint256);

    function getSentProfileIds(uint256 profileId) external view returns (uint256[] memory);

    function getReceivedProfileIds(uint256 profileId) external view returns (uint256[] memory);

    function getSentIceCandies(uint256 profileId) external view returns (SentIceCandyStruct[] memory);

    function getReceivedIceCandies(uint256 profileId) external view returns (SentIceCandyStruct[] memory);

    event Sent(
        uint256 indexed tokenId,
        uint256 indexed from,
        uint256 indexed to,
        address module,
        uint256 moduleId,
        IIceCandy.IceCandyType iceCandyType,
        uint256 blockNumber
    );

    event Mint(uint256 indexed tokenId, address indexed to, IceCandyType indexed iceCandyType, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {INFTCollectionModule} from "./INFTCollectionModule.sol";
import {ISNSAccountModule} from "./ISNSAccountModule.sol";
import {IScoreModule} from "./IScoreModule.sol";
import {IMirrorModule} from "./IMirrorModule.sol";
import {ISkillModule} from "./ISkillModule.sol";
import {IFlavorExtension} from "./IFlavorExtension.sol";

interface IProfile {
    struct ProfileStruct {
        address[] wallets;
        string name;
        string introduction;
        string imageURI;
        uint256 snsAccountsPubId;
    }

    struct CreateProfileStructData {
        string name;
        string introduction;
        string imageURI;
        INFTCollectionModule.NFTStruct[] nfts;
        INFTCollectionModule.NFTStruct[] poaps;
        ISNSAccountModule.SNSAccountStruct[] snsAccounts;
        ISkillModule.SkillStruct[] skills;
    }

    function setGlobals(address globals) external;

    function createProfile(CreateProfileStructData calldata vars) external returns (uint256);

    function createNFTCollection(uint256 profileId, INFTCollectionModule.NFTStruct[] calldata nfts) external;

    function createPOAPCollection(uint256 profileId, INFTCollectionModule.NFTStruct[] calldata poaps) external;

    function createSNSAccount(uint256 profileId, ISNSAccountModule.SNSAccountStruct[] calldata snsAccounts) external;

    function addMirror(uint256 profileId, IMirrorModule.MirrorStruct calldata mirror) external;

    function addSkill(uint256 profileId, ISkillModule.SkillStruct calldata skill) external;

    function activateFlavor(uint256 profileId, uint256 extensionId) external;

    function deactivateFlavor(uint256 profileId, uint256 extensionId) external;

    function addWallet(uint256 profileId, address wallet) external;

    function getProfile(uint256 profileId) external view returns (ProfileStruct memory);

    function getNFTCollection(uint256 profileId) external view returns (INFTCollectionModule.NFTStruct[] memory);

    function getPOAPCollection(uint256 profileId) external view returns (INFTCollectionModule.NFTStruct[] memory);

    function getSNSAccounts(uint256 profileId) external view returns (ISNSAccountModule.SNSAccountStruct[] memory);

    function getScore(uint256 profileId) external view returns (IScoreModule.ScoreStruct[] memory);

    function getMirror(uint256 profileId) external view returns (IMirrorModule.MirrorStruct[] memory);

    function getSkill(uint256 profileId) external view returns (ISkillModule.SkillStruct[] memory);

    function getFlavor(uint256 profileId) external view returns (IFlavorExtension.FlavorStruct[] memory);

    function getProfileId(address wallet) external view returns (uint256);

    event ProfileCreated(uint256 indexed profileId, address indexed owner, uint256 blockNumber);

    event WalletAdded(uint256 profileId, address wallet);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IIceCandy} from "../interfaces/IIceCandy.sol";

library ScoreLogic {
    function calcProfileScore(
        uint256 numberOfSentProfiles,
        uint256 unmberOfReceivedProfiles,
        uint256 numberOfSentIceCandies,
        uint256 numberOfReceivedIceCandies
    ) internal pure returns (uint256) {
        uint256 score;
        score += numberOfSentProfiles * 100;
        score += unmberOfReceivedProfiles * 100;
        score += numberOfSentIceCandies * 10;
        score += numberOfReceivedIceCandies * 10;
        return score;
    }

    function calcNFTScore(uint256 numberOfNFTs) internal pure returns (uint256) {
        return numberOfNFTs * 10;
    }

    function calcPOAPScore(uint256 numberOfPOAPs) internal pure returns (uint256) {
        return numberOfPOAPs * 10;
    }
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

interface INFTCollectionModule {
    struct NFTStruct {
        uint256 chainId;
        address contractAddress;
        uint256 tokenId;
        string tokenURI; // for cross chain
        address owner;
    }

    function createCollection(uint256 profileId, NFTStruct[] calldata nfts) external;

    function getCollection(uint256 profileId) external view returns (NFTStruct[] memory);

    event NFTCollectionCreated(uint256 indexed profileId, address indexed module, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISNSAccountModule {
    struct SNSAccountStruct {
        string service;
        string userId;
        string userPageURL;
        address wallet;
    }

    function createSNSAccount(uint256 profileId, SNSAccountStruct[] calldata sns) external;

    function getSNSAccounts(uint256 profileId) external view returns (SNSAccountStruct[] memory);

    event SNSAccountCreated(uint256 indexed profileId, uint256 blockNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISkillModule {
    struct SkillStruct {
        string name;
        string description;
        string link;
    }

    function addSkill(uint256 profileId, SkillStruct calldata skill) external;

    function getSkill(uint256 profileId) external view returns (SkillStruct[] memory);

    event SkillAdded(uint256 indexed profileId, uint256 indexed moduleId, uint256 blockNumber);
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