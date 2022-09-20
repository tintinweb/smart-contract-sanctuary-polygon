// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ILevels.sol";
import "../interfaces/IExperience.sol";
import "../interfaces/ICivilizations.sol";

/**
 * @title Experience
 * @notice This contract tracks and assigns experience of all the characters stored on the [Civilizations](/docs/core/Civilizations.md) instance.
 *
 * @notice Implementation of the [IExperience](/docs/interfaces/IExperience.md) interface.
 */
contract Experience is IExperience, Ownable {
    // =============================================== Storage ========================================================

    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Levels](/docs/codex/Levels.md) instance. */
    address public levels;

    /** @notice Map to store the list of authorized addresses to assign experience. */
    mapping(address => bool) authorized;

    /** @notice Map to track the experience of composed IDs. */
    mapping(bytes => uint256) public experience;

    // ============================================== Modifiers =======================================================

    /** @notice Checks against if the `msg.sender` is authorized to assign experience. */
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "Experience: onlyAuthorized() msg.sender not authorized."
        );
        _;
    }

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the [assignExperience](#assignExperience) function is called.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _experience   Total experience amount.
     */
    event ExperienceIncreased(bytes _id, uint256 _experience);

    /**
     * @notice Event emmited when the [assignExperience](#assignExperience) function is called if the character increased a level.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _level    The new level reached.
     */
    event NewLevel(bytes _id, uint256 _level);

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _levels           The address of the [Levels](/docs/codex/Levels.md) instance.
     */
    constructor(address _levels, address _civilizations) {
        levels = _levels;
        civilizations = _civilizations;
        authorized[msg.sender] = true;
    }

    /**
     * @notice Replaces the address of the [Levels](/docs/codex/Levels.md) instance to determine character levels.
     *
     * Requirements:
     * @param _levels    Address of the [Levels](/docs/codex/Levels.md) instance.
     */
    function setLevels(address _levels) public onlyOwner {
        levels = _levels;
    }

    /**
     * @notice Assigns new experience to the composed ID provided.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _amount   The amount of experience to add.
     */
    function assignExperience(bytes memory _id, uint256 _amount)
        public
        onlyAuthorized
    {
        require(
            ICivilizations(civilizations).exists(_id),
            "Experience: assignExperience() token not minted."
        );
        uint256 _old_level = ILevels(levels).getLevel(experience[_id]);
        experience[_id] += _amount;
        uint256 _new_level = ILevels(levels).getLevel(experience[_id]);
        if (_old_level != _new_level) {
            emit NewLevel(_id, _new_level);
        }
        emit ExperienceIncreased(_id, experience[_id]);
    }

    /**
     * @notice Assigns a new address as an authority to assign experience.
     *
     * Requirements:
     * @param _authority    Address to give authority.
     */
    function addAuthority(address _authority) public onlyOwner {
        authorized[_authority] = true;
    }

    /**
     * @notice Removes an authority to assign experience.
     *
     * Requirements:
     * @param _authority    Address to give authority.
     */
    function removeAuthority(address _authority) public onlyOwner {
        require(
            authorized[_authority],
            "Experience: removeAuthority() address is not authorized."
        );
        authorized[_authority] = false;
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to return the total experience of a composed ID.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _experience  Total experience of the character.
     */
    function getExperience(bytes memory _id)
        public
        view
        returns (uint256 _experience)
    {
        return experience[_id];
    }

    /**
     * @notice External function to return the level of a composed ID.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     *
     * @return _level   Level number of the character.
     */
    function getLevel(bytes memory _id) public view returns (uint256 _level) {
        return ILevels(levels).getLevel(experience[_id]);
    }

    /**
     * @notice External function to return the total experience required to reach the next level a composed ID.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _experience  Total experience required to reach the next level.
     */
    function getExperienceForNextLevel(bytes memory _id)
        public
        view
        returns (uint256 _experience)
    {
        return ILevels(levels).getExperience(getLevel(_id)) - experience[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ICivilizations
 * @notice Interface for the [Civilizations](/docs/core/Civilizations.md) contract.
 */
interface ICivilizations {
    /**
     * @notice Internal struct to store the global state of an upgrade.
     *
     * Requirements:
     * @param price         Price to purchase the upgrade.
     * @param available     Status of the purchase mechanism for the upgrade.
     */
    struct Upgrade {
        uint256 price;
        bool available;
    }

    /** @notice See [Civilizations#pause](/docs/core/Civilizations.md#pause) */
    function pause() external;

    /** @notice See [Civilizations#unpause](/docs/core/Civilizations.md#unpause) */
    function unpause() external;

    /** @notice See [Civilizations#transfer](/docs/core/Civilizations.md#transfer) */
    function transfer(
        address _from,
        address _to,
        uint256 _token_id
    ) external;

    /** @notice See [Civilizations#setInitializeUpgrade](/docs/core/Civilizations.md#setInitializeUpgrade) */
    function setInitializeUpgrade(uint256 _upgrade_id, bool _available)
        external;

    /** @notice See [Civilizations#setUpgradePrice](/docs/core/Civilizations.md#setUpgradePrice) */
    function setUpgradePrice(uint256 _upgrade_id, uint256 _price) external;

    /** @notice See [Civilizations#setMintPrice](/docs/core/Civilizations.md#setMintPrice) */
    function setMintPrice(uint256 _price) external;

    /** @notice See [Civilizations#setToken](/docs/core/Civilizations.md#setToken) */
    function setToken(address _token) external;

    /** @notice See [Civilizations#addCivilization](/docs/core/Civilizations.md#addCivilization) */
    function addCivilization(address _civilization) external;

    /** @notice See [Civilizations#mint](/docs/core/Civilizations.md#mint) */
    function mint(uint256 _civilization_id) external;

    /** @notice See [Civilizations#buyUpgrade](/docs/core/Civilizations.md#buyUpgrade) */
    function buyUpgrade(bytes memory _id, uint256 _upgrade_id) external;

    /** @notice See [Civilizations#getCharacterUpgrades](/docs/core/Civilizations.md#getCharacterUpgrades) */
    function getCharacterUpgrades(bytes memory _id)
        external
        view
        returns (bool[3] memory _upgrades);

    /** @notice See [Civilizations#getUpgradeInformation](/docs/core/Civilizations.md#getUpgradeInformation) */
    function getUpgradeInformation(uint256 _upgrade_id)
        external
        view
        returns (Upgrade memory _upgrade);

    /** @notice See [Civilizations#getTokenID](/docs/core/Civilizations.md#getTokenID) */
    function getTokenID(uint256 _civilization_id, uint256 _token_id)
        external
        view
        returns (bytes memory _id);

    /** @notice See [Civilizations#isAllowed](/docs/core/Civilizations.md#isAllowed) */
    function isAllowed(address _spender, bytes memory _id)
        external
        view
        returns (bool _allowed);

    /** @notice See [Civilizations#exists](/docs/core/Civilizations.md#exists) */
    function exists(bytes memory _id) external view returns (bool _exist);

    /** @notice See [Civilizations#ownerOf](/docs/core/Civilizations.md#ownerOf) */
    function ownerOf(bytes memory _id) external view returns (address _owner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ILevels
 * @notice Interface for the [Levels](/docs/codex/Levels.md) contract.
 */
interface ILevels {
    /**
     * @notice Internal struct to define the level ranges.
     *
     * Requirements:
     * @param min   The minimum amount of experience to achieve the level.
     * @param max   The maximum amount of experience for this level (non inclusive).
     */
    struct Level {
        uint256 min;
        uint256 max;
    }

    /** @notice See [Levels#getLevel](/docs/codex/Levels.md#getLevel) */
    function getLevel(uint256 _experience) external view returns (uint256);

    /** @notice See [Levels#getExperience](/docs/codex/Levels.md#getExperience) */
    function getExperience(uint256 _level) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IExperience
 * @notice Interface for the [Experience](/docs/core/Experience.md) contract.
 */
interface IExperience {
    /** @notice See [Experience#setLevel](/docs/core/Experience.md#setLevel) */
    function setLevels(address _levels) external;

    /** @notice See [Experience#assignExperience](/docs/core/Experience.md#assignExperience) */
    function assignExperience(bytes memory _id, uint256 _amount) external;

    /** @notice See [Experience#addAuthority](/docs/core/Experience.md#addAuthority) */
    function addAuthority(address _authority) external;

    /** @notice See [Experience#removeAuthority](/docs/core/Experience.md#removeAuthority) */
    function removeAuthority(address _authority) external;

    /** @notice See [Experience#getExperience](/docs/core/Experience.md#getExperience) */
    function getExperience(bytes memory _id)
        external
        view
        returns (uint256 _experience);

    /** @notice See [Experience#getLevel](/docs/core/Experience.md#getLevel) */
    function getLevel(bytes memory _id) external view returns (uint256 _level);

    /** @notice See [Experience#getExperienceForNextLevel](/docs/core/Experience.md#getExperienceForNextLevel) */
    function getExperienceForNextLevel(bytes memory _id)
        external
        view
        returns (uint256 _experience);
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