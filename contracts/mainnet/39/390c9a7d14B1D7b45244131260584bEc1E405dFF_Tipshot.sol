// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title Tipshot {Blockchain powered sport prediction marketplace}.
 */

contract Tipshot is Ownable, IERC721Receiver {
  using Counters for Counters.Counter;

  // ========== STATE VARIABLES ========== //
  Counters.Counter private _predictionIds;

  uint256 private pointer;

  ///@notice maps the generated id to the prediction data
  mapping(uint256 => PredictionData) public Predictions;

  ///@notice maps the generated id to the prediction stats
  mapping(uint256 => Statistics) public PredictionStats;

  //      tokenId          prediction id
  mapping(uint256 => mapping(uint256 => Vote)) public Validations; //maps miners tokenId to vote data

  //    buyer address    prediction id
  mapping(address => mapping(uint256 => PurchaseData)) public Purchases;

  //      predictionId => activePool index
  mapping(uint256 => uint256) public Index;

  mapping(address => uint256) public Balances;

  mapping(address => LockedFundsData) public LockedFunds;

  address public NFT_CONTRACT_ADDRESS;

  uint8 internal constant SIXTY_PERCENT = 3;

  uint8 internal constant MAX_VALIDATORS = 5;

  uint16 internal constant HOURS = 3600;

  mapping(address => uint256[]) public BoughtPredictions;

  mapping(address => uint256[]) public OwnedPredictions;

  mapping(address => ValidationData[]) public OwnedValidations;

  mapping(uint256 => address) public TokenOwner;

  mapping(address => Profile) public User;

  mapping(address => uint256[]) public dummyList;

  mapping(address => ValidationData[]) public dummyValidations;

  enum Status {
    Pending,
    Won,
    Lost,
    Inconclusive
  }

  enum State {
    Inactive,
    Withdrawn,
    Rejected,
    Active,
    Concluded
  }

  enum ValidationStatus {
    Neutral,
    Positive,
    Negative
  }

  struct LockedFundsData {
    uint256 amount;
    uint256 lastPushDate;
    uint256 releaseDate;
    uint256 totalInstances;
  }

  struct Vote {
    address miner;
    bool assigned;
    ValidationStatus opening;
    ValidationStatus closing;
    bool settled;
  }

  struct PredictionData {
    address seller;
    string ipfsHash;
    string key;
    uint256 createdAt;
    uint256 startTime; //start time of first predicted event
    uint256 endTime; //end time of last predicted event
    uint32 odd;
    uint256 price;
    Status status;
    State state;
    bool withdrawnEarnings;
    ValidationStatus winningOpeningVote;
    ValidationStatus winningClosingVote;
  }

  struct Statistics {
    uint8 validatorCount;
    uint8 upvoteCount;
    uint8 downvoteCount;
    uint8 wonVoteCount;
    uint8 lostVoteCount;
    uint64 buyCount;
  }

  struct PurchaseData {
    bool purchased;
    string key;
    bool refunded;
  }

  struct ValidationData {
    uint256 id;
    uint256 tokenId;
    string key;
  }

  struct Profile {
    string profile;
    string key;
    uint256 wonCount;
    uint256 lostCount;
    uint256 totalPredictions;
    uint256[10] recentTips;
    uint8 spot;
  }

  uint256 public miningFee; // paid by seller -> to be shared by validators
  uint256 public minerStakingFee; // paid by miner, staked per validation
  uint32 public minerPercentage; // %  for miner, In event of a prediction won

  uint256[] public miningPool;
  uint256[] public activePool;

  uint8 public freeTipsQuota;

  uint8 public usedFreeQuota;

  /**********************************/
  /*╔═════════════════════════════╗
    ║           EVENTS            ║
    ╚═════════════════════════════╝*/

  event VariableUpdated(
    uint256 miningFee,
    uint256 minerStakingFee,
    uint32 minerPercentage
  );
  event PredictionCreated(
    address indexed sender,
    uint256 indexed id,
    string ipfsHash,
    string key
  );
  event PredictionUpdated(
    address indexed sender,
    uint256 indexed id,
    string ipfsHash,
    string key
  );
  event DepositCreated(address sender, uint256 value);

  event ValidationAssigned(
    address miner,
    uint256 indexed id,
    uint256 indexed tokenId
  );
  event OpeningVoteSubmitted(
    uint256 indexed id,
    uint256 indexed tokenId,
    uint8 option,
    State state
  );
  event PredictionPurchased(address indexed buyer, uint256 indexed id);
  event ClosingVoteSubmitted(
    uint256 indexed id,
    uint256 indexed tokenId,
    uint8 option
  );

  event PredictionWithdrawn(uint256 indexed id, address seller);

  event MinerSettled(
    address indexed miner,
    uint256 indexed id,
    uint256 indexed tokenId,
    uint256 minerEarnings,
    bool refunded
  );

  event SellerSettled(
    address indexed seller,
    uint256 indexed id,
    uint256 sellerEarnings
  );

  event BuyerRefunded(address indexed buyer, uint256 indexed id, uint256 price);

  event Withdrawal(address indexed recipient, uint256 amount, uint256 balance);

  event MinerNFTAndStakingFeeWithdrawn(
    address indexed seller,
    uint256 indexed id,
    uint256 indexed tokenId
  );

  event LockedFundsTransferred(
    address indexed user,
    uint256 amount,
    uint256 lockedBalance
  );

  /*╔═════════════════════════════╗
    ║             END             ║
    ║            EVENTS           ║
    ╚═════════════════════════════╝*/
  /**********************************/

  /**********************************/
  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  modifier onlySeller(uint256 _id) {
    require(msg.sender == Predictions[_id].seller, "Only prediction seller");
    _;
  }

  modifier notSeller(uint256 _id) {
    require(msg.sender != Predictions[_id].seller, "Seller Unauthorized!");
    _;
  }

  modifier tipsMeetsTimeRequirements(uint256 _startTime, uint256 _endTime) {
    require(
      _isValidTiming(_startTime, _endTime),
      "Doesn't meet time requirements"
    );

    _;
  }

  modifier hasMinimumBalance(uint256 _amount) {
    require(Balances[msg.sender] >= _amount, "Not enough balance");

    _;
  }

  modifier predictionEventNotStarted(uint256 _id) {
    require(
      Predictions[_id].startTime > block.timestamp,
      "Event already started"
    );
    _;
  }

  modifier predictionEventEnded(uint256 _UID) {
    require(block.timestamp > Predictions[_UID].endTime, "Event not started");
    _;
  }

  modifier validatorCountIncomplete(uint256 _id) {
    require(
      PredictionStats[_id].validatorCount < MAX_VALIDATORS,
      "Required validator limit reached"
    );
    _;
  }

  modifier validatorCountComplete(uint256 _id) {
    require(
      PredictionStats[_id].validatorCount == MAX_VALIDATORS,
      "Required validator limit reached"
    );
    _;
  }

  modifier predictionActive(uint256 _id) {
    require(
      Predictions[_id].state == State.Active,
      "Prediction currently inactive"
    );
    _;
  }

  modifier notMined(uint256 _id) {
    require(
      PredictionStats[_id].validatorCount == 0,
      "Prediction already mined"
    );
    _;
  }

  modifier isNftOwner(uint256 _tokenId) {
    require(TokenOwner[_tokenId] == msg.sender, "Not NFT Owner");
    _;
  }

  modifier assignedToMiner(uint256 _id, uint256 _tokenId) {
    require(
      Validations[_tokenId][_id].assigned == true,
      "Not assigned to miner"
    );

    _;
  }

  /*╔═════════════════════════════╗
    ║             END             ║
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/
  /**********************************/

  // constructor
  constructor() {
    owner = payable(msg.sender);
  }

  /**********************************/
  /*╔═════════════════════════════╗
    ║    INTERNAL FUNCTIONS       ║
    ╚═════════════════════════════╝*/

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   */

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath:multiplication overflow");
    return c;
  }

  /**
   * @notice Checks if prediction data meets requirements.
   * @param _startTime Timestamp of the kickoff time of the first prediction event.
   * @param _endTime Timestamp of the proposed end of the last prediction event.
   * @return bool
   */

  function _isValidTiming(uint256 _startTime, uint256 _endTime)
    internal
    view
    returns (bool)
  {
    require(_endTime > _startTime, "End time less than start time");
    if (
      add(block.timestamp, mul(8, HOURS)) > _startTime ||
      _startTime > add(block.timestamp, mul(24, HOURS)) ||
      sub(_endTime, _startTime) > mul(24, HOURS)
    ) {
      return false;
    }

    return true;
  }

  /**
   * @notice removes all user's concluded & settled bought predictions.
   */

  function purchasedPredictionsCleanup() internal {
    if (BoughtPredictions[msg.sender].length == 0) {
      return;
    }
    for (
      uint256 index = 0;
      index < BoughtPredictions[msg.sender].length;
      index++
    ) {
      uint256 _id = BoughtPredictions[msg.sender][index];

      if (
        (Predictions[_id].winningClosingVote == ValidationStatus.Neutral) ||
        (Predictions[_id].winningClosingVote == ValidationStatus.Negative)
      ) {
        if (Purchases[msg.sender][_id].refunded == false) {
          dummyList[msg.sender].push(_id);
        }
      }
    }
    BoughtPredictions[msg.sender] = dummyList[msg.sender];
    delete dummyList[msg.sender];
  }

  /**
   * @notice Incrementally assigns a tip to a miner for validation
   * @param _tokenId Miner's NFT id.
   * @param _key purchase key (for verification).
   */

  function _assignPredictionToMiner(uint256 _tokenId, string memory _key)
    internal
    returns (uint256)
  {
    uint256 current = pointer + 1;

    //if prediction withdrawn or prediction first game starting in less than 2 hours => skip;
    if (
      miningPool[pointer] == 0 ||
      ((block.timestamp + (2 * HOURS)) > Predictions[current].startTime)
    ) {
      pointer = next(pointer);
      current = pointer + 1;
    }

    require(pointer < miningPool.length, "Mining pool currently empty");
    require(
      block.timestamp >= (Predictions[current].createdAt + (4 * HOURS)),
      "Not available for mining"
    );
    Validations[_tokenId][current].miner = msg.sender;
    Validations[_tokenId][current].assigned = true;
    PredictionStats[current].validatorCount += 1;
    OwnedValidations[msg.sender].push(
      ValidationData({id: current, tokenId: _tokenId, key: _key})
    );
    uint256 _id = current;
    if (PredictionStats[current].validatorCount == MAX_VALIDATORS) {
      delete miningPool[pointer];
      pointer += 1;
    }

    return _id;
  }

  /**
   * @notice Moves the pointer to the next item on in the mining pool.
   * @param _point Current index of the pointer.
   */

  function next(uint256 _point) internal view returns (uint256) {
    uint256 x = _point + 1;
    while (x < miningPool.length) {
      if (miningPool[x] != 0) {
        break;
      }
      x += 1;
    }
    return x;
  }

  /*╔══════════════════════════════╗
    ║  TRANSFER NFT TO CONTRACT    ║
    ╚══════════════════════════════╝*/

  function _transferNftToContract(uint256 _tokenId)
    internal
    notZeroAddress(NFT_CONTRACT_ADDRESS)
  {
    if (IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == msg.sender) {
      IERC721(NFT_CONTRACT_ADDRESS).safeTransferFrom(
        msg.sender,
        address(this),
        _tokenId
      );
      require(
        IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == address(this),
        "nft transfer failed"
      );
    } else {
      require(
        IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == address(this),
        "Doesn't own NFT"
      );
    }

    TokenOwner[_tokenId] = msg.sender;
  }

  /*╔════════════════════════════════════╗
    ║ RETURN NFT FROM CONTRACT TO OWNER  ║
    ╚════════════════════════════════════╝*/

  function _withdrawNFT(uint256 _tokenId)
    internal
    isNftOwner(_tokenId)
    notZeroAddress(TokenOwner[_tokenId])
    notZeroAddress(NFT_CONTRACT_ADDRESS)
  {
    address _nftRecipient = TokenOwner[_tokenId];
    IERC721(NFT_CONTRACT_ADDRESS).safeTransferFrom(
      address(this),
      _nftRecipient,
      _tokenId
    );
    require(
      IERC721(NFT_CONTRACT_ADDRESS).ownerOf(_tokenId) == msg.sender,
      "nft transfer failed"
    );
    TokenOwner[_tokenId] = address(0);
  }

  /**
   * @notice Adds prediction to list of currently active tips.
   * @param  _id Prediction ID.
   */

  function addToActivePool(uint256 _id) internal {
    activePool.push(_id);
    Index[_id] = activePool.length - 1;
  }

  /**
   * @notice Adds prediction to the list of tipster's recent tips.
   * @param  _id Prediction ID.
   */
  function addToRecentPredictionsList(address tipster, uint256 _id) internal {
    if (User[tipster].spot == 10) {
      User[tipster].spot = 0;
    }
    uint8 _spot = User[tipster].spot;
    User[tipster].recentTips[_spot] = _id;
    User[tipster].spot += 1;
  }

  /**
   * @notice Removes prediction from list of currently active tips.
   * @param  _id Prediction ID.
   */

  function removeFromActivePool(uint256 _id) internal {
    uint256 _index = Index[_id];
    activePool[_index] = activePool[activePool.length - 1];
    Index[activePool[_index]] = _index;
    activePool.pop();
  }

  /**
   * @notice Calculate majority opening vote.
   * @param  _id Prediction ID.
   * @return status -> majority opening consensus.
   */

  function _getWinningOpeningVote(uint256 _id)
    internal
    view
    returns (ValidationStatus status)
  {
    if (PredictionStats[_id].upvoteCount > PredictionStats[_id].downvoteCount) {
      return ValidationStatus.Positive;
    } else {
      return ValidationStatus.Negative;
    }
  }

  /**
   * @notice Calculate majority closing vote.
   * @param  _id Prediction ID.
   * @return status -> majority closing consensus (tip outcome).
   */

  function _getWinningClosingVote(uint256 _id)
    internal
    view
    returns (ValidationStatus status)
  {
    if (
      PredictionStats[_id].wonVoteCount > PredictionStats[_id].lostVoteCount
    ) {
      return ValidationStatus.Positive;
    } else {
      return ValidationStatus.Negative;
    }
  }

  /**
   * @notice Makes decision to either lock miner's staking fee or refund to wallet.
   * @param  _id Prediction ID.
   * @param  _tokenId Miner's token id.
   * @return bool -> if refunded(true), if locked(false).
   */

  function _refundMinerStakingFee(uint256 _id, uint256 _tokenId)
    internal
    returns (bool)
  {
    Vote memory _vote = Validations[_tokenId][_id];
    PredictionData memory _prediction = Predictions[_id];
    bool refund = false;
    if (
      _vote.opening == _prediction.winningOpeningVote &&
      _vote.closing == _prediction.winningClosingVote
    ) {
      Balances[_vote.miner] += minerStakingFee;
      refund = true;
    } else {
      lockFunds(_vote.miner, minerStakingFee);
    }
    return refund;
  }

  /**
   * @notice Locks user's funds for a month and extends release date by another month for each subsequent lock instance.
   * @param  _user Address of user.
   * @param  _amount Amount to be locked.
   */

  function lockFunds(address _user, uint256 _amount)
    internal
    notZeroAddress(_user)
  {
    LockedFunds[_user].amount += _amount;

    if (LockedFunds[_user].lastPushDate == 0) {
      LockedFunds[_user].releaseDate = add(
        block.timestamp,
        mul(mul(24, HOURS), 30)
      );
    } else {
      LockedFunds[_user].releaseDate += mul(mul(24, HOURS), 30);
    }
    LockedFunds[_user].lastPushDate = block.timestamp;
    LockedFunds[_user].totalInstances += 1;
  }

  /**
   * @notice Removes concluded & settled transactions from miner's validations list.
   */

  function ownedValidationsCleanup() internal {
    if (OwnedValidations[msg.sender].length == 0) {
      return;
    }
    for (
      uint256 index = 0;
      index < OwnedValidations[msg.sender].length;
      index++
    ) {
      ValidationData memory _validation = OwnedValidations[msg.sender][index];

      if (Validations[_validation.tokenId][_validation.id].settled == false) {
        dummyValidations[msg.sender].push(_validation);
      }
    }
    OwnedValidations[msg.sender] = dummyValidations[msg.sender];
    delete dummyValidations[msg.sender];
  }

  /**
   * @notice Creates new prediction, added to the mining pool.
   * @param _id generated id.
   * @param _ipfsHash ipfs hash containing the encrypted prediction data.
   * @param _key prediction data encryption key (encrypted).
   * @param _startTime expected start time of the first game in the predictions.
   * @param _endTime expected end time of the last game in the predictions.
   * @param _odd total accumulated odd.
   * @param _price selling price.
   */

  function _setupPrediction(
    uint256 _id,
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) internal tipsMeetsTimeRequirements(_startTime, _endTime) {
    Predictions[_id].seller = msg.sender;
    Predictions[_id].ipfsHash = _ipfsHash;
    Predictions[_id].key = _key;
    Predictions[_id].createdAt = block.timestamp;
    Predictions[_id].startTime = _startTime;
    Predictions[_id].endTime = _endTime;
    Predictions[_id].odd = _odd;

    if (canChargeFee(msg.sender)) {
      Predictions[_id].price = _price;
    } else {
      Predictions[_id].price = 0;
    }

    if (Predictions[_id].price == 0) {
      require(usedFreeQuota < freeTipsQuota, "Free quota used up!");
    }
  }

  /**
   * @notice Removes concluded & settled transactions from tipster's sold predictions list.
   */

  function ownedPredictionsCleanup() internal {
    if (OwnedPredictions[msg.sender].length == 0) {
      return;
    }
    for (
      uint256 index = 0;
      index < OwnedPredictions[msg.sender].length;
      index++
    ) {
      uint256 _id = OwnedPredictions[msg.sender][index];
      if (
        Predictions[_id].state == State.Withdrawn ||
        Predictions[_id].state == State.Rejected
      ) {
        continue;
      }
      if (
        (Predictions[_id].winningClosingVote == ValidationStatus.Neutral) ||
        (Predictions[_id].winningClosingVote == ValidationStatus.Positive)
      ) {
        if (Predictions[_id].withdrawnEarnings == false) {
          dummyList[msg.sender].push(_id);
        }
      }
    }
    OwnedPredictions[msg.sender] = dummyList[msg.sender];
    delete dummyList[msg.sender];
  }

  /**
   * @notice Middleware function, checks if tipster can publish a paid tip.
   * @param _tipster Address of tipster
   */

  function canChargeFee(address _tipster)
    internal
    view
    returns (bool isProfitable)
  {
    if (User[_tipster].totalPredictions < 10) {
      return false;
    }
    uint16 capitalEmployed = 10000;
    uint256 earned = 0;
    for (uint256 index = 0; index < User[_tipster].recentTips.length; index++) {
      if (
        Predictions[User[_tipster].recentTips[index]].winningClosingVote ==
        ValidationStatus.Positive
      ) {
        earned += mul(Predictions[User[_tipster].recentTips[index]].odd, 10);
      }
    }
    if (earned > capitalEmployed) {
      return true;
    }

    return false;
  }

  /*╔═════════════════════════════╗
    ║             END             ║
    ║      INTERNAL FUNCTIONS     ║
    ╚═════════════════════════════╝*/
  /**********************************/

  /**********************************/
  /*╔═════════════════════════════╗
    ║    EXTERNAL FUNCTIONS       ║
    ╚═════════════════════════════╝*/

  /**
   * @notice Set all contract's config variables .
   * @param _miningFee miner staking fee in wei (paid by prediction seller, distributed among miners).
   * @param _minerStakingFee Miner staking fee in wei.
   * @param _minerPercentage Percentage of the total_prediction_earnings each miner receives in event of winning (Value between 0 - 100)
   */

  function setVariables(
    uint256 _miningFee,
    uint256 _minerStakingFee,
    uint32 _minerPercentage
  ) external onlyOwner {
    miningFee = _miningFee;
    minerStakingFee = _minerStakingFee;
    minerPercentage = _minerPercentage;
    emit VariableUpdated(miningFee, minerStakingFee, minerPercentage);
  }

  /**
   * @notice Set Miner NFT contract address.
   * @param _NftAddress Deployed NFT contract address.
   */

  function setNftAddress(address _NftAddress)
    external
    onlyOwner
    notZeroAddress(_NftAddress)
  {
    NFT_CONTRACT_ADDRESS = _NftAddress;
  }

  /**
   * @notice Sets maximum number free tips that can exist in the active pool at any given time.
   * @param _quota amount.
   */

  function setFreeTipsQuota(uint8 _quota) external onlyOwner {
    freeTipsQuota = _quota;
  }

  /**
   * @notice Creates new prediction, added to the mining pool.
   * @param _ipfsHash ipfs hash containing the encrypted prediction data.
   * @param _key prediction data encryption key (encrypted).
   * @param _startTime expected start time of the first game in the predictions.
   * @param _endTime expected end time of the last game in the predictions.
   * @param _odd total accumulated odd
   * @param _price selling price
   */

  function createPrediction(
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external payable isOpen {
    require(_odd > 100, "Odd must be greater than 1");
    if (msg.value < miningFee) {
      require(
        Balances[msg.sender] >= sub(miningFee, msg.value),
        "Insufficient balance"
      );
      Balances[msg.sender] -= sub(miningFee, msg.value);
    } else {
      uint256 bal = sub(msg.value, miningFee);
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }

    _predictionIds.increment();
    uint256 _id = _predictionIds.current();

    _setupPrediction(_id, _ipfsHash, _key, _startTime, _endTime, _odd, _price);

    miningPool.push(_id);

    ownedPredictionsCleanup();
    OwnedPredictions[msg.sender].push(_id);

    emit PredictionCreated(msg.sender, _id, _ipfsHash, _key);
  }

  /**
   * @notice Tipster can withdraw prediction only before any miner has mined it (staking fee refunded).
   * @param _id prediction Id
   */

  function withdrawPrediction(uint256 _id)
    external
    onlySeller(_id)
    notMined(_id)
  {
    require(
      Predictions[_id].state != State.Withdrawn,
      "Prediction already withdrawn!"
    );
    Predictions[_id].state = State.Withdrawn;
    delete miningPool[_id - 1]; //delete prediction entry from mining pool
    Balances[Predictions[_id].seller] += miningFee; //Refund mining fee
    emit PredictionWithdrawn(_id, msg.sender);
  }

  /**
   * @notice Creates new prediction, added to the mining pool.
   * @param _id prediction id
   * @param _ipfsHash ipfs hash containing the encrypted prediction data.
   * @param _key prediction data encryption key (encrypted).
   * @param _startTime expected start time of the first game in the predictions.
   * @param _endTime expected end time of the last game in the predictions.
   * @param _odd total accumulated odd
   * @param _price selling price
   */

  function updatePrediction(
    uint256 _id,
    string memory _ipfsHash,
    string memory _key,
    uint256 _startTime,
    uint256 _endTime,
    uint16 _odd,
    uint256 _price
  ) external onlySeller(_id) notMined(_id) {
    _setupPrediction(_id, _ipfsHash, _key, _startTime, _endTime, _odd, _price);

    emit PredictionUpdated(msg.sender, _id, _ipfsHash, _key);
  }

  /**
   * @notice miner can place validation request and pay staking fee by sending it in the transaction
   * @param _tokenId NFT token Id
   * @param _key encrypted purchase key
   */

  function requestValidation(uint256 _tokenId, string memory _key)
    external
    payable
    isOpen
  {
    if (msg.value < minerStakingFee) {
      require(
        Balances[msg.sender] >= (minerStakingFee - msg.value),
        "Insufficient balance"
      );
      Balances[msg.sender] -= (minerStakingFee - msg.value);
    } else {
      uint256 bal = msg.value - minerStakingFee;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }

    require(miningPool.length > 0, "mining pool empty");
    ownedValidationsCleanup();
    _transferNftToContract(_tokenId);
    uint256 _id = _assignPredictionToMiner(_tokenId, _key);
    emit ValidationAssigned(msg.sender, _id, _tokenId);
  }

  /**
   * @notice miner submits opening validation decision on an assigned prediction
   * @param _id Prediction ID
   * @param _tokenId Miner's NFT token Id
   * @param _option Miner's tip validation vote
   */

  function submitOpeningVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  )
    external
    predictionEventNotStarted(_id)
    isNftOwner(_tokenId)
    assignedToMiner(_id, _tokenId)
  {
    require(_option == 1 || _option == 2, "Invalid validation option");
    require(
      Validations[_tokenId][_id].opening == ValidationStatus.Neutral,
      "Opening vote already cast"
    );
    if (_option == 1) {
      Validations[_tokenId][_id].opening = ValidationStatus.Positive;
      PredictionStats[_id].upvoteCount += 1;
    } else {
      Validations[_tokenId][_id].opening = ValidationStatus.Negative;
      PredictionStats[_id].downvoteCount += 1;
    }

    if (PredictionStats[_id].upvoteCount == SIXTY_PERCENT) {
      //prediction receives 60% positive validations
      Predictions[_id].state = State.Active;
      addToActivePool(_id);
      if (Predictions[_id].price == 0) {
        usedFreeQuota += 1;
      }
    }

    if (PredictionStats[_id].downvoteCount == SIXTY_PERCENT) {
      //prediction receives 60% negative validations
      Predictions[_id].state = State.Rejected;
      delete miningPool[_id - 1]; //delete prediction entry from mining pool
    }

    uint256 minerBonus = miningFee / MAX_VALIDATORS;
    Balances[msg.sender] += minerBonus; //miner recieves mining bonus.

    emit OpeningVoteSubmitted(_id, _tokenId, _option, Predictions[_id].state);
  }

  /**
   * @notice Users can purchase prediction by sending purchase fee in the transaction
   * @param _id Prediction ID
   * @param _key encrypted key of purchaser
   */

  function purchasePrediction(uint256 _id, string memory _key)
    external
    payable
    isOpen
    predictionEventNotStarted(_id)
    predictionActive(_id)
  {
    if (msg.value < Predictions[_id].price) {
      require(
        Balances[msg.sender] >= (Predictions[_id].price - msg.value),
        "Insufficient balance"
      );
      Balances[msg.sender] -= (Predictions[_id].price - msg.value);
    } else {
      uint256 bal = msg.value - Predictions[_id].price;
      if (bal > 0) {
        Balances[msg.sender] += bal;
      }
    }
    purchasedPredictionsCleanup();
    Purchases[msg.sender][_id].purchased = true;
    Purchases[msg.sender][_id].key = _key;
    PredictionStats[_id].buyCount += 1;
    BoughtPredictions[msg.sender].push(_id);
    emit PredictionPurchased(msg.sender, _id);
  }

  /**
   * @notice miner submits closing validation decision (outcome) on seller's prediction.
   * @param _id Prediction ID
   * @param _tokenId Miner's NFT token Id
   * @param _option Miner's prediction outcome vote
   */

  function submitClosingVote(
    uint256 _id,
    uint256 _tokenId,
    uint8 _option
  )
    external
    predictionActive(_id)
    isNftOwner(_tokenId)
    assignedToMiner(_id, _tokenId)
  {
    require(_option == 1 || _option == 2, "Invalid validation option");
    require(
      block.timestamp > Predictions[_id].endTime + (2 * HOURS),
      "Can't cast closing vote now"
    );

    require(
      Validations[_tokenId][_id].closing == ValidationStatus.Neutral,
      "Closing vote already cast"
    );

    require(
      block.timestamp < Predictions[_id].endTime + (6 * HOURS),
      "Vote window period expired"
    );

    if (_option == 1) {
      Validations[_tokenId][_id].closing = ValidationStatus.Positive;
      PredictionStats[_id].wonVoteCount += 1;
    } else {
      Validations[_tokenId][_id].closing = ValidationStatus.Negative;
      PredictionStats[_id].lostVoteCount += 1;
    }
    _withdrawNFT(_tokenId);

    emit ClosingVoteSubmitted(_id, _tokenId, _option);
  }

  /**
   * @notice In the event that a tip was rejected, all participating miners can withdraw thier NFT & staking fee.
   * @param _id Prediction ID
   * @param _tokenId Miner's NFT token Id
   */

  function withdrawMinerNftandStakingFee(uint256 _id, uint256 _tokenId)
    external
    assignedToMiner(_id, _tokenId)
    isNftOwner(_tokenId)
  {
    require(
      Predictions[_id].state == State.Rejected,
      "Prediction not rejected"
    );
    require(
      Validations[_tokenId][_id].settled == false,
      "Staking fee already refunded"
    );
    Validations[_tokenId][_id].settled = true;
    Balances[TokenOwner[_tokenId]] += minerStakingFee;
    _withdrawNFT(_tokenId);
    emit MinerNFTAndStakingFeeWithdrawn(msg.sender, _id, _tokenId);
  }

  /**
   * @notice At the end of the closing vote window period, transaction conclustion & miners settlement takes place.
   * @param _id Prediction ID
   * @param _tokenId Miner's NFT token Id
   */

  function settleMiner(uint256 _id, uint256 _tokenId) external isOpen {
    require(
      Predictions[_id].state == State.Active ||
        Predictions[_id].state == State.Concluded,
      "Not an active prediction"
    );
    require(Validations[_tokenId][_id].miner == msg.sender, "Not miner");
    require(
      Validations[_tokenId][_id].settled == false,
      "Miner already settled"
    );
    require(
      block.timestamp > Predictions[_id].endTime + (6 * HOURS),
      "Not cooled down yet"
    );
    if (Predictions[_id].state == State.Active) {
      Predictions[_id].state = State.Concluded;
      if (Predictions[_id].price == 0 && usedFreeQuota != 0) {
        usedFreeQuota -= 1;
      }
      Predictions[_id].winningOpeningVote = _getWinningOpeningVote(_id);
      Predictions[_id].winningClosingVote = _getWinningClosingVote(_id);
      if (Predictions[_id].winningClosingVote == ValidationStatus.Positive) {
        User[Predictions[_id].seller].wonCount += 1;
      } else {
        User[Predictions[_id].seller].lostCount += 1;
      }
      User[Predictions[_id].seller].totalPredictions += 1;
      addToRecentPredictionsList(Predictions[_id].seller, _id);
      removeFromActivePool(_id);
    }
    uint256 _minerEarnings = 0;
    bool _refunded = _refundMinerStakingFee(_id, _tokenId);
    if (Predictions[_id].winningClosingVote == ValidationStatus.Positive) {
      _minerEarnings =
        (Predictions[_id].price *
          PredictionStats[_id].buyCount *
          minerPercentage) /
        100;
    }

    Balances[Validations[_tokenId][_id].miner] += _minerEarnings;

    Validations[_tokenId][_id].settled = true;

    emit MinerSettled(msg.sender, _id, _tokenId, _minerEarnings, _refunded);
  }

  /**
   * @notice Tips purchase is refunded if the tips lost.
   * @param _id Prediction ID
   */

  function refundBuyer(uint256 _id) external isOpen {
    require(
      Predictions[_id].state == State.Concluded,
      "Prediction not concluded"
    );
    require(
      Purchases[msg.sender][_id].purchased == true,
      "No purchase history found"
    );
    require(Purchases[msg.sender][_id].refunded == false, "Already refunded");
    require(
      Predictions[_id].winningClosingVote == ValidationStatus.Negative,
      "Prediction won"
    );
    Balances[msg.sender] += Predictions[_id].price;
    Purchases[msg.sender][_id].refunded = true;
    emit BuyerRefunded(msg.sender, _id, Predictions[_id].price);
  }

  /**
   * @notice Tipster is settled is tips Won.
   * @param _id Prediction ID
   */

  function settleSeller(uint256 _id) external isOpen onlySeller(_id) {
    require(
      Predictions[_id].state == State.Concluded,
      "Prediction not concluded"
    );
    require(Predictions[_id].withdrawnEarnings == false, "Earnings withdrawn");

    require(
      Predictions[_id].winningClosingVote == ValidationStatus.Positive,
      "Prediction lost!"
    );

    uint256 _minerEarnings = (Predictions[_id].price *
      PredictionStats[_id].buyCount *
      minerPercentage) / 100;
    uint256 _totalMinersRewards = _minerEarnings *
      PredictionStats[_id].validatorCount;
    uint256 _sellerEarnings = (Predictions[_id].price *
      PredictionStats[_id].buyCount) - _totalMinersRewards;

    Predictions[_id].withdrawnEarnings = true;
    Balances[Predictions[_id].seller] += _sellerEarnings;
    emit SellerSettled(msg.sender, _id, _sellerEarnings);
  }

  /**
   * @notice Withdraw funds from the contract.
   * @param _amount Amount to be withdrawn.
   */

  function withdrawFunds(uint256 _amount) external isOpen {
    require(Balances[msg.sender] >= _amount, "Not enough balance");
    Balances[msg.sender] -= _amount;
    // attempt to send the funds to the recipient
    (bool success, ) = payable(msg.sender).call{value: _amount}("");
    // if it failed, update their credit balance so they can pull it later
    if (!success) {
      Balances[msg.sender] += _amount;
    }

    emit Withdrawal(msg.sender, _amount, Balances[msg.sender]);
  }

  /**
   * @notice Withdraw locked funds to contract balance.
   * @param _amount Amount to be withdrawn.
   */

  function transferLockedFunds(uint256 _amount) external isOpen {
    require(LockedFunds[msg.sender].amount >= _amount, "Not enough balance");
    require(
      block.timestamp > LockedFunds[msg.sender].releaseDate,
      "Assets still frozen"
    );
    LockedFunds[msg.sender].amount -= _amount;
    Balances[msg.sender] += _amount;

    emit LockedFundsTransferred(
      msg.sender,
      _amount,
      LockedFunds[msg.sender].amount
    );
  }

  /**
   * @notice Tipster's profile information.
   * @param _profileData ipfs hash of json data.
   * @param _key Encrypted storage key.
   */

  function addProfile(string memory _profileData, string memory _key) external {
    User[msg.sender].profile = _profileData;
    User[msg.sender].key = _key;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  receive() external payable {
    Balances[msg.sender] += msg.value;
  }

  /*╔═════════════════════════════╗
    ║             END             ║
    ║      EXTERNAL FUNCTIONS     ║
    ╚═════════════════════════════╝*/
  /**********************************/

  /**********************************
  *   Array Accessor functions
  /**********************************/

  function getMiningPoolLength() public view returns (uint256 length) {
    return miningPool.length;
  }

  function getActivePoolLength() public view returns (uint256 length) {
    return activePool.length;
  }

  function getOwnedPredictionsLength(address seller)
    public
    view
    returns (uint256 length)
  {
    return OwnedPredictions[seller].length;
  }

  function getOwnedValidationsLength(address miner)
    public
    view
    returns (uint256 length)
  {
    return OwnedValidations[miner].length;
  }

  function getBoughtPredictionsLength(address buyer)
    public
    view
    returns (uint256 length)
  {
    return BoughtPredictions[buyer].length;
  }

  function getRecentPrediction(address seller, uint8 index)
    public
    view
    returns (uint256)
  {
    return User[seller].recentTips[index];
  }
}

