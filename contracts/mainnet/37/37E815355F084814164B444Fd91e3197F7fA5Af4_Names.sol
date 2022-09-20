// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/ICivilizations.sol";
import "../interfaces/INames.sol";
import "../interfaces/IExperience.sol";

/**
 * @title Names
 * @notice This contract manages unique names for all characters in the [Civilizations](/docs/core/Civilizations.md) instance.
 * Some checks are based on the original Rarity names contract https://github.com/rarity-adventure/rarity-names/blob/main/contracts/rarity_names.sol
 * created by https://twitter.com/mat_nadler.
 *
 * @notice Implementation of the [INames](/docs/interfaces/INames.md) interface.
 */
contract Names is INames, Pausable, Ownable {
    // =============================================== Storage ========================================================
    /** @notice Address of the [Civilizations](/docs/core/Civilizations.md) instance. */
    address public civilizations;

    /** @notice Address of the [Experience](/docs/core/Experience.md) instance. */
    address public experience;

    /** @notice Map to track the names of the characters. */
    mapping(bytes => string) public names;

    /** @notice Map to track the names availability. */
    mapping(string => bool) public claimed_names;

    // =============================================== Modifiers ======================================================

    /**
     * @notice Checks against the [Civilizations](/docs/core/Civilizations.md) instance if the `msg.sender` is the owner or
     * has allowance to access a composed ID.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    modifier onlyAllowed(bytes memory _id) {
        require(
            ICivilizations(civilizations).exists(_id),
            "Names: onlyAllowed() token not minted."
        );
        require(
            ICivilizations(civilizations).isAllowed(msg.sender, _id),
            "Names: onlyAllowed() msg.sender is not allowed to access this token."
        );
        _;
    }

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the character name is changed.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _name     New name of the character.
     */
    event ChangeName(bytes _id, string _name);

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _civilizations    The address of the [Civilizations](/docs/core/Civilizations.md) instance.
     * @param _experience       The address of the [Experience](/docs/core/Experience.md) instance.
     */
    constructor(address _civilizations, address _experience) {
        civilizations = _civilizations;
        experience = _experience;
    }

    /** @notice Pauses the contract */
    function pause() public onlyOwner {
        _pause();
    }

    /** @notice Resumes the contract */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Assigns a name to a character and marks it as claimed.
     *
     * Requirements:
     * @param _id       Composed ID of the character.
     * @param _name     Name to assign and claim.
     */
    function claimName(bytes memory _id, string memory _name)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            IExperience(experience).getLevel(_id) >= 5,
            "Name: claimName() not enough level."
        );
        require(
            bytes(names[_id]).length == 0,
            "Name: claimName() already named."
        );
        require(isNameValid(_name), "Name: claimName() invalid name.");
        require(
            isNameAvailable(_name),
            "Name: claimName() name not available."
        );
        claimed_names[toLowerCase(_name)] = true;
        names[_id] = _name;
        emit ChangeName(_id, _name);
    }

    /**
     * @notice Replaces the name of a character with a name already assigned.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _new_name     Name to replace for the character.
     */
    function replaceName(bytes memory _id, string memory _new_name)
        public
        whenNotPaused
        onlyAllowed(_id)
    {
        require(
            IExperience(experience).getLevel(_id) >= 5,
            "Name: replaceName() not enough level."
        );
        require(isNameValid(_new_name), "Name: replaceName() invalid name.");
        require(
            isNameAvailable(_new_name),
            "Name: replaceName() name not available."
        );
        string memory old_name = names[_id];
        require(
            bytes(old_name).length != 0,
            "Name: replaceName() no name assigned."
        );
        claimed_names[toLowerCase(old_name)] = false;
        claimed_names[toLowerCase(_new_name)] = false;

        names[_id] = _new_name;
        emit ChangeName(_id, _new_name);
    }

    /**
     * @notice Removes the assigned name to the character.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     */
    function clearName(bytes memory _id) public whenNotPaused onlyAllowed(_id) {
        string memory old_name = names[_id];
        require(
            bytes(old_name).length != 0,
            "Name: clearName() no name assigned."
        );
        claimed_names[toLowerCase(old_name)] = false;
        names[_id] = "";
        emit ChangeName(_id, "");
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to get the assigned name of a character.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     *
     * @return _name    The assigned name of the character.
     */
    function getCharacterName(bytes memory _id)
        public
        view
        returns (string memory _name)
    {
        return names[_id];
    }

    /**
     * @notice External function to check if a name is available to assign.
     *
     * Requirements:
     * @param _name         The name to check.
     *
     * @return _available   Boolean to know if the name is available.
     */
    function isNameAvailable(string memory _name)
        public
        view
        returns (bool _available)
    {
        return !claimed_names[toLowerCase(_name)];
    }

    /**
     * @notice External function to check if a name is valid to assign.
     *
     * Requirements:
     * @param _name         The name to check.
     *
     * @return _available   Boolean to know if the name is valid.
     */
    function isNameValid(string memory _name)
        public
        pure
        returns (bool _available)
    {
        bytes memory b = bytes(_name);
        if (b.length < 1) return false;
        if (b.length > 25) return false;
        if (b[0] == 0x20) return false;
        if (b[b.length - 1] == 0x20) return false;

        bytes1 last_char = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && last_char == 0x20) return false;

            if (
                !(char >= 0x30 && char <= 0x39) &&
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x20)
            ) return false;

            last_char = char;
        }

        return true;
    }

    /**
     * @notice External function to convert a name to lower case.
     *
     * Requirements:
     * @param _name         The name to convert.
     *
     * @return _lower_case   The provided name as a lower case string.
     */
    function toLowerCase(string memory _name)
        public
        pure
        returns (string memory _lower_case)
    {
        bytes memory b_str = bytes(_name);
        bytes memory b_lower = new bytes(b_str.length);
        for (uint256 i = 0; i < b_str.length; i++) {
            if ((uint8(b_str[i]) >= 65) && (uint8(b_str[i]) <= 90)) {
                b_lower[i] = bytes1(uint8(b_str[i]) + 32);
            } else {
                b_lower[i] = b_str[i];
            }
        }
        return string(b_lower);
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
pragma solidity 0.8.17;

/**
 * @title INames
 * @notice Interface for the [Names](/docs/core/Names.md) contract.
 */
interface INames {
    /** @notice See [Names#pause](/docs/codex/Names.md#pause) */
    function pause() external;

    /** @notice See [Names#unpause](/docs/codex/Names.md#unpause) */
    function unpause() external;

    /** @notice See [Names#claimName](/docs/codex/Names.md#claimName) */
    function claimName(bytes memory _id, string memory _name) external;

    /** @notice See [Names#replaceName](/docs/codex/Names.md#replaceName) */
    function replaceName(bytes memory _id, string memory _new_name) external;

    /** @notice See [Names#clearName](/docs/codex/Names.md#clearName) */
    function clearName(bytes memory _id) external;

    /** @notice See [Names#getCharacterName](/docs/codex/Names.md#getCharacterName) */
    function getCharacterName(bytes memory _id)
        external
        view
        returns (string memory _name);

    /** @notice See [Names#isNameAvailable](/docs/codex/Names.md#isNameAvailable) */
    function isNameAvailable(string memory _name)
        external
        view
        returns (bool _available);

    /** @notice See [Names#isNameValid](/docs/codex/Names.md#isNameValid) */
    function isNameValid(string memory _name)
        external
        pure
        returns (bool _available);

    /** @notice See [Names#toLowerCase](/docs/codex/Names.md#toLowerCase) */
    function toLowerCase(string memory _name)
        external
        pure
        returns (string memory _lower_case);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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