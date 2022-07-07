//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/ElementData.sol";
import "./interfaces/IHub.sol";
import "./interfaces/IParticipationToken.sol";
import "./interfaces/IPermissions.sol";
import "./interfaces/ISnapshots.sol";
import "./interfaces/IWorld.sol";

import "./common/MathLib.sol";

contract Hub is IHub, Ownable {
    IParticipationToken public immutable participationToken; // TODO VYMYSLI NAZOV?
    IPermissions public immutable permissions;
    ISnapshots public immutable snapshots;
    IWorld public immutable world;

    // Current Settings
    uint256 public constant defaultPermissions = 511; // first 9bits 0x1FF

    uint256 public placeReward = 0; // How many tokens to receive for placing one element
    uint256 public expansionCost = 0; // How many tokens it cost to expand by one element
    uint256 public cooldownDuration = 0;

    uint256 public tokensNeededPerOneSnapshotCell = 0;
    uint256 public elementsNeededPerSnapshotCell = 0;

    uint256 public tokensForNextWorldExpansion;

    mapping(address => uint256) public lastPlacedTime;

    constructor(
        address participationToken_,
        address permissionCards_,
        address snapshots_,
        address world_
    ) {
        participationToken = IParticipationToken(participationToken_);
        permissions = IPermissions(permissionCards_);
        snapshots = ISnapshots(snapshots_);
        world = IWorld(world_);
    }

    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory permissionIDs,
        address rightsReceiver,
        address tokensReceiver
    ) external {
        require(tokensReceiver != address(0), "TokensReceiver is zero address");
        require(notOnCooldown(_msgSender()), "On cooldown");
        require(
            permissions.hasPermissions(
                _msgSender(),
                permissionIDs,
                value,
                defaultPermissions
            ),
            "Not enough permissions"
        );

        ElementData memory ed = world.element(x, y);

        require(
            ed.value != value || ed.rightsHolder != rightsReceiver,
            "No change"
        );

        participationToken.mint(tokensReceiver, placeReward);

        lastPlacedTime[_msgSender()] = block.timestamp;

        world.placeElement(x, y, value, rightsReceiver);
    }

    function expandWorldRadius(uint256 tokensToDonate) external {
        require(
            participationToken.balanceOfAccount(_msgSender()) >= tokensToDonate,
            "Not enough tokens"
        );

        uint256 treshold = world.worldCircumference() * expansionCost;

        tokensForNextWorldExpansion += tokensToDonate;

        if (tokensForNextWorldExpansion >= treshold) {
            world.expandWorldRadius(1);
            tokensForNextWorldExpansion -= treshold;
        }

        participationToken.burn(_msgSender(), tokensToDonate);
    }

    function createSnapshot(
        int256 x,
        int256 y,
        uint256 radiusInCells
    ) external {
        require(world.inWorldBounds(x, y), "Out of world bounds");

        (int256 cellX, int256 cellY) = world.belongsToCell(x, y);

        uint256 area_CU = MathLib.area(radiusInCells);
        uint256 requiredTokens = area_CU * tokensNeededPerOneSnapshotCell;

        require(
            participationToken.balanceOfAccount(_msgSender()) >= requiredTokens,
            "Not enoough tokens"
        );

        uint256 myElements = _elementsCountInCells(
            cellX,
            cellY,
            radiusInCells,
            _msgSender()
        );

        require(
            myElements >= area_CU * elementsNeededPerSnapshotCell,
            "Not owned enough"
        );

        participationToken.burn(_msgSender(), requiredTokens);

        snapshots.createSnapshot(
            _msgSender(),
            x,
            y,
            radiusInCells,
            world.placedElementsCount()
        );
    }

    function _elementsCountInCells(
        int256 cellX,
        int256 cellY,
        uint256 radiusInCells,
        address rightsHolder
    ) private view returns (uint256) {
        uint256 result = 0;

        int256 r = int256(radiusInCells);

        for (int256 x = -r; x <= r; x++) {
            for (int256 y = -r; y <= r; y++) {
                result += world.elementsCountInCell(
                    cellX + x,
                    cellY + y,
                    rightsHolder
                );
            }
        }

        return result;
    }

    function notOnCooldown(address operator) public view returns (bool) {
        return lastPlacedTime[operator] + cooldownDuration <= block.timestamp;
    }

    function setBasicParams(
        uint256 tokensRewardedPerOnePlacedElement_,
        uint256 expansionCost_,
        uint256 cooldown_
    ) external onlyOwner {
        placeReward = tokensRewardedPerOnePlacedElement_;
        expansionCost = expansionCost_;
        cooldownDuration = cooldown_;
    }

    function setSnapshotParams(
        uint256 tokensNeededPerOneSnapshotCell_,
        uint256 elementsNeededPerSnapshotCell_
    ) external onlyOwner {
        tokensNeededPerOneSnapshotCell = tokensNeededPerOneSnapshotCell_;
        elementsNeededPerSnapshotCell = elementsNeededPerSnapshotCell_;
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

interface IHub {
    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        uint256[] memory permissionIDs,
        address rightsReceiver,
        address tokensReceiver
    ) external;
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

interface IPermissions {
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

    function setURI(string memory newuri) external;

    function validatePermissions(address owner, uint256[] memory cards)
        external
        view
        returns (uint256);

    function hasPermissions(
        address owner,
        uint256[] memory permissionIDs,
        uint256 value,
        uint256 defaultPermissions
    ) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/SnapshotData.sol";

interface ISnapshots {
    event SnapshotCreated(
        uint256 id,
        int256 x,
        int256 y,
        uint256 radiusInCells,
        uint256 historyPoint
    );

    function createSnapshot(
        address to,
        int256 x,
        int256 y,
        uint256 radiusInCells,
        uint256 historyPoint
    ) external;

    function setURI(string memory newuri) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../common/ElementData.sol";

interface IWorld {
    event ElementPlaced(
        uint256 id,
        int256 x,
        int256 y,
        uint256 value,
        address rightsReceiver
    );

    // TODO ZMENIT rightsReceiver  NA OWNWER   v evente ??

    function inWorldBounds(int256 x, int256 y) external view returns (bool);

    function belongsToCell(int256 x, int256 y)
        external
        view
        returns (int256, int256);

    function placeElement(
        int256 x,
        int256 y,
        uint256 value,
        address rightsReceiver
    ) external;

    function expandWorldRadius(uint256 amount) external;

    function element(int256 x, int256 y)
        external
        view
        returns (ElementData memory data);

    function worldRadius() external view returns (uint256);

    function placedElementsCount() external view returns (uint256);

    function elementsCountInCell(
        int256 cellX,
        int256 cellY,
        address rightsHolder
    ) external view returns (uint256);

    function worldCircumference() external view returns (uint256);
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

    function circumference(uint256 radius) public pure returns (uint256) {
        return ((radius * 2 + 1) * 4 - 4);
    }

    function diameter(uint256 radius) public pure returns (uint256) {
        return 2 * radius + 1;
    }

    function area(uint256 radius) public pure returns (uint256) {
        uint256 d = diameter(radius);
        return d * d;
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

struct SnapshotData {
    int256 x;
    int256 y;
    uint256 radiusInCells;
    uint256 historyPoint;
}