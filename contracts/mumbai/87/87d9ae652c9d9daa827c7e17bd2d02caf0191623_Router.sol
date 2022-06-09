/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/test4.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/**
 * @title A routing contract to distribute funds
 * @author Kasper De Blieck
 * @notice This contract will receive funds and distribute them to other shareholder addresses via a distribution key.
 * The contract owner is responsable for setting and updating the shareholders and triggering the payout.
 */
contract Router is Ownable() {
    
    // Event to notify shareholders of pay outs
    event DistributeFunds(address indexed to, uint256 value);

    // Struct with shareholder info
    struct ShareHolderStruct{
        uint16 basePoint; //the amount of base points (0.1%, or 0.0001) he owns of incoming funds
        uint16 index; // index in the shareholder in the shareholders array keeping all shareholders
    }
 
    // Mapping to link a shareholder address to it's data
    mapping(address => ShareHolderStruct) public distributionKey;
  
    // Array to keep track of share holders present
    address payable[] public shareholders;
    
    // Used to make sure at most 100% is being routed
    uint16 public totalBasePoints;
  
    modifier onlyShareHolder() {
        require(distributionKey[_msgSender()].basePoint > 0, "Only shareholders with a share have access to this function");
        _;
    }

  
    // FUNCTIONS
    constructor (){
    }
  
    /**
    * @dev receive and fallback in order to receive Ether on the contract address
    */
    receive() external payable {}
    fallback() external payable {}

    /**
     * @return Returns the amount of shareholders
     */
    function getShareholdersLength() view external returns(uint){
        return shareholders.length;
    }
  
    /**
    * @notice Function to add, remove or update shareholders.
    * To remove, just set basePoint_ to 0.
    * Before updating the distribution key, the existing balance will be settled
    * @param shareHolder_ address of the new shareholder
    * @param basePoint_ the share of the shareholder in basePoint (0.1%)
    */
    function setShareHolder(address payable shareHolder_, uint16 basePoint_) external onlyOwner{
        // Check if the new value does not result in a payout of more than 100%
        require((totalBasePoints + basePoint_ - distributionKey[shareHolder_].basePoint ) <= 10000,
            "The sum of distribution keys cannot be bigger than 100%.");
  
        // If there are still funds left, pay them out before updating the distribution keys
        if (address(this).balance > 0) {
            distributeFunds();
        }
  
        // Update sum of all shareholder basepoints
        totalBasePoints = totalBasePoints + basePoint_ - distributionKey[shareHolder_].basePoint;
      
        // Set the share
        distributionKey[shareHolder_].basePoint = basePoint_;
      
        // If the shareholder did not exist, add him to the list of shareholders and save the index.
        // Check for the edge case the index in the mapping has default value 0, but is actual the first element in the list
        if ((distributionKey[shareHolder_].index == uint16(0)) && ((shareholders.length == 0) || (shareHolder_ != shareholders[0]))){
            distributionKey[shareHolder_].index = uint16(shareholders.length);
            shareholders.push(shareHolder_);
        }
        // Else, check if the shareholder needs to be deleted from the shareholder list
        else if (basePoint_ == 0){
        // Order does not mather in the list, overwrite the address-to-delete with the last address
        // and delete the last address to avoid gaps in the array
            distributionKey[shareholders[shareholders.length-1]].index = distributionKey[shareHolder_].index;
            shareholders[distributionKey[shareHolder_].index] = shareholders[shareholders.length-1];

            shareholders.pop();
            distributionKey[shareHolder_].index = 0;
        }
    }
  
    /**
    * @notice Function for each shareholder to withdrawl his remaining funds from the contract.
    */
    function distributeFunds() public onlyOwner{
        // Keep track of initial share
        uint256 totalShare = address(this).balance;
        // For each shareholder, calculate the share and send it
        for (uint i = 0; i < shareholders.length; i++) {
            uint256 share = totalShare * uint256(distributionKey[shareholders[i]].basePoint) / 10000;
            shareholders[i].transfer(share);
            emit DistributeFunds(shareholders[i], share);
        }
  
        // Send remaining funds to the contract owner
        withdrawlAllFunds();
  
    }
  

    /**
    * @notice Function for the owner to withdrawl all funds from the contract.
    */
    function withdrawlAllFunds() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }
 
}