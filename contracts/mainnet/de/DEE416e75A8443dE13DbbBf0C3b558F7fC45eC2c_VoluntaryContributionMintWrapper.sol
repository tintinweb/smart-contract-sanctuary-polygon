// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ImQuark.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title   Help people in need affected by the two massive earthquakes in Turkey!
 * 
 * @author  Y.Kara -  mQuark - Unbounded - soonami.io
 * @notice  This is a wrapper for the mQuark protocol. 
 *          Accepts mint and sends the value to a valid Turkish organization account.
 *          
 * 
 *          All the contributions are voluntary. This address is a valid address that 
 *          accepts crypto for Polygon Mainnet Network. 
 * 
 *          "0xbe4CdE5eeEeD1f0A97a9457f6eF5b71EAE108652"
 * 
 *          Please kindly check these URLs if you are looking for more info!
 * 
 *          https://www.paribu.com/blog/en/news/about-our-disaster-support-plan-and-the-cryptocurrency-donation-system/
 *          https://twitter.com/0xpolygon/status/1623690024452558852?s=12&t=SQfdUZkeYXI76wNu6-vT3w
 *          https://twitter.com/TurkeyReliefDAO/status/1623681944725733376?s=20&t=QVBZvmaNJu_8Z8Nv0IkVQg
 */
