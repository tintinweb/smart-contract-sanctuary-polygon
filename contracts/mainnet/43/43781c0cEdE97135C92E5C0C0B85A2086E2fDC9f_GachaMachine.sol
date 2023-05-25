/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

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

// File: contracts/LUXON/utils/ILuxOnCharacter.sol



pragma solidity ^0.8.16;

interface ILuxOnCharacter {
    struct Character {
        uint256 tokenId;
        string name;
    }
    function setCharacterName(Character[] memory _character) external;
    function getCharacterInfo(uint256 tokenId) external view returns (string memory);
}

// File: contracts/Admin/data/GachaStruct.sol


pragma solidity ^0.8.18;

    enum GachaType {
        None,
        Character,
        FateCore
    }

    struct InputGachaInfo {
        uint256 tokenId;
        string name;
        uint256[] tierRatio;
        uint256[][] gachaGradeRatio;
        uint256[] gachaFateCoreRatio;
        uint256[] gachaFateCoreList;
        GachaType gachaType;
        bool isValid;
    }

    struct GachaInfo {
        uint256 tokenId;
        string name;
        uint256[] tierRatio;
        uint256[][] gachaGradeRatio;
        bool isValid;
    }

    struct FateCoreGachaInfo {
        uint256 tokenId;
        string name;
        uint256[] gachaFateCoreRatio;
        uint256[] gachaFateCoreList;
        bool isValid;
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/Admin/data/ActorData.sol


pragma solidity ^0.8.18;


contract DspActorData is Ownable {
    event SetGachaTypeById(uint256 indexed id, uint256 indexed gachaType);
    event SetGachaTypeByName(string indexed name, uint256 indexed gachaType);

    struct InputGachaTypeById {
        uint256 id;
        uint256 gachaType;
    }

    struct InputGachaTypeByName {
        string name;
        uint256 gachaType;
    }

    // id => type
    mapping(uint256 => uint256) private gachaTypeById;
    // fate core id => name
    mapping(string => uint256) private gachaTypeByName;


    function getGachaTypeById(uint256 _id) public view returns(uint256) {
        return gachaTypeById[_id];
    }

    function getGachaTypeByName(string memory _name) public view returns(uint256) {
        return gachaTypeByName[_name];
    }

    function getGachaTypeByIds(uint256[] memory _ids) public view returns(uint256[] memory) {
        uint256[] memory gachaTypes = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            gachaTypes[i] = gachaTypeById[_ids[i]];
        }
        return gachaTypes;
    }

    function getGachaTypeByNames(string[] memory _names) public view returns(uint256[] memory) {
        uint256[] memory gachaTypes = new uint256[](_names.length);
        for (uint256 i = 0; i < _names.length; i++) {
            gachaTypes[i] = gachaTypeByName[_names[i]];
        }
        return gachaTypes;
    }

    function setGachaTypeById(InputGachaTypeById memory _inputGachaTypeById) external onlyOwner {
        gachaTypeById[_inputGachaTypeById.id] = _inputGachaTypeById.gachaType;
        emit SetGachaTypeById(_inputGachaTypeById.id, _inputGachaTypeById.gachaType);
    }

    function setGachaTypeByIds(InputGachaTypeById[] memory _inputGachaTypeByIds) external onlyOwner {
        for (uint256 i = 0; i < _inputGachaTypeByIds.length; i++) {
            gachaTypeById[_inputGachaTypeByIds[i].id] = _inputGachaTypeByIds[i].gachaType;
            emit SetGachaTypeById(_inputGachaTypeByIds[i].id, _inputGachaTypeByIds[i].gachaType);
        }
    }

    function setGachaTypeByName(InputGachaTypeByName memory _inputGachaTypeByName) external onlyOwner {
        gachaTypeByName[_inputGachaTypeByName.name] = _inputGachaTypeByName.gachaType;
        emit SetGachaTypeByName(_inputGachaTypeByName.name, _inputGachaTypeByName.gachaType);
    }

    function setGachaTypeByNames(InputGachaTypeByName[] memory _inputGachaTypeByNames) external onlyOwner {
        for (uint256 i = 0; i < _inputGachaTypeByNames.length; i++) {
            gachaTypeByName[_inputGachaTypeByNames[i].name] = _inputGachaTypeByNames[i].gachaType;
            emit SetGachaTypeByName(_inputGachaTypeByNames[i].name, _inputGachaTypeByNames[i].gachaType);
        }
    }
}
// File: contracts/Admin/data/FateCoreData.sol


pragma solidity ^0.8.18;


