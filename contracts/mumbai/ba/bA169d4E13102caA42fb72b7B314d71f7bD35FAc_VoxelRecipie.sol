// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract VoxelRecipie is Ownable {
    constructor() {
        totalSupply = 0;
    }

    string[] traitsNames = [
        "Breed_Fur",
        "Clothes",
        "Earrings",
        "Ears",
        "Eyes",
        "Hand",
        "Hat",
        "Mouth",
        "Neck"
    ];

    uint256 public totalSupply;
    mapping(uint256 => bool) usedTokenIds;

    struct Recipie {
        address owner;
        uint256[] parents;
        string[] traits;
        uint256 badgeNumber;
    }
    Recipie[] public recipies;

    function getRecipie(uint256 _id)
        public
        view
        returns (Recipie memory _recipie)
    {
        _recipie = recipies[_id];
        for (uint256 i = 0; i < traitsNames.length; i++) {
            _recipie.traits[i] = string(abi.encodePacked(traitsNames[i],':',_recipie.traits[i]));
        }
        _recipie = recipies[_id];
        return _recipie;
    }

    function createRecipie(
        address _owner,
        uint256[] calldata _parents,
        string[] calldata _traits
    ) public {
        for (uint256 i = 0; i < _parents.length; i++) {
            bool used = usedTokenIds[_parents[i]];
            require(!used, "Parent tokenId already used");
            usedTokenIds[_parents[i]] = true;
        }
        totalSupply++;
        uint256 _badgeId = totalSupply;
        Recipie memory _recipie = Recipie(
            _owner,
            _parents,
            _traits,
            totalSupply
        );
        recipies[_badgeId] = _recipie;
    }

    
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}