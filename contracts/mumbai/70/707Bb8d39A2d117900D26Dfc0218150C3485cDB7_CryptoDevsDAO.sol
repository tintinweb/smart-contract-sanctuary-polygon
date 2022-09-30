// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

//Interface for the FakeNFTMarketplace
interface IFakeNFTMarketplace {
    /**
     * @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
     * @return returns the price in Wei for an NFT
     */
    function getPrice() external view returns (uint256);

    /**
     * @dev available() returns whether or not the given _tokenId has already been purchased
     *  @param _tokenId - the fake NFT tokenID that will be checked
     * @return Returns a boolean value - true if available, false if not
     */
    function available(uint256 _tokenId) external view returns (bool);

    /**
     * @dev purchase() purchases an NFT from the FakeNFTMarketplace
     *  @param _tokenId - the fake NFT tokenID to purchase
     */
    function purchase(uint256 _tokenId) external payable;
}

//Minimal interface for CryptoDevsNFT containing only two functions
interface ICryptoDevsNFT{
    /**
     * @dev balanceOf() returns the number of NFTs owned by the given address
     * @param _owner - address to fetch number of NFTs for
     * @return Returns the number of NFTs owned
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @dev tokenOfOwnerByIndex() returns a tokenID at given index for owner
     * @param _owner - address to fetch the NFT TokenID for
     * @param _index - index of NFT in owned tokens array to fetch
     * @return Returns the TokenID of the NFT
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable{
    //mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    //number of proposals that have been created
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    struct Proposal {
        //the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes.
        uint256 nftTokenId;
        //the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        //number of yay votes for this proposal.
        uint256 yayVotes;
        //number of nay votes for this proposal.
        uint256 nayVotes;
        //whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        //mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not.
        mapping(uint256 => bool) voters;
    }

    /**
     * Create a payable constructor which initializes the contract instances for FakeNFTMarketplace and CryptoDevsNFT.
     * The payable allows this constructor to accept an ETH deposit when it is being deployed.
     */
    constructor(address _nftMarketplaceContractAddress, address _cryptoDevsNFTContractAddress) payable{
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplaceContractAddress);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFTContractAddress);
    }

    /**
     * Create a modifier which only allows a function to be called by someone who owns at least 1 CryptoDevsNFT.
     */
    modifier nftHolderOnly(){
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    /**
     * Create a modifier which only allows a function to be called if the given proposal's deadline has not been exceeded yet.
     */
    modifier activeProposalOnly(uint256 _proposalIndex){
        require(proposals[_proposalIndex].deadline > block.timestamp, "DEADLINE_EXCEEDED");
        _;
    }

    /**
     * Create a modifier which only allows a function to be called if the given proposals' deadline HAS been exceeded and if the proposal has not yet been executed
     */
    modifier inactiveProposalsOnly(uint256 _proposalIndex){
        require(proposals[_proposalIndex].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        require(proposals[_proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    /**
     * Create an enum named Vote containing possible options for a vote.
     */
    enum Vote{YAY,NAY}

    /**
     * @dev createProposal() allows a CryptoDevsNFT holder to create a new proposal in the DAO.
     * @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
     * @return Returns the proposal index for the newly created proposal
     */
    function createProposal(uint256 _nftTokenId) external nftHolderOnly() returns (uint256){
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        //This is global memory available to all functions within the contract. This storage is a permanent storage that Ethereum stores on every node within its environment.
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;
        return numProposals - 1;
    }

    /**
     * @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal.
     * @param _proposalIndex - the index of the proposal to vote on in the proposals array.
     * @param _vote - the type of vote they want to cast.
     */
    function voteOnProposal(uint256 _proposalIndex, Vote _vote) external nftHolderOnly() activeProposalOnly(_proposalIndex){
        Proposal storage proposal = proposals[_proposalIndex];
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;
        for(uint256 i = 0; i < voterNFTBalance; i++){
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false){
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");
        _vote == Vote.YAY?proposal.yayVotes+=numVotes:proposal.nayVotes+=numVotes;
    }

    /**
     * @dev executeProposal() allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded.
     * @param _proposalIndex - the index of the proposal to execute in the proposals array.
     */
    function executeProposal(uint256 _proposalIndex) external nftHolderOnly() inactiveProposalsOnly(_proposalIndex){
        Proposal storage proposal = proposals[_proposalIndex];
        //If the proposal has more YAY votes than NAY votes purchase the NFT from the FakeNFTMarketplace.
        if(proposal.yayVotes > proposal.nayVotes){
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value:nftPrice}(proposal.nftTokenId);
        }
        proposal.executed=true;
    }

    /**
     * @dev withdrawEther() allows the contract owner (deployer) to withdraw the ETH from the contract.
     * This will transfer the entire ETH balance of the contract to the owner address.
     */
    function withdrawEther() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}

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