//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./common/CellMath.sol";
import "./interfaces/IParticipationToken.sol";
import "./interfaces/IPermissionCards.sol";

/* ------------------------ EXAMPLES -----------------------------------
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

contract World is Ownable {
    IParticipationToken private immutable _participationToken;
    IPermissionCards private immutable _permissionCards;

    // Current Settings
    uint256 public defaultPermissions;
    uint256 public tokensRewardedPerOnePlacedElement;
    uint256 public tokensNeededPerOneElementForExpansion;
    uint256 public timeCondition;

    uint256 private immutable _cellRadius;
    uint256 private _worldRadius;

    uint256 private _placedElementsCount;
    uint256 public tokensForNextWorldExpansion;

    mapping(int256 => mapping(int256 => mapping(address => uint256)))
        private _numberOfPlacedElementsInCellByAddress;

    mapping(int256 => mapping(int256 => address)) private _elementPlacedBy;

    mapping(address => uint256) private _lastPlacedTime;

    event ElementPlaced(
        uint256 id,
        int256 x,
        int256 y,
        address rightsHolder,
        uint256 value
    );

    constructor(
        address participationToken_,
        address cards_,
        uint256 worldRadius_,
        uint256 cellRadius_
    ) {
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _participationToken = IParticipationToken(participationToken_);
        _permissionCards = IPermissionCards(cards_);

        _worldRadius = worldRadius_;
        _cellRadius = cellRadius_;
    }

    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory permissionCards,
        address rightsHolder, // Who receives rights to element
        address tokensHolder // Who receives placing reward
    ) external {
        require(
            _lastPlacedTime[_msgSender()] + timeCondition >= block.timestamp,
            "Hub: Not enought time passed"
        );

        require(
            rightsHolder != address(0) && tokensHolder != address(0),
            "Hub: Holder is zero address"
        );

        int256 b = int256(_worldRadius); // World Bound
        require(
            (x <= b) && (x >= -b) && (y <= b) && (y >= -b),
            "Hub: out of world bounds"
        );

        uint256 myPermissions = defaultPermissions; // start with default permissions

        for (uint256 i = 0; i < permissionCards.length; ++i) {
            // gather permissions from permissionCards
            if (
                _permissionCards.balanceOfAccount(
                    _msgSender(),
                    permissionCards[i]
                ) > 0
            ) {
                // ceck if we own permission permissionCards then add to my permsisons
                myPermissions |= permissionCards[i];
            }
        }

        require(
            myPermissions & value == value,
            "Hub: not enough permissions for value"
        );

        uint256 elementID = _placedElementsCount++;

        emit ElementPlaced(elementID, x, y, rightsHolder, value);

        _lastPlacedTime[_msgSender()] = block.timestamp;

        // TODO Ziskaj participation token iba v tedy ak sme zmenili ownera elementu .
        //  takze ak by som si sam na jednmo pixely spamoval  tak nebudem dostavat
        _participationToken.mint(
            tokensHolder,
            tokensRewardedPerOnePlacedElement
        );

        // najdi cell
        (int256 x_CU, int256 y_CU) = CellMath.BelongsToCell(
            x,
            y,
            cellDiameter()
        );

        // old ownerovi zmensim pocet owned elemetov . v cell
        if (_elementPlacedBy[x][y] != address(0)) {
            // niekto tam uz je
            _numberOfPlacedElementsInCellByAddress[x_CU][y_CU][
                _elementPlacedBy[x][y]
            ]--;
        }

        // novi owner zvysim pocet elementov v cell
        _numberOfPlacedElementsInCellByAddress[x_CU][y_CU][rightsHolder]++;

        // poznacim do latet owners
        _elementPlacedBy[x][y] = rightsHolder;
    }

    function _worldCircumference() private view returns (uint256) {
        return (((_worldRadius + 1) * 2 + 1) * 4 - 4);
    }

    function donateToExpandWorld(uint256 amount) external {
        require(
            amount >= _participationToken.balanceOfAccount(_msgSender()),
            "Hub: Not enough tokens"
        );

        // This is basicaly 1 Participation token per 1 element on circumference.
        uint256 treshold = _worldCircumference() *
            tokensNeededPerOneElementForExpansion;
        tokensForNextWorldExpansion += amount;

        if (tokensForNextWorldExpansion >= treshold) {
            _worldRadius++;
            tokensForNextWorldExpansion -= treshold;
        }

        _participationToken.burn(_msgSender(), amount);
    }

    function setParams(
        uint256 defaultPermissions_,
        // uint256 tokensCostPerSnapshotCell_,
        //  uint256 elementsNeededPerSnapshotCell_,
        uint256 tokensRewardedPerOnePlacedElement_,
        uint256 tokensNeededPerOneElementForExpansion_
    ) external onlyOwner {
        defaultPermissions = defaultPermissions_;
        // tokensCostPerSnapshotCell = tokensCostPerSnapshotCell_;
        //elementsNeededPerSnapshotCell = elementsNeededPerSnapshotCell_;
        tokensRewardedPerOnePlacedElement = tokensRewardedPerOnePlacedElement_;
        tokensNeededPerOneElementForExpansion = tokensNeededPerOneElementForExpansion_;
    }

    function numberOfPlacedElementsInCellByAddress(
        int256 x_CU,
        int256 y_CU,
        address placedBy
    ) external view returns (uint256) {
        return _numberOfPlacedElementsInCellByAddress[x_CU][y_CU][placedBy];
    }

    function elementPlacedBy(int256 x_EU, int256 y_EU)
        external
        view
        returns (address)
    {
        return _elementPlacedBy[x_EU][y_EU];
    }

    function cellDiameter() public view returns (uint256) {
        return _cellRadius * 2 + 1;
    }

    function worldRadius() external view returns (uint256) {
        return _worldRadius;
    }

    function placedElementsCount() external view returns (uint256) {
        return _placedElementsCount;
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
    function ClosestNumber(int256 n, int256 m) public pure returns (int256) {
        // find the quotient
        int256 q = n / m;

        // 1st possible closest number
        int256 n1 = m * q;

        // 2nd possible closest number
        int256 n2 = (n * m) > 0 ? (m * (q + 1)) : (m * (q - 1));

        if (Abs(n - n1) < Abs(n - n2)) {
            return n1;
        } else {
            return n2;
        }
    }

    function Abs(int256 n) public pure returns (int256) {
        if (n > 0) {
            return n;
        } else if (n == 0) {
            return 0;
        } else {
            return -n;
        }
    }

    //  ---- Examples ----
    // x=0,y=0,diameter=3   BelongsToCell 0,0
    // x=1,y=0,diameter=3   BelongsToCell 0,0
    // x=2,y=0,diameter=3   BelongsToCell 1,0
    // x=4,y=0,diameter=3   BelongsToCell 1,0
    // x=5,y=0,diameter=3   BelongsToCell 2,0
    function BelongsToCell(
        int256 x,
        int256 y,
        uint256 diameter
    ) public pure returns (int256, int256) {
        int256 diameter_INT = int256(diameter);

        int256 resultX = ClosestNumber(x, diameter_INT) / diameter_INT;
        int256 resultY = ClosestNumber(y, diameter_INT) / diameter_INT;

        return (resultX, resultY);
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