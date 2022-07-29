/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// File: contracts/IConversationNFT.sol



pragma solidity ^0.8.0;

// interface to access the mint function of ConversationNFT
interface IConversationNFT {

    // Returns the id of token minted in ``owner``'s account.
    function awardSouvenir(address _humanWallet, string calldata tokenURI) external returns (uint);

    // Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner) external view returns (uint256 balance);
    
    // Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) external view returns (string memory); 
}

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/Humans.sol


pragma solidity ^0.8.0;




contract Humans is Ownable {
    
    // using counters to ensure only incrementing by 1
    using Counters for Counters.Counter;
    // setting humanCounter to be the Counter
    Counters.Counter private _humanCounter;

    // event for succesful registration of a human
    event NewHumanRegistered (uint indexed humanId, bytes32 indexed name, address indexed humanWallet);

    // struct of the Human with sepcific information of the human
    struct Human {
        uint256 humanId;
        bytes32 name;
        address humanWallet;
    }
    
    // array of all the registered humans
    Human[] public humans;

    // mapping of address to humanId
    mapping (address => uint) public humansWalletToHumanId;

    // @dev modifier to check that the both human wallets are registered
    modifier humansNotRegistered(address _personAWallet, address _personBWallet) { 
        require(
            humansWalletToHumanId[_personAWallet] != 0 && humansWalletToHumanId[_personBWallet] != 0, 
            "One Human not registered"
        );
        _;
    }

    // function to register a new human based on input variables
    function registerHuman(bytes32 _name, address _humanWallet) external onlyOwner {
        // check that a human is not already registered with this address
        require(humansWalletToHumanId[_humanWallet] == 0, "Can't reqister twice");
        // increment the human counter by one
        _humanCounter.increment();
        // set the values in a struct for the new human
        Human memory _newHuman = Human({
            humanId: _humanCounter._value,
            name: _name,
            humanWallet: _humanWallet
        });
        // push the new registered human into the array of all humans registered
        humans.push(_newHuman);
        // map the new registeried human by its counter to its wallet address
        humansWalletToHumanId[_humanWallet] = _humanCounter._value;
        // emit the new human registered
        emit NewHumanRegistered (_humanCounter._value, _name, _humanWallet);
    }
}

// File: contracts/Conversations.sol


pragma solidity ^0.8.0;




contract Conversations is Humans {
    
    // using counters to ensure only incrementing by 1
    using Counters for Counters.Counter;
    // setting conversationCounter to be the Counter
    Counters.Counter private conversationCounter;
    
    // Event for the succesful registration of a new Conversastion.
    event NewConversationRegistered (uint256 indexed conversationId, bytes32 indexed conversationName, address indexed personAWallet, address personBWallet);

    // struct of the Conversation with sepcific information needed to mint 
    struct Conversation {
        uint conversationId;
        bytes32 conversationName;
        address personAWallet;
        address personBWallet;
    }

    // array of all the Conversations
    Conversation[] public conversations;

    // Function to register a new Conversation based on input variables.
    function registerConversation(bytes32 _conversationName, address _personAWallet, address _personBWallet) external
    humansNotRegistered(_personAWallet, _personBWallet)  {
        // increment the conversation counter
        conversationCounter.increment();
        // set the new conversation with its specific values
        Conversation memory _newConversation = Conversation({
            conversationId: conversationCounter._value,
            conversationName: _conversationName,
            personAWallet: _personAWallet,
            personBWallet: _personBWallet
        });
        // add the conversation to the conversations array
        conversations.push(_newConversation);
        // emit the new Conversation registered
        emit NewConversationRegistered (conversationCounter._value, _conversationName, _personAWallet, _personBWallet);
    }

}
// File: contracts/ConversationNFTHandler.sol



pragma solidity ^0.8.0;




// contract to handle the mint of NFTs based on Conversations
contract ConversationNFTHandler is Conversations {
    
    // event for succesful mint of two NFTs for each human 
    //!!! could probably be optimized -> decide if 2 Events are better or using a struct
    event ConversationNFTsMinted (address indexed personAWallet, address indexed personBWallet, uint indexed conversationId, uint _nftIdA, uint _nftIdB);

    // address of the contract how mints the NFT 
    address private conversationNFTAddress; 

    // map the converstions and NFTs to make sure a NFT just get minted once
    mapping (uint => uint8) private mintedConversations;
    // map nftId to each wallet
    mapping  (uint => address) public mintedNftPersonWallet;

    // constructor with setting the correct address of the contract we are accessing when minting
    constructor(address _conversationNFTAddress) {   
        // setting the correct address
        conversationNFTAddress = _conversationNFTAddress;
    }

    // function to mint the NFTs to the two wallet adresses
    function mintConversationSouvenir (uint _conversationId, address _personAWallet, address _personBWallet, string memory _tokenURI) external 
    humansNotRegistered(_personAWallet, _personBWallet)  {
        // require no NFT is minted for the specific conversation
        require(mintedConversations[_conversationId] == 0, "Can't mint twice");
        uint _nftIdA;
        uint _nftIdB;
        _nftIdA = singleMint(_personAWallet, _tokenURI);
        _nftIdB = singleMint(_personBWallet, _tokenURI);
        mintedConversations[_conversationId] = 1;

        emit ConversationNFTsMinted(_personAWallet, _personBWallet, _conversationId, _nftIdA, _nftIdB);
    }

    // function to call the mint from the IConversationNFT interface with return value of the NFT id
    function singleMint(address _humanWallet, string memory _tokenURI) private returns (uint) {
        uint nftId;
        // sets the nftid which is given by minting
        nftId = IConversationNFT(conversationNFTAddress).awardSouvenir(_humanWallet, _tokenURI);
        // set mapping of minted NFT to wallet
        mintedNftPersonWallet[nftId] = _humanWallet;
        return (nftId);
    }


    // Returns the number of tokens in ``owner``'s account.
    function balanceOf(address _humanWallet) external view returns (uint256) {
        uint256 balance;
        balance = IConversationNFT(conversationNFTAddress).balanceOf(_humanWallet);
        return balance;
    }
    
    // Returns the owner of the `tokenId` token.
    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner;
        owner = IConversationNFT(conversationNFTAddress).ownerOf(_tokenId);
        return owner;
    }

    // Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        string memory _tokenURI;
        _tokenURI = IConversationNFT(conversationNFTAddress).tokenURI(_tokenId);
        return _tokenURI;
    } 

}