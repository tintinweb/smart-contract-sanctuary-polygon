pragma solidity ^0.8.17;

interface IMergeGators {

    struct RequestStatusMerge {
        uint256[] randomWords;
        uint prize;
        address reciever;
    }

    enum lvlUp {
        TRUE,
        FALSE
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }


   struct NFT_Anatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFT_Level {
        uint8 trait1Lvl;
        uint8 trait2Lvl;
        uint8 trait3Lvl;
        uint8 trait4Lvl;
        uint8 trait5Lvl;
        uint8 trait6Lvl;
        uint8 trait7Lvl;
    }

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event chanceIsSet(uint256 value);
    error InvalidSigner();
    error RangeOutOfBounds();
    error callErr();
    error Mergefailed();
    error invalidSigner();
    event mergeRequested(uint256 _1st, uint256 _2nd, uint256 _3rd, address _owner);
    event mergeFulfilled(uint256 mergeId);
    event mergePrizeStatus(bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// _______________________________________________________________________
//     _   _                              __                              
//     /  /|                            /    )                            
// ---/| /-|----__---)__----__----__---/---------__--_/_----__---)__---__-
//   / |/  |  /___) /   ) /   ) /___) /  --,   /   ) /    /   ) /   ) (_ `
// _/__/___|_(___ _/_____(___/_(___ _(____/___(___(_(_ __(___/_/_____(__)_
//                          /                                             
//                      (_ /                                              

import {MultiSigWallet} from './treasury.sol';
import './extension/Ownable.sol';
import './chainlink/VRFConsumerBaseV2.sol';
import './chainlink/VRFCoordinatorV2Interface.sol';
import './IMergeGators.sol';

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract MergeGators is Ownable, VRFConsumerBaseV2, IMergeGators {
    /*//////////////////////////////////////////////////////////////
                               MERGE GATORS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => RequestStatusMerge) private vrf_requests; 

    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit = 100000;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable gasLane;
    VRFCoordinatorV2Interface private immutable mvrfCoordinator;

    uint256 internal constant MAX_CHANCE_VALUE = 1000;
    uint256 internal MIN_CHANCE_VALUE = 777;

    uint256 private _taxAmount;
    uint256 private _prizeBps;
    uint256 private _prizePortionBps;

    address payable public taxTreasury;

    address public alligatorsAddress;

    constructor(
        address erc721_,
        address payable _taxTreasuryAddress,
        uint256 taxPay_,
        uint64 subscriptionId_,
        address vrfCoordinatorV2_,
        bytes32 gasLane_,
        uint256 prizeBps_,
        uint256 prizePortionBps_
    ) VRFConsumerBaseV2(vrfCoordinatorV2_) {

            _setupOwner(msg.sender);
            //alligators = Alligators(ERC721_);
            alligatorsAddress = erc721_;
            taxTreasury = _taxTreasuryAddress;
            _taxAmount = taxPay_;
            _prizeBps = prizeBps_;
            _prizePortionBps = prizePortionBps_;
            subscriptionId = subscriptionId_;
            mvrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
            gasLane = gasLane_;
        }

    function merge3NFTs(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable {
        require(msg.value >= _taxAmount, "ERR");
        payable(address(this)).transfer(_calculatePortionToRewardPool());
        taxTreasury.transfer(_taxAmount - _calculatePortionToRewardPool());

        bytes memory approval = abi.encodeWithSignature("setApprovalForAll(address, bool)", alligatorsAddress, true);
        bytes memory mergeParams = abi.encodeWithSignature("merge3alligators(uint256, uint256, uint256, address)",_1st, _2nd, _3rd, msg.sender);

        (bool approved, ) = alligatorsAddress.delegatecall(approval);
        (bool success, ) = alligatorsAddress.call(mergeParams);

        if (!approved || !success) revert Mergefailed();

        _mergePrize(msg.sender);
    }

    function merge3Wjoker(uint256 _1st, uint256 _2nd, uint256 _3rd) public payable {

        require(msg.value >= _taxAmount, "ERR");
        payable(address(this)).transfer(_calculatePortionToRewardPool());
        taxTreasury.transfer(_taxAmount - _calculatePortionToRewardPool());

        bytes memory approval = abi.encodeWithSignature("setApprovalForAll(address, bool)", alligatorsAddress, true);
        bytes memory mergeParams = abi.encodeWithSignature("mergeWjoker(uint256, uint256, uint256, address)",_1st, _2nd, _3rd, msg.sender);

        (bool approved, ) = alligatorsAddress.delegatecall(approval);
        (bool success, ) = alligatorsAddress.call(mergeParams);

        if (!approved || !success) revert Mergefailed();

        _mergePrize(msg.sender);
    }
    
    function _mergePrize(address _receiver) internal returns (uint256 requestId) {
        requestId = mvrfCoordinator.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrf_requests[requestId] = RequestStatusMerge(
            {
                randomWords: new uint256[](0),
                prize : 0, reciever: _receiver
            });
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        vrf_requests[_requestId].randomWords = _randomWords;

        uint moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;

        uint256[2] memory chanceArracy = getChanceArray();

        if (moddedRng > chanceArracy[0]) {
            // withdraw from tax treasury to the reciever. !!!
            address payable to = payable(vrf_requests[_requestId].reciever);
            to.transfer(_calculatePortionToDistribute());
            emit mergePrizeStatus(true);
        }
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function _getBalance() internal view returns (uint256) {
        address payable self = payable(address(this));
        uint256 balance = self.balance;
        return balance;
    }

    function _calculatePortionToDistribute() internal view returns (uint256) {
        return _getBalance() * _prizeBps / 10_000;
    }

    function _calculatePortionToRewardPool() internal view returns (uint256) {
        return _taxAmount * _prizePortionBps / 10_000;
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function getChanceArray() public view returns (uint256[2] memory) {
        return [MIN_CHANCE_VALUE, MAX_CHANCE_VALUE];
    }

    function setChanceArray(uint256 _min) external onlyOwner {
        require(_min < MAX_CHANCE_VALUE, "invalid");
        MIN_CHANCE_VALUE = _min;
    }

    function setTaxAmount(uint256 taxAmount) external onlyOwner {
        _taxAmount = taxAmount;
    }

    function setRewardPoolPortion(uint256 percentage) external onlyOwner {
        _prizePortionBps = percentage;
    }

    function setPrizePortion(uint256 percentage) external onlyOwner {
        _prizeBps = percentage;
    }

    function setTreasuryAddress(address payable _taxTreasuryAddress) external onlyOwner {
        if (_taxTreasuryAddress == address(0)) revert callErr();
        taxTreasury = _taxTreasuryAddress;
    }
    
    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        if (_rescueTo == address(0)) revert callErr();
        _rescueTo.transfer(_amount);
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 indexed value, uint256 balance);
    event SubmittedTx(address indexed to, uint256 indexed value, bytes indexed data);
    event ApprovedTx(uint256 indexed txId, address indexed approver);
    event RevokeApproval(address indexed owner, uint indexed txId);
    event TxExecuted(address indexed to, uint256 indexed value, bytes indexed data, address executor);

    mapping(address => bool) private isOwner;

    struct Transaction {
        uint256 id;
        address to;
        uint256 value;
        bytes data;
        uint256 confirmations;
        bool executed;
    }

    mapping(uint256 => Transaction) private transactions;
    mapping(uint256 => mapping(address => bool)) private approved;

    uint256 public required;
    uint256 public txId;

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotOwner();
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId > txId - 1) {
            revert TxDoesNotExist();
        }
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) {
            revert TxAlreadyExecuted();
        }
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (approved[_txId][msg.sender]) {
            revert TxAlreadyApproved();
        }
        _;
    }

    error InvalidNumRequired();
    error InvalidOwnerAddress();
    error AlreadyOwner();
    error NotOwner();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyApproved();
    error TxNotApproved();
    error LessConfirmationsThanRequired();
    error TxExecutionFailed();

    constructor(address[] memory _owners, uint256 _required) {
        if (_required > _owners.length) {
            revert InvalidNumRequired();
        }
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) {
                revert InvalidOwnerAddress();
            }
            if (isOwner[owner]) {
                revert AlreadyOwner();
            }
            isOwner[owner] = true;
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        Transaction storage transaction = transactions[txId];
        transaction.id = txId;
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        txId++;
        emit SubmittedTx(_to, _value, _data);
    }

    function approveTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        transactions[_txId].confirmations++;
        approved[_txId][msg.sender] = true;
        emit ApprovedTx(_txId, msg.sender);
    }

    function executeTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        if (transaction.confirmations < required) {
            revert LessConfirmationsThanRequired();
        }
        transaction.executed = true;
        (bool success, ) = payable(transaction.to).call{
            value: transaction.value
        }(transaction.data);
        if (!success) {
            revert TxExecutionFailed();
        }
        emit TxExecuted(
            transaction.to,
            transaction.value,
            transaction.data,
            msg.sender
        );
    }

    function revokeApproval(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        if (approved[_txId][msg.sender]) {
            transactions[_txId].confirmations--;
            approved[_txId][msg.sender] = false;
        } else {
            revert TxNotApproved();
        }
        emit RevokeApproval(msg.sender, _txId);
    }

    function getTransaction(uint256 _txId) external view txExists(_txId) returns (Transaction memory) {
        return transactions[_txId];
    }

    function checkOwner(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    function checkApproved(uint256 _txId, address _approver) external view returns (bool) {
        return approved[_txId][_approver];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../../src/MergeGators.sol";

contract MergeGatorsMock is MergeGators {

    address constant collection_ = 0x1A5c6fE6a6Fdec026B10bBDbe54dcAD4bd7f6a43;
    uint256 constant bps = 3;
    uint256 constant portion = 30;

    address payable constant taxAddr = payable(0xE9b455e4e8Be2d5d7f703c6EEbeBE5bc4203b9BE);
    uint256 taxPay = 0.00001 ether;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2,
        bytes32 gasLane
        )
        MergeGators(collection_,
                    taxAddr,
                    taxPay,
                    subscriptionId,
                    vrfCoordinatorV2,
                    gasLane,
                    bps,
                    portion)
    {}

}