pragma solidity ^0.8.0;

import "../base/IMetadataFactory.sol";
import "../base/IGameEngine.sol";
import "../base/Ownable.sol";
import "./ProxyTarget.sol";
// import "hardhat/console.sol";

contract MetadataHandler is Ownable, ProxyTarget {
    
	bool public initialized;
    mapping(uint => IMetadataFactory.nftMetadata) nfts; //ID to Metadata

    uint nonce;

    address nftContract;
    IMetadataFactory metadataFactory;

    function initialize(address _nftFactory, address _metaFactory) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;

        nftContract = _nftFactory;
        metadataFactory = IMetadataFactory(_metaFactory);
    }

    modifier onlyNFTFactory{
        require(msg.sender == nftContract,"Not NFT factory");
        _;
    }

    function setContracts(address _nftFactory) external onlyOwner{
        nftContract = _nftFactory;
    }

    function getToken(uint256 _tokenId) external view returns(uint8, uint8) {
        return (
            nfts[_tokenId].nftType,
            nfts[_tokenId].level
            // nfts[_tokenId].canClaim,
            // nfts[_tokenId].stakedTime,
            // nfts[_tokenId].lastClaimTime
        );
    }
    
    function addMetadata(uint8 level,uint8 tokenType,uint tokenID) external onlyNFTFactory{
        nonce++;
        nfts[tokenID] = metadataFactory.createRandomMetadata(level, tokenType,nonce);
    }

    function getTokenURI(uint tokenId) external view returns (string memory)
    {
        IMetadataFactory.nftMetadata memory nft = nfts[tokenId];
        return metadataFactory.buildMetadata(nft, nft.nftType==1,tokenId);
    }

    function changeNft(uint tokenID, uint8 nftType, uint8 level) external onlyNFTFactory {
        IMetadataFactory.nftMetadata memory original = nfts[tokenID];
        nonce++;
        if(original.level != level) { //level up if level changes, level will only ever go up 1 at a time
            original = metadataFactory.levelUpMetadata(original,nonce);
        } 
        
        if(original.nftType != nftType) { //only recreate metadata if type changes (steal)
            uint8[] memory traits;
            if(nftType == 0) {
                (traits,) = metadataFactory.createRandomZombie(level,nonce);
            } else {
                (traits,) = metadataFactory.createRandomSurvivor(level,nonce);
            }
            original = metadataFactory.constructNft(nftType, traits, level);
        } else {
            // //Level and type have not changed, change everything else
            // original.canClaim = canClaim;
            // original.stakedTime = stakedTime;
            // original.lastClaimTime = lastClaimTime;
        }
        nfts[tokenID] = original;
    }
}

pragma solidity ^0.8.0;

interface IMetadataFactory{
    struct nftMetadata {
        uint8 nftType;//0->Zombie 1->Survivor
        uint8[] traits;
        uint8 level;
        // uint nftCreationTime;
        // bool canClaim;
        // uint stakedTime;
        // uint lastClaimTime;
    }

    function createRandomMetadata(uint8 level, uint8 tokenType,uint nonce) external returns(nftMetadata memory);
    function createRandomZombie(uint8 level,uint nonce) external returns(uint8[] memory, uint8);
    function createRandomSurvivor(uint8 level,uint nonce) external returns(uint8[] memory, uint8);
    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level) external view returns(nftMetadata memory);
    function buildMetadata(nftMetadata memory nft, bool survivor,uint id) external view returns(string memory);
    function levelUpMetadata(nftMetadata memory nft,uint nonce) external returns (nftMetadata memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGameEngine{
    function stake ( uint tokenId ) external;
    function alertStake (uint tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0
import './Context.sol';

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
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

/// @dev Proxy for NFT Factory
contract ProxyTarget {

    // Storage for this proxy
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
    bytes32 internal constant ADMIN_SLOT          = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}