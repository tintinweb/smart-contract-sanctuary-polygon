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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LandRegister is  Ownable{
    struct Land{
        uint256 id;
        string location;
        uint256 area;
        uint256 pricePerArea;
        address payable owner;
        bool isListed;
    }
    
    mapping(uint => Land) public lands;
    uint256 public landCount;

    event LandRegistered(uint256 id, string location, uint256 area, 
                        uint256 pricePerArea, address payable owner);

    event LandTransferred(uint256 id, address payable oldOwner, address payable newOwner);
    event LandBought(uint256 id, address payable oldOwner, address payable newOwner);
    
    constructor(){
        landCount = 0;
    }
    
    function registerLand(
        address payable owner, string memory _location, 
        uint256 _area, uint256 _pricePerArea
    ) public onlyOwner{
        landCount++;
        lands[landCount] = Land(landCount, _location, _area, _pricePerArea, owner, false);
        emit LandRegistered(landCount, _location, _area, _pricePerArea, owner);
    }

    function transferLand(uint _landId, address payable _newOwner) public{
        Land memory land = lands[_landId];

        require(msg.sender == land.owner, "Only owner can transfer the land");

        land.owner = _newOwner;
        land.isListed = false;
        lands[_landId] = land;

        emit LandTransferred(_landId, _newOwner, _newOwner);
    }
    
    function buyLand(uint _landId, address payable _newOwner) public {
        Land memory land = lands[_landId];

        require(land.isListed == true, "Land is not listed");
        // require(msg.value >= land.pricePerArea * land.area, "Insufficient balance");
        
        land.owner = _newOwner;
        land.isListed = false;
        lands[_landId] = land;

        // payable(land.owner).transfer(msg.value);

        emit LandBought(_landId, _newOwner, _newOwner);
    }

    function listLand(uint256 _landId, uint256 _pricePerArea) public{
        Land memory land = lands[_landId];
        require(msg.sender == land.owner, "Only owner can list the land");
        land.isListed = true;
        land.pricePerArea = _pricePerArea;
        lands[_landId] = land;
    }

    function unListLand(uint _landId) public{
        Land memory land = lands[_landId];
        require(msg.sender == land.owner, "Only owner can unlist the land");
        land.isListed = false;
        lands[_landId] = land;
    }
    
    function getLands(address payable _owner) public view returns(Land[] memory){
        Land[] memory landsOfUser = new Land[](landCount);
        uint count = 0;
        for(uint i = 1; i <= landCount; i++){
            if(lands[i].owner == _owner){
                landsOfUser[count] = lands[i];
                count++;
            }
        }
        return landsOfUser;
    }

     function getListedLand() public view returns(Land[] memory){
        Land[] memory landsOfUser = new Land[](landCount);
        uint count = 0;
        for(uint i = 1; i <= landCount; i++){
            if(lands[i].isListed == true){
                landsOfUser[count] = lands[i] ;
                count++;
            }
        }
        return landsOfUser;
    }


}