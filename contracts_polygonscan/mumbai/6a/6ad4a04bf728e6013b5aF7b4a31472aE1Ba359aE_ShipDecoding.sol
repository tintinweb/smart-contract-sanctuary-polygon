// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../utils/StringUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IShipDecoding {
    function isPirate(string calldata _metadata) external pure returns (bool);
    function isCrossedTheOcean(string calldata _metadata) external pure returns (bool);

    function getBackground(string calldata _metadata) external view returns (string memory);
    function getShip(string calldata _metadata) external view returns (string memory);
    function getFlag(string calldata _metadata) external view returns (string memory);
    function getMast(string calldata _metadata) external view returns (string memory);
    function getAnchor(string calldata _metadata) external view returns (string memory);
    function getSail(string calldata _metadata) external view returns (string memory);
    function getWaves(string calldata _metadata) external view returns (string memory);
}

contract ShipDecoding is Ownable {
    
    using StringUtils for string;

    mapping(string => string) public backgrounds;
    mapping(string => string) public ships;
    mapping(string => string) public flags;
    mapping(string => string) public masts;
    mapping(string => string) public anchors;
    mapping(string => string) public sails;
    mapping(string => string) public waves;

    constructor() {
        backgrounds["0"] = "null";
        backgrounds["1"] = "day";
        backgrounds["2"] = "bay";
        backgrounds["3"] = "night";
        backgrounds["4"] = "island";
        backgrounds["5"] = "harbour";

        ships["00"] = "null";
        ships["01"] = "cyborg";
        ships["02"] = "ice";
        ships["03"] = "classic";
        ships["04"] = "mahogany";
        ships["05"] = "pink";
        ships["06"] = "diamond";
        ships["07"] = "ocean_green";
        ships["08"] = "bone";
        ships["09"] = "royal";
        ships["10"] = "gold";

        flags["0"] = "null";
        flags["1"] = "blue";
        flags["2"] = "orange";
        flags["3"] = "violet";
        flags["4"] = "red";
        flags["5"] = "brown";
        flags["6"] = "green";
        flags["7"] = "pink";
        flags["8"] = "yellow";

        masts["0"] = "null";
        masts["1"] = "diamond";
        masts["2"] = "gold";
        masts["3"] = "ice";
        masts["4"] = "wood";
        masts["5"] = "bone";

        anchors["0"] = "null";
        anchors["1"] = "classic";
        anchors["2"] = "steel";
        anchors["3"] = "diamond";
        anchors["4"] = "ice";
        anchors["5"] = "gold";
        anchors["6"] = "bone";

        sails["00"] = "null";
        sails["01"] = "orange";
        sails["02"] = "classic";
        sails["03"] = "green";
        sails["04"] = "pennant_chain";
        sails["05"] = "pirate_white";
        sails["06"] = "white_stripes";
        sails["07"] = "white";
        sails["08"] = "violet";
        sails["09"] = "yellow";
        sails["10"] = "blue";
        sails["11"] = "pink";
        sails["12"] = "pirate_black";
        sails["13"] = "bulb_chain";
        sails["14"] = "red";
        sails["15"] = "colored";
        sails["16"] = "gold";
        sails["17"] = "pirate_red";

        waves["0"] = "null";
        waves["1"] = "blue";
        waves["2"] = "red";
        waves["3"] = "yellow";
        waves["4"] = "green";
    }

    ///// BOOLEAN METADATA DECODE /////

    function isPirate(string calldata _metadata) external pure returns (bool) {
        return _metadata.substring(0,0).compareStrings("2");
    } 

    function isCrossedTheOcean(string calldata _metadata) external pure returns (bool) {
        return _metadata.substring(1, 1).compareStrings("2");
    }

    ///// STRING METADATA DECODE /////

    function getBackground(string calldata _metadata) external view returns (string memory) {
        return backgrounds[_metadata.substring(2, 2)];
    }

    function getShip(string calldata _metadata) external view returns (string memory) {
        return ships[_metadata.substring(3, 4)];
    }

    function getFlag(string calldata _metadata) external view returns (string memory) {
        return flags[_metadata.substring(5, 5)];
    }

    function getMast(string calldata _metadata) external view returns (string memory) {
        return masts[_metadata.substring(6, 6)];
    }

    function getAnchor(string calldata _metadata) external view returns (string memory) {
        return anchors[_metadata.substring(7, 7)];
    }

    function getSail(string calldata _metadata) external view returns (string memory) {
        return sails[_metadata.substring(8, 9)];
    }

    function getWaves(string calldata _metadata) external view returns (string memory) {
        return waves[_metadata.substring(10, 10)];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library StringUtils {

    function compareStrings(string memory a, string memory b) external pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Substring indexing is done from left -> right
    // Example. str = 0003050040002061101
    // str[0]  = 0
    // str[5]  = 5
    // str[18] = 1
    function substring(string memory str, uint inclStartIndex, uint inclEndIndex) external pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(inclEndIndex-inclStartIndex+1);
        for(uint i = inclStartIndex; i <= inclEndIndex; i++) {
            result[i-inclStartIndex] = strBytes[i];
        }
        return string(result);
    }

    function append(string calldata a, string calldata b) external pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function strToUint(string memory _str) external pure returns(uint256 res, bool err) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0, false);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return (res, true);
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