contract DspFateCoreData is Ownable {
    event SetFateCoreData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event DeleteFateCoreData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event SetFateCoreName(uint256 indexed id, string indexed name);

    struct FateCoreInfo {
        string name;
        uint256 tier;
        uint256 gachaGrade;
        uint256 classType;
        uint256 nation;
        uint256 element;
        uint256 rootId;
        bool isValid;
    }

    struct FateCoreName {
        uint256 id;
        string name;
    }

    // fate core id => name
    mapping(uint256 => string) private fateCoreName;
    // name => fate core info
    mapping(string => FateCoreInfo) private fateCoreData;
    // tier => gacha grade => name[]
    mapping(uint256 => mapping(uint256 => string[])) private fateCoreInfoTable;

    uint256 private fateCoreCount;

    function getFateCoreInfo(string memory name) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (fateCoreData[name].tier, fateCoreData[name].gachaGrade, fateCoreData[name].classType, fateCoreData[name].nation, fateCoreData[name].element, fateCoreData[name].rootId, fateCoreData[name].isValid);
    }

    function getFateCoreInfoIsValid(string memory name) public view returns(bool) {
        return fateCoreData[name].isValid;
    }

    function getFateCoreName(uint256 id) public view returns (string memory) {
        return fateCoreName[id];
    }

    function setFateCoreName(FateCoreName[] memory _fateCoreName) external onlyOwner {
        for (uint256 i = 0; i < _fateCoreName.length; i++) {
            fateCoreName[_fateCoreName[i].id] = _fateCoreName[i].name;
            emit SetFateCoreName(_fateCoreName[i].id, _fateCoreName[i].name);
        }
    }

    function setFateCoreData(FateCoreInfo[] memory _fateCoreData) external onlyOwner {
        for (uint256 i = 0; i < _fateCoreData.length; i++) {
            require(_fateCoreData[i].isValid, "isValid false use delete");
            if (!fateCoreData[_fateCoreData[i].name].isValid) {
                fateCoreCount++;
            } else if (fateCoreData[_fateCoreData[i].name].tier != _fateCoreData[i].tier) {
                uint256 index;
                uint256 _tier = fateCoreData[_fateCoreData[i].name].tier;
                uint256 _gachaGrade = fateCoreData[_fateCoreData[i].name].gachaGrade;
                for (uint256 j = 0; j < fateCoreInfoTable[_tier][_gachaGrade].length; j++) {
                    if (keccak256(abi.encodePacked(fateCoreInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(_fateCoreData[i].name))) {
                        index = j;
                        break;
                    }
                }
                for (uint256 j = index; j < fateCoreInfoTable[_tier][_gachaGrade].length - 1; j++) {
                    fateCoreInfoTable[_tier][_gachaGrade][j] = fateCoreInfoTable[_tier][_gachaGrade][j + 1];
                }
                fateCoreInfoTable[_tier][_gachaGrade].pop();
            }
            fateCoreInfoTable[_fateCoreData[i].tier][_fateCoreData[i].gachaGrade].push(_fateCoreData[i].name);
            fateCoreData[_fateCoreData[i].name] = _fateCoreData[i];

            emit SetFateCoreData(_fateCoreData[i].name, _fateCoreData[i].tier, _fateCoreData[i].gachaGrade, _fateCoreData[i].classType, _fateCoreData[i].nation, _fateCoreData[i].element, _fateCoreData[i].isValid);
        }
    }

    function deleteFateCoreData(string[] memory names) external onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            uint256 _tier = fateCoreData[names[i]].tier;
            uint256 _gachaGrade = fateCoreData[names[i]].gachaGrade;

            uint256 index;
            for (uint256 j = 0; j < fateCoreInfoTable[_tier][_gachaGrade].length; j++) {
                if (keccak256(abi.encodePacked(fateCoreInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(fateCoreData[names[i]].name))) {
                    index = j;
                    break;
                }
            }
            for (uint256 j = index; j < fateCoreInfoTable[_tier][_gachaGrade].length - 1; j++) {
                fateCoreInfoTable[_tier][_gachaGrade][j] = fateCoreInfoTable[_tier][_gachaGrade][j + 1];
            }
            fateCoreInfoTable[_tier][_gachaGrade].pop();
            fateCoreCount--;

            emit DeleteFateCoreData(fateCoreData[names[i]].name, fateCoreData[names[i]].tier, fateCoreData[names[i]].gachaGrade, fateCoreData[names[i]].classType, fateCoreData[names[i]].nation, fateCoreData[names[i]].element, fateCoreData[names[i]].isValid);
            delete fateCoreData[names[i]];
        }
    }

    function getFateCoreCount() public view returns (uint256) {
        return fateCoreCount;
    }

    function getFateCoreCountByTireAndGachaGrade(uint256 _tier, uint256 _gachaGrade) public view returns (uint256) {
        return fateCoreInfoTable[_tier][_gachaGrade].length;
    }

    function getFateCoreInfoByTireAndIndex(uint256 _tier, uint256 _gachaGrade, uint index) public view returns (string memory) {
        return fateCoreInfoTable[_tier][_gachaGrade][index];
    }
}
// File: contracts/Admin/LuxOnAdmin.sol


pragma solidity ^0.8.16;


contract LuxOnAdmin is Ownable {

    mapping(string => mapping(address => bool)) private _superOperators;

    event SuperOperator(string operator, address superOperator, bool enabled);

    function setSuperOperator(string memory operator, address[] memory _operatorAddress, bool enabled) external onlyOwner {
        for (uint256 i = 0; i < _operatorAddress.length; i++) {
            _superOperators[operator][_operatorAddress[i]] = enabled;
            emit SuperOperator(operator, _operatorAddress[i], enabled);
        }
    }

    function isSuperOperator(string memory operator, address who) public view returns (bool) {
        return _superOperators[operator][who];
    }
}
// File: contracts/LUXON/utils/LuxOnSuperOperators.sol


pragma solidity ^0.8.16;



contract LuxOnSuperOperators is Ownable {

    event SetLuxOnAdmin(address indexed luxOnAdminAddress);
    event SetOperator(string indexed operator);

    address private luxOnAdminAddress;
    string private operator;

    constructor(
        string memory _operator,
        address _luxOnAdminAddress
    ) {
        operator = _operator;
        luxOnAdminAddress = _luxOnAdminAddress;
    }

    modifier onlySuperOperator() {
        require(LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, msg.sender), "LuxOnSuperOperators: not super operator");
        _;
    }

    function getLuxOnAdmin() public view returns (address) {
        return luxOnAdminAddress;
    }

    function getOperator() public view returns (string memory) {
        return operator;
    }

    function setLuxOnAdmin(address _luxOnAdminAddress) external onlyOwner {
        luxOnAdminAddress = _luxOnAdminAddress;
        emit SetLuxOnAdmin(_luxOnAdminAddress);
    }

    function setOperator(string memory _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    function isSuperOperator(address spender) public view returns (bool) {
        return LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, spender);
    }
}
// File: contracts/LUXON/utils/RandomSeedNumber.sol


