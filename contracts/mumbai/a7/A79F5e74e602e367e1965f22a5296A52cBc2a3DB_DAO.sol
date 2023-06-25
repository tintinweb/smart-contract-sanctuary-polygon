// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
interface INFTmarketPlace{
    function purchase (uint256 _tokenId)  external payable;
    function getPrice() external view returns (uint256);
    function available (uint256 _tokenId) external view returns(bool);
}
interface IARtoken {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract DAO is Ownable{
    struct Proposal{
  
        uint256 nftTokenId;   
        uint256 deadline;        
        uint256 PosVotes;    
        uint256 NegVotes;        
        bool executed;    
        mapping(uint256 => bool) voters;

    }
  
    INFTmarketPlace marketplace;
    IARtoken artoken;
     mapping (uint256=>Proposal) public proposals;
     uint256 public totalProposals=0;
    constructor (address _nftMarketplace, address _artoken){
        marketplace=INFTmarketPlace(_nftMarketplace);
        artoken=IARtoken(_artoken);
    }

    modifier NFTholderonly(){
        require(artoken.balanceOf(msg.sender)>0,"you dont hold the nft");
        _;
    }
   
    function CreateProposal(uint _tokenId,uint _deadline )public NFTholderonly {


        Proposal storage newproposal =proposals[totalProposals];
        newproposal.deadline=_deadline;
        newproposal.nftTokenId=_tokenId;
        totalProposals++;
    }
    function vote(uint256 _proposalId,bool _vote) public NFTholderonly {
  
        require(_proposalId<totalProposals,"proposal doesn't exits");
        require(proposals[_proposalId].executed==false,'Proposal already executed');
         require(
        proposals[_proposalId].deadline > block.timestamp,
        "DEADLINE_EXCEEDED"
    );
        bool numvotes=false;
       
            uint256 tokenId = artoken.tokenOfOwnerByIndex(msg.sender, 0);
        numvotes=proposals[_proposalId].voters[tokenId];
         
          require(numvotes==false,"Already voted");
        if(_vote==true){
            proposals[_proposalId].PosVotes+=artoken.balanceOf(msg.sender);
        }
        else{
             proposals[_proposalId].NegVotes+=artoken.balanceOf(msg.sender);
        }

        


       

    }

    function executeProposal(uint256 proposalIndex)external
    NFTholderonly{
    Proposal storage proposal = proposals[proposalIndex];
     require(
        proposals[proposalIndex].deadline <= block.timestamp,
        "DEADLINE_EXCEEDED"
    );

    // If the proposal has more YAY votes than NAY votes
    // purchase the NFT from the FakeNFTMarketplace
    if (proposal.PosVotes > proposal.NegVotes) {
        uint256 nftPrice = marketplace.getPrice();
        require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
        marketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
}

function withdrawEther() external onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, "Nothing to withdraw, contract balance empty");
    (bool sent, ) = payable(owner()).call{value: amount}("");
    require(sent, "FAILED_TO_WITHDRAW_ETHER");
}


receive() external payable {}
}