// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.1;

/**
 * @dev Context variant with ERC2771 support.
 */
// based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
abstract contract ERC2771Context {
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.18;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";
import { MultiOwner } from "./utils/MultiOwner.sol";
import { IMaterialObject } from "./interfaces/IMaterialObject.sol";
import { ICraftObject } from "./interfaces/ICraftObject.sol";

interface ICatalyst {
    function balanceOf(address account) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract CraftLogic is ERC2771Context, MultiOwner, ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    // Define an array to store the recipes
    mapping(uint256 => Recipe) private recipes;

    struct Material {
        address tokenAddress; // The address of the ERC1155 contract for this material
        uint256 tokenid; // The ID of the token in the ERC1155 contract
        uint256 amount; // The amount of the token required
    }

    struct Artifacts {
        address tokenAddress; // The address of the ERC1155 contract for this Artifacts
        uint256 tokenid; // The ID of the token in the ERC1155 contract
        uint256 amount; // The amount of the token required
    }

    struct Catalyst {
        address tokenAddress; // The address of the ERC20/721/1155 contract for this catalyst
        uint256 tokenid; // The ID of the token in the contract : ERC20 => 0
        uint256 amount; // The required balance of the token
        uint8 tokenType; // Type of the token: 0 = ERC20, 1 = ERC721, 2 = ERC1155
    }

    struct Recipe {
        uint256 id;
        string name;
        Material[] materials;
        Artifacts[] artifacts;
        Catalyst catalyst; //erc 20/ erc721/ erc1155
        bool active;
    }
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event that is emitted when a new artifact is crafted
    event Crafted(address indexed crafter, uint256 recipeId, string recipeName);
    // Event that is emitted when a new recipe is created
    event RecipeCreated(uint256 indexed recipeId, string name, address indexed owner);
    // Event that is emitted when a new recipe is created
    event RecipeUpdated(uint256 indexed recipeId, string name, address indexed owner);
    // Event that is emitted when a new recipe is created
    event ChangeRecipeStatus(uint256 indexed recipeId, bool active, address indexed owner);
    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    // The error thrown when trying to create a recipe that already exists.
    error ExistentCraft(uint256 id);
    // The error thrown when trying to update a recipe that doesn't exist.
    error NonExistentCraft(uint256 id);
    // The error thrown when trying to create or update a recipe without any materials.
    error EmptyMaterialsArray();
    // The error thrown when trying to create or update a recipe without any artifacts.
    error EmptyArtifactsArray();
    // The error thrown when trying to craft using an inactive recipe.
    error RecipeInactive(uint256 recipeId);
    // The error thrown when the required condition for a catalyst is not satisfied during crafting.
    error CatalystConditionNotSatisfied();
    // The error thrown when the name of the recipe is too long.
    error NameTooLong();
    // The error thrown when an invalid address is provided. The reason for invalidity is provided as a parameter.
    error InvalidAddress(string reason);
    // Error to throw if the function call is not made by an GelatoRelay.
    error OnlyGelatoRelay();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {}

    /**
     * @dev This function returns the Recipe structure for a given recipeId.
     *
     * @param recipeId ID of the recipe to be retrieved.
     */
    function getRecipe(uint256 recipeId) external view returns (Recipe memory recipe) {
        return recipes[recipeId];
    }

    function _checkCatalystCondition(Catalyst memory catalyst) internal view {
        if (catalyst.tokenAddress != address(0)) {
            // ERC20
            if (catalyst.tokenType == 0 && ICatalyst(catalyst.tokenAddress).balanceOf(_msgSender()) < catalyst.amount)
                revert CatalystConditionNotSatisfied();
            // ERC721
            else if (
                catalyst.tokenType == 1 && ICatalyst(catalyst.tokenAddress).ownerOf(catalyst.tokenid) != _msgSender()
            ) revert CatalystConditionNotSatisfied();
            // ERC1155
            else if (
                catalyst.tokenType == 2 &&
                ICatalyst(catalyst.tokenAddress).balanceOf(_msgSender(), catalyst.tokenid) < catalyst.amount
            ) revert CatalystConditionNotSatisfied();
        }
    }

    /**
     * @dev This function allows users to craft an artifact given a recipeId.
     * The function first checks if the recipe is active and satisfies the catalyst condition,
     * then it burns the required materials and mints the new artifact.
     *
     * @param recipeId ID of the recipe to be used for crafting.
     */
    function craft(uint256 recipeId) external nonReentrant {
        _craft(recipeId);
    }

    function _craft(uint256 recipeId) private {
        // Retrieve the recipe
        Recipe storage recipe = recipes[recipeId];

        // Ensure the recipe is active
        if (!recipe.active) revert RecipeInactive(recipeId);

        // Check catalyst condition
        Catalyst memory catalyst = recipe.catalyst;
        _checkCatalystCondition(catalyst);

        // Burn the required materials
        uint256 materialsLength = recipe.materials.length;
        for (uint256 i = 0; i < materialsLength; ) {
            Material memory material = recipe.materials[i];
            IMaterialObject(material.tokenAddress).burnObject(_msgSender(), material.tokenid, material.amount);
            unchecked {
                ++i;
            }
        }

        // Mint the artifacts
        uint256 artifactsLength = recipe.artifacts.length;
        for (uint256 i = 0; i < artifactsLength; ) {
            Artifacts memory artifact = recipe.artifacts[i];
            ICraftObject(artifact.tokenAddress).craftObject(_msgSender(), artifact.tokenid, artifact.amount);
            unchecked {
                ++i;
            }
        }
        // Emit the Crafted event
        emit Crafted(_msgSender(), recipeId, recipe.name);
    }

    /**
     * @dev This function creates a new recipe. It checks if the recipe already exists,
     * ensures that the materials and artifacts arrays have at least one element,
     * and emits a RecipeCreated event.
     *
     * Requirements:
     * - The caller must be the owner.
     * - The materials and artifacts arrays must not be empty.
     *
     * @param recipeId the ID of the recipe to create
     * @param name the name of the recipe
     * @param materials the materials required for the recipe
     * @param artifacts the artifacts produced by the recipe
     * @param catalyst the catalyst required for the recipe
     */
    function createRecipe(
        uint256 recipeId,
        string calldata name,
        Material[] calldata materials,
        Artifacts[] calldata artifacts,
        Catalyst calldata catalyst
    ) external payable onlyOwner {
        _createOrUpdateRecipe(recipeId, name, materials, artifacts, catalyst, true, false);
    }

    /**
     * @dev This function updates an existing recipe. It checks if the recipe exists,
     * ensures that the materials and artifacts arrays have at least one element,
     * and emits a RecipeUpdated event.
     *
     * Requirements:
     * - The caller must be the owner.
     * - The materials and artifacts arrays must not be empty.
     *
     * @param recipeId the ID of the recipe to update
     * @param name the name of the recipe
     * @param materials the materials required for the recipe
     * @param artifacts the artifacts produced by the recipe
     * @param catalyst the catalyst required for the recipe
     * @param active the status of the recipe
     */
    function updateRecipe(
        uint256 recipeId,
        string memory name,
        Material[] memory materials,
        Artifacts[] memory artifacts,
        Catalyst calldata catalyst,
        bool active
    ) external onlyOwner {
        _createOrUpdateRecipe(recipeId, name, materials, artifacts, catalyst, active, true);
    }

    function _createOrUpdateRecipe(
        uint256 recipeId,
        string memory name,
        Material[] memory materials,
        Artifacts[] memory artifacts,
        Catalyst calldata catalyst,
        bool active,
        bool isUpdate // true:= update, false:= create
    ) internal {
        // Check if the recipe already exists
        if (recipes[recipeId].id == recipeId && !isUpdate) revert ExistentCraft(recipeId);
        if (recipes[recipeId].id != recipeId && isUpdate) revert NonExistentCraft(recipeId);

        uint256 materialsLength = materials.length;
        uint256 artifactsLength = artifacts.length;
        // Check that materials and artifacts arrays have at least one element
        if (materialsLength == 0) revert EmptyMaterialsArray();
        if (artifactsLength == 0) revert EmptyArtifactsArray();

        // Update or Create a new recipe
        Recipe storage recipe = recipes[recipeId];
        recipe.id = recipeId;
        recipe.name = name;
        recipe.catalyst = catalyst;
        recipe.active = active;

        // Update the materials array
        delete recipe.materials;
        for (uint256 i = 0; i < materialsLength; ) {
            recipe.materials.push(materials[i]);
            unchecked {
                ++i;
            }
        }

        // Update the artifacts array
        delete recipe.artifacts;
        for (uint256 i = 0; i < artifactsLength; ) {
            recipe.artifacts.push(artifacts[i]);
            unchecked {
                ++i;
            }
        }
        // Emit the RecipeCreated event
        if (isUpdate) {
            emit RecipeUpdated(recipeId, name, _msgSender());
        } else {
            emit RecipeCreated(recipeId, name, _msgSender());
        }
    }

    /**
     * @dev This function changes the status of an existing recipe. It checks if the recipe exists,
     * and emits a ChangeRecipeStatus event.
     *
     * Requirements:
     * - The caller must be the owner.
     *
     * @param recipeId the ID of the recipe to update
     * @param active the new status of the recipe
     */
    function changeRecipeStatus(uint256 recipeId, bool active) external onlyOwner {
        // Check if the recipe already exists
        if (recipes[recipeId].id != recipeId) revert NonExistentCraft(recipeId);

        // Update
        Recipe storage recipe = recipes[recipeId];
        recipe.active = active;
        // Emit the RecipeCreated event
        emit ChangeRecipeStatus(recipeId, active, _msgSender());
    }

    /* -------------------------------------------------------------------------- */
    /*                               RelayCraft                                  */
    /* -------------------------------------------------------------------------- */
    address constant GELATO_RELAY = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    modifier onlyGelatoRelay() {
        if (!_isGelatoRelay(msg.sender)) revert OnlyGelatoRelay();
        _;
    }

    function _isGelatoRelay(address _forwarder) internal pure returns (bool) {
        return _forwarder == GELATO_RELAY;
    }

    // Function to craft object by relayer.
    function craftByRelayer(uint256 recipeId) external onlyGelatoRelay nonReentrant {
        _craft(recipeId);
    }
}

// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.18;

interface ICraftObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function craftObject(address to, uint256 tokenId, uint256 amount) external;

    function burnObject(address from, uint256 tokenid, uint256 amount) external;

    function burnBatchObject(address from, uint256[] memory ids, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.18;

interface IMaterialObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function getObject(address to, uint256 tokenid, uint256 amount) external;

    function burnObject(address from, uint256 tokenid, uint256 amount) external;

    function burnBatchObject(address from, uint256[] memory ids, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.18;

/**
 * @dev Contracts to manage multiple owners.
 */
abstract contract MultiOwner {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    mapping(address => bool) private _owners;
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event OwnershipGranted(address indexed operator, address indexed target);
    event OwnershipRemoved(address indexed operator, address indexed target);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidOwner();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[msg.sender] = true;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (!_owners[msg.sender]) revert InvalidOwner();
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns the address of the current owner.
     */
    function ownerCheck(address targetAddress) external view virtual returns (bool) {
        return _owners[targetAddress];
    }

    /**
     * @dev Set the address of the owner.
     */
    function setOwner(address newOwner) external virtual onlyOwner {
        _owners[newOwner] = true;
        emit OwnershipGranted(msg.sender, newOwner);
    }

    /**
     * @dev Remove the address of the owner list.
     */
    function removeOwner(address oldOwner) external virtual onlyOwner {
        _owners[oldOwner] = false;
        emit OwnershipRemoved(msg.sender, oldOwner);
    }
}