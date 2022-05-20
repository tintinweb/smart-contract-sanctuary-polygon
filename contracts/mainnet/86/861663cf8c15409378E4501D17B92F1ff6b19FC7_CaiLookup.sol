// contracts/ArmoniaCrypt.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Cai_EnumerateString.sol";

contract CaiLookup is Ownable {
    mapping ( string  => string ) private valueByCode;
    EnumerableSetString.StringSet private set;
    
    function add ( string memory _code  ) public onlyOwner {
        valueByCode[_code] = _code;
        EnumerableSetString.add(set,_code);
    }

    function value(string memory _val) public onlyOwner view returns(string memory) {
        return valueByCode[_val];
    }

    function enumerate() public  onlyOwner view returns (string[] memory) {
        return EnumerableSetString.values(set);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableSetString {
   // Inspired from the original EnumerableSet
    struct Set {
        string[] _values;
        mapping (string => uint256) _indexes;
    }

    struct StringSet {
        Set _inner;
    }


    function _at(Set storage set, uint256 index) private view returns (string memory) {
        if( index > _length(set) || index < 1  ){
            return "";
        }else{
            return set._values[index-1];
        }
    }
    function _pos(Set storage set, string memory value) private view returns (uint256) {
        return set._indexes[value] ;
    }

    function _contains(Set storage set, string memory value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _add(Set storage set, string memory _value) private returns (bool) {
        if (!_contains(set, _value)) {
            set._values.push(_value);
            set._indexes[_value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, string memory _value) private returns (bool) {
        uint256 valueIndex = set._indexes[_value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastvalue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }
            set._values.pop();
            delete set._indexes[_value];
            return true;
        } else {
            return false;
        }
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _values(Set storage set) private view returns (string[] memory) {
        return set._values;
    }

  // Public method
    function at(StringSet storage set, uint256 index) internal view returns (string memory) {
        return _at(set._inner, index);
    }
    function pos(StringSet storage set,  string memory value) internal view returns (uint256) {
        return _pos(set._inner, value );
    }
    function add(StringSet storage set,  string memory _value) internal returns (bool) {
        return _add(set._inner,  _value);
    }
    function remove(StringSet storage set, string memory  _value) internal returns (bool) {
        return _remove(set._inner, _value);
    }
    function length(StringSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function values(StringSet storage set) internal view returns (string[] memory) {
        string[] memory store = _values(set._inner);
        string[] memory result;
        assembly {
            result := store
        }
        return result;
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