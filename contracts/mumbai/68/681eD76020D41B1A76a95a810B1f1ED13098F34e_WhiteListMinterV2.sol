// SPDX-License-Identifier: MIT
//repo
/*************************

This contract is designed speicifically to interact with the PunchableERC721 contract.

**************************/

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface ExistingSDKContract{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function punchACard(string memory eventId, uint256 _tID, uint8 increment) external;
    function getNFTPunchesPerCard(string memory eventId, uint256 _tID) external view returns (uint256);
    function tokenExperience(uint tokenId) external view returns (uint);
} 

interface NewSDKContract{
    function mint(address _to, uint256 _eID, string memory _Uri) external ;
    function mint(address _to, uint256 _eID) external ;
}

contract WhiteListMinterV2 is Ownable{

    struct DropEvent {
        ExistingSDKContract whiteListedContract;
        NewSDKContract dropContract;
        mapping(uint => uint[]) eIdToAllowedEIDs;
        uint maxMints;
        uint mints;
    }

    mapping(string => DropEvent) public dropEvents;

    function createDropEvent(string memory eventId, 
                address whiteListedContract, 
                address dropContract,
                uint maxMints)
                external
            onlyOwner {
        require(address(dropEvents[eventId].whiteListedContract) == address(0) && 
            address(dropEvents[eventId].dropContract) == address(0),"This eventId already exists." );
        DropEvent storage newEvent = dropEvents[eventId];
        newEvent.whiteListedContract =  ExistingSDKContract(whiteListedContract);
        newEvent.dropContract = NewSDKContract(dropContract);
        newEvent.maxMints = maxMints;
    }

    function setAllowedEIDs(string memory eventId, uint8 eID, uint[] memory allowedEIDs) external onlyOwner {
        dropEvents[eventId].eIdToAllowedEIDs[eID] = allowedEIDs;
    }

    function updateWhitelistContract(string memory eventId, address whiteListedContract) external onlyOwner {
        dropEvents[eventId].whiteListedContract = ExistingSDKContract(whiteListedContract);
    }

    function updateDropContract(string memory eventId, address dropContract) external onlyOwner {
        dropEvents[eventId].dropContract = NewSDKContract(dropContract);
    }

    function validateEID(string memory eventId, uint eID, uint dropEID) internal view returns (bool valid){
        uint arraySize = dropEvents[eventId].eIdToAllowedEIDs[eID].length;
        for (uint i=0; i < arraySize; i++){
            if (dropEvents[eventId].eIdToAllowedEIDs[eID][i] == dropEID){
                return true;
            }
        }
        return false;
    }

    function whiteListMint(
        string memory eventId,
        uint _tokenIdToPunch,
        uint256 _eID, 
        string memory _Uri
        ) 
        external
        {
            require(dropEvents[eventId].whiteListedContract.ownerOf(_tokenIdToPunch) == _msgSender(),
                    "You don't own this NFT");
            require(dropEvents[eventId].maxMints > dropEvents[eventId].mints, "This drop is out of free mints.");
            uint whitelistEID = dropEvents[eventId].whiteListedContract.tokenExperience(_tokenIdToPunch);
            require( validateEID( eventId, whitelistEID, _eID), "Not allowed to mint with this experienceId");
            dropEvents[eventId].whiteListedContract.punchACard(eventId, _tokenIdToPunch,  1);
            dropEvents[eventId].mints += 1;
            dropEvents[eventId].dropContract.mint( _msgSender(),  _eID, _Uri);
    }

     function whiteListMint(
        string memory eventId,
        uint _tokenIdToPunch,
        uint256 _eID
        ) 
        external
        {
            require(dropEvents[eventId].whiteListedContract.ownerOf(_tokenIdToPunch) == _msgSender(),
                    "You don't own this NFT");
            require(dropEvents[eventId].maxMints > dropEvents[eventId].mints, "This drop is out of free mints.");
            uint whitelistEID = dropEvents[eventId].whiteListedContract.tokenExperience(_tokenIdToPunch);
            require( validateEID( eventId, whitelistEID, _eID), "Not allowed to mint with this experienceId");
            dropEvents[eventId].whiteListedContract.punchACard(eventId, _tokenIdToPunch,  1);
            dropEvents[eventId].mints += 1;
            dropEvents[eventId].dropContract.mint( _msgSender(),  _eID);
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