pragma solidity ^0.8.16;




contract RandomSeedNumber is VRFConsumerBaseV2, LuxOnSuperOperators {
    event RequestSent(address indexed userAddress, uint256 indexed gachaTicketTokenId, uint256 indexed tokenId, uint256 requestId);
    event RequestFulfilled(address indexed userAddress, uint256 indexed requestId, uint256[] indexed randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    // keyHash = the maximum gas price you are willing to pay for a request in wei
    //https://docs.chain.link/vrf/v2/subscription/supported-networks
    // -> VRFCoordinator, keyHash 수정
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; // mumbai

    constructor(
        uint64 subscriptionId,
        string memory operator,
        address luxOnAdmin
    )
    VRFConsumerBaseV2(vrfCoordinator) LuxOnSuperOperators(operator, luxOnAdmin)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords(address userAddress, uint256 gachaTicketTokenId, uint256 tokenId)
    external
    onlySuperOperator
    {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
        randomWords : new uint256[](0),
        exists : true,
        fulfilled : false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(userAddress, gachaTicketTokenId, tokenId, requestId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(msg.sender, _requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return request.fulfilled;
    }

    function getRequestStatusMany(uint256[] memory _requestIdArray) external view returns (bool[] memory fulfilled) {
        bool[] memory fulfilledResults = new bool[](_requestIdArray.length);
        for (uint i = 0; i < _requestIdArray.length; i++) {
            require(s_requests[_requestIdArray[i]].exists, "request not found");
            RequestStatus memory request = s_requests[_requestIdArray[i]];
            fulfilledResults[i] = request.fulfilled;
        }
        return fulfilledResults;

    }

    function getRandomNumber(
        uint256 _requestId
    ) external view returns (uint256 randomWord) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return request.randomWords[0];
    }
}

// File: contracts/Admin/data/GachaDataV2.sol


pragma solidity ^0.8.16;



contract DspGachaData is Ownable {
    event SetGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] tierRatio, uint256[][]gachaGradeRatio, bool isValid);
    event SetFateCoreGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] ratio, uint256[]list, bool isValid);
    event RemoveGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] tierRatio, uint256[][]gachaGradeRatio, bool isValid);
    event RemoveFateCoreGachaInfo(uint256 indexed tokenId, string indexed name, uint256[] ratio, uint256[] list, bool isValid);

    uint256 private gachaCount;

    // tokenId => GachaInfo
    mapping(uint256 => GachaInfo) private gachaInfo;

    // tokenId => FateCoreGachaInfo
    mapping(uint256 => FateCoreGachaInfo) private fateCoreGachaInfo;

    // token id => type
    mapping(uint256 => uint256) private gachaTypeByTokenId;

    function getGachaCount() public view returns (uint256) {
        return gachaCount;
    }

    function getGachaInfo(uint256 _tokenId) public view returns (GachaInfo memory) {
        return gachaInfo[_tokenId];
    }

    function getFateCoreGachaInfo(uint256 _tokenId) public view returns (FateCoreGachaInfo memory) {
        return fateCoreGachaInfo[_tokenId];
    }

    function getGachaType(uint256 _tokenId) public view returns (uint256) {
        return uint256(gachaTypeByTokenId[_tokenId]);
    }

    function getGachaTierRatio(uint256 _tokenId) public view returns (uint256[] memory, uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < gachaInfo[_tokenId].tierRatio.length; i++) {
            sum += gachaInfo[_tokenId].tierRatio[i];
        }
        return (gachaInfo[_tokenId].tierRatio, sum);
    }

    function getGachaGachaGradeRatio(uint256 _tokenId) public view returns (uint256[][] memory, uint256[] memory) {
        uint256[] memory sum = new uint256[](gachaInfo[_tokenId].gachaGradeRatio.length);
        for (uint256 i = 0; i < gachaInfo[_tokenId].gachaGradeRatio.length; i++) {
            for (uint256 j = 0; j < gachaInfo[_tokenId].gachaGradeRatio[i].length; j++) {
                sum[i] += gachaInfo[_tokenId].gachaGradeRatio[i][j];
            }
        }
        return (gachaInfo[_tokenId].gachaGradeRatio, sum);
    }

    function getGachaFateCoreRatio(uint256 _tokenId) public view returns (uint256[] memory, uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < fateCoreGachaInfo[_tokenId].gachaFateCoreRatio.length; i++) {
            sum += fateCoreGachaInfo[_tokenId].gachaFateCoreRatio[i];
        }
        return (fateCoreGachaInfo[_tokenId].gachaFateCoreRatio, sum);
    }

    function getFateCoreByIndex(uint256 _tokenId, uint256 index) public view returns (uint256) {
        return fateCoreGachaInfo[_tokenId].gachaFateCoreList[index];
    }

    function setGachaInfo(InputGachaInfo memory _inputGachaInfo) external onlyOwner {
        require(_inputGachaInfo.tokenId != 0, "gacha id not valid");
        if (GachaType.Character == _inputGachaInfo.gachaType) {
            GachaInfo memory _gachaInfo = GachaInfo(_inputGachaInfo.tokenId, _inputGachaInfo.name, _inputGachaInfo.tierRatio, _inputGachaInfo.gachaGradeRatio, _inputGachaInfo.isValid);
            uint256 sumTierRatio = 0;
            for (uint256 i = 0; i < _gachaInfo.tierRatio.length; i++) {
                sumTierRatio += _gachaInfo.tierRatio[i];
            }
            require(sumTierRatio != 0, "gacha ratio sum 0");
            if (!gachaInfo[_gachaInfo.tokenId].isValid) {
                gachaCount++;
            }
            for (uint256 i = 0; i < _gachaInfo.gachaGradeRatio.length; i++) {
                if (_gachaInfo.tierRatio[i] != 0) {
                    uint256 sumGachaGradeRatio = 0;
                    for (uint256 j = 0; j < _gachaInfo.gachaGradeRatio[i].length; j++) {
                        sumGachaGradeRatio += _gachaInfo.gachaGradeRatio[i][j];
                    }
                    require(sumGachaGradeRatio != 0, "gacha gacha grade ratio sum 0");
                }
            }
            gachaTypeByTokenId[_gachaInfo.tokenId] = uint256(GachaType.Character);
            gachaInfo[_gachaInfo.tokenId] = _gachaInfo;
            emit SetGachaInfo(_gachaInfo.tokenId, _gachaInfo.name, _gachaInfo.tierRatio, _gachaInfo.gachaGradeRatio, _gachaInfo.isValid);
        } else if (GachaType.FateCore == _inputGachaInfo.gachaType) {
            FateCoreGachaInfo memory _fateCoreGachaInfo = FateCoreGachaInfo(_inputGachaInfo.tokenId, _inputGachaInfo.name, _inputGachaInfo.gachaFateCoreRatio, _inputGachaInfo.gachaFateCoreList, _inputGachaInfo.isValid);
            uint256 sumRatio = 0;
            for (uint256 i = 0; i < _fateCoreGachaInfo.gachaFateCoreRatio.length; i++) {
                sumRatio += _fateCoreGachaInfo.gachaFateCoreRatio[i];
            }
            require(sumRatio != 0, "gacha ratio sum 0");
            require(_fateCoreGachaInfo.gachaFateCoreRatio.length == _fateCoreGachaInfo.gachaFateCoreList.length, "not same count");
            if (!fateCoreGachaInfo[_fateCoreGachaInfo.tokenId].isValid) {
                gachaCount++;
            }
            gachaTypeByTokenId[_fateCoreGachaInfo.tokenId] = uint256(GachaType.FateCore);
            fateCoreGachaInfo[_fateCoreGachaInfo.tokenId] = _fateCoreGachaInfo;
            emit SetFateCoreGachaInfo(_fateCoreGachaInfo.tokenId, _fateCoreGachaInfo.name, _fateCoreGachaInfo.gachaFateCoreRatio, _fateCoreGachaInfo.gachaFateCoreList, _fateCoreGachaInfo.isValid);
        }
    }

    function setGachaInfos(InputGachaInfo[] memory _inputGachaInfo) external onlyOwner {
        for (uint256 k = 0; k < _inputGachaInfo.length; k++) {
            require(_inputGachaInfo[k].tokenId != 0, "gacha id not valid");
            if (GachaType.Character == _inputGachaInfo[k].gachaType) {
                GachaInfo memory _gachaInfo = GachaInfo(_inputGachaInfo[k].tokenId, _inputGachaInfo[k].name, _inputGachaInfo[k].tierRatio, _inputGachaInfo[k].gachaGradeRatio, _inputGachaInfo[k].isValid);
                uint256 sumTierRatio = 0;
                for (uint256 i = 0; i < _gachaInfo.tierRatio.length; i++) {
                    sumTierRatio += _gachaInfo.tierRatio[i];
                }
                require(sumTierRatio != 0, "gacha ratio sum 0");
                if (!gachaInfo[_gachaInfo.tokenId].isValid) {
                    gachaCount++;
                }
                for (uint256 i = 0; i < _gachaInfo.gachaGradeRatio.length; i++) {
                    if (_gachaInfo.tierRatio[i] != 0) {
                        uint256 sumGachaGradeRatio = 0;
                        for (uint256 j = 0; j < _gachaInfo.gachaGradeRatio[i].length; j++) {
                            sumGachaGradeRatio += _gachaInfo.gachaGradeRatio[i][j];
                        }
                        require(sumGachaGradeRatio != 0, "gacha gacha grade ratio sum 0");
                    }
                }
                gachaTypeByTokenId[_gachaInfo.tokenId] = uint256(GachaType.Character);
                gachaInfo[_gachaInfo.tokenId] = _gachaInfo;
                emit SetGachaInfo(_gachaInfo.tokenId, _gachaInfo.name, _gachaInfo.tierRatio, _gachaInfo.gachaGradeRatio, _gachaInfo.isValid);
            } else if (GachaType.FateCore == _inputGachaInfo[k].gachaType) {
                FateCoreGachaInfo memory _fateCoreGachaInfo = FateCoreGachaInfo(_inputGachaInfo[k].tokenId, _inputGachaInfo[k].name, _inputGachaInfo[k].gachaFateCoreRatio, _inputGachaInfo[k].gachaFateCoreList, _inputGachaInfo[k].isValid);
                uint256 sumRatio = 0;
                for (uint256 i = 0; i < _fateCoreGachaInfo.gachaFateCoreRatio.length; i++) {
                    sumRatio += _fateCoreGachaInfo.gachaFateCoreRatio[i];
                }
                require(sumRatio != 0, "gacha ratio sum 0");
                require(_fateCoreGachaInfo.gachaFateCoreRatio.length == _fateCoreGachaInfo.gachaFateCoreList.length, "not same count");
                if (!fateCoreGachaInfo[_fateCoreGachaInfo.tokenId].isValid) {
                    gachaCount++;
                }
                gachaTypeByTokenId[_fateCoreGachaInfo.tokenId] = uint256(GachaType.FateCore);
                fateCoreGachaInfo[_fateCoreGachaInfo.tokenId] = _fateCoreGachaInfo;
                emit SetFateCoreGachaInfo(_fateCoreGachaInfo.tokenId, _fateCoreGachaInfo.name, _fateCoreGachaInfo.gachaFateCoreRatio, _fateCoreGachaInfo.gachaFateCoreList, _fateCoreGachaInfo.isValid);
            }
        }
    }

    function removeGachaInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha id not valid");
        if (gachaInfo[_tokenId].isValid) {
            gachaCount--;
        }
        emit RemoveGachaInfo(_tokenId, gachaInfo[_tokenId].name, gachaInfo[_tokenId].tierRatio, gachaInfo[_tokenId].gachaGradeRatio, gachaInfo[_tokenId].isValid);
        delete gachaInfo[_tokenId];
    }

    function removeFateCoreGachaInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha id not valid");
        if (fateCoreGachaInfo[_tokenId].isValid) {
            gachaCount--;
        }
        emit RemoveFateCoreGachaInfo(_tokenId, fateCoreGachaInfo[_tokenId].name, fateCoreGachaInfo[_tokenId].gachaFateCoreRatio, fateCoreGachaInfo[_tokenId].gachaFateCoreList, fateCoreGachaInfo[_tokenId].isValid);
        delete fateCoreGachaInfo[_tokenId];
    }
}
// File: contracts/Admin/data/DataAddress.sol