contract VoluntaryContributionMintWrapper {

  address admin;
  ImQuark mQuark;
  // address immutable contributionValidAddress;
  uint256 internal totalContributedAmount;
  address constant CONTRIBUTON_ADDRESS = 0xbe4CdE5eeEeD1f0A97a9457f6eF5b71EAE108652;
  mapping(address => bool) public mintedAddresses;
  event TokenMinted(address from, uint256 amount, uint256 tokenId);
  event VoluntaryContributionWithoutMint(address sender, uint256 amount);


  modifier onlyAdmin() {
    if (msg.sender != admin) revert("unauthorized access");
    _;
  }

  // constructor(address _contributionValidAddress ) {
  //   admin = msg.sender;
  //   contributionValidAddress = _contributionValidAddress;
  // }
  constructor( ) {
    admin = msg.sender;
  }

  function setAdmin(address addr) external onlyAdmin {
    admin = addr;
  }

  function setmQuark(ImQuark addr) external onlyAdmin {
    mQuark = addr;
  }

  function voluntaryContributionMint(
    address signer,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external payable {
    if(mintedAddresses[msg.sender]) revert ("You already minted!");
    (, , , , uint256 minToken, , uint256 mintCount, , , ) = mQuark.getProjectCollection(templateId, projectId, collectionId);
    mintedAddresses[msg.sender] = true;

    mQuark.mintFreeWithPreURI(signer, projectId, templateId, collectionId, signature, uri,salt);
    uint256 nextMintedToken = minToken + mintCount;
    mQuark.safeTransferFrom(address(this), msg.sender, nextMintedToken);

    if(msg.value > 0) {
      totalContributedAmount += msg.value;
      // (bool sent,) = (contributionValidAddress).call{value: msg.value}("");
      (bool sent,) = (CONTRIBUTON_ADDRESS).call{value: msg.value}("");
      require(sent, "Failed to send Ether");
    }

    emit TokenMinted(msg.sender, msg.value, nextMintedToken);
  }

  function getTotalContribution() external view returns(uint256){
    return totalContributedAmount;
  }

  function getMintStatus() external view returns(bool) {
    return mintedAddresses[msg.sender];
  }

  function voluntaryContributionWithoutMint() external payable{
    totalContributedAmount += msg.value;
    // (bool sent,) = (contributionValidAddress).call{value: msg.value}("");
    (bool sent,) = (CONTRIBUTON_ADDRESS).call{value: msg.value}("");
    require(sent, "Failed to send Ether");
    emit VoluntaryContributionWithoutMint(msg.sender,msg.value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ImQuark {

  struct TokenInfo{
    // status of the upgradibilty
    bool isLocked;
    // token's royalty receiver
    address royaltyReciever;
    // the token uri
    string uri;
  }

  struct Collection {
    address royaltyReceiver;
    // the id of the project that the collection belongs to. This id is assigned by the contract.
    uint256 projectId;
    // the id of the template that the collection inherits from.
    uint256 templateId;
    // the created collection's id for a template id
    uint256 collectionId;
    // the minimum token id that can be minted from the collection
    uint256 minTokenId;
    // the maximum token id that can be minted from the collection
    uint256 maxTokenId;
    // the number of minted tokens from the collection
    uint256 mintCount;
    // the URIs of the collection (minted tokens inherit one of the URI)
    string[] collectionURIs;
    // the total supply of the collection
    uint16 totalSupply;
    //0: static / 1: limited / 2: dynamic  | free 3: static / 4: limited / 5: dynamic
    uint8 mintType;
  }

  struct SellOrder {
    // the order maker (the person selling the URI)
    address payable seller;
    // the "from" token contract address
    address fromContractAddress;
    // the token id whose project URI will be sold
    uint256 fromTokenId;
    // the project's id whose owner is selling the URI
    uint256 projectId;
    // the URI that will be sold
    string slotUri;
    // the price required for the URI
    uint256 sellPrice;
  }

  struct BuyOrder {
    // the order executer (the person buying the URI)
    address buyer;
    // the order maker (the person selling the URI)
    address seller;
    // the "from" token contract address
    address fromContractAddress;
    // the token id whose project URI will be sold
    uint256 fromTokenId;
    // the "to" token contract address
    address toContractAddress;
    // the token id whose project URI will be sold
    uint256 toTokenId;
    // the project's id whose owner is selling the URI
    uint256 projectId;
    // the URI that will be bought
    string slotUri;
    // the price required for the URI
    uint256 buyPrice;
  }

  // Packed parameters for Create Collection functions
  struct CreateCollectionParams {
    uint256[] templateIds;
    uint256[] collectionIds;
    uint16[] totalSupplies;
  }

  // Event for when a collection is created
  event CollectionCreated(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint16 totalSupply,
    uint256 minId,
    uint256 maxId,
    string[] collectionUris
  );

  // Event for when an NFT is minted
  event NFTMinted(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256 tokenId,
    string uri,
    address to
  );
  // Event for free static and limited dynamic minting
  event NFTMintedFree(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    int256 variationId,
    uint256 tokenId,
    string uri,
    address to
  );

  // Event for free fully dynamic minting
  event NFTMintedWithPreUri(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    string uri,
    uint256 tokenId,
    address to
  );
  // Event for when a URI slot is added for a project for a token
  event ProjectURISlotAdded(uint256 tokenId, uint256 projectId, string uri);
  // Event for when a URI slot is reset for a project for a token
  event ProjectSlotURIReset(uint256 tokenId, uint256 projectId);
  // Event for when a URI is updated for a project for a token
  event ProjectURIUpdated(bytes signature, uint256 projectId, uint256 tokenId, string updatedUri);
  // Event for when the royalty rate is set
  event RoyaltySet(address reciever, uint256 royaltyAmount);

  /**
   * @notice Performs a single NFT mint without any slots.(Static and Limited Dynamic).
   *
   * @param to             The address of the token receiver.
   * @param projectId      Collection owner's project id
   * @param templateId     Collection's inherited template's id
   * @param collectionId   Collection id for its template
   * @param variationId    Variation id for the collection. (0 for the static typed collection)
   */
  function mint(
    address to,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external;

  /**
   * @notice Performs a single NFT mint without any slots.(Fully Dynamic)
   * @param signer         The address of the signer that signed the parameters used to create the signatures.
   * @param to             The address of the token receiver.
   * @param projectId      Collection owner's project id
   * @param templateId     Collection's inherited template's id
   * @param collectionId   Collection id for its template
   * @param signature      The signed data for the NFT URI, using the project's registered wallet.
   * @param uri            The URI that will be assigned to the NFT
   * @param salt           The salt value
   * */
  function mintWithPreURI(
    address signer,
    address to,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external;
  /**
   *  Performs single free mint withot any slots.(Static and Limited Dynamic)
   *  NFT is locked to upgradability. It can be unlocked on the Control Contract.
   *
   *  @param projectId     Collection owner's project id
   *  @param templateId    Collection's inherited template's id
   *  @param collectionId  Collection ID for its template
   *  @param variationId   Variation ID for the collection. (0 for the static typed collection)
   */
  function mintFree(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external;

  /**
   * @notice  Performs single free mint without uris.(Only Fully Dynamic)
   *          NFT is locked to upgradability. It can be unlocked on the Control Contract.
   *
   * @param signer       The address of the signer that signed the parameters used to create the signatures.
   * @param projectId    Collection owner's project id
   * @param templateId   Collection's inherited template's id
   * @param collectionId Collection id for its template
   * @param signature    The signed data for the NFT URI, using the project's registered wallet.
   * @param uri          The URI that will be assigned to the NFT
   * @param salt           The salt value
   */
  function mintFreeWithPreURI(
    address signer,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    bytes calldata signature,
    string calldata uri,
    bytes calldata salt
  ) external;


  /**
   * Mints a single non-fungible token (NFT) with multiple URI slots.
   * Initializes the URI slots with the given project's URI.
   *
   * @notice Reverts if the number of given templates is more than 256.
   *
   * @param to                     The address of the token receiver.
   * @param templateId             The ID of the collection's inherited template.
   * @param collectionId           The ID of the collection for its template.
   * @param variationId            Variation ID for the collection. (0 for the static typed collection)
   * @param projectIds             The IDs of the collection owner's project.
   * @param projectSlotDefaultUris The project slot will be pre-initialized with the project's default slot URI.
   */
  function mintWithURISlots(
    address to,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external;

  /**
   * @notice Performs a batch mint operation without any URI slots.
   *
   * @param to               The address of the token receiver.
   * @param projectId        The collection owner's project ID.
   * @param templateIds      The collection's inherited template's ID.
   * @param collectionIds    The collection ID for its template.
   * @param variationIds     Variation IDs for the collections.
   * @param amounts          The number of mint amounts from each collection.
   */
  function mintBatch(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint256[] calldata variationIds,
    uint16[] calldata amounts
  ) external;

  /**
   * @dev Performs batch mint operation with single given project URI slot for every token
   *
   * @param to                 Token receiver
   * @param projectId          The collection owner's project ID.
   * @param templateIds        The collection's inherited template's ID.
   * @param collectionIds      The collection ID for its template.
   * @param variationIds       Variation IDs for the collections.
   * @param amounts            The number of mint amounts from each collection.
   * @param projectDefaultUri  Project slot will be pre-initialized with the project's default slot URI
   * */
  function mintBatchWithURISlot(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint256[] calldata variationIds,
    uint16[] calldata amounts,
    string calldata projectDefaultUri
  ) external;

  /**
   *
   * Adds a single URI slot to a single non-fungible token (NFT).
   * Initializes the added slot with the given project's default URI.
   *
   * @notice Reverts if the number of given projects is more than 256.
   *         The added slot's initial state will be pre-filled with the project's default URI.
   *
   * @param owner                  The owner of the token.
   * @param tokenContract          The contract address of the token
   * @param tokenId                The ID of the token to which the slot will be added.
   * @param projectId              The ID of the slot's project.
   * @param projectSlotDefaultUri The project's default URI that will be set to the added slot.
   */
  function addURISlotToNFT(
    address owner,
    address tokenContract,
    uint256 tokenId,
    uint256 projectId,
    string calldata projectSlotDefaultUri
  ) external;

  /**
   * Adds multiple URI slots to a single token in a batch operation.
   *
   * @notice Reverts if the number of projects is more than 256.
   *          Slots' initial state will be pre-filled with the given default URI values.
   *
   * @param owner                  The owner of the token.
   * @param tokenContract          The contract address of the token
   * @param tokenId                The ID of the token to which the slots will be added.
   * @param projectIds             An array of IDs for the slots that will be added.
   * @param projectSlotDefaultUris An array of default URI values for the added
   */
  function addBatchURISlotsToNFT(
    address owner,
    address tokenContract,
    uint256 tokenId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external;

  /**
   * Adds the same URI slot to multiple tokens in a batch operation.
   *
   * @notice Reverts if the number of tokens is more than 20.
   *         Slots' initial state will be pre-filled with the given default URI value.
   *
   * @param owner                The owner of the tokens.
   * @param tokensContracts      The contract address of each token
   * @param tokenIds             An array of IDs for the tokens to which the slot will be added.
   * @param projectId            The ID of the project for the slot that will be added.
   * @param projectDefaultUris   The default URI value for the added slot.
   */
  function addBatchURISlotToNFTs(
    address owner,
    address[] calldata tokensContracts,
    uint256[] calldata tokenIds,
    uint256 projectId,
    string calldata projectDefaultUris
  ) external;

  /**
   * Updates the URI slot of a single token.
   *
   * @notice The project must sign the new URI with its wallet address.
   *
   * @param owner          The address of the owner of the token.
   * @param signature      The signed data for the updated URI, using the project's wallet address.
   * @param project        The address of the project.
   * @param projectId      The ID of the project.
   * @param tokenContract  The contract address of the token
   * @param tokenId        The ID of the token.
   * @param updatedUri     The updated, signed URI value.
   */
  function updateURISlot(
    address owner,
    bytes calldata signature,
    address project,
    uint256 projectId,
    address tokenContract,
    uint256 tokenId,
    string calldata updatedUri
  ) external;

  /**
   * Transfers the URI slot of a single token to another token's URI slot for the same project.
   * Also resets the URI slot of the sold token to the default URI value for the project.
   *
   * @notice Reverts if slots are not added for both tokens.
   *         Reverts if the URI to be sold doesn't match the current URI of the token.
   *         Reverts if one of the tokens is not owned by the seller or buyer.
   *
   * @param seller             A struct containing details about the sell order.
   * @param buyer              A struct containing details about the buy order.
   * @param projectDefaultUri  The default URI value for the project.
   */
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    string calldata projectDefaultUri
  ) external;

  /**
   * Performs a batch operation to create multiple collections at once.(Static and Limited Dynamic)
   * Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
   *
   * @param royaltyReciever          Royalty receiver of the collection tokens when being sold.
   * @param projectId                The ID of the registered project that will own the collections.
   * @param signer                   The address of the signer that signed the parameters used to create the signatures.
   * @param createParams             Packed parameters
   * * templateIds       The IDs of the selected templates to use for creating the collections.
   * * collectionIds     The IDs of the next collections ids for the templates
   * * totalSupplies     The total supplies of tokens for the new collections.
   * @param signatures               The signatures created using the given parameters and signed by the signer.
   *                                 Second dimension includes, each signatures of each variation.
   * @param uris                     The URIs that will be assigned to the collections.
   *                                 Second dimension includes variations.
   * @param isCollectionFree         Status of the collection
   */
  function createCollections(
    address royaltyReciever,
    uint256 projectId,
    address signer,
    CreateCollectionParams calldata createParams,
    bytes[][] calldata signatures,
    string[][] calldata uris,
    bool[] calldata isCollectionFree
  ) external;

  /**
   * Performs a batch operation to create multiple collections at once.(Fully Dynamic)
   * Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
   *
   * @param createParams   Packed parameters
   * * templateIds         The IDs of the selected templates to use for creating the collections.
   * * collectionIds       The IDs of the next collections ids for the templates
   * * totalSupplies       The total supplies of tokens for the new collections.
   */
  function createCollectionsWithoutURIs(
    address royaltyReciever,
    uint256 projectId,
    CreateCollectionParams calldata createParams,
    bool[] calldata isCollectionFree
  ) external;

  /**
   * Registers ERC721-Collections to the contract. URI slots to can be added to the NFTs.
   * Collection has to be represented by a chosen template.
   *
   * @param tokenContract ERC721 contract address
   * @param templateUri   Selected template URI that represents the collection.
   */
  function registerExternalCollection(address tokenContract, string calldata templateUri) external;

  /**
   * @dev See ERC 165
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  /**
   * Removes the lock on the NFT that prevents to have slots.
   *
   * @param projectId    Collection owner's project id
   * @param templateId   Collection's inherited template's id
   * @param collectionId Collection id for its template
   * @param tokenId      Token id
   */
  function unlockFreeMintNFT(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 tokenId
  ) external;

  /**
   * Every project will be able to place a slot to tokens if owners want
   * These slots will store the uri that refers 'something' on the project
   * Slots are viewable by other projects but modifiable only by the owner of
   * the token who has a valid signature by the project
   *
   * @notice Returns the project URI for the given token ID
   *
   * @param tokenContract  The address of the token
   * @param tokenId        The ID of the token whose project URI is to be returned
   * @param projectId      The ID of the project associated with the given token
   *
   * @return           The URI of the given token's project slot
   */
  function tokenProjectURI(
    address tokenContract,
    uint256 tokenId,
    uint256 projectId
  ) external view returns (string memory);

  /**
   * @return Collection template uri
   */
  function externalCollectionURI(address collectionAddress) external view returns (string memory);

  /**
   * @notice This function returns the last collection ID for a given project and template.
   *
   * @param projectId  The ID of the project to get the last collection ID for
   * @param templateId The ID of the template to get the last collection ID for
   * @return           The last collection ID for the given project and template
   */
  function getProjectLastCollectionId(uint256 projectId, uint256 templateId) external view returns (uint256);

  /**
   * @notice This function checks whether a given token has been assigned a slot for a given project.
   *
   * @param contractAddress The address of the token
   * @param tokenId         The ID of the token to check
   * @param projectId       The ID of the project to check
   * @return isAdded        "true" if the given token has been assigned a slot for the given project
   */
  function isSlotAddedForProject(
    address contractAddress,
    uint256 tokenId,
    uint256 projectId
  ) external view returns (bool isAdded);

  /**
   * @return isFreeMinted True if the token is minted for free.
   */
  function getIsFreeMinted(uint256 tokenId) external view returns (bool isFreeMinted);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * The function getProjectCollection is used to retrieve the details of a specific collection that was created by a registered project.
   *
   * @param templateId       The ID of the template used to create the collection.
   * @param projectId        The ID of the project that created the collection.
   * @param collectionId     The ID of the collection.
   *
   * @return _royaltyReceiver Royalty receiver when the token of the collection is being sold.
   * @return _projectId       The ID of the project that created the collection.
   * @return _templateId      The ID of the template used to create the collection.
   * @return _collectionId    The ID of the collection.
   * @return minTokenId       The minimum token ID in the collection.
   * @return maxTokenId       The maximum token ID in the collection.
   * @return mintCount        The number of tokens that have been minted for this collection.
   * @return collectionURIs   The URI associated with the collection.
   * @return totalSupply      The total number of tokens in the collection.
   * @return mintType         The Collection type
   *
   * (Paid- 0:Static 1: Limited 2: Dynamic | Free- 4:Static 5:Limited 6:Dynamic)
   */
  function getProjectCollection(
    uint256 templateId,
    uint256 projectId,
    uint256 collectionId
  )
    external
    view
    returns (
      address _royaltyReceiver,
      uint256 _projectId,
      uint256 _templateId,
      uint256 _collectionId,
      uint256 minTokenId,
      uint256 maxTokenId,
      uint256 mintCount,
      string[] memory collectionURIs,
      uint16 totalSupply,
      uint8 mintType
    );

  error ExceedsLimit();
  error InvalidTemplateId();
  error InvalidVariation();
  error UnexsistingTokenMint();
  error NotEnoughSupply();
  error VerificationFailed();
  error InvalidIdAmount();
  error InvalidId(uint256 templateId, uint256 collectionId);
  error UnexistingToken();
  error NotOwner();
  error ProjectIdZero();
  error AddedSlot();
  error UriSLotUnexist();
  error UsedSignature();
  error CallerNotAuthorized();
  error InvalidCollectionId();
  error InvalidContractAddress();
  error LockedNFT(uint256 tokenId);
  error SellerIsNotOwner();
  error BuyerIsNotOwner();
  error InvalidTokenAddress();
  error NonERC721Implementer();
  error InvalidTokenId();
  error GivenTokenAddressNotRegistered();
  error SellerGivenURIMismatch();
  error CollectionIsNotFreeForMint();
  error LengthMismatch();
  error WrongMintType();
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