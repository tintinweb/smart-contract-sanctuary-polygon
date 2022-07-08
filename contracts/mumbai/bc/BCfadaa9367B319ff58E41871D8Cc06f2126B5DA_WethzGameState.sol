/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


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


abstract contract Privileges is Ownable {
    // owner proposes, city holders vote
    address public daoHybrid = address(0);
    // anyone proposes, city holders vote
    address public dao = address(0);

    bool public ownerIsAdmin = true;
    bool public ownerCanPause = true;
    bool public paused = false;


    modifier onlyPrivileged {
        require((ownerIsAdmin && msg.sender == owner()) || msg.sender == daoHybrid || msg.sender == dao);
        _;
    }

    modifier onlyPrivilegedWeak {
        require((ownerCanPause && msg.sender == owner()) || (ownerIsAdmin && msg.sender == owner())
            || msg.sender == daoHybrid || msg.sender == dao);
        _;
    }


    function setOwnerIsAdmin(bool newValue) public onlyPrivileged {
        // do not allow the removal of owner privileges unless some form of dao governance is already set
        if(!newValue)
            require(daoHybrid != address(0) || dao != address(0));
        ownerIsAdmin = newValue;
    }

    function setOwnerCanPause(bool newValue) public onlyPrivileged {
        ownerCanPause = newValue;
    }

    function setPaused(bool newValue) public onlyPrivilegedWeak {
        paused = newValue;
    }

    function setDaoHybrid(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        // daoHybrid is considered safer than dao.
        // If daoHybrid is already set, do not allow dao to change it
        if(msg.sender == dao)
            require(daoHybrid == address(0));
        daoHybrid = newValue;
    }

    function setDao(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        dao = newValue;
    }


    function _isContract(address _addr) internal view returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}


struct City {
    address owner;
    uint16[2] rowcol;
    bool[5] buildings;
    uint16[10] units;
    bool[32] upgrades;
    uint16 government;
    uint16[10] citizens;
}

contract WethzGameState is Privileges {
    address public wethzPolyProxy = address(0);
    address public logic1 = address(0);
    address public logic2 = address(0);
    address public logic3 = address(0);
    address public logic4 = address(0);
    address public logic5 = address(0);

    //tokenIds on the map
    uint16[34][34] public nfts;
    mapping(uint16 => City) public cities;


    modifier onlyLogic {
        require(msg.sender == logic1 || msg.sender == logic2 || msg.sender == logic3 || msg.sender == logic4
            || msg.sender == logic5);
        _;
    }

    modifier onlyWethzPolyProxy {
        require(msg.sender == wethzPolyProxy);
        _;
    }


    function setWethzPolyProxy(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        wethzPolyProxy = newValue;
    }

    function setLogic1(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        logic1 = newValue;
    }

    function setLogic2(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        logic2 = newValue;
    }

    function setLogic3(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        logic3 = newValue;
    }

    function setLogic4(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        logic4 = newValue;
    }

    function setLogic5(address newValue) public onlyPrivileged {
        require(_isContract(newValue));
        logic5 = newValue;
    }


    function setCity(uint16 id, address tokenOwner, uint16[2] memory position, bool[5] memory buildings) public onlyWethzPolyProxy {
        uint16[10] memory units;
        bool[32] memory upgrades;
        uint16[10] memory citizens;

        //init pikeman
        units[0] = 1;

        nfts[position[0]][position[1]] = id;
        cities[id] = City(tokenOwner, position, buildings, units, upgrades, 0, citizens);
    }
}