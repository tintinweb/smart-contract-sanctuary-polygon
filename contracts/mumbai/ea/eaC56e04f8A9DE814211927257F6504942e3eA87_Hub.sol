//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IParticipationToken.sol";
import "./IPermissionCards.sol";
import "./ISnapshots.sol";
import "./CellMath.sol";

contract Hub is Ownable {
    IParticipationToken public immutable participationToken;
    IPermissionCards public immutable cards;
    ISnapshots public immutable snapshots;

    uint256 public countOfPlacedElements;

    // TODO Budem chciet menit
    uint256 public defaultPermissions =
        0x0000000000000000000000000000000000000000000000000000000000007FFF;

    // TODO Budem chciet menit
    uint256 public snapshotCost = 0; // FOR FREE FOR NOW

    int256 constant cellSize = 1; // NEBUDE SA UZ NIKDY MENIT po deploy inak by to rozbilo strukturu

    // TODO nejak definovat kolko percent prostredia potrebujem

    // Cell  test[cellX][cellY][address] number of owned in this cell
    mapping(int256 => mapping(int256 => mapping(address => uint256)))
        public ownersInCells;

    mapping(int256 => mapping(int256 => address)) public latestOwners;

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

    // Can be used to place element by caller or on behalf of somebody else.
    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        address owner, // zmenit na on behalf of ??   moze byt niekto iny alebo ja sam.
        uint256[] memory permissionCardsIDs // Cards for permissions   -- vo vnuttri sa overi ci sender vlastni tieto karty - SU TO NFT IDCKA
    ) external {
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

        participationToken.mint(owner, 1);

        // najdi cell
        (int256 cellX, int256 cellY) = CellMath.BelongsToCell(x, y, cellSize);

        // old ownerovi zmensim pocet owned elemetov . v cell
        if (latestOwners[x][y] != address(0)) {
            // niekto tam uz je
            ownersInCells[cellX][cellY][latestOwners[x][y]]--;
        }

        // novi owner zvysim pocet elementov v cell
        ownersInCells[cellX][cellY][owner]++;

        // poznacim do latet owners
        latestOwners[x][y] = owner;
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
        uint256 size
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
        int256 cellSize
    ) public pure returns (int256, int256) {
        int256 resultX = ClosestNumber(x, cellSize) / cellSize;
        int256 resultY = ClosestNumber(y, cellSize) / cellSize;

        return (resultX, resultY);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct SnapshotData {
    int256 x;
    int256 y;
    uint256 size;
    uint256 pointInHistory;
    // Add more fields if needed
}