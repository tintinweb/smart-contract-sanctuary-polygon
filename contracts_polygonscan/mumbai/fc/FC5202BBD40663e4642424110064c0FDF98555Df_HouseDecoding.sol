// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../utils/StringUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IHouseDecoding {
    function getBackground(string calldata _metadata) external view returns (string memory);
    function getType(string calldata _metadata) external view returns (string memory);
    function getWindow(string calldata _metadata) external view returns (string memory);
    function getDoor(string calldata _metadata) external view returns (string memory);
    function getRoof(string calldata _metadata) external view returns (string memory);
    function getForeground(string calldata _metadata) external view returns (string memory);
}

contract HouseDecoding is Ownable {
    
    using StringUtils for string;

    mapping(string => string) public backgrounds;
    mapping(string => string) public types;
    mapping(string => string) public windows;
    mapping(string => string) public doors;
    mapping(string => string) public roofs;
    mapping(string => string) public foregrounds;

    constructor() {
        backgrounds["0"] = "null";
        backgrounds["1"] = "day";
        backgrounds["2"] = "forest";
        backgrounds["3"] = "river";
        backgrounds["4"] = "beach";
        backgrounds["5"] = "field";
        backgrounds["6"] = "cave";
        backgrounds["7"] = "night";

        types["0"] = "null";
        types["1"] = "pink";
        types["2"] = "classic";
        types["3"] = "cyborg";
        types["4"] = "mahogany";
        types["5"] = "brick";
        types["6"] = "diamond";
        types["7"] = "bone";
        types["8"] = "gold";

        windows["0"] = "null";
        windows["1"] = "diamond";
        windows["2"] = "classic";
        windows["3"] = "steel";
        windows["4"] = "gold";
        windows["5"] = "circle";
        windows["6"] = "bone";

        doors["00"] = "null";
        doors["01"] = "purple";
        doors["02"] = "blue";
        doors["03"] = "red";
        doors["04"] = "classic";
        doors["05"] = "green";
        doors["06"] = "white";
        doors["07"] = "brown";
        doors["08"] = "yellow";
        doors["09"] = "white_stripes";
        doors["10"] = "pink";
        doors["11"] = "orange";

        roofs["0"] = "null";
        roofs["1"] = "wood";
        roofs["2"] = "bricks";
        roofs["3"] = "bone";
        roofs["4"] = "thatch";
        roofs["5"] = "diamond";
        roofs["6"] = "gold";

        foregrounds["0"] = "null";
        foregrounds["1"] = "bushes";
        foregrounds["2"] = "grass";
        foregrounds["3"] = "flower_bed";
        foregrounds["4"] = "dirt";
    }

    ///// STRING METADATA DECODE /////

    function getBackground(string calldata _metadata) external view returns (string memory) {
        return backgrounds[_metadata.substring(0, 0)];
    }

    function getType(string calldata _metadata) external view returns (string memory) {
        return types[_metadata.substring(1, 1)];
    }

    function getWindow(string calldata _metadata) external view returns (string memory) {
        return windows[_metadata.substring(2, 2)];
    }

    function getDoor(string calldata _metadata) external view returns (string memory) {
        return doors[_metadata.substring(3, 4)];
    }

    function getRoof(string calldata _metadata) external view returns (string memory) {
        return roofs[_metadata.substring(5, 5)];
    }

    function getForeground(string calldata _metadata) external view returns (string memory) {
        return foregrounds[_metadata.substring(6, 6)];
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