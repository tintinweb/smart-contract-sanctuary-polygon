/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: UNLICENSED

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

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol

pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol

pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol

pragma solidity ^0.8.0;

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.8.7;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external;
}

// File: contracts/interfaces/ILendingPool.sol

pragma solidity 0.8.7;

interface ILendingPool {
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// File: contracts/interfaces/IAaveIncentivesController.sol

pragma solidity 0.8.7;

interface IAaveIncentivesController {
  function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);
  function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
  function getUserUnclaimedRewards(address user) external view returns (uint256);
}

// File: contracts/interfaces/ICurve.sol

pragma solidity 0.8.7;

interface ICurve {
    function curve (uint256 currentTime, uint256 exponent, uint256 minimumPercentage, uint256 latestOpeningTime) external returns (uint256);
}

// File: contracts/interfaces/IVikings.sol

pragma solidity 0.8.7;

interface IVikings {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isVikingLocked(uint256 vikingId) external view returns (bool vikingStatus);
    function mintByType(address _owner, uint256 _type) external;
    function lockToken(uint256 tokenId, bool status) external;
    function tokenStrength(uint256 tokenId) external view returns (uint256 strength);
}

// File: contracts/NineWorldsMulti.sol

pragma solidity 0.8.7;


contract NineWorldsMulti is Ownable, VRFConsumerBase {
    using Counters for Counters.Counter;
    
    enum Status {
        Join,
        Stake,
        Claim
    }
    
    struct StakeData {
        uint256 minPrice;
        uint256 minStakeAmount;
        uint256 stakeToken;
        uint256 boatInterest;
    }

    struct CurveData {
        uint256 exponent;
        uint256 minimumPercentage;
        uint256 stakeStartTime;
        uint256 latestOpeningTime;
    }
    
    struct Boat {
        Status status;
        uint256 joinDeadline;
        uint256 minParticipants;
        uint256 currentParticipants;
        uint256 winnerIndex;
        uint256 randomNumber;
        uint256 actualOpeningTime;
        uint256 totalStrength;
        uint256 randomValue;
        StakeData stakeData;
        CurveData curveData;
    }

    uint256 constant public DIV_FACTOR = 100000;
    uint256 constant public PID = 1;
    uint256 constant public MAX_LOCK_VIKINGS = 5;

    uint256 public feePercentage = 50000;//50 percentage 
    uint256 public penaltyFactor = 10000;//10 percentage of penalty
    uint256 public strengthFactor = 10000; //10 percentage of strengthFactor
    uint256 public mintType = 6;
    address public feeReceiver;

    mapping (uint256 => Boat) public boats;
    mapping(address => mapping(uint256 => uint256)) public userStakesAmStake;
    mapping(address => mapping(uint256 => uint256)) public userStakesToken;
    mapping(uint256 => address[]) public boatParticipants;
    mapping(uint256 => mapping(address => uint256[])) public vikingsLocked;

    Counters.Counter public boatsNumber;
    
    ILendingPool public lendingPool;
    IAaveIncentivesController public claimContract;
    IERC20 public stakeToken;
    IERC20 public amStakeToken;
    IVikings public vikingsContract;
    ICurve public curveContract;

    bytes32 internal keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 internal feeLink = 1e14; // 0.0001 LINK POLYGON MATIC

    uint256 private totalStakeAmount;
    uint256 private maticBalance;

    event UserClaim(address user, uint256 userStake, uint256 userWithdraw,uint256 userPercentage);
    event UserParticipation(address user, uint256 boatId, uint256 amount, uint256 investAmount);
    event Withdraw(uint256 boatId, uint256 stakeTotal, uint256 investAmount, uint256 fee, uint256 actualOpeningTime, uint256 latestOpeningTime);
    event UserExit(address user, uint256 userStake);
    event ExtendedJoinDeadline(uint256 boatId, uint256 joinDeadline);
    event RequestValues(bytes32 requestId);
    event RandomnessEvent(bytes32 requestId);
    
    constructor (ILendingPool _lendingPool, IERC20 _stakeToken, IAaveIncentivesController _claimContract, IERC20 _amStakeToken, address _feeReceiver, ICurve _curve, IVikings _vikingsContract)
    VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1) {
        lendingPool = _lendingPool;
        stakeToken = _stakeToken;
        claimContract = _claimContract;
        amStakeToken = _amStakeToken;
        feeReceiver = _feeReceiver;
        curveContract = _curve;
        vikingsContract = _vikingsContract;
        stakeToken.approve(address(_lendingPool), type(uint256).max);
    }

    function setPenaltyFactor(uint256 _penaltyFactor) external onlyOwner {
        penaltyFactor = _penaltyFactor;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    function setStrengthFactor(uint256 _strengthFactor) external onlyOwner {
        strengthFactor = _strengthFactor;
    }

    function setMintType(uint256 _mintType) external onlyOwner {
        mintType = _mintType;
    }

    function claimRewards(address[] memory _claimAssets, address _to) external onlyOwner {
        claimContract.claimRewards(_claimAssets, type(uint256).max, _to);
    }

    function goToNextState(uint256[] memory _boatIds) external onlyOwner {
        for (uint256 i = 0; i < _boatIds.length; i++) {
            require(_boatIds[i] <= boatsNumber.current(), "NineWorldsMulti: The boat id does not exist");
            require(block.timestamp >= boats[_boatIds[i]].joinDeadline, "NineWorldsMulti: The join deadline is not finished");
            if (boats[_boatIds[i]].status == Status.Join) {
                if(boats[_boatIds[i]].stakeData.stakeToken >= boats[_boatIds[i]].stakeData.minStakeAmount && boats[_boatIds[i]].currentParticipants >= boats[_boatIds[i]].minParticipants) {
                    boats[_boatIds[i]].status = Status(uint256(boats[_boatIds[i]].status) + 1);
                    boats[_boatIds[i]].curveData.stakeStartTime = block.timestamp;
                } else {
                    boats[_boatIds[i]].joinDeadline = block.timestamp + 1 days;
                    emit ExtendedJoinDeadline(_boatIds[i],  boats[_boatIds[i]].joinDeadline);
                }
            }
        }
    }

    function addBoat(uint256 _minPrice, uint256 _minParticipants, uint256 _joinDeadline, uint256 _latestOpeningTime, uint256 _minStakeAmount, uint256 _exponent, uint256 _minimumPercentage) external onlyOwner {
        require(_minPrice > 0, "NineWorldsMulti: Minimun price is wrong, not enough price");
        require(_minParticipants > 0, "NineWorldsMulti: Minimun participants are wrong, not enough");
        uint256 newBoatId = boatsNumber.current();
        boats[newBoatId].status = Status.Join;
        boats[newBoatId].joinDeadline = block.timestamp + _joinDeadline;
        boats[newBoatId].stakeData.minPrice = _minPrice;
        boats[newBoatId].stakeData.minStakeAmount = _minStakeAmount;
        boats[newBoatId].minParticipants = _minParticipants;
        boats[newBoatId].curveData.latestOpeningTime = _latestOpeningTime;
        boats[newBoatId].curveData.exponent = _exponent;
        boats[newBoatId].curveData.minimumPercentage = _minimumPercentage;
        boatsNumber.increment();
    }

    function checkBoats() external onlyOwner {
        for (uint256 i = 0; i < boatsNumber.current(); i++) {
            if(boats[i].status == Status.Stake) {
                uint256 result = curveContract.curve((block.timestamp - boats[i].curveData.stakeStartTime), boats[i].curveData.exponent, boats[i].curveData.minimumPercentage, boats[i].curveData.latestOpeningTime);
                uint randomNumber = uint(keccak256(abi.encode(boats[i].randomNumber, boats[i].curveData.stakeStartTime, boats[i].stakeData.stakeToken))) % 10000;
                if (randomNumber < result) {
                    _endStakeAndWithdraw(i);
                }
            }
        }
    }

    function claimAssets(address _asset, address _to, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(_asset, _to, _amount);
    }

    function participate(uint256 _boatId, uint256[] memory vikingIds, uint256 _amount) external {
        require(_boatId <= boatsNumber.current(), "NineWorldsMulti: The boat id does not exist");
        require(boats[_boatId].status == Status.Join && boats[_boatId].joinDeadline >= block.timestamp, "NineWorldsMulti: Boat participation is not open");
        require(userStakesToken[_msgSender()][_boatId] == 0, "NineWorldsMulti: The user is already on the boat");
        require(_amount > 0 && _amount >= boats[_boatId].stakeData.minPrice, "NineWorldsMulti: The amount to participate is wrong");
        require(stakeToken.balanceOf(_msgSender()) >= boats[_boatId].stakeData.minPrice && stakeToken.balanceOf(_msgSender()) >= _amount, "NineWorldsMulti: User balance is not enough");
        require(MAX_LOCK_VIKINGS >= vikingIds.length, "NineWorldsMulti: Max number of vikings locked");
        uint256 nftStrength = 0;
        for(uint256 i = 0; i < vikingIds.length; i++) {
            require(vikingsContract.ownerOf(vikingIds[i]) == _msgSender(), "NineWorldsMulti: The user does not own the viking id");
            require(!vikingsContract.isVikingLocked(vikingIds[i]), "NineWorldsMulti: The viking is lock");
            uint256 tokenStrength = vikingsContract.tokenStrength(vikingIds[i]);
            require(tokenStrength > 0, "NineWorldsMulti: Vikings id has an invalid strength");
            vikingsContract.lockToken(vikingIds[i], true);
            nftStrength = nftStrength + getStrengthRate(vikingsContract.tokenStrength(vikingIds[i]));
        }
        vikingsLocked[_boatId][_msgSender()] = vikingIds;
        boats[_boatId].currentParticipants = boats[_boatId].currentParticipants + 1;
        boatParticipants[_boatId].push(_msgSender());
        userStakesToken[_msgSender()][_boatId] = _amount;
        boats[_boatId].totalStrength = boats[_boatId].totalStrength + _amount + nftStrength;
        boats[_boatId].stakeData.stakeToken = boats[_boatId].stakeData.stakeToken + _amount;
        totalStakeAmount =  totalStakeAmount + _amount;
        TransferHelper.safeTransferFrom(address(stakeToken), _msgSender(), address(this), _amount);
        lendingPool.deposit(address(stakeToken), _amount, address(this), 0);
        emit UserParticipation(_msgSender(), _boatId, userStakesToken[_msgSender()][_boatId], userStakesAmStake[_msgSender()][_boatId]);
    }
    
    function claimBoat(uint256 _boatId) external {
        require(boats[_boatId].stakeData.stakeToken > 0, "NineWorldsMulti: Invalid claim, stake total insufficient");
        require(boats[_boatId].status == Status.Claim, "NineWorldsMulti: The participation is still active");
        require(userStakesToken[_msgSender()][_boatId] > 0, "NineWorldsMulti: The user has not right to claim");
        uint256 userStake = userStakesToken[_msgSender()][_boatId];
        userStakesToken[_msgSender()][_boatId] = 0;
        uint256 userPercentage = (userStake * DIV_FACTOR) / boats[_boatId].stakeData.stakeToken;
        uint256 userInterest = (boats[_boatId].stakeData.boatInterest * userPercentage) / DIV_FACTOR;
        if(boatParticipants[_boatId][boats[_boatId].winnerIndex] == _msgSender()) {
            vikingsContract.mintByType(_msgSender(), mintType);
        }
        userStakesAmStake[_msgSender()][_boatId] = userStake + userInterest;
        for(uint256 i = 0; i < vikingsLocked[_boatId][_msgSender()].length; i++) {
            vikingsContract.lockToken(vikingsLocked[_boatId][_msgSender()][i], false);
        }
        TransferHelper.safeTransfer(address(stakeToken), _msgSender(), userStakesAmStake[_msgSender()][_boatId]);
        emit UserClaim(_msgSender(), userStake, userStakesAmStake[_msgSender()][_boatId], userPercentage);
    }

    function userExitBoat(uint256 _boatId) external {
        require(_boatId <= boatsNumber.current(), "NineWorldsMulti: The boat id does not exist");
        require(boats[_boatId].status == Status.Join, "NineWorldsMulti: The status is not Join, exit option is not available");
        require(userStakesToken[_msgSender()][_boatId] > 0, "NineWorldsMulti: The user has not right to claim");
        uint256 userStake = userStakesToken[_msgSender()][_boatId];
        boats[_boatId].stakeData.stakeToken = boats[_boatId].stakeData.stakeToken - userStake;
        totalStakeAmount =  totalStakeAmount - userStake;
        userStakesToken[_msgSender()][_boatId] = 0;
        userStakesAmStake[_msgSender()][_boatId] = 0;
        _deleteFromArray(boatParticipants[_boatId], _msgSender());
        boats[_boatId].currentParticipants--;
        uint256 nftStrength = 0;
        for(uint256 i = 0; i < vikingsLocked[_boatId][_msgSender()].length; i++) {
            vikingsContract.lockToken(vikingsLocked[_boatId][_msgSender()][i], false);
            nftStrength = getStrengthRate(vikingsContract.tokenStrength(vikingsLocked[_boatId][_msgSender()][i]));
        }
        boats[_boatId].totalStrength = boats[_boatId].totalStrength - userStake - nftStrength;
        lendingPool.withdraw(address(stakeToken), userStake, _msgSender());
        emit UserExit(_msgSender(), userStake);
    }

    function requestRandomValues() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= feeLink, "NineWorldsMulti: Not enough LINK, fill contract with LINK");
        requestId = requestRandomness(keyHash, feeLink);
        emit RequestValues(requestId);
    }

    function getStrengthRate(uint256 _value) public view returns (uint256) {
        return ((_value * 1e6) * strengthFactor) / DIV_FACTOR;
    }

    function getUserBoats(address _userAddress) external view returns (uint256[] memory) {
        uint256 currentBoats = boatsNumber.current() - 1;
        uint256[] memory result = new uint256[](currentBoats);
        for (uint256 i = 0; i < currentBoats; i++) {
            result[i] = userStakesToken[_userAddress][i];
        }
        return result;
    }

    function _endStakeAndWithdraw(uint256 _boatId) internal {
        require(_boatId <= boatsNumber.current(), "NineWorldsMulti: The boat id does not exist");
        require(boats[_boatId].status == Status.Stake, "NineWorldsMulti: Boat is not in STAKE state");
        boats[_boatId].status = Status.Claim;
        uint256 stakeTokenAmount = boats[_boatId].stakeData.stakeToken;
        boats[_boatId].actualOpeningTime = block.timestamp;
        boats[_boatId].randomValue = _randomBoatIndex(_boatId);
        boats[_boatId].winnerIndex = _checkWinner(_boatId);
        uint256 aTokenBalance = amStakeToken.balanceOf(address(this));
        uint256 currentBenefits = aTokenBalance - totalStakeAmount;
        uint256 boatBenefit = (currentBenefits * stakeTokenAmount) / totalStakeAmount;
        uint256 fee = boatBenefit * feePercentage / DIV_FACTOR;
        boats[_boatId].stakeData.boatInterest = boatBenefit - fee;
        totalStakeAmount = totalStakeAmount - stakeTokenAmount;
        uint256 boatWithdraw = stakeTokenAmount + boats[_boatId].stakeData.boatInterest;
        lendingPool.withdraw(address(stakeToken), fee, feeReceiver);
        lendingPool.withdraw(address(stakeToken), boatWithdraw, address(this));
        emit Withdraw(_boatId, stakeTokenAmount, boatBenefit, fee, boats[_boatId].actualOpeningTime, boats[_boatId].curveData.latestOpeningTime);
    }

    function _randomBoatIndex(uint256 _boatId) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(boats[_boatId].stakeData.stakeToken, boats[_boatId].randomNumber))) % boats[_boatId].totalStrength;
    }

    function _checkWinner(uint256 _boatId) internal view returns (uint) {
        uint result = 0;
        uint currentStrength = 0;
        for(uint i = 0; i < boatParticipants[_boatId].length; i++) {
            address user = boatParticipants[_boatId][i];
            uint256 nftStrength = 0;
            for(uint256 j = 0; j < vikingsLocked[_boatId][user].length; j++) {
                nftStrength = nftStrength + getStrengthRate(vikingsContract.tokenStrength(vikingsLocked[_boatId][user][j]));
            }
            currentStrength = currentStrength + userStakesToken[user][_boatId] + nftStrength;
            if (currentStrength >= boats[_boatId].randomValue) {
                result = i;
                break;
            }
        }
        return result;
    }

    function _expandRandomAux(uint256 randomValue, uint256 n) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
    }

    function _deleteFromArray(address[] storage _array, address _userAddress) internal {
        uint index = 0;
        bool isFound = false;
        uint256 arrayLength = _array.length;
        for(uint i = 0; i < arrayLength; i++) {
            if(_array[i] == _userAddress) {
                index = i;
                isFound = true;
                break;
            }
        }
        if(isFound) {
            _array[index] = _array[arrayLength - 1];
            _array.pop();
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256[] memory expandedValues = _expandRandomAux(randomness, boatsNumber.current());
        for (uint256 i = 0; i < expandedValues.length; i++) {
            boats[i].randomNumber = expandedValues[i];
        }
        emit RandomnessEvent(requestId);
    }
}