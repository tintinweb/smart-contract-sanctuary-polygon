// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Interface for FakeNFTMarketplace
 */

interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the marketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the _tokenID has been purchased
    /// @return Returns a boolean, available if true
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the marketplace
    /// @param _tokenId is the NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by a given address
    /// @param owner is the address to fetch the number of NFTs from
    /// @return Returns the no. of tokens in 'owner's' account
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns token ID owned by an address at given index
    /// @param owner is the address to fetch the NFT token IDs from
    /// @return Returns the tokenID
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        //the tokenId of the NFT to purchase from marketplace
        uint256 nftTokenId;
        //UNIX timestamp until which proposal is active
        uint256 deadline;
        //no. of yes votes
        uint256 yesVotes;
        //no. of no votes
        uint256 noVotes;
        //whether or not this proposal has been executed - can't be executed before deadline
        bool executed;
        //mapping of CryptoDevNFT tokenIDs to booleans, indicating if NFT has been used to vote
        mapping(uint256 => bool) voters;
    }

    //mapping of prposalID to proposal
    mapping(uint256 => Proposal) public proposals;

    //no. of proposals created
    uint256 public numProposals;

    //initializing contracts we are calling from
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    //payable constructor that initializes the contract instances
    //payable allows constructor to accept an ETH deposit when deployed
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    //this modifier only allows a CryptoDev holder to call a modified function
    modifier nftHolderOnly() {
        require(
            cryptoDevsNFT.balanceOf(msg.sender) > 0,
            "NOT A MEMBER OF THIS DAO"
        );
        _;
    }

    /// @dev createProposal allows an NFT holder to create a new proposal in the DAO
    /// @param _nftTokenId is the token ID to be purchased from the marketplace
    /// @return Returns the proposal index for newly created proposal
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(
            nftMarketplace.available(_nftTokenId),
            "That NFT is not for sale."
        );
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;

        //Set the proposal's voting deadline to be curr time + 5 mins
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        //returning the index of the new proposal
        return numProposals - 1;
    }

    //Modifier that only allows function to be called if given proposal's deadline hasn't passed
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "Deadline has passed for this proposal"
        );
        _;
    }

    //YES = 0, NO = 1
    enum Vote {
        YES,
        NO
    }

    /// @dev voteOnProposal allows NFT holder to case vote on active proposal
    /// @param proposalIndex is the index of the proposal on the proposals array
    /// @param vote is the type of vote they want to cast

    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        //Calculating how many NFTs are owned by the voter
        //that haven't already been used for voting for this proposal

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes > 0, "Already voted.");

        if (vote == Vote.YES) {
            proposal.yesVotes += numVotes;
        } else {
            proposal.noVotes += numVotes;
        }
    }

    //Modifier that only allows a function to be called if the proposal's deadline has exceeded
    //and  proposal hasn't yet been executed

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "Deadline has NOT passed"
        );

        require(
            proposals[proposalIndex].executed == false,
            "Proposal has been executed"
        );
        _;
    }

    /// @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal the deadline
    /// @param proposalIndex - the index of the proposal to execute in the proposal's array
    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        //If proposal has more yes votes than no votes, purchase the NFT from the marketplace
        if (proposal.yesVotes > proposal.noVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();

            //checking the balance of the contract
            require(
                address(this).balance >= nftPrice,
                "Not enough funds in the treasury"
            );
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows contract owner to withdraw from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //these functions allow the contract to accept ETH deposits without a function being called
    //empty calldata
    receive() external payable {}

    //if no other function matches
    fallback() external payable {}
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