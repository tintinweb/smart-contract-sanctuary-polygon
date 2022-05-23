//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./tokens/IParticipationToken.sol";
import "./tokens/IPermissionCards.sol";
import "./tokens/ISnapshots.sol";
import "./common/CellMath.sol";

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

contract Hub is Ownable {
    IParticipationToken public immutable participationToken;
    IPermissionCards public immutable permissionCards;
    ISnapshots public immutable snapshots;

    // TODO Budem chciet menit
    uint256 public defaultPermissions =
        0x0000000000000000000000000000000000000000000000000000000000007FFF;

    // These can be set from outside
    uint256 public tokensCostPerSnapshotCell = cellArea_EU * 1000;
    uint256 public elementsNeededPerSnapshotCell = cellArea_EU / 2;
    uint256 public tokensRewardedPerOnePlacedElement = 100;
    uint256 public tokensNeededPerOneElementForExpansion = 100;

    uint256 constant cellRadius_EU = 1;
    uint256 constant cellDiameter_EU = cellRadius_EU * 2 + 1;
    uint256 constant cellArea_EU = cellDiameter_EU * cellDiameter_EU;

    uint256 public worldRadius_EU = 100;
    uint256 public tokensForNextWorldExpansion = 0;

    mapping(int256 => mapping(int256 => mapping(address => uint256)))
        private _numberOfPlacedElementsInCellByAddress;

    mapping(int256 => mapping(int256 => address)) private _elementPlacedBy;

    uint256 public placedElementsCount;

    event PlacedElement(
        uint256 id,
        int256 x,
        int256 y,
        address owner,
        uint256 value
    );

    event CreatedSnapshot(uint256 id);

    constructor(
        address participationToken_,
        address cards_,
        address snapshots_
    ) {
        participationToken = IParticipationToken(participationToken_);
        permissionCards = IPermissionCards(cards_);
        snapshots = ISnapshots(snapshots_);
    }

    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory permissionCardsIDs, // Cards for permissions   -- vo vnuttri sa overi ci sender vlastni tieto karty - SU TO NFT IDCKA
        address onBehalfOf
    ) external {
        _placeElement(x, y, value, permissionCardsIDs, onBehalfOf);
    }

    function _placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory permissionCardsIDs, // Cards for permissions   -- vo vnuttri sa overi ci sender vlastni tieto karty - SU TO NFT IDCKA
        address owner
    ) private {
        require(owner != address(0), "Hub: owner is zero address");

        int256 b = int256(worldRadius_EU); // World Bound
        require(
            (x <= b) && (x >= -b) && (y <= b) && (y >= -b),
            "Hub: out of world bounds"
        );

        uint256 myPermissions = defaultPermissions; // start with default permissions

        for (uint256 i = 0; i < permissionCardsIDs.length; ++i) {
            // gather permissions from permissionCards
            if (
                permissionCards.balanceOfAccount(
                    msg.sender,
                    permissionCardsIDs[i]
                ) > 0
            ) {
                // ceck if we own permission permissionCards then add to my permsisons
                myPermissions |= permissionCardsIDs[i];
            }
        }

        require(
            myPermissions & value == value,
            "Hub: not enough permissions for value"
        );

        uint256 elementID = placedElementsCount++;

        emit PlacedElement(elementID, x, y, owner, value);

        // TODO Ziskaj participation token iba v tedy ak sme zmenili ownera elementu .
        //  takze ak by som si sam na jednmo pixely spamoval  tak nebudem dostavat
        participationToken.mint(owner, tokensRewardedPerOnePlacedElement);

        // najdi cell
        (int256 x_CU, int256 y_CU) = CellMath.BelongsToCell(
            x,
            y,
            cellDiameter_EU
        );

        // old ownerovi zmensim pocet owned elemetov . v cell
        if (_elementPlacedBy[x][y] != address(0)) {
            // niekto tam uz je
            _numberOfPlacedElementsInCellByAddress[x_CU][y_CU][
                _elementPlacedBy[x][y]
            ]--;
        }

        // novi owner zvysim pocet elementov v cell
        _numberOfPlacedElementsInCellByAddress[x_CU][y_CU][owner]++;

        // poznacim do latet owners
        _elementPlacedBy[x][y] = owner;
    }

    function createSnapshot(
        int256 x_EU,
        int256 y_EU,
        uint256 radius_CU
    ) external {
        int256 b = int256(worldRadius_EU); // World Bound
        require(
            (x_EU <= b) && (x_EU >= -b) && (y_EU <= b) && (y_EU >= -b),
            "Hub: out of world bounds"
        );

        (int256 x_CU, int256 y_CU) = CellMath.BelongsToCell(
            x_EU,
            y_EU,
            cellDiameter_EU
        );

        uint256 myElements = 0;

        uint256 diameter_CU = (2 * radius_CU + 1);
        uint256 area_CU = diameter_CU * diameter_CU;
        uint256 requiredTokens = tokensCostPerSnapshotCell * area_CU;

        require(
            participationToken.balanceOfAccount(msg.sender) >= requiredTokens,
            "Hub: Not enought tokens"
        );

        for (uint256 x = 0; x < diameter_CU; ++x) {
            for (uint256 y = 0; y < diameter_CU; ++y) {
                int256 cX = x_CU + int256(x) - (int256(diameter_CU) / 2);
                int256 cY = y_CU + int256(y) - (int256(diameter_CU) / 2);

                myElements += _numberOfPlacedElementsInCellByAddress[cX][cY][
                    msg.sender
                ];
            }
        }

        require(
            myElements > area_CU * elementsNeededPerSnapshotCell,
            "Hub: not owned enough"
        );

        participationToken.burn(msg.sender, requiredTokens);

        uint256 lastElementID = placedElementsCount;

        uint256 snapshotID = snapshots.mint(
            msg.sender,
            x_EU,
            y_EU,
            radius_CU,
            lastElementID
        );

        emit CreatedSnapshot(snapshotID);
    }

    function _worldCircumference() private view returns (uint256) {
        return (((worldRadius_EU + 1) * 2 + 1) * 4 - 4);
    }

    function donateToExpandWorld(uint256 amount) external {
        require(
            amount >= participationToken.balanceOfAccount(msg.sender),
            "Hub: Not enough tokens"
        );

        // This is basicaly 1 Participation token per 1 element on circumference.
        uint256 treshold = _worldCircumference() *
            tokensNeededPerOneElementForExpansion;
        tokensForNextWorldExpansion += amount;

        if (tokensForNextWorldExpansion >= treshold) {
            worldRadius_EU++;
            tokensForNextWorldExpansion -= treshold;
        }

        participationToken.burn(msg.sender, amount);
    }

    function setDefaultPermissions(uint256 value) external {
        defaultPermissions = value;
    }

    function setTokenCostPerSnapshotCell(uint256 value) external {
        tokensCostPerSnapshotCell = value;
    }

    function setTokensPerOnePlacedElement(uint256 value) external {
        tokensRewardedPerOnePlacedElement = value;
    }

    function setCapturePercentagePerCell(uint256 value) external {
        elementsNeededPerSnapshotCell = value;
    }

    function setTokensNeededPerOneElementForExpansion(uint256 value) external {
        tokensNeededPerOneElementForExpansion = value;
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

import "../common/SnapshotData.sol";

interface ISnapshots {
    function mint(
        address to,
        int256 x,
        int256 y,
        uint256 radius_CU,
        uint256 lastElementID
    ) external returns (uint256);

    function snapshotData(uint256 id)
        external
        view
        returns (SnapshotData memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library CellMath {
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

    function BelongsToCell(
        int256 x,
        int256 y,
        uint256 cellDiameter_EU
    ) public pure returns (int256, int256) {
        int256 cellDiameter_EU_INT = int256(cellDiameter_EU);

        int256 resultX = ClosestNumber(x, cellDiameter_EU_INT) /
            cellDiameter_EU_INT;
        int256 resultY = ClosestNumber(y, cellDiameter_EU_INT) /
            cellDiameter_EU_INT;

        return (resultX, resultY);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct SnapshotData {
    int256 x;
    int256 y;
    uint256 radius_CU; // CellUnits
    uint256 lastElementID;
    // Add more fields if needed
}