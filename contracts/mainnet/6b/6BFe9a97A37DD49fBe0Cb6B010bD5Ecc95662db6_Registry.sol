// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {

    address [] public allProjectTokens;
    mapping(string => address []) public projectTokensByCountry;
    mapping(string => address []) public projectTokensByCategory;

    constructor(){}

    function addAllProjectTokens(address [] memory projectTokens) external onlyOwner {
        allProjectTokens = projectTokens;
    }

    function addProjectTokenByCountry(string memory countryCode, address [] memory projectTokens) external onlyOwner {
        projectTokensByCountry[countryCode] = projectTokens;
    }

    function addProjectTokenByCategory(string memory category, address [] memory projectTokens) external onlyOwner {
        projectTokensByCategory[category] = projectTokens;
    }

    function getProjectTokenByCountry(string memory country) external view returns (address [] memory) {
        return projectTokensByCountry[country];
    }

    function getProjectTokenByCategory(string memory category) external view returns (address [] memory) {
        return projectTokensByCategory[category];
    }

    function findBestProjectTokens(string memory filter) external view returns (address [] memory) {
        uint filterLength = _strlen(filter);
        if (filterLength == 0) {
            return allProjectTokens;
        }
        require(filterLength == 5, "Invalid filter");
        string memory countryCode = _substring(filter, 0, 2);
        string memory category = _substring(filter, 2, 5);

        string memory emptyCategory = "XXX";
        string memory emptyCountry = "XX";

        if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked(emptyCategory))) {
            return projectTokensByCountry[countryCode];
        }

        if (keccak256(abi.encodePacked(countryCode)) == keccak256(abi.encodePacked(emptyCountry))) {
            return projectTokensByCategory[category];
        }

        address [] memory projectTokens = projectTokensByCountry[countryCode];
        address [] memory projectTokensByCategory = projectTokensByCategory[category];
        return _intersectArrays(projectTokens, projectTokensByCategory);
    }

    function _substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    /**
   * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
   * @param A The first array
   * @param B The second array
   * @return The intersection of the two arrays
   */
    function _intersectArrays(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint newLength = 0;
        for (uint i = 0; i < length; i++) {
            if (_contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint j = 0;
        for (uint i = 0; i < length; i++) {
            if (includeMap[i]) {
                newAddresses[j] = A[i];
                j++;
            }
        }
        return newAddresses;
    }

    function _contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}