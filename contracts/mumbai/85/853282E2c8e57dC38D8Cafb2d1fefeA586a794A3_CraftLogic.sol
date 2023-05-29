// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IDailyObject } from "./interfaces/IDailyObject.sol";
import { ICraftObject } from "./interfaces/ICraftObject.sol";

contract CraftLogic {
    address _dailyObject;
    address _craftObject;

    // Define an array to store the recipes
    mapping(uint256 => Recipe) public recipes;

    struct Material {
        address tokenAddress; // The address of the ERC1155 contract for this material
        uint256 tokenId; // The ID of the token in the ERC1155 contract
        uint256 amount; // The amount of the token required
    }

    struct Artifacts {
        address tokenAddress; // The address of the ERC1155 contract for this Artifacts
        uint256 tokenId; // The ID of the token in the ERC1155 contract
        uint256 amount; // The amount of the token required
    }

    struct Recipe {
        uint256 id;
        string name;
        Material[] materials;
        Artifacts[] artifacts;
        bool active;
    }

    constructor(address dailyObject, address craftObject) {
        _dailyObject = dailyObject;
        _craftObject = craftObject;
    }

    function createRecipe(
        uint256 id,
        string memory name,
        Material[] memory materials,
        Artifacts[] memory artifacts
    ) public {
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
    }

    function craft(uint256 recipeId) public {
        // Retrieve the recipe
        Recipe storage recipe = recipes[recipeId];

        // Ensure the recipe is active
        require(recipe.active, "Recipe is not active.");

        // Burn the required materials
        for (uint i = 0; i < recipe.materials.length; i++) {
            Material memory material = recipe.materials[i];
            IDailyObject(material.tokenAddress).burn(msg.sender, material.tokenId, material.amount);
        }

        // Mint the artifacts
        for (uint i = 0; i < recipe.artifacts.length; i++) {
            Artifacts memory artifact = recipe.artifacts[i];
            ICraftObject(artifact.tokenAddress).mint(msg.sender, artifact.tokenId, artifact.amount, "");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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

    function getObject(address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

interface IDailyObject {
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
}