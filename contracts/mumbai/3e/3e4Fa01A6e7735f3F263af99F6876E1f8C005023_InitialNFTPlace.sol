// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { ByteHasher } from './libraries/ByteHasher.sol';
import { ISemaphore } from './libraries/ISemaphore.sol';


//0x330C8452C879506f313D1565702560435b0fee4C
//groupID

contract InitialNFTPlace is IERC721Receiver, VRFConsumerBaseV2 {
    using ByteHasher for bytes;

      



    //chainlink for mumbai
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint64 s_subscriptionId = 325;
    mapping( uint => uint ) requestIdToMarketplaceId;


    Marketplace[] public marketplaces;
    


    ISemaphore internal immutable semaphore;
    mapping(uint256 => bool) internal nullifierHashes;

    enum MarketplaceType {
        NULL,
        GIVEAWAY,
        RETAIL
    }

    uint constant RANDOM_PRIME = 325778765244908313467197;
    uint constant MOD_OF_RANDOM = 100000000000000000000;
    uint constant EXECUTOR_REWARD_MAX_LIMIT = 10; //divisor
    uint constant EXECUTOR_REWARD_INCREASE_FACTOR = 1000; //divisor
    
    address constant SEMAPHORE_ADDRESS = 0x330C8452C879506f313D1565702560435b0fee4C;
    uint constant SEMAPHORE_GROUP_ID = 1;


    mapping( uint => uint[] ) public NFTsOfMarketplaces;
    mapping( address => uint ) public balance;

    mapping(uint => mapping(address => Participant)) public participants;

    struct Participant {
        bool isParticipated;
        uint nonce;
        bool isClaimed;
    }

    struct Marketplace {
        MarketplaceType marketType;
        string marketplaceURI;
        uint256 giveawayTime;
        address owner;
        address contractAddress;
        uint256 price;
        uint pool;
        address transferPricesTo;
        bool isDistributed;
        uint randomSeed;
        uint participantNumber;
    }


    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        marketplaces.push();
        semaphore = ISemaphore(SEMAPHORE_ADDRESS);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    //createGiveawayMarketplace

    function createGiveawayMarketplace ( 
        string calldata _marketplaceURI, 
        uint256 _giveawayTime, 
        address _contractAddress, 
        uint256 _price, 
        address _transferPricesTo 
        ) external {

        address msgSender = msg.sender;

        marketplaces.push( Marketplace(
                {
                marketType: MarketplaceType.GIVEAWAY,
                marketplaceURI: _marketplaceURI,
                giveawayTime: _giveawayTime,
                owner: msgSender,
                contractAddress: _contractAddress,
                price: _price,
                pool: 0,
                transferPricesTo: _transferPricesTo,
                isDistributed: false,
                randomSeed: 0,
                participantNumber: 0
                }
            ) );



    } 
/*
    function beParticipant( uint marketplaceId ) external payable {
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.marketType == MarketplaceType.GIVEAWAY, "not giveaway" );
        require( block.timestamp < marketplace.giveawayTime, "participation ended" );

        address msgSender = msg.sender;
        Participant memory participant = participants[ marketplaceId ][ msgSender ];
        //normally there will be semaphore
        require( participant.isParticipated == false, "already participated" );
        //end

        uint msgValue = msg.value;
        require( msgValue >= marketplace.price, "not enough ether" );
        marketplaces[ marketplaceId ].pool += msgValue;

        participants[ marketplaceId ][ msgSender ].isParticipated = true;
        participants[ marketplaceId ][ msgSender ].nonce = marketplace.participantNumber;
        
        ++marketplaces[ marketplaceId ].participantNumber;

    }



*/
/*
actionId: abi.encode( contractAddress, marketplaceId )
signal: abi.encode(receiver) (current metamask wallet address)  
*/
        function beParticipant( 
            uint marketplaceId,
            uint root,
            uint nullifierHash,
            uint[8] calldata proof
            ) external payable {

        require( nullifierHashes[ nullifierHash ], "reused nullifier");

        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.marketType == MarketplaceType.GIVEAWAY, "not giveaway" );
        require( block.timestamp < marketplace.giveawayTime, "participation ended" );

        address msgSender = msg.sender;
        Participant memory participant = participants[ marketplaceId ][ msgSender ];
        //normally there will be semaphore
        require( participant.isParticipated == false, "already participated with this address" );


        //end

        uint msgValue = msg.value;
        require( msgValue >= marketplace.price, "not enough ethers" );

        semaphore.verifyProof(
            root,
            SEMAPHORE_GROUP_ID,
            abi.encodePacked( msgSender ).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this), marketplaceId ).hashToField(),
            proof
        );

        marketplaces[ marketplaceId ].pool += msgValue;
        nullifierHashes[ nullifierHash ] = true;
        participants[ marketplaceId ][ msgSender ].isParticipated = true;
        participants[ marketplaceId ][ msgSender ].nonce = marketplace.participantNumber;
        ++marketplaces[ marketplaceId ].participantNumber;

    }
    //change this mappings to storage variable

        function verifyTest( 
            uint marketplaceId,
            uint root,
            uint nullifierHash,
            uint[8] calldata proof
        ) external view returns( bool ) {

        semaphore.verifyProof(
            root,
            SEMAPHORE_GROUP_ID,
            abi.encodePacked( msg.sender ).hashToField(),
            nullifierHash,
            abi.encodePacked(address(this), marketplaceId ).hashToField(),
            proof
        );
            return true;
        }

    //will be used chainlink
    /*
    function getRandomNumber() internal view returns( uint ) {
        uint randomNumber;

        randomNumber = uint(keccak256(abi.encodePacked( block.number / 2, block.timestamp)));

        return randomNumber;
    }
    */


    function getExecutorReward( uint marketplaceId ) public view returns( uint ) {
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        uint lockedPool;
        if( marketplace.participantNumber >= NFTsOfMarketplaces[ marketplaceId ].length ) {
            lockedPool = marketplace.pool - ( (marketplace.participantNumber - NFTsOfMarketplaces[ marketplaceId ].length ) * marketplace.price );
        } else {
            lockedPool = marketplace.pool;
        }
        
        uint reward = lockedPool / EXECUTOR_REWARD_INCREASE_FACTOR * (block.timestamp - marketplace.giveawayTime);
        if( reward > lockedPool / EXECUTOR_REWARD_MAX_LIMIT ) {
            reward = lockedPool / EXECUTOR_REWARD_MAX_LIMIT;
        }

        return reward;
    }


    function executeGiveaway( uint marketplaceId ) external {
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.marketType == MarketplaceType.GIVEAWAY, "not giveaway" );
        require( block.timestamp > marketplace.giveawayTime, "participation not ended" );
        require( marketplace.isDistributed == false, "already distributed" );

        marketplaces[ marketplaceId ].isDistributed = true;
        //marketplaces[ marketplaceId ].randomSeed = getRandomNumber();


        uint lockedPool;
        if( marketplace.participantNumber >= NFTsOfMarketplaces[ marketplaceId ].length ) {
            lockedPool = marketplace.pool - ( (marketplace.participantNumber - NFTsOfMarketplaces[ marketplaceId ].length ) * marketplace.price );
        } else {
            lockedPool = marketplace.pool;
        }

        uint reward = getExecutorReward( marketplaceId );
        payable( msg.sender ).transfer( reward );
        balance[ marketplace.transferPricesTo ] += lockedPool - reward;

        uint requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestIdToMarketplaceId[ requestId ] = marketplaceId;

        
    }

    

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        
        uint marketplaceId = requestIdToMarketplaceId[ requestId ];
        marketplaces[ marketplaceId ].randomSeed = randomWords[0] % MOD_OF_RANDOM;
  }

    function getGiveawayResult( uint marketplaceId, address participant ) public view returns( uint ) {
        require( participants[ marketplaceId ][ participant ].isParticipated, "not participated" );
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.isDistributed, "not distributed yet" );
        require( marketplaces[ marketplaceId ].randomSeed > 0, "have not gotten random yet");
        return ( participants[ marketplaceId ][ participant ].nonce * RANDOM_PRIME + marketplace.randomSeed ) % marketplace.participantNumber;
    }

    function claimNFT( uint marketplaceId ) external {

        address msgSender = msg.sender;
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.marketType == MarketplaceType.GIVEAWAY, "not giveaway" );
        require( marketplace.isDistributed, "not distributed" );
        require( marketplaces[ marketplaceId ].randomSeed > 0, "have not gotten random yet");
        require( participants[ marketplaceId ][ msgSender ].isClaimed == false, "already claimed" );

        //winners have values below winnerNumber
        uint[] memory nfts = NFTsOfMarketplaces[ marketplaceId ];
        uint result = getGiveawayResult( marketplaceId, msgSender );
        require( nfts.length > result, "not winner" );

        participants[ marketplaceId ][ msgSender ].isClaimed = true;
        IERC721( marketplace.contractAddress ).transferFrom( 
            address( this ),
            msgSender,
            result
        );
    }


        function claimPrice( uint marketplaceId ) external {
        address msgSender = msg.sender;
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.marketType == MarketplaceType.GIVEAWAY, "not giveaway" );
        require( marketplace.isDistributed, "not distributed" );
        require( marketplaces[ marketplaceId ].randomSeed > 0, "have not gotten random yet");
        require( participants[ marketplaceId ][ msgSender ].isClaimed == false, "already claimed" );

        //winners have values below winnerNumber
        uint[] memory nfts = NFTsOfMarketplaces[ marketplaceId ];
        uint result = getGiveawayResult( marketplaceId, msgSender );
        require( nfts.length <= result, "winner cannot take prices" );

        participants[ marketplaceId ][ msgSender ].isClaimed = true;
        payable( msgSender ).transfer( marketplace.price );
    }


    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
    return number;
    }

    function withdraw() external {
        address msgSender = msg.sender;
        uint amount = balance[ msgSender ];
        require( amount > 0 , "no balance of user");
        balance[ msgSender ] = 0;
        payable( msgSender ).transfer( amount );
    }


    //marketplace id can be passed as data
    //requirelar işe yaramıyor yani bazıları
    function onERC721Received( address operator, address from, uint256 tokenId, bytes memory data ) public override returns (bytes4) {

        uint marketplaceId = bytesToUint( data );
        require( marketplaceId != 0, "no data" );
        require( marketplaceId < marketplaces.length, "invalid id" );

        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        
        require( marketplace.contractAddress == msg.sender, "not equal to marketplace's nft contract" );
        require( marketplace.owner == operator || marketplace.owner == from || address(0) == from, "not owner" );
        require( block.timestamp < marketplace.giveawayTime, "participation ended" );

        NFTsOfMarketplaces[ marketplaceId ].push( tokenId );


        return this.onERC721Received.selector;
    }

    function renounceOwnership( uint marketplaceId ) external {
        require( marketplaceId < marketplaces.length && marketplaceId > 0, "invalid id" );
        Marketplace memory marketplace = marketplaces[ marketplaceId ];
        require( marketplace.owner == msg.sender, "not owner" );

        marketplaces[ marketplaceId ].owner = address(0);
    }

    function getBlockTimestamp() public view returns( uint ) {
        return block.timestamp;
    }

    //giveawayden önce yükleyebilsin
    function addNFTtoMarketplace( uint256 marketplaceId, uint256 tokenId ) external {
        require( marketplaceId < marketplaces.length && marketplaceId > 0, "invalid id" );
        address msgSender = msg.sender;

        Marketplace memory marketplace = marketplaces[ marketplaceId ];

        require( marketplace.owner == msgSender, "not owner" );
        require( block.timestamp < marketplace.giveawayTime, "participation ended" );

        address contractAddress = marketplace.contractAddress;


        IERC721( contractAddress ).transferFrom( 
            msgSender,
            address( this ),
            tokenId
        );

        NFTsOfMarketplaces[ marketplaceId ].push( tokenId );
        


    } 

