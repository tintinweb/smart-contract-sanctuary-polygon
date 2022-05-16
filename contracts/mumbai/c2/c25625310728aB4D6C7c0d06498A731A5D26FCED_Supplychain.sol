/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

// SPDX-License-Identifier: GPL-3.0
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity =0.8.13;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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

// File: contracts/final_year.sol





contract Supplychain is Ownable {
 
    struct Details {
        uint Temperature;
        uint Latitude;
        uint Longitude;

    }
    event UpdateDetails (address indexed updaterAddress, uint indexed boxNumber,uint TemperatureinCelsius,uint Latitude,uint Longitude,uint indexed timestamp);
    
    mapping (uint => mapping(uint => Details)) public updateDetailsMapping;

    function updateDetails (uint boxNumber, uint _Temperature, uint _Latitude, uint _Longitude)  public onlyOwner returns (bool) {

        Details memory currentDetail = Details(_Temperature,_Latitude,_Longitude);
        updateDetailsMapping[boxNumber][block.timestamp] = currentDetail;
        emit UpdateDetails(msg.sender,boxNumber,_Temperature,_Latitude,_Longitude,block.timestamp);
        return true;
    }

    function getTemperature(uint _boxNumber, uint timestamp) public view returns (uint) {
        Details memory currentDetail = updateDetailsMapping[_boxNumber][timestamp];
        uint g_Temperature = currentDetail.Temperature;
        return g_Temperature;
    }

    function getLocation(uint _boxNumber, uint timestamp) public view returns (uint,uint) {
        Details memory currentDetail = updateDetailsMapping[_boxNumber][timestamp];
        uint g_Latitude = currentDetail.Latitude;
        uint g_Longitude =currentDetail.Longitude;
        return (g_Latitude,g_Longitude);
    }

}