// contracts/Ownable.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
  address payable public owner; //The contract deployer and owner

  /** contract can be locked in case of emergencies */
  bool public locked = false;

  /** nominated address can claim ownership of contract 
    and automatically become owner */
  address payable public nominatedOwner;

  event IsLocked(bool lock_status);
  event NewOwnerNominated(address nominee);
  event OwnershipTransferred(address newOwner);

  /// @notice Only allows the `owner` to execute the function.
  modifier onlyOwner() {
    require(msg.sender == owner, "Unauthorized access");
    _;
  }

  modifier isOpen() {
    require(!locked, "Contract in locked state");

    _;
  }

  modifier notZeroAddress(address _address) {
    require(_address != address(0), "Cannot specify 0 address");
    _;
  }

  function lock() external onlyOwner {
    locked = true;
    emit IsLocked(locked);
  }

  function unlock() external onlyOwner {
    locked = false;
    emit IsLocked(locked);
  }

  /**
    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param _address Address of the new owner.
   */

  function nominateNewOwner(address _address)
    external
    onlyOwner
    notZeroAddress(_address)
  {
    require(_address != owner, "Owner address can't be nominated");
    nominatedOwner = payable(_address);
    emit NewOwnerNominated(nominatedOwner);
  }

  /**  @notice Needs to be called by `pendingOwner` to claim ownership.
   * @dev Transfers ownership of the contract to a new account (`nominatedOwner`).
   * Can only be called by the current owner.
   */

  function transferOwnership() external {
    require(nominatedOwner != address(0), "Nominated owner not set");
    require(msg.sender == nominatedOwner, "Not a nominated owner");
    owner = nominatedOwner;
    emit OwnershipTransferred(owner);
  }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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