//first approve from the erc721 contract in the frontend 
    function addAllNFTstoMarketplace( uint256 marketplaceId ) external {
        require( marketplaceId < marketplaces.length && marketplaceId > 0, "invalid id" );
        address msgSender = msg.sender; 

        Marketplace memory marketplace = marketplaces[ marketplaceId ];

        require( marketplace.owner == msgSender, "not owner" );
        require( block.timestamp < marketplace.giveawayTime, "participation ended" );

        address contractAddress = marketplace.contractAddress;

        uint totalSupply = IERC721Enumerable( contractAddress ).totalSupply();

        for( uint index = 0; index < totalSupply; index++ ) {

        IERC721( contractAddress ).transferFrom( 
            msgSender,
            address( this ),
            index
         );

        NFTsOfMarketplaces[ marketplaceId ].push( index );

        }
        

    }

    function fetchAllMarketplaces() external view returns( Marketplace[] memory ) {
        return marketplaces;
    }

    function fetchMarketplace( uint id ) external view returns( Marketplace memory ) {
        return marketplaces[ id ];
    }


    


    //60 40     

    //add NFT

    // participantId % (participantNumber / winners) == randomNumber % (participantNumber / winners)


    //createRetailMarketplace


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ByteHasher {
    /// @dev Creates a keccak256 hash of a bytestring.
    /// @param value The bytestring to hash
    /// @return The hash of the specified value
    /// @dev `>> 8` makes sure that the result is included in our field
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISemaphore {
    /// @notice Reverts if the zero-knowledge proof is invalid.
    /// @param root The of the Merkle tree
    /// @param groupId The id of the Semaphore group
    /// @param signalHash A keccak256 hash of the Semaphore signal
    /// @param nullifierHash The nullifier hash
    /// @param externalNullifierHash A keccak256 hash of the external nullifier
    /// @param proof The zero-knowledge proof
    /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}