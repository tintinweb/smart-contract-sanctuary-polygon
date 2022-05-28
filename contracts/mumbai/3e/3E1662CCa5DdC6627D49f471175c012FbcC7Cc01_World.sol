//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/ElementData.sol";
import "./common/CellData.sol";
import "./common/MathLib.sol";
import "./interfaces/IParticipationToken.sol";
import "./interfaces/IPermissionCards.sol";
import "./interfaces/IWorld.sol";

/* ------------------------ EXAMPLES -----------------------------------

TODO lepsie vysvetlenie worldu kde ma origin ako sa zklada z cellov
ze sa tu placuju elementy ale musim mat permision
 _
|_|       Cell 1x1 Elements, Area = 1 Element, Diameter = 1, Radius = 0

------------------------------------------------------------------------

 _ _ _    Cell 3x3 Elements, Area = 9 Elements
|_|_|_|
|_|_|_|
|_|_|_|
<----->   Cell Diameter in this example 3
    <->   Cell Radius in this example 1

-----------------------------------------------------------------------*/

contract World is IWorld, Ownable {
    IParticipationToken public immutable participationToken;
    IPermissionCards public immutable permissionCards;

    // Current Settings
    uint256 public defaultPermissions;
    uint256 public tokensRewardedPerOnePlacedElement;
    uint256 public tokensNeededPerOneElementForExpansion;
    uint256 public cooldown;

    uint256 public worldRadius;

    uint256 public placedElementsCount;

    uint256 public tokensForNextWorldExpansion;

    mapping(address => uint256) public lastPlacedTime;

    uint256 public immutable cellRadius;

    mapping(int256 => mapping(int256 => CellData)) private _cells;
    mapping(int256 => mapping(int256 => ElementData)) private _elements;

    constructor(
        address participationToken_,
        address cards_,
        uint256 worldRadius_,
        uint256 cellRadius_
    ) {
        participationToken = IParticipationToken(participationToken_);
        permissionCards = IPermissionCards(cards_);

        worldRadius = worldRadius_;
        cellRadius = cellRadius_;
    }

    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory myPermissionCards,
        address rightsReceiver,
        address tokensReceiver
    ) external {
        require(
            rightsReceiver != address(0),
            "World: rightsReceiver is zero address"
        );
        require(
            tokensReceiver != address(0),
            "World: tokensReceiver is zero address"
        );

        require(notOnCooldown(_msgSender()), "World: on cooldown");
        require(inWorldBounds(x, y), "World: out of world bounds");

        require(
            hasPermissions(_msgSender(), value, myPermissionCards),
            "World: not enough permissions"
        );

        uint256 elementID = placedElementsCount++;

        lastPlacedTime[_msgSender()] = block.timestamp;

        if (
            _elements[x][y].value != value ||
            _elements[x][y].rightsHolder != rightsReceiver
        ) {
            participationToken.mint(
                tokensReceiver,
                tokensRewardedPerOnePlacedElement
            );
        }

        (int256 cellX, int256 cellY) = belongsToCell(x, y);

        if (_elements[x][y].rightsHolder != address(0)) {
            _cells[cellX][cellY].count[_elements[x][y].rightsHolder] -= 1;
        }

        _cells[cellX][cellY].count[rightsReceiver]++;

        _elements[x][y] = ElementData(value, rightsReceiver);

        emit ElementPlaced(elementID, x, y, value, rightsReceiver);
    }

    function donateToExpandWorld(uint256 amount) external {
        require(
            participationToken.balanceOfAccount(_msgSender()) >= amount,
            "World: Not enough tokens"
        );

        uint256 wolrdCircumference = (((worldRadius + 1) * 2 + 1) * 4 - 4);

        uint256 treshold = wolrdCircumference *
            tokensNeededPerOneElementForExpansion;

        tokensForNextWorldExpansion += amount;

        if (tokensForNextWorldExpansion >= treshold) {
            worldRadius++;
            tokensForNextWorldExpansion -= treshold;
        }

        participationToken.burn(_msgSender(), amount);
    }

    function setParams(
        uint256 defaultPermissions_,
        uint256 tokensRewardedPerOnePlacedElement_,
        uint256 tokensNeededPerOneElementForExpansion_,
        uint256 cooldown_
    ) external onlyOwner {
        defaultPermissions = defaultPermissions_;
        tokensRewardedPerOnePlacedElement = tokensRewardedPerOnePlacedElement_;
        tokensNeededPerOneElementForExpansion = tokensNeededPerOneElementForExpansion_;
        cooldown = cooldown_;
    }

    function elementsCountInCell(
        int256 cellX,
        int256 cellY,
        address rightsHolder
    ) external view returns (uint256) {
        return _cells[cellX][cellY].count[rightsHolder];
    }

    function notOnCooldown(address operator) public view returns (bool) {
        return lastPlacedTime[operator] + cooldown < block.timestamp;
    }

    function hasPermissions(
        address operator,
        uint256 value,
        uint256[] memory cards
    ) public view returns (bool) {
        uint256 myPermissions = defaultPermissions; // start with default permissions

        for (uint256 i = 0; i < cards.length; ++i) {
            if (permissionCards.balanceOfAccount(operator, cards[i]) > 0) {
                myPermissions |= cards[i];
            }
        }

        return myPermissions & value == value;
    }

    function inWorldBounds(int256 x, int256 y) public view returns (bool) {
        int256 b = int256(worldRadius);
        return (x <= b) && (x >= -b) && (y <= b) && (y >= -b);
    }

    function belongsToCell(int256 x, int256 y)
        public
        view
        returns (int256, int256)
    {
        int256 d = int256(cellRadius) * 2 + 1;
        int256 resultX = MathLib.closestNumber(x, d) / d;
        int256 resultY = MathLib.closestNumber(y, d) / d;
        return (resultX, resultY);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct ElementData {
    uint256 value;
    address rightsHolder;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct CellData {
    mapping(address => uint256) count;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library MathLib {
    function closestNumber(int256 n, int256 m) external pure returns (int256) {
        // find the quotient
        int256 q = n / m;

        // 1st possible closest number
        int256 n1 = m * q;

        // 2nd possible closest number
        int256 n2 = (n * m) > 0 ? (m * (q + 1)) : (m * (q - 1));

        if (abs(n - n1) < abs(n - n2)) {
            return n1;
        } else {
            return n2;
        }
    }

    function abs(int256 n) public pure returns (int256) {
        if (n > 0) {
            return n;
        } else if (n == 0) {
            return 0;
        } else {
            return -n;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IParticipationToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOfAccount(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPermissionCards {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function balanceOfAccount(address account, uint256 id)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWorld {
    event ElementPlaced(
        uint256 id,
        int256 x,
        int256 y,
        uint256 value,
        address rightsReceiver
    );

    function worldRadius() external view returns (uint256);

    function placedElementsCount() external view returns (uint256);

    function cellRadius() external view returns (uint256);

    function elementsCountInCell(
        int256 cellX,
        int256 cellY,
        address rightsHolder
    ) external view returns (uint256);

    function inWorldBounds(int256 x, int256 y) external view returns (bool);

    function belongsToCell(int256 x, int256 y)
        external
        view
        returns (int256, int256);

    function notOnCooldown(address operator) external view returns (bool);

    function hasPermissions(
        address operator,
        uint256 value,
        uint256[] memory cards
    ) external view returns (bool);
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