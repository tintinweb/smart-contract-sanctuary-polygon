/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: contracts/metadatav0.sol


pragma solidity ^0.8.15;




library Proccess {
    //Toma el uint array y lo moduliza (%222) +1
    function setModulo(uint[] memory _array) internal pure returns(uint[] memory){
        uint[] memory moduled= new uint[](_array.length);
        for(uint i=0; i<_array.length -1;i++){
            uint zz= (_array[i] %222)+1;
            moduled[i]=zz;
        }
        return moduled;
    }
    //Toma el array modulizado y lo compara para devolver el array de atributos

    function compareModuledarray(uint[] memory _moduledArray) internal pure returns (uint[] memory) {
        uint[] memory treated= new uint[](_moduledArray.length);
        for(uint i=0;i<_moduledArray.length -1;i++){
            uint ww= internalCheck(_moduledArray[i]);
            treated[i]=ww;
        }
        return treated;
    }
    function internalCheck(uint _interessedNumber)internal pure  returns (uint) {
        if(_interessedNumber==22||_interessedNumber==2
        ||_interessedNumber==13||_interessedNumber==222||
        _interessedNumber==73||_interessedNumber== 0){
            return 0;
        }
        if(0<_interessedNumber && _interessedNumber<13){
            return 1;
        }
        if(13<=_interessedNumber && _interessedNumber<35){
            return 2;
        }if(35<=_interessedNumber && _interessedNumber<73){
            return 3;
        }if(73<=_interessedNumber && _interessedNumber<111){
            return 4;
        }if(111<=_interessedNumber && _interessedNumber<159){
            return 5;
        }
        return 6;
    }
}

interface IRDD{
    function ownerOf(uint256 tokenId) external view returns (address);
}
contract MetadataV0 is Ownable, VRFConsumerBaseV2 {
    using Proccess for uint[];
    //Tiene que usar el vrf the chainlink para tomar los valores de atributos
    //Usar interfaces para fijarse quien es el duenio del nft
    VRFCoordinatorV2Interface private COORDINATOR;
    IRDD private i_rdd;
    // Your subscription ID.
    uint64 s_subscriptionId;

    // MATIC coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations
    address s_vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations
    bytes32 s_keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    uint32 s_callbackGasLimit = 300000;

    // The default is 3, but you can set this higher.
    uint16 s_requestConfirmations = 3;

    // For this example, retrieve 7 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    
    mapping(uint256 => uint256) s_requestIdToRequestIndex;
    mapping(uint256 => uint256[]) public s_requestIndexToRandomWords;
    uint256 public requestCounter;

    //
    //          URI RELATED STRUCTURES
    //

    address private s_interestedContract;
    address private s_Emergencyholder;
    address private s_migrationContract;
    bool private isHidden;
    string private s_HiddenMetadata;
    uint32 public immutable s_numWords = 7;


    uint64 public tokensProccesed;// default 0
    struct Datita{
        bool procesa3;
        uint[] sinProcesar;
        uint[] procesa2;
        string metadata;
    }
    
    mapping (uint256 => Datita)private s_randomWordsProcesadosYValATR;

    event ReturnedRandomness(uint256[] randomWords);




    constructor(uint64 subscriptionId,address _interested, string memory _hidden) VRFConsumerBaseV2(s_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(s_vrfCoordinator);
        s_subscriptionId = subscriptionId;
        tokensProccesed=0;
        isHidden=true;
        s_HiddenMetadata=_hidden;
        setInterestedCOntract(_interested);
    }

    modifier onlyInterested {
        require(msg.sender==s_interestedContract ||msg.sender==owner(),"Not allowed to interact");
        _;
    }

    //
    //          ONLY OWNER FUNCTIONS
    //          ONLY OWNER FUNCTIONS
    //          ONLY OWNER FUNCTIONS
    //

    function setMigrationContract(address _migrationCOntract) external  onlyOwner {
        s_interestedContract=_migrationCOntract;
    }
    function seeMigrationCOntract() external onlyOwner view returns (address) {
        return s_migrationContract;
    }
    function setInterestedCOntract(address _interested) public onlyOwner {
        s_interestedContract=_interested;
        i_rdd=IRDD(s_interestedContract);

    }
    function updateSubId(uint64 _newSubId) external onlyOwner{
        s_subscriptionId=_newSubId;
    }
    function seeInterestedContract() external view onlyOwner returns (address) {
        return s_interestedContract;
    }
    function setEmercencyHolder(address _wmrcy)external onlyOwner  {
        s_Emergencyholder=_wmrcy;
    }
    function seeEmercencyHolder()external view returns (address) {
        return s_Emergencyholder;
    }
    function setHiddenMetadata(string memory _newMtDt)external onlyOwner   {
        s_HiddenMetadata=_newMtDt;
    }
    function setIsHiddenFalse()external onlyOwner{
        isHidden=false;
    }
    function seeHidden()external view returns(string memory){
        return s_HiddenMetadata;
    } 

    function setTknIdMetadata(uint tknId,string memory _mtdt) external onlyOwner{
        require(tokensProccesed>=tknId,"TknId hasn't been proceced");
        s_randomWordsProcesadosYValATR[tknId].metadata=_mtdt;
    }

    function seeTknAtrProcceced(uint tknId)external view returns(uint[] memory){
       return s_randomWordsProcesadosYValATR[tknId].procesa2;
    }

    function requestRandomWords() external onlyInterested  {
        // require(msg.sender==s_interestedContract,"Not RDD contract, sorry!");
        // Will revert if subscription is not set and funded.
        uint requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        s_requestIdToRequestIndex[requestId] = requestCounter;
        // s_requestIndexToRandomWords[requestCounter] = s_randomWords;
        requestCounter += 1;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param requestId - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
       uint256 requestNumber = s_requestIdToRequestIndex[requestId];
        s_requestIndexToRandomWords[requestNumber] = randomWords;
    }

    //Due this function is gassss demanding, instead of using one call for proccesing all data,
    // we are splitting the action in separate calls to avoid function breaking
    function proccessDataANdATR(uint tokenId) external {
        require(!s_randomWordsProcesadosYValATR[tokenId].procesa3,"Already proccessed!");
        uint256[] memory unproccd=s_requestIndexToRandomWords[tokenId];
        uint[] memory semi= unproccd.setModulo();
        uint[] memory proc=semi.compareModuledarray();
        Datita memory zzz=Datita(true,semi,proc,"vamo newels");
        s_randomWordsProcesadosYValATR[tokenId]=zzz;
        tokensProccesed++;

    }
    //
    //           See token Uri
    //

    function seeTknURI(uint tknId) external view returns(string memory){
        require(msg.sender==s_interestedContract||msg.sender==owner(),"Not allowed to interact");
        if(isHidden|| i_rdd.ownerOf(tknId)==s_Emergencyholder){
            return s_HiddenMetadata;
        }
        return s_randomWordsProcesadosYValATR[tknId].metadata;
    }


    //
    //
    //          MIGRATION SECTION (yes, we are prepearing v1 and so on...)
    //
    //

    function migrateValuesToNewContract(uint _tknId) external view returns (Datita memory) {
        require(msg.sender==s_migrationContract||msg.sender==owner(),"Not allowed to interact");
        return (s_randomWordsProcesadosYValATR[_tknId]);
    }
}