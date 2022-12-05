// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ITrue_chest.sol";

contract True_chest is Ownable, Pausable, ITrue_chest { 
mapping (address => mapping (uint256 => uint256)) public chest1;
mapping (address => mapping (uint256 => uint256)) public chest2;
mapping (address => mapping (uint256 => uint256)) public chest3;
mapping (address => mapping (uint256 => uint256)) public chest4;
mapping (address => mapping (uint256 => uint256)) public chest5;
mapping (address => mapping (uint256 => uint256)) public chest6;
mapping (address => mapping (uint256 => uint256)) public chest7;
mapping (address => mapping (uint256 => uint256)) public chest8;
mapping (address => mapping (uint256 => uint256)) public chest9;
mapping (address => mapping (uint256 => uint256)) public chest10;
mapping (address => uint256) public detal;



function Get_detal (address adr)  public virtual override view  returns (uint256) {
    return  detal[adr];
}
function T_detal (address adr) external onlyOwner {
     detal[adr] =  detal[adr] +1;
}
function take_detal (address adr, uint256 num) public virtual override {
    require(msg.sender==adr);
    require( detal[adr] >= num);
     detal[adr] =  detal[adr]-num;
}


function Get_chest1 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest1[adr][num_track];
}
function T_chest1 (address adr,uint256 num_track) external onlyOwner {
    chest1[adr][num_track] = chest1[adr][num_track] +1;
}
function take_chest1 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest1[adr][num_track] = chest1[adr][num_track] -num;
}

function Get_chest2 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest2[adr][num_track];
}
function T_chest2 (address adr,uint256 num_track) external onlyOwner {
    chest2[adr][num_track] = chest2[adr][num_track] +1;
}
function take_chest2 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest2[adr][num_track] = chest2[adr][num_track] -num;
}

function Get_chest3 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest3[adr][num_track];
}
function T_chest3 (address adr,uint256 num_track) external onlyOwner {
    chest3[adr][num_track] = chest3[adr][num_track] +1;
}
function take_chest3 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest3[adr][num_track] = chest3[adr][num_track] -num;
}

function Get_chest4 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest4[adr][num_track];
}
function T_chest4 (address adr,uint256 num_track) external onlyOwner {
    chest4[adr][num_track] = chest4[adr][num_track] +1;
}
function take_chest4 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest4[adr][num_track] = chest4[adr][num_track] -num;
}

function Get_chest5 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest5[adr][num_track];
}
function T_chest5 (address adr,uint256 num_track) external onlyOwner {
    chest5[adr][num_track] = chest5[adr][num_track] +1;
}
function take_chest5 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest5[adr][num_track] = chest5[adr][num_track] -num;
}

function Get_chest6 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest6[adr][num_track];
}
function T_chest6 (address adr,uint256 num_track) external onlyOwner {
    chest6[adr][num_track] = chest6[adr][num_track] +1;
}
function take_chest6 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest6[adr][num_track] = chest6[adr][num_track] -num;
}

function Get_chest7 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest7[adr][num_track];
}
function T_chest7 (address adr,uint256 num_track) external onlyOwner {
    chest7[adr][num_track] = chest7[adr][num_track] +1;
}
function take_chest7 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest7[adr][num_track] = chest7[adr][num_track] -num;
}

function Get_chest8 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest8[adr][num_track];
}
function T_chest8 (address adr,uint256 num_track) external onlyOwner {
    chest8[adr][num_track] = chest8[adr][num_track] +1;
}
function take_chest8 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest8[adr][num_track] = chest8[adr][num_track] -num;
}

function Get_chest9 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest9[adr][num_track];
}
function T_chest9 (address adr,uint256 num_track) external onlyOwner {
    chest9[adr][num_track] = chest9[adr][num_track] +1;
}
function take_chest9 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest9[adr][num_track] = chest9[adr][num_track] -num;
}

function Get_chest10 (address adr,uint256 num_track)  public virtual override view  returns (uint256) {
    return chest10[adr][num_track];
}
function T_chest10 (address adr,uint256 num_track) external onlyOwner {
    chest10[adr][num_track] = chest10[adr][num_track] +1;
}
function take_chest10 (address adr,uint256 num_track, uint256 num) public virtual override {
    require(msg.sender==adr);
     require( detal[adr] >= num);
    chest10[adr][num_track] = chest10[adr][num_track] -num;
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITrue_chest {

function Get_detal (address adr)  external view  returns (uint256);
function take_detal (address adr, uint256 num) external;    

function Get_chest1 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest1 (address adr,uint256 num_track, uint256 num) external;

function Get_chest2 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest2 (address adr,uint256 num_track, uint256 num) external;

function Get_chest3 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest3 (address adr,uint256 num_track, uint256 num) external;

function Get_chest4 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest4 (address adr,uint256 num_track, uint256 num) external;

function Get_chest5 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest5 (address adr,uint256 num_track, uint256 num) external;

function Get_chest6 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest6 (address adr,uint256 num_track, uint256 num) external;

function Get_chest7 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest7 (address adr,uint256 num_track, uint256 num) external;

function Get_chest8 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest8 (address adr,uint256 num_track, uint256 num) external;

function Get_chest9 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest9 (address adr,uint256 num_track, uint256 num) external;

function Get_chest10 (address adr,uint256 num_track)  external view  returns (uint256);
function take_chest10 (address adr,uint256 num_track, uint256 num) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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