/**
 *Submitted for verification at polygonscan.com on 2022-04-26
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

// File: contracts/NFTGiveaway.sol



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
    function tokenOfOwnerByIndex(
        address owner, uint256 index
        ) 
        external 
        view 
        returns (
            uint256 tokenId
        );

}
struct GiveAway{
    uint256 NFT;
    address deliveryAddr;
    address polyAddr;
}

contract NFTGiveaway is Ownable {

 
    // address constant public petContract=0xCFf08957F6eF129022ddE6569B57002f31AE8c91;
    event Received(address indexed _from, uint256 _amount);
    event Assigned(uint256 _targetNFT, address _delivery, address indexed _to); 
    PetNumber public pet; 
    uint256 public lastTokenId=0;
    uint256 public countNFTs=12;
    uint256 public maxNFTs=5;
    uint256 public registryAmount=0;
    mapping(uint256 => bool) public rewardedNFTs;
    mapping(uint256 => bool) public askedNFTs;
    mapping(uint256 => GiveAway) public nFTRegistry;
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

    function setCountNFTs(uint256 _n) external onlyOwner {
        countNFTs = _n;
    }

    function setMaxNFTs(uint256 _maxNFTs) external onlyOwner {
        maxNFTs = _maxNFTs;
    }

    function availableNFT(uint256 _targetNFT) view public returns(bool){
        if (askedNFTs[_targetNFT]) return false;
        uint256 counter=0;
        for (uint256 i=0; i<pet.balanceOf(msg.sender);i++){
            uint256 ownerTokenId = pet.tokenOfOwnerByIndex(msg.sender, i);
            if (ownerTokenId>lastTokenId && !rewardedNFTs[ownerTokenId]){
                counter++;
            }
        }
        return counter >= countNFTs;
    } 

    function getNFT(uint256 _targetNFT, address _delivery) external{
        require(maxNFTs>0,"Reached max supply");
        require(availableNFT(_targetNFT), "Not available");
        if (availableNFT(_targetNFT)){
            nFTRegistry[registryAmount] = GiveAway(_targetNFT, _delivery, msg.sender);
            registryAmount++;
            maxNFTs--;
            askedNFTs[_targetNFT] = true;
            uint256 counter=0;
            for (uint256 i=0; i<pet.balanceOf(msg.sender);i++){
                uint256 ownerTokenId = pet.tokenOfOwnerByIndex(msg.sender, i);
                if (ownerTokenId>lastTokenId && !rewardedNFTs[ownerTokenId] && counter < countNFTs){
                    rewardedNFTs[ownerTokenId] = true;
                    counter++;
                }
            }
        emit Assigned(_targetNFT, _delivery, msg.sender);   
        }
    }

    
}