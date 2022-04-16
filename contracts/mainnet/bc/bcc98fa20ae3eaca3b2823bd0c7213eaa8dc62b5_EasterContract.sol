/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/EasterContract.sol



pragma solidity >=0.7.0 <0.9.0;

interface PetNumber{
    function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function getPetTraits(uint256 _tokenId) external view returns(uint8 zeros, uint8 ones, uint8 twos, uint8 threes);
}

contract EasterContract is Ownable {

 
    // address constant public petContract=0xCFf08957F6eF129022ddE6569B57002f31AE8c91;
    event Received(address indexed _from, uint256 _amount);
    event Rewarded(address indexed _to, uint256 _amount);
    PetNumber public pet; 
    uint256 public lastTokenId=0;
    mapping(uint256 => bool) rewardedNFTs;
    constructor(address _petAddress){
        pet = PetNumber(payable(_petAddress));
    }

    receive() external payable virtual {
        emit Received(msg.sender, msg.value);
    }

    function withdraw() external virtual onlyOwner {

    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
    }

    function setLastTokenId(uint256 _lastTokenId) external onlyOwner {
        lastTokenId = _lastTokenId;
    }

    function potentialReward() external view returns(bool) {
        uint256 thisBalance = address(this).balance;
        if (thisBalance<=0) return false;
        for (uint256 i=0; i<pet.balanceOf(msg.sender);i++){
            uint256 ownerTokenId = pet.tokenOfOwnerByIndex(msg.sender, i);
            if (ownerTokenId>lastTokenId && !rewardedNFTs[ownerTokenId]){
                uint256 zeros=0;
                uint256 ones=0;
                uint256 twos=0;
                uint256 threes=0;
                (zeros, ones, twos, threes) = pet.getPetTraits(ownerTokenId);
                if (zeros>0){

                    return true;
                }
            }
        }
        return false;
        
    }

    function getReward() external returns(bool){
        uint256 thisBalance = address(this).balance;
        require(thisBalance>0,"Balance is 0");
        for (uint256 i=0; i<pet.balanceOf(msg.sender);i++){
            uint256 ownerTokenId = pet.tokenOfOwnerByIndex(msg.sender, i);
            if (ownerTokenId>lastTokenId && !rewardedNFTs[ownerTokenId]){
                uint256 zeros=0;
                uint256 ones=0;
                uint256 twos=0;
                uint256 threes=0;
                (zeros, ones, twos, threes) = pet.getPetTraits(ownerTokenId);
                if (zeros>0){

                    uint256 extractValue = thisBalance < 5 ether ? thisBalance : 5 ether;
                    (bool os, ) = payable(msg.sender).call{value: extractValue}("");
                    require(os);
                    rewardedNFTs[ownerTokenId] = true;
                    emit Rewarded(msg.sender, extractValue);
                    return true;
                }
            }
        }
        return false;
        
    }

}