// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-contracts/access/Ownable.sol";
import "../UnicodeLib.sol";
import "./ITraitChecker.sol";

contract ArabicNumeralsTraitChecker is Ownable, ITraitChecker {
    string public constant TRAIT_FAMILY = "Arabic Numeral Club";


    constructor() Ownable() {
    }

    function getTraitWithProof(string calldata /*_username*/, bytes32[] calldata /*proof*/) external pure returns (string memory, string memory) {
        revert("TraitChecker: invalid function called");
    }

    function getTrait(string calldata _username) external pure returns (string memory, string memory) {
        bytes memory b = bytes(_username);
        
        //for each char
        for (uint i = 0; i < b.length;) {
            (uint32 code, uint8 size) = UnicodeLib.readUnicodeDecimal(b, i);
            i += size;
            if(code < 0xd9a0 || code > 0xd9a9) {
                return ("","");
            }
        }
        uint l = b.length / 2;
    
        if(l == 1) return (TRAIT_FAMILY,"Arabic 10 club");
        if(l == 2) return (TRAIT_FAMILY,"Arabic 100 club");
        if(l == 3) return (TRAIT_FAMILY,"Arabic 1000 club");
        if(l == 4) return (TRAIT_FAMILY,"Arabic 10k club");
        if(l == 5) return (TRAIT_FAMILY,"Arabic 100k club");
        if(l == 6) return (TRAIT_FAMILY,"Arabic 1m club");

        return ("",""); // number too long
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.7;

library UnicodeLib {

    function unicodeSize(bytes memory b, uint i) internal pure returns (uint8) {
        require(i < b.length, "INVALID_INDEX");
        uint8 currentByte = uint8(b[i]);
        uint8 size = 0;
        if(currentByte < 128) {
            size = 1;
        }
        if(currentByte & 0xe0 == 0xc0) { // 110xxxxx : 2 last bits set to 1, means our character is encoded into 2 bytes
            size = 2;
        } 
        if(currentByte &  0xf0 == 0xe0) { // 1110xxxx : 3 last bits set to 1, means our character is encoded into 3 bytes. 
            size = 3;
        } 
        if(currentByte & 0xf8 == 0xf0) { // 11110xxx : 4 last bits set to 1, means our character is encoded into 4 bytes. 
            size = 4;
        }
        require(size != 0 && i + size <= b.length, "INVALID_UNICODE");
        return size;
    }


    function readUnicodeDecimal(bytes memory b, uint i) internal pure returns (uint32, uint8) {
        uint32 res = 0;
        uint8 uniSize = unicodeSize(b, i);
        for(uint8 j = 0; j < uniSize; j++) {
            if(j > 0) {
                require(b[i+j] & 0xc0 == 0x80, "INVALID_UNICODE");
                res *= 256;
            }
            uint8 temp = uint8(b[i +j]);
            res += temp;
        }
        return (res, uniSize);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-contracts/access/Ownable.sol";

interface ITraitChecker{
    function getTraitWithProof(string calldata _username, bytes32[] calldata proof) external view returns (string memory, string memory);
    function getTrait(string calldata _username) external view returns (string memory, string memory);
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