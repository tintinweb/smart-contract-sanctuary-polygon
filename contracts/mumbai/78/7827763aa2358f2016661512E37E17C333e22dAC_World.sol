//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/CellMath.sol";
import "./common/ElementData.sol";
import "./common/CellData.sol";
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
    IParticipationToken private immutable _participationToken;
    IPermissionCards private immutable _permissionCards;

    // Current Settings
    uint256 public defaultPermissions;
    uint256 public tokensRewardedPerOnePlacedElement;
    uint256 public tokensNeededPerOneElementForExpansion;
    uint256 public timeCondition;

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
        _participationToken = IParticipationToken(participationToken_);
        _permissionCards = IPermissionCards(cards_);

        worldRadius = worldRadius_;
        cellRadius = cellRadius_;
    }

    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory permissionCards,
        address rightsReceiver, // Who receives rights to element
        address tokensReceiver // Who receives placing reward
    ) external {
        _checkReceivers(rightsReceiver, tokensReceiver);
        _checkCooldown(_msgSender());
        _checkBounds(x, y);
        _checkPlaceElementPermissions(_msgSender(), value, permissionCards);

        uint256 elementID = placedElementsCount++;

        emit ElementPlaced(elementID, x, y, value, rightsReceiver);

        lastPlacedTime[_msgSender()] = block.timestamp;

        ElementData memory oldElementData = _elements[x][y];

        if (
            oldElementData.value != value ||
            oldElementData.rightsHolder != rightsReceiver
        ) {
            _participationToken.mint(
                tokensReceiver,
                tokensRewardedPerOnePlacedElement
            );
        }

        // najdi cell
        (int256 x_CU, int256 y_CU) = CellMath.belongsToCell(x, y, cellRadius);

        // old ownerovi zmensim pocet owned elemetov . v cell
        if (_elements[x][y].rightsHolder != address(0)) {
            _cells[x_CU][y_CU].count[_elements[x][y].rightsHolder]--;
        }

        _cells[x_CU][y_CU].count[rightsReceiver]++;

        _elements[x][y] = ElementData(value, rightsReceiver);
    }

    function donateToExpandWorld(uint256 amount) external {
        address operator = _msgSender();

        require(
            amount >= _participationToken.balanceOfAccount(operator),
            "Hub: Not enough tokens"
        );

        uint256 treshold = CellMath.cellCircumference(worldRadius + 1) * // World Circumference
            tokensNeededPerOneElementForExpansion;
        tokensForNextWorldExpansion += amount;

        if (tokensForNextWorldExpansion >= treshold) {
            worldRadius++;
            tokensForNextWorldExpansion -= treshold;
        }

        _participationToken.burn(operator, amount);
    }

    function setParams(
        uint256 defaultPermissions_,
        uint256 tokensRewardedPerOnePlacedElement_,
        uint256 tokensNeededPerOneElementForExpansion_,
        uint256 timeCondition_
    ) external onlyOwner {
        defaultPermissions = defaultPermissions_;
        tokensRewardedPerOnePlacedElement = tokensRewardedPerOnePlacedElement_;
        tokensNeededPerOneElementForExpansion = tokensNeededPerOneElementForExpansion_;
        timeCondition = timeCondition_;
    }

    function elementCountInCell(
        int256 cellX,
        int256 cellY,
        address rightsHolder
    ) external view returns (uint256) {
        return _cells[cellX][cellY].count[rightsHolder];
    }

    function _checkReceivers(address rightsReceiver, address tokensReceiver)
        private
        pure
    {
        require(
            rightsReceiver != address(0) && tokensReceiver != address(0),
            "Hub: Holder is zero address"
        );
    }

    function _checkCooldown(address operator) private view {
        require(
            lastPlacedTime[operator] + timeCondition >= block.timestamp,
            "Hub: Not enought time passed"
        );
    }

    function _checkBounds(int256 x, int256 y) private view {
        int256 b = int256(worldRadius); // World Bound
        require(
            (x <= b) && (x >= -b) && (y <= b) && (y >= -b),
            "Hub: out of world bounds"
        );
    }

    function _checkPlaceElementPermissions(
        address operator,
        uint256 value,
        uint256[] memory cards
    ) public view {
        uint256 myPermissions = defaultPermissions; // start with default permissions

        for (uint256 i = 0; i < cards.length; ++i) {
            if (_permissionCards.balanceOfAccount(operator, cards[i]) > 0) {
                myPermissions |= cards[i];
            }
        }

        require(
            myPermissions & value == value,
            "Hub: not enough permissions for value"
        );
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

library CellMath {
    // find closest number n to m
    function closestNumber(int256 n, int256 m) public pure returns (int256) {
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

    function belongsToCell(
        int256 x,
        int256 y,
        uint256 radius
    ) public pure returns (int256, int256) {
        int256 d = int256(radius) * 2 + 1; // Radius to diameter
        int256 resultX = closestNumber(x, d) / d;
        int256 resultY = closestNumber(y, d) / d;
        return (resultX, resultY);
    }

    function cellCircumference(uint256 cellRadius)
        public
        pure
        returns (uint256)
    {
        return (((cellRadius) * 2 + 1) * 4 - 4);
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

    function elementCountInCell(
        int256 cellX,
        int256 cellY,
        address rightsHolder
    ) external view returns (uint256);

    // Prida nejake dalsie metody  donateToExpandWorld
    // placeElement
    // ... setParams
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