pragma solidity ^0.8.16;


contract DspDataAddress is Ownable {

    event SetDataAddress(string indexed name, address indexed dataAddress, bool indexed isValid);

    struct DataAddressInfo {
        string name;
        address dataAddress;
        bool isValid;
    }

    mapping(string => DataAddressInfo) private dataAddresses;

    function getDataAddress(string memory _name) public view returns (address) {
        require(dataAddresses[_name].isValid, "this data address is not valid");
        return dataAddresses[_name].dataAddress;
    }

    function setDataAddress(DataAddressInfo memory _dataAddressInfo) external onlyOwner {
        dataAddresses[_dataAddressInfo.name] = _dataAddressInfo;
        emit SetDataAddress(_dataAddressInfo.name, _dataAddressInfo.dataAddress, _dataAddressInfo.isValid);
    }

    function setDataAddresses(DataAddressInfo[] memory _dataAddressInfos) external onlyOwner {
        for (uint256 i = 0; i < _dataAddressInfos.length; i++) {
            dataAddresses[_dataAddressInfos[i].name] = _dataAddressInfos[i];
            emit SetDataAddress(_dataAddressInfos[i].name, _dataAddressInfos[i].dataAddress, _dataAddressInfos[i].isValid);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnData.sol


pragma solidity ^0.8.16;



contract LuxOnData is Ownable {
    address private luxonData;
    event SetLuxonData(address indexed luxonData);

    constructor(
        address _luxonData
    ) {
        luxonData = _luxonData;
    }

    function getLuxOnData() public view returns (address) {
        return luxonData;
    }

    function setLuxOnData(address _luxonData) external onlyOwner {
        luxonData = _luxonData;
        emit SetLuxonData(_luxonData);
    }

    function getDataAddress(string memory _name) public view returns (address) {
        return DspDataAddress(luxonData).getDataAddress(_name);
    }
}
// File: contracts/Admin/data/ValueChipData.sol


pragma solidity ^0.8.16;


contract DspValueChipData is Ownable {
    event SetValueChipInfo(uint256 indexed tokenId, string indexed name, uint256 indexed valueChipsType, string characterName, uint256 gameEnumByValueChipsType);
    event RemoveValueChipInfo(uint256 indexed tokenId);

    enum ValueChipsType { None, Hero, Class, Nation, Element }
    uint256 private valueChipCount;

    struct InputValueChipInfo {
        uint256 tokenId;
        string name;
        ValueChipsType valueChipsType;
        string characterName;
        uint256 gameEnumByValueChipsType;
        bool isValid;
    }

    struct ValueChipInfo {
        string name;
        ValueChipsType valueChipsType;
        string characterName;
        uint256 gameEnumByValueChipsType;
        bool isValid;
    }

    // tokenId => ValueChipInfo
    mapping(uint256 => ValueChipInfo) private valueChipInfo;
    uint256[] private valueChipTokenIdList;

    function getValueChipCount() public view returns (uint256) {
        return valueChipCount;
    }

    function getValueChipInfo(uint256 _tokenId) public view returns (string memory, uint32, string memory, uint256, bool) {
        return (
        valueChipInfo[_tokenId].name,
        uint32(valueChipInfo[_tokenId].valueChipsType),
        valueChipInfo[_tokenId].characterName,
        valueChipInfo[_tokenId].gameEnumByValueChipsType,
        valueChipInfo[_tokenId].isValid
        );
    }

    function getValueChipsIsValid(uint256 _tokenId) public view returns (bool) {
        return valueChipInfo[_tokenId].isValid;
    }

    function getValueChipValueChipsType(uint256 _tokenId) public view returns (uint32) {
        return uint32(valueChipInfo[_tokenId].valueChipsType);
    }

    function getValueChipTokenIdList() public view returns (uint256[] memory) {
        return valueChipTokenIdList;
    }

    function setValueChipInfo(InputValueChipInfo memory _valueChipInfo) external onlyOwner {
        require(_valueChipInfo.tokenId != 0, "value chip id not valid");
        require(_valueChipInfo.isValid, "value chip not valid");
        if (!valueChipInfo[_valueChipInfo.tokenId].isValid) {
            valueChipCount++;
        }
        valueChipInfo[_valueChipInfo.tokenId] =
        ValueChipInfo(
            _valueChipInfo.name,
            _valueChipInfo.valueChipsType,
            _valueChipInfo.characterName,
            _valueChipInfo.gameEnumByValueChipsType,
            _valueChipInfo.isValid
        );
        emit SetValueChipInfo(_valueChipInfo.tokenId, _valueChipInfo.name, uint256(_valueChipInfo.valueChipsType), _valueChipInfo.characterName, _valueChipInfo.gameEnumByValueChipsType);
    }

    function setValueChipInfos(InputValueChipInfo[] memory _valueChipInfos) external onlyOwner {
        for (uint256 i = 0; i < _valueChipInfos.length; i++) {
            require(_valueChipInfos[i].tokenId != 0, "value chip id not valid");
            require(_valueChipInfos[i].isValid, "value chip not valid");
            if (!valueChipInfo[_valueChipInfos[i].tokenId].isValid) {
                valueChipCount++;
                valueChipTokenIdList.push(_valueChipInfos[i].tokenId);
            }
            valueChipInfo[_valueChipInfos[i].tokenId] =
            ValueChipInfo(
                _valueChipInfos[i].name,
                _valueChipInfos[i].valueChipsType,
                _valueChipInfos[i].characterName,
                _valueChipInfos[i].gameEnumByValueChipsType,
                _valueChipInfos[i].isValid
            );
            emit SetValueChipInfo(_valueChipInfos[i].tokenId, _valueChipInfos[i].name, uint256(_valueChipInfos[i].valueChipsType), _valueChipInfos[i].characterName, _valueChipInfos[i].gameEnumByValueChipsType);
        }
    }

    function removeValueChipInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha ticket id not valid");
        if (valueChipInfo[_tokenId].isValid) {
            valueChipCount--;
            uint256 index;
            for (uint256 i = 0; i < valueChipTokenIdList.length; i++) {
                if (valueChipTokenIdList[i] == _tokenId) {
                    index = i;
                }
            }
            for (uint256 i = index; i < valueChipTokenIdList.length - 1; i++) {
                valueChipTokenIdList[i] = valueChipTokenIdList[i + 1];
            }
            valueChipTokenIdList.pop();
        }
        emit RemoveValueChipInfo(_tokenId);
        delete valueChipInfo[_tokenId];
    }
}
// File: contracts/Admin/data/CharacterData.sol


pragma solidity ^0.8.16;




contract DspCharacterData is Ownable, LuxOnData {
    event SetCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event DeleteCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event SetCharacterName(uint256 indexed id, string indexed name);

    struct CharacterInfo {
        string name;
        uint256 tier;
        uint256 gachaGrade;
        uint256 classType;
        uint256 nation;
        uint256 element;
        uint256 rootId;
        bool isValid;
    }

    struct CharacterName {
        uint256 id;
        string name;
    }

    struct MatchValueChip {
        string name;
        uint256 valueChipId;
    }

    constructor(address dataAddress) LuxOnData(dataAddress) {}

    string public valueChipData = "DspValueChipData";

    // character id => name
    mapping(uint256 => string) private characterName;
    // name => character info
    mapping(string => CharacterInfo) private characterData;
    // tier => gacha grade => name[]
    mapping(uint256 => mapping(uint256 => string[])) private characterInfoTable;
    // name => value chip
    mapping(string => uint256) private matchValueChip;

    uint256 private characterCount;

    function getCharacterInfo(string memory name) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (characterData[name].tier, characterData[name].gachaGrade, characterData[name].classType, characterData[name].nation, characterData[name].element, characterData[name].rootId, characterData[name].isValid);
    }

    function getCharacterInfoIsValid(string memory name) public view returns(bool) {
        return characterData[name].isValid;
    }

    function getCharacterName(uint256 id) public view returns (string memory) {
        return characterName[id];
    }

    function setMatchValueChip(MatchValueChip[] memory _matchValueChips) external onlyOwner {
        address valueChipAddress = getDataAddress(valueChipData);
        for (uint256 i = 0; i < _matchValueChips.length; i++) {
            ( , uint32 _valueChipsType, string memory _characterName, , bool _isValid) = DspValueChipData(valueChipAddress).getValueChipInfo(_matchValueChips[i].valueChipId);
            if (
                _isValid &&
                _valueChipsType == uint32(DspValueChipData.ValueChipsType.Hero) &&
                uint(keccak256(abi.encodePacked(_characterName))) == uint(keccak256(abi.encodePacked(_matchValueChips[i].name)))
            ) {
                matchValueChip[_matchValueChips[i].name] = _matchValueChips[i].valueChipId;
            }
        }
    }

    function setCharacterName(CharacterName[] memory _characterName) external onlyOwner {
        for (uint256 i = 0; i < _characterName.length; i++) {
            characterName[_characterName[i].id] = _characterName[i].name;
            emit SetCharacterName(_characterName[i].id, _characterName[i].name);
        }
    }

    function setCharacterData(CharacterInfo[] memory _characterData) external onlyOwner {
        for (uint256 i = 0; i < _characterData.length; i++) {
            require(_characterData[i].isValid, "isValid false use delete");
            if (!characterData[_characterData[i].name].isValid) {
                characterCount++;
            } else if (characterData[_characterData[i].name].tier != _characterData[i].tier) {
                uint256 index;
                uint256 _tier = characterData[_characterData[i].name].tier;
                uint256 _gachaGrade = characterData[_characterData[i].name].gachaGrade;
                for (uint256 j = 0; j < characterInfoTable[_tier][_gachaGrade].length; j++) {
                    if (keccak256(abi.encodePacked(characterInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(_characterData[i].name))) {
                        index = j;
                        break;
                    }
                }
                for (uint256 j = index; j < characterInfoTable[_tier][_gachaGrade].length - 1; j++) {
                    characterInfoTable[_tier][_gachaGrade][j] = characterInfoTable[_tier][_gachaGrade][j + 1];
                }
                characterInfoTable[_tier][_gachaGrade].pop();
            }
            characterInfoTable[_characterData[i].tier][_characterData[i].gachaGrade].push(_characterData[i].name);
            characterData[_characterData[i].name] = _characterData[i];

            emit SetCharacterData(_characterData[i].name, _characterData[i].tier, _characterData[i].gachaGrade, _characterData[i].classType, _characterData[i].nation, _characterData[i].element, _characterData[i].isValid);
        }
    }

    function deleteCharacterData(string[] memory names) external onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            uint256 _tier = characterData[names[i]].tier;
            uint256 _gachaGrade = characterData[names[i]].gachaGrade;

            uint256 index;
            for (uint256 j = 0; j < characterInfoTable[_tier][_gachaGrade].length; j++) {
                if (keccak256(abi.encodePacked(characterInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(characterData[names[i]].name))) {
                    index = j;
                    break;
                }
            }
            for (uint256 j = index; j < characterInfoTable[_tier][_gachaGrade].length - 1; j++) {
                characterInfoTable[_tier][_gachaGrade][j] = characterInfoTable[_tier][_gachaGrade][j + 1];
            }
            characterInfoTable[_tier][_gachaGrade].pop();
            characterCount--;

            emit DeleteCharacterData(characterData[names[i]].name, characterData[names[i]].tier, characterData[names[i]].gachaGrade, characterData[names[i]].classType, characterData[names[i]].nation, characterData[names[i]].element, characterData[names[i]].isValid);
            delete characterData[names[i]];
        }
    }

    function getMatchValueChip(string memory _name) public view returns (uint256) {
        return matchValueChip[_name];
    }

    function getCharacterCount() public view returns (uint256) {
        return characterCount;
    }

    function getCharacterCountByTireAndGachaGrade(uint256 _tier, uint256 _gachaGrade) public view returns (uint256) {
        return characterInfoTable[_tier][_gachaGrade].length;
    }

    function getCharacterInfoByTireAndIndex(uint256 _tier, uint256 _gachaGrade, uint index) public view returns (string memory) {
        return characterInfoTable[_tier][_gachaGrade][index];
    }
}
// File: contracts/Admin/GachaMachineV5.sol


pragma solidity ^0.8.18;










contract GachaMachine is LuxOnData {
    event SetCharacterTokenAddress(address indexed characterTokenAddress);
    event GachaActor(address indexed userAddrss, uint256 indexed gachaTokenId, uint256 indexed actorTokenId, string name);

    address private characterTokenAddress;
    address private randomSeedAddress;
    string public gachaData = "DspGachaData";
    string public characterData = "DspCharacterData";
    string public fateCoreData = "DspFateCoreData";
    string public actorData = "DspActorData";

    constructor(
        address dataAddress,
        address _characterTokenAddress,
        address _randomSeedAddress
    ) LuxOnData(dataAddress) {
        characterTokenAddress = _characterTokenAddress;
        randomSeedAddress = _randomSeedAddress;
    }

    struct Gacha {
        uint256 gachaTokenId;
        RandomSeed[] randomSeed;
    }

    struct RandomSeed {
        address userAddress;
        uint256 actorTokenId;
        uint256 requestId;
    }

    struct GachaSimulator {
        uint256 gachaTokenId;
        bytes32[] seed;
    }

    function getCharacterTokenAddress() public view returns (address) {
        return characterTokenAddress;
    }

    function setCharacterTokenAddress(address _characterTokenAddress) external onlyOwner {
        characterTokenAddress = _characterTokenAddress;
        emit SetCharacterTokenAddress(_characterTokenAddress);
    }

    function gachaActor(Gacha[] memory _gachas) external onlyOwner {
        address gachaDataAddress = getDataAddress(gachaData);
        for (uint256 i = 0; i < _gachas.length; i++) {
            Gacha memory _gacha = _gachas[i];
            uint256 gachaType = DspGachaData(gachaDataAddress).getGachaType(_gacha.gachaTokenId);
            ILuxOnCharacter.Character[] memory _character = new ILuxOnCharacter.Character[](_gacha.randomSeed.length);
            uint256 count = 0;
            address characterDataAddress = getDataAddress(characterData);
            if (uint256(GachaType.Character) == gachaType) {
                (uint256[] memory _tierRatio, uint256 _tierRatioSum) = DspGachaData(gachaDataAddress).getGachaTierRatio(_gacha.gachaTokenId);
                (uint256[][] memory _gachaGradeRatio, uint256[] memory _gachaGradeRatioSum) = DspGachaData(gachaDataAddress).getGachaGachaGradeRatio(_gacha.gachaTokenId);
                for (uint256 j = 0; j < _gacha.randomSeed.length; j++) {
                    if (uint(keccak256(abi.encodePacked(ILuxOnCharacter(characterTokenAddress).getCharacterInfo(_gacha.randomSeed[j].actorTokenId)))) != uint(keccak256(abi.encodePacked("")))) {
                        continue;
                    }
                    uint256 seed_ = RandomSeedNumber(randomSeedAddress).getRandomNumber(_gacha.randomSeed[j].requestId);
                    uint256 _tier = randomNumber(
                        bytes32(seed_),
                        _gacha.randomSeed[j].actorTokenId,
                        _tierRatio,
                        _tierRatioSum,
                        "tier"
                    );
                    uint256 _gachaGrade = randomNumber(
                        bytes32(seed_),
                        _gacha.randomSeed[j].actorTokenId,
                        _gachaGradeRatio[_tier],
                        _gachaGradeRatioSum[_tier],
                        "gacha_grade"
                    );

                    uint index = uint(keccak256(abi.encodePacked(seed_, _gacha.randomSeed[j].actorTokenId, "index"))) %
                    DspCharacterData(characterDataAddress).getCharacterCountByTireAndGachaGrade(_tier + 1, _gachaGrade + 1);
                    _character[count] = ILuxOnCharacter.Character(
                        _gacha.randomSeed[j].actorTokenId,
                        DspCharacterData(characterDataAddress).getCharacterInfoByTireAndIndex(_tier + 1, _gachaGrade + 1, index)
                    );
                    emit GachaActor(_gacha.randomSeed[j].userAddress, _gacha.gachaTokenId, _gacha.randomSeed[j].actorTokenId, _character[count].name);
                    count++;
                }
            } else if (uint256(GachaType.FateCore) == gachaType) {
                address fateCoreDataAddress = getDataAddress(fateCoreData);
                address actorDataAddress = getDataAddress(actorData);
                (uint256[] memory _ratio, uint256 _ratioSum) = DspGachaData(gachaDataAddress).getGachaFateCoreRatio(_gacha.gachaTokenId);
                for (uint256 j = 0; j < _gacha.randomSeed.length; j++) {
                    if (uint(keccak256(abi.encodePacked(ILuxOnCharacter(characterTokenAddress).getCharacterInfo(_gacha.randomSeed[j].actorTokenId)))) != uint(keccak256(abi.encodePacked("")))) {
                        continue;
                    }
                    uint256 seed_ = RandomSeedNumber(randomSeedAddress).getRandomNumber(_gacha.randomSeed[j].requestId);
                    uint256 index = randomNumber(bytes32(seed_), _gacha.randomSeed[j].actorTokenId, _ratio,_ratioSum, "fateCore");
                    uint256 actorId = DspGachaData(gachaDataAddress).getFateCoreByIndex(_gacha.gachaTokenId, index);
                    string memory name = getName(actorDataAddress, characterDataAddress, fateCoreDataAddress, actorId);
                    _character[count] = ILuxOnCharacter.Character(_gacha.randomSeed[j].actorTokenId, name);
                    emit GachaActor(_gacha.randomSeed[j].userAddress, _gacha.gachaTokenId, _gacha.randomSeed[j].actorTokenId,  _character[count].name);
                    count++;
                }
            }
            ILuxOnCharacter.Character[] memory character_ = new ILuxOnCharacter.Character[](count);
            for (uint256 j = 0; j < count; j++) {
                character_[j] = _character[j];
            }
            ILuxOnCharacter(characterTokenAddress).setCharacterName(character_);
        }
    }

    function getName(address actorDataAddress, address characterDataAddress, address fateCoreDataAddress, uint256 actorId) private view returns (string memory) {
        uint256 actorType = DspActorData(actorDataAddress).getGachaTypeById(actorId);
        if (uint256(GachaType.Character) == actorType) {
            return DspCharacterData(characterDataAddress).getCharacterName(actorId);
        } else if (uint256(GachaType.FateCore) == actorType) {
            return DspFateCoreData(fateCoreDataAddress).getFateCoreName(actorId);
        }
        revert("not exist actor name");
    }

    function gachaActorSimulator(GachaSimulator memory _gacha) public view returns (string[] memory) {
        address gachaDataAddress = getDataAddress(gachaData);
        address characterDataAddress = getDataAddress(characterData);
        address fateCoreDataAddress = getDataAddress(fateCoreData);
        address actorDataAddress = getDataAddress(actorData);
        uint256 gachaType = DspGachaData(gachaDataAddress).getGachaType(_gacha.gachaTokenId);
        string[] memory _characterName = new string[](_gacha.seed.length);
        if (uint256(GachaType.Character) == gachaType) {
            (uint256[] memory _tierRatio, uint256 _tierRatioSum) = DspGachaData(gachaDataAddress).getGachaTierRatio(_gacha.gachaTokenId);
            (uint256[][] memory _gachaGradeRatio, uint256[] memory _gachaGradeRatioSum) = DspGachaData(gachaDataAddress).getGachaGachaGradeRatio(_gacha.gachaTokenId);
            for (uint256 j = 0; j < _gacha.seed.length; j++) {
                bytes32 seed = _gacha.seed[j];
                uint256 _tier = randomNumber(seed, j, _tierRatio, _tierRatioSum, "tier");
                uint256 _gachaGrade = randomNumber(seed, j, _gachaGradeRatio[_tier], _gachaGradeRatioSum[_tier], "gacha_grade");
                uint256 characterCount = DspCharacterData(characterDataAddress).getCharacterCountByTireAndGachaGrade(_tier + 1, _gachaGrade + 1);
                uint256 index = uint(keccak256(abi.encodePacked(seed, j, "index"))) % characterCount;
                string memory name = DspCharacterData(characterDataAddress).getCharacterInfoByTireAndIndex(_tier + 1, _gachaGrade + 1, index);
                _characterName[j] = name;
            }
        } else if (uint256(GachaType.FateCore) == gachaType) {
            (uint256[] memory _ratio, uint256 _ratioSum) = DspGachaData(gachaDataAddress).getGachaFateCoreRatio(_gacha.gachaTokenId);
            for (uint256 j = 0; j < _gacha.seed.length; j++) {
                bytes32 seed = _gacha.seed[j];
                uint256 index = randomNumber(seed, j, _ratio, _ratioSum, "fateCore");
                uint256 actorId = DspGachaData(gachaDataAddress).getFateCoreByIndex(_gacha.gachaTokenId, index);
                _characterName[j] = getName(actorDataAddress, characterDataAddress, fateCoreDataAddress, actorId);
            }
        }
        return _characterName;
    }

    function randomNumber(bytes32 _seed, uint256 _tokenId, uint256[] memory _ratio, uint256 _ratioSum, string memory _type) private pure returns (uint256 index) {
        uint ratio = (uint(keccak256(abi.encodePacked(_seed, _tokenId, _type))) % _ratioSum) + 1;
        index = 0;
        uint ratioSum = 0;
        for (uint256 i = 0; i < _ratio.length; i++) {
            ratioSum += _ratio[i];
            if (ratio <= ratioSum) {
                break;
            }
            index++;
        }
    }
}