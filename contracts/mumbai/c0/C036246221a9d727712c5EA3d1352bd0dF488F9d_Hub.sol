//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
//console.log("Deploying a Greeter with greeting:", _greeting);
import "@openzeppelin/contracts/utils/Context.sol";
import "./IParticipationToken.sol";
import "./IPermissionCards.sol";
import "./ISnapshots.sol";
import "./CellMath.sol";

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

contract Hub {
    IParticipationToken public immutable participationToken;
    IPermissionCards public immutable cards;
    ISnapshots public immutable snapshots;

    // TODO Budem chciet menit
    uint256 public defaultPermissions =
        0x0000000000000000000000000000000000000000000000000000000000007FFF;

    // TODO Budem chciet menit
    // Spravit ako fixed cost per cell
    uint256 public snapshotCostPerCell = 0; // FOR FREE FOR NOW  number of participation tokens
    uint256 public capturePercentagePerCell = 60; // hodnoty  od 0 po 100 akceptovatelne

    uint256 constant cellRadius_EU = 1;
    uint256 constant cellDiameter_EU = cellRadius_EU * 2 + 1;
    uint256 constant cellArea_EU = cellDiameter_EU * cellDiameter_EU;

    // TODO nejak definovat kolko percent prostredia potrebujem

    // TODO tieto public veci dam ako private a spravit vlastny setter ... kde si pekne pomenujem premenne ?
    // Cell  test[x_CU][y_CU][address] number of owned in this cell
    mapping(int256 => mapping(int256 => mapping(address => uint256)))
        public ownersInCells;

    mapping(int256 => mapping(int256 => address)) public latestOwners;
    uint256 public countOfPlacedElements;

    constructor(
        address participationToken_,
        address cards_,
        address snapshots_
    ) {
        participationToken = IParticipationToken(participationToken_);
        cards = IPermissionCards(cards_);
        snapshots = ISnapshots(snapshots_);
    }

    // TODO zamysli sa nad parametrami ci potrebujem tolko indexed, a ci chcem mensie datove typy
    event PlacedElement(
        uint256 indexed index,
        int256 indexed x,
        int256 indexed y,
        address owner,
        uint256 value
    );

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

        // Chceme zapisat na blockchain element s hodnotou value .
        // musim zkontrolovat ci mam permissiony a to zistim tak ze overim ze mam permission cards ...
        // pomocou bitovych operacii

        // zacnem s defaukt permissions

        uint256 myPermissions = defaultPermissions; // start with default permissions

        for (uint256 i = 0; i < permissionCardsIDs.length; ++i) {
            // gather permissions from cards
            if (cards.balanceOfCard(msg.sender, permissionCardsIDs[i]) > 0) {
                // ceck if we own permission cards then add to my permsisons
                myPermissions |= permissionCardsIDs[i];
            }
        }

        require(
            myPermissions & value == value,
            "Hub: not enough permissions for value"
        );

        emit PlacedElement(countOfPlacedElements, x, y, owner, value);

        countOfPlacedElements++;

        // TODO Ziskaj participation token iba v tedy ak sme zmenili ownera elementu .
        //  takze ak by som si sam na jednmo pixely spamoval  tak nebudem dostavat
        participationToken.mintPT(owner, 1);

        // najdi cell
        (int256 x_CU, int256 y_CU) = CellMath.BelongsToCell(
            x,
            y,
            cellDiameter_EU
        );

        // console.log("CellMath.BelongsToCell");
        // console.logInt(x_CU);
        // console.logInt(y_CU);
        //console.log("x_CU:", x_CU);
        //console.log("y_CU:", y_CU);

        // old ownerovi zmensim pocet owned elemetov . v cell
        if (latestOwners[x][y] != address(0)) {
            // niekto tam uz je
            ownersInCells[x_CU][y_CU][latestOwners[x][y]]--;
        }

        // novi owner zvysim pocet elementov v cell
        ownersInCells[x_CU][y_CU][owner]++;

        // poznacim do latet owners
        latestOwners[x][y] = owner;
    }

    function createSnapshot(
        int256 x_EU, // x ElementUnits
        int256 y_EU, // y ElementUnits
        uint256 radius_CU //  Akceptovatelne hodnoty  [0 . 1 , 2 ...]   0 znamena ze velkost bude presne jeden cell
    ) external {
        // najdi cell
        (int256 x_CU, int256 y_CU) = CellMath.BelongsToCell(
            x_EU,
            y_EU,
            cellDiameter_EU
        );

        uint256 ownedElements = 0;

        uint256 diameter_CU = (2 * radius_CU + 1);

        // TODO DOKONCIT
        require(
            participationToken.balanceOfPT(msg.sender) >=
                (snapshotCostPerCell * diameter_CU * diameter_CU)
        );

        // TODO JE TO TAKTO DOSTACUJUCE (precision) ?
        for (uint256 x = 0; x < diameter_CU; ++x) {
            for (uint256 y = 0; y < diameter_CU; ++y) {
                int256 cX = x_CU + int256(x) - (int256(diameter_CU) / 2);
                int256 cY = y_CU + int256(y) - (int256(diameter_CU) / 2);

                ownedElements += ownersInCells[cX][cY][msg.sender];
            }
        }

        // TODO ??? DAVA ZMYSEL AZ OD URCITEHO POCTU ?
        // URCI KOLKO TO JE

        require(
            (ownedElements / 100) * capturePercentagePerCell >
                (diameter_CU * diameter_CU * cellArea_EU),
            "Hub: not owned enough"
        );

        // TODO REQUIRE  PARTICIPATION TOKENY !

        snapshots.mint(
            msg.sender,
            x_EU,
            y_EU,
            radius_CU,
            countOfPlacedElements
        );

        //snapshots.mint(msg.sender, x, y, size, pointInHistory);
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
    function mintPT(address account, uint256 amount) external;

    function burnPT(address account, uint256 amount) external;

    function balanceOfPT(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPermissionCards {
    function mintCard(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function mintBatchCard(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function balanceOfCard(address account, uint256 id)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SnapshotData.sol";

interface ISnapshots {
    function mint(
        address to,
        int256 x,
        int256 y,
        uint256 radius_CU,
        uint256 pointInHistory
    ) external;

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
    uint256 pointInHistory;
    // Add more fields if needed
}