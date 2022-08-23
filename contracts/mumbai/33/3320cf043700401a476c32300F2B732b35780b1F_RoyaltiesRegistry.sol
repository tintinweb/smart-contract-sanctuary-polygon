/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;
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


contract RoyaltiesRegistry is Ownable {

    event SetRoyaltiesForContract(address indexed ContractAddress, uint256 royaltieAmount, address by);
    event ChangeRoyaltiesForContract(address indexed ContractAddress, uint256 royaltieAmount, address by);

    struct royaltieItem{
        address user;
        uint256 percent1000;//100 = 100%
    }

    mapping(address=>royaltieItem) internal getRoyaltiesOfCollection; // 1000 = 100%

    uint256 public marketPlaceRoyalty; // 100 = 100%
    address public marketPlaceWalletAddress; 

    constructor(address _marketplaceWallet,uint256 marketplaceRoyalty) {
    marketPlaceRoyalty = marketplaceRoyalty;
    marketPlaceWalletAddress = _marketplaceWallet;
  }

    function getRoyaltiesOf(address _contract) public view returns(royaltieItem memory) {
        return getRoyaltiesOfCollection[_contract];
    }

    function getRoyaltiesPercent1000Of(address _contract) external view returns(uint256) {
        return getRoyaltiesOfCollection[_contract].percent1000;
    }

    function getRoyaltiesUserOf(address _contract) external view returns(address) {
        return getRoyaltiesOfCollection[_contract].user;
    }

    // function checkOwner(address _contract) public view {
    //     if ((owner() != _msgSender()) && (Ownable(_contract).owner() != _msgSender())) {
    //         revert("Token owner not detected");
    //     }
    // }

    function setRoyaltiesOfContract(address _contract, uint256 _amount,address _user) public onlyOwner {
        // checkOwner(_contract);
        getRoyaltiesOfCollection[_contract] = royaltieItem(_user,_amount);
        emit SetRoyaltiesForContract(_contract, _amount, msg.sender);
    }

    function changeRoyaltiesOfContract(address _contract, uint256 _newAmount) public  onlyOwner{
        // checkOwner(_contract);
        getRoyaltiesOfCollection[_contract].percent1000 = _newAmount;
        emit ChangeRoyaltiesForContract(_contract, _newAmount,msg.sender);
    }

    function changeRoyaltiesOwnerOfContract(address _contract,address _user) public onlyOwner {
        // checkOwner(_contract);
        getRoyaltiesOfCollection[_contract].user = _user;
        emit ChangeRoyaltiesForContract(_contract, getRoyaltiesOfCollection[_contract].percent1000,_user);
    }

    function setRoyaltiesOfMarketplace(uint256 _amount) public onlyOwner {
        marketPlaceRoyalty = _amount; //100 = 100%
    }

    function setRoyaltiesOfMarketplace(address _wallet) public onlyOwner {
        marketPlaceWalletAddress = _wallet;
    }
    


    
}