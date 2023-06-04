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

pragma solidity >=0.8.18;
import { MultiOwner } from "./utils/MultiOwner.sol";
import { IMaterialObject } from "./interfaces/IMaterialObject.sol";
import { ICraftObject } from "./interfaces/ICraftObject.sol";

contract CraftLogic is MultiOwner {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address _materialObject;
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    // Define an array to store the recipes
    mapping(uint256 => Recipe) public recipes;

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

    struct Recipe {
        uint256 id;
        string name;
        Material[] materials;
        Artifacts[] artifacts;
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
    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error ExistentCraft();
    error NonExistentCraft();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(address materialObject) {
        _materialObject = materialObject;
    }

    function getRecipe(uint256 recipeId) external view returns (Recipe memory recipe) {
        return recipes[recipeId];
    }

    // Solidity allows arrays to be variable length. However, operations on larger arrays
    // can increase gas costs. It is therefore recommended to set a maximum length for arrays
    function createRecipe(
        uint256 id,
        string memory name,
        Material[] memory materials,
        Artifacts[] memory artifacts
    ) public onlyOwner {
        // Check if the recipe already exists
        if (recipes[id].id == id) revert ExistentCraft();

        // Check that materials and artifacts arrays have at least one element
        require(materials.length > 0, "Materials array is empty.");
        require(artifacts.length > 0, "Artifacts array is empty.");

        // Create a new recipe
        Recipe storage newRecipe = recipes[id];
        newRecipe.id = id;
        newRecipe.name = name;
        newRecipe.active = true;

        // Copy the elements of the materials array
        for (uint256 i = 0; i < materials.length; i++) {
            newRecipe.materials.push(materials[i]);
        }

        // Copy the elements of the artifacts array
        for (uint256 i = 0; i < artifacts.length; i++) {
            newRecipe.artifacts.push(artifacts[i]);
        }
        // Emit the RecipeCreated event
        emit RecipeCreated(id, name, msg.sender);
    }

    function updateRecipe(
        uint256 id,
        string memory name,
        Material[] memory materials,
        Artifacts[] memory artifacts,
        bool active
    ) public onlyOwner {
        // Check if the recipe exists
        if (recipes[id].id != id) revert NonExistentCraft();

        // Check that materials and artifacts arrays have at least one element
        require(materials.length > 0, "Materials array is empty.");
        require(artifacts.length > 0, "Artifacts array is empty.");

        // Update or Create a new recipe
        Recipe storage recipe = recipes[id];
        recipe.id = id;
        recipe.name = name;
        recipe.active = active;

        // Update the materials array
        delete recipe.materials;
        for (uint256 i = 0; i < materials.length; i++) {
            recipe.materials.push(materials[i]);
        }

        // Update the artifacts array
        delete recipe.artifacts;
        for (uint256 i = 0; i < artifacts.length; i++) {
            recipe.artifacts.push(artifacts[i]);
        }
        // Emit the RecipeCreated event
        emit RecipeUpdated(id, name, msg.sender);
    }

    function craft(uint256 recipeId) public {
        // Retrieve the recipe
        Recipe storage recipe = recipes[recipeId];

        // Ensure the recipe is active
        require(recipe.active, "Recipe is not active.");

        // Burn the required materials
        for (uint i = 0; i < recipe.materials.length; i++) {
            Material memory material = recipe.materials[i];
            IMaterialObject(material.tokenAddress).burn(msg.sender, material.tokenid, material.amount);
        }

        // Mint the artifacts
        for (uint i = 0; i < recipe.artifacts.length; i++) {
            Artifacts memory artifact = recipe.artifacts[i];
            ICraftObject(artifact.tokenAddress).getObject(msg.sender, artifact.tokenid, artifact.amount);
        }
        // Emit the Crafted event
        emit Crafted(msg.sender, recipeId, recipe.name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface ICraftObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function getObject(address to, uint256 tokenid, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity >=0.8.18;

interface IMaterialObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function getObject(address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function burn(address owner, uint256 id, uint256 amount) external;

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity >=0.8.18;
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contracts to manage multiple owners.
 */
abstract contract MultiOwner is Context {
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
        _owners[_msgSender()] = true;
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