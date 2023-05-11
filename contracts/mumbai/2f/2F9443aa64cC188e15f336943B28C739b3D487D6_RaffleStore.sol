/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//import "../../utils/introspection/IERC165.sol";
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

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
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
//import "@chainlink/contracts/src/v0.7/dev/VRFConsumerBase.sol";

//import "./vendor/SafeMathChainlink.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol

interface LinkTokenInterface {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256 remaining);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(
        address spender,
        uint256 addedValue
    ) external returns (bool success);

    function increaseApproval(
        address spender,
        uint256 subtractedValue
    ) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(
        address to,
        uint256 value
    ) external returns (bool success);

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

// File: @chainlink/contracts/src/v0.8/dev/VRFRequestIDBase.sol

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
        return
            uint256(
                keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce))
            );
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
    function makeRequestId(
        bytes32 _keyHash,
        uint256 _vRFInputSeed
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// File: @chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol

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
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal virtual;

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
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            _seed,
            address(this),
            nonces[_keyHash]
        );
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
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */ private nonces;

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
    function rawFulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) external {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}
/**
 * @title RaffleStore
 * @dev Keeps track of different raffles
 */

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}

contract RaffleStore is IERC721Receiver, VRFConsumerBase {
    enum RaffleStatus {
        ONGOING,
        PENDING_COMPLETION,
        GETTING_WINNER,
        COMPLETE
    }
    struct Raffle {
        address creator;
        address nftContractAddress;
        uint256 nftId;
        uint256 ticketQuantity;
        uint256 ticketCost;
        uint256 duration;
        string currency;
        uint256 chargeAmount;
        RaffleStatus status;
        address[] tickets;
        address winner;
        RaffleTest testValues;
    }
    struct RaffleTest {
        uint256 winnerIndex;
        uint256 ticketCount;
        uint256 randomNumber;
    }
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee,
        bytes32 _keyHash,
        IERC20 _polyDogeContractAddrss
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
        polyDogeContractAddress = _polyDogeContractAddrss;
    }
    // Contract owner address
    address public owner;
    // map VRF request to raffle
    mapping(bytes32 => uint256) internal randomnessRequestToRaffle;
    // params for Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    IERC20 internal polyDogeContractAddress;
    Raffle[] public raffles;
    ///////////////////////
    uint256 createChargeMatic = 10 ** 15;
    uint256 createChargeSpecialMatic = 5 * 10 ** 14;
    uint256 createChargePolydoge = 10 ** 15;
    uint256 createChargeSpecialPolydoge = 5 * 10 ** 14;
    string maticType = "MATIC";
    string polydogeType = "PolyDoge";
    address walletA = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    address walletB = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    address walletC = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    address walletD = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    address walletE = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    address walletF = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    uint256 rewardCreator = 94;
    uint256 rewardA = 1;
    uint256 rewardB = 1;
    uint256 rewardC = 1;
    uint256 rewardD = 1;
    uint256 rewardE = 1;
    uint256 rewardF = 1;
    // creates a new raffle
    // nftContract.approve should be called before this
    function createRaffleByMatic(
        IERC721 _nftContract,
        uint256 _nftId,
        uint256 _ticketQuantity,
        uint256 _ticketCost,
        uint256 _duration
    ) public payable {
        uint payAmount = 0;
        if(isSpecialNFT(_nftContract, _nftId)) {
            payAmount = createChargeSpecialMatic;
        }
        else {
            payAmount = createChargeMatic;
        }
        require(
            msg.value >= payAmount,
            "Need to pay to create Raffle"
        );
        // transfer the nft from the raffle creator to this contract
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            abi.encode(_ticketQuantity, _ticketCost, _duration, maticType, payAmount)
        );
    }
    function createRaffleByPolyDoge(
        IERC721 _nftContract,
        uint256 _nftId,
        uint256 _ticketQuantity,
        uint256 _ticketCost,
        uint256 _duration
    ) public {
        uint payAmount = 0;
        if(isSpecialNFT(_nftContract, _nftId)) {
            payAmount = createChargeSpecialPolydoge;
        }
        else {
            payAmount = createChargePolydoge;
        }
        polyDogeContractAddress.transferFrom(msg.sender, address(this), payAmount);
        // transfer the nft from the raffle creator to this contract
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            abi.encode(_ticketQuantity, _ticketCost, _duration, polydogeType, payAmount)
        );
    }
    function isSpecialNFT(IERC721 NFTaddress, uint256 _nftId)  internal returns (bool) {
        return false;
    }
    function isRaffleExist(uint256 _raffleId)  internal returns (bool) {
        return raffles.length > _raffleId;
    }
    function getPolyDogeAddress() view public  returns(address) {
        return  address(polyDogeContractAddress);
    }
    
    // complete raffle creation when receiving ERC721
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        (uint256 _ticketQuantity, uint256 _ticketCost, uint256 _duration, string memory _currency, uint256 _payAmount) = abi.decode(
            data,
            (uint256, uint256, uint256, string, uint256)
        );

        // init tickets
        address[] memory _tickets;
        address _winner;
        // create raffle
        Raffle memory _raffle = Raffle(
            tx.origin,
            msg.sender,
            _tokenId,
            _ticketQuantity,
            _ticketCost,
            _duration,
            _currency,
            _payAmount,
            RaffleStatus.ONGOING,
            _tickets,
            _winner,
            RaffleTest(uint256(0),
            uint256(0),
            uint256(0))

        );
        // store raffle in state
        raffles.push(_raffle);

        // emit event
        emit RaffleCreated(raffles.length - 1, tx.origin);

        // return funciton singature to confirm safe transfer
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function cancelRaffle(
        uint256 _raffleId
    ) public {
        // transfer the nft from the raffle creator to this contract
        //uint256 _raffleId = getRaffleIndex(msg.sender, address(_nftContract), _nftId);
        Raffle memory _raffle = raffles[_raffleId];
        require(
            _raffle.tickets.length == 0 && _raffle.status == RaffleStatus.ONGOING,
            "raffle was already started!"
        );
        require(
            msg.sender == _raffle.creator,
            "You are not the creator!"
        );
        require(
            isRaffleExist(_raffleId),
            "Raffle doesn't exist!"
        );
        
        IERC721(_raffle.nftContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _raffle.nftId,
            abi.encode()
        );
        raffles[_raffleId].status = RaffleStatus.PENDING_COMPLETION;
    }
    function getRaffleIndex(
        address _creator,
        address _nftContract,
        uint256 _nftId
    ) public view returns(uint256) {
        for (uint256 i=0; i<raffles.length; i++) {
            if(raffles[i].creator == _creator && raffles[i].nftContractAddress == _nftContract && raffles[i].nftId == _nftId) {
                return i;
            }
        }
        return raffles.length;
    }
    // enters a user in the draw for a given raffle
    function enterRaffleByCoin(uint256 raffleId, uint256 ticketCount) public payable {
        require(
            uint256(raffles[raffleId].status) == uint256(RaffleStatus.ONGOING),
            "Raffle no longer active"
        );
        require(
            raffles[raffleId].tickets.length + ticketCount <= raffles[raffleId].ticketQuantity,
            "Ticket is full"
        );
        require(
            msg.value >= raffles[raffleId].ticketCost * ticketCount, 
            "Ticket price not paid"
        );
        enterRaffle(raffleId, ticketCount);
    }
    function enterRaffleByToken(uint256 raffleId, uint256 ticketCount) public {
        require(
            uint256(raffles[raffleId].status) == uint256(RaffleStatus.ONGOING),
            "Raffle no longer active"
        );
        require(
            raffles[raffleId].tickets.length + ticketCount <= raffles[raffleId].ticketQuantity,
            "Ticket is full"
        );
        polyDogeContractAddress.transferFrom(msg.sender, address(this), raffles[raffleId].ticketCost * ticketCount);
        enterRaffle(raffleId, ticketCount);
    }
    function enterRaffle(uint256 raffleId, uint256 ticketCount) internal {
        for (uint256 i = 0; i < ticketCount; i++) {
            raffles[raffleId].tickets.push(msg.sender);
        }
        if (
            raffles[raffleId].tickets.length == raffles[raffleId].ticketQuantity
        ) {
            raffles[raffleId].status = RaffleStatus.PENDING_COMPLETION;
        }
    }
    function getTickets(uint256 _raffleId)
        public view returns(address[] memory)
    {
        return raffles[_raffleId].tickets;
    }
    function endRaffle(uint256 _raffleId)
        public 
    {
        require(
            uint256(raffles[_raffleId].status) == uint256(RaffleStatus.PENDING_COMPLETION),
            "Can't end raffle!"
        );
        chooseWinner(_raffleId);
    }
    function chooseWinner(uint256 _raffleId) internal {
        //Request a random number from Chainlink
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - top up to contract complete raffle"
        );

        // IRandomNumberGenerator randomGenerator = IRandomNumberGenerator(0xCEF01FeA5A5438959C1B44eCFe5216c0FE0AbA1B);
        // randomGenerator.getRandomNumber(
        //     uint256(keccak256(abi.encodePacked(_raffleId, uint256(0))))
        // );

        // uint32 randomResult = randomGenerator.viewRandomResult();
        // uint256 winnerIndex = randomResult % raffles[_raffleId].tickets.length;
        // raffles[_raffleId].status = RaffleStatus.COMPLETE;
        // raffles[_raffleId].winner = raffles[_raffleId].tickets[winnerIndex];
        // uint256 winnerIndex = 0;
        // //Raffle memory _raffle = raffles[_raffleId];
        // raffles[_raffleId].winner = raffles[_raffleId].tickets[winnerIndex];
        // distributionFunds(_raffleId);
        bytes32 requestId = requestRandomness(keyHash, fee, uint256(keccak256(abi.encodePacked(_raffleId, uint256(0)))));
        randomnessRequestToRaffle[requestId] = _raffleId;
        raffles[_raffleId].status = RaffleStatus.GETTING_WINNER;
    }
    // This function needs to use < 200k gas otherwise it will revert!
    // (award winner)
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        Raffle storage raffle = raffles[randomnessRequestToRaffle[requestId]];
        uint256 winnerIndex = randomness % raffle.tickets.length;
        raffle.winner = raffle.tickets[winnerIndex];
        raffle.status = RaffleStatus.COMPLETE;
        raffle.testValues.winnerIndex = winnerIndex;
        raffle.testValues.ticketCount = raffle.tickets.length;
        raffle.testValues.randomNumber = randomness;
        emit RaffleComplete(
            randomnessRequestToRaffle[requestId],
            raffle.tickets[winnerIndex]
        );
    }
    function distributeRaffle(uint256 _raffleId)
        public 
    {
        distributionFunds(_raffleId);
    }
    function setERC20TokenContractAddress(address _erc20Address)
        public 
    {
        polyDogeContractAddress = IERC20(_erc20Address);
    }
    
    function modifyReward(
            uint256 _rewardCreator, 
            uint256 _rewardA,
            uint256 _rewardB,
            uint256 _rewardC,
            uint256 _rewardD,
            uint256 _rewardE,
            uint256 _rewardF
        ) public {
        rewardCreator = _rewardCreator;
        rewardA = _rewardA;
        rewardB = _rewardB;
        rewardC = _rewardC;
        rewardD = _rewardD;
        rewardE = _rewardE;
        rewardF = _rewardF;
    }
    function distributionFunds(uint256 _raffleId)
        internal
    {
        IERC721(raffles[_raffleId].nftContractAddress).transferFrom(
            address(this),
            raffles[_raffleId].winner,
            raffles[_raffleId].nftId
        );
        uint256 incomeAmount = raffles[_raffleId].ticketCost * raffles[_raffleId].tickets.length;
        if(keccak256(bytes(raffles[_raffleId].currency)) == keccak256(bytes(maticType))) {
            payable(raffles[_raffleId].creator).transfer(incomeAmount * rewardCreator / 100);
            payable(walletA).transfer(incomeAmount * rewardA / 100);
            payable(walletB).transfer(incomeAmount * rewardB / 100);
            payable(walletC).transfer(incomeAmount * rewardC / 100);
            payable(walletD).transfer(incomeAmount * rewardD / 100);
            payable(walletE).transfer(incomeAmount * rewardE / 100);
            payable(walletF).transfer(incomeAmount * rewardF / 100 + raffles[_raffleId].chargeAmount);
        }
        else {
            polyDogeContractAddress.transfer(raffles[_raffleId].creator, incomeAmount * rewardCreator / 100);
            polyDogeContractAddress.transfer(walletA, incomeAmount * rewardA / 100);
            polyDogeContractAddress.transfer(walletB, incomeAmount * rewardB / 100);
            polyDogeContractAddress.transfer(walletC, incomeAmount * rewardC / 100);
            polyDogeContractAddress.transfer(walletD, incomeAmount * rewardD / 100);
            polyDogeContractAddress.transfer(walletE, incomeAmount * rewardE / 100);
            polyDogeContractAddress.transfer(walletF, incomeAmount * rewardF / 100 + raffles[_raffleId].chargeAmount);
        }
    }
    address[] _tickets;
    function createTestRaffle()
        public 
    {
        _tickets.push(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
        _tickets.push(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
        _tickets.push(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
        Raffle memory _raffle = Raffle(
            tx.origin,
            msg.sender,
            0,
            0,
            0,
            0,
            "0",
            0,
            RaffleStatus.ONGOING,
            _tickets,
            address(0),
            RaffleTest(uint256(0),
            uint256(0),
            uint256(0))

        );
        raffles.push(_raffle);
    }   
    function fulfillRandomnessTest(uint256 raffleId, uint256 randomness)
        public
    {
        Raffle storage raffle = raffles[raffleId];
        uint256 winnerIndex = randomness % raffle.tickets.length;
        raffle.winner = raffle.tickets[winnerIndex];
        raffle.status = RaffleStatus.COMPLETE;
        raffle.testValues.winnerIndex = winnerIndex;
        raffle.testValues.ticketCount = raffle.tickets.length;
        raffle.testValues.randomNumber = randomness;
    }

    event RaffleCreated(uint256 id, address creater);
    event TicketsPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event RaffleComplete(uint256 id, address winner);
}