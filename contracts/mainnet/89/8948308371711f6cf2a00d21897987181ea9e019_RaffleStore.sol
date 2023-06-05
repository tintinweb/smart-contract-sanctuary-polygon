/**
 *Submitted for verification at polygonscan.com on 2023-06-05
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

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;

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

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    address public owner;

    enum RaffleStatus {
        ONGOING,
        PENDING_COMPLETION,
        GETTING_WINNER,
        COMPLETE,
        CANCELLED
    }
    enum RaffleTokenType {
        MATIC,
        POLYDOGE,
        SPEPE
    }
    struct Raffle {
        address creator;
        address nftContractAddress;
        uint256 nftId;
        uint256 ticketQuantity;
        uint256 ticketCost;
        uint256 startDate;
        uint256 duration;
        RaffleTokenType tokenType;
        address tokenAddress;
        uint256 chargeAmount;
        RaffleStatus status;
        address[] tickets;
        address winner;
    }
    struct RaffleTest {
        uint256 winnerIndex;
        uint256 ticketCount;
        uint256 randomNumber;
    }
    struct RewardData {
        address rewardWallet;
        uint256 rewardAmount;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee,
        bytes32 _keyHash,
        IERC20 _polyDogeContractAddrss,
        IERC20 _sPepeContractAddrss
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
        polyDogeContractAddress = _polyDogeContractAddrss;
        sPepeContractAddress = _sPepeContractAddrss;
    }
    
    // map VRF request to raffle
    mapping(bytes32 => uint256) internal randomnessRequestToRaffle;

    mapping (address => bool) public specialNFTS;
    
    // params for Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    IERC20 internal polyDogeContractAddress;
    IERC20 internal sPepeContractAddress;
    Raffle[] public raffles;
    ///////////////////////
    uint256 createNormalRaffleAmount = 10 ** 17;
    uint256 createSpecialRaffleAmount = 5 * 10 ** 16;
    address walletA = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletB = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletC = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletD = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletE = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletF = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address managerAddress = address(0x5a755DB0F90A54336A7e770A1094e618d8B9Bf7B);
    uint256 rewardCreator = 94;
    uint256 rewardA = 1;
    uint256 rewardB = 1;
    uint256 rewardC = 1;
    uint256 rewardD = 1;
    uint256 rewardE = 1;
    uint256 rewardF = 1;
    mapping(address => uint256) public totalTicketBalance;

    // creates a new raffle
    // nftContract.approve should be called before this

    // modify the base amounts for starting a raffle vs starting a featured raffle - onlyOwner
    function modifyRaffleCreateAmount(uint256 _specialNFT, uint256 _normalNFT) public onlyOwner{
        require(msg.sender == managerAddress, "You are not manger!");
        createNormalRaffleAmount = _normalNFT;
        createSpecialRaffleAmount = _specialNFT;
    }

    // add a NFT address to the list of special NFTs
    function addSpecialNFT(address _NFTAddress) public {
        specialNFTS[_NFTAddress] = true;
    }

    // modify the distribution of percentages to the partnered collections - onlyOwner
    function modifyRewardAmount(uint256 _rewardCreator, uint256 _rewardA,uint256 _rewardB,uint256 _rewardC,uint256 _rewardD,uint256 _rewardE,uint256 _rewardF) public onlyOwner{
        require(msg.sender == managerAddress, "You are not manger!");
        rewardCreator = _rewardCreator;
        rewardA = _rewardA;
        rewardB = _rewardB;
        rewardC = _rewardC;
        rewardD = _rewardD;
        rewardE = _rewardE;
        rewardF = _rewardF;
    }

    // modify the reward wallet for partnered collecitons - onlyOwner
    function modifyRewardWallets(address _walletA, address _walletB, address _walletC, address _walletD, address _walletE, address _walletF) public onlyOwner{
        require(msg.sender == managerAddress, "You are not manger!");
        walletA = _walletA;
        walletB = _walletB;
        walletC = _walletC;
        walletD = _walletD;
        walletE = _walletE;
        walletF = _walletF;
    }

    // get the current reward percentages for each partnered wallets
    function getRewardAmounts() public view returns( uint256, uint256, uint256, uint256, uint256, uint256, uint256 ){
        return (
            rewardCreator,
            rewardA,
            rewardB,
            rewardC,
            rewardD,
            rewardE,
            rewardF
        );
    }

    // get the current wallets receiving percentages (partners)
    function getRewardWallets() public view returns(address, address, address, address, address, address){
        return (
            walletA,
            walletB,
            walletC,
            walletD,
            walletE,
            walletF
        );
    }




    // starting the raffle - setting the payment amount and transfering the NFT
    function createRaffle(IERC721 _nftContract, uint256 _nftId, uint256 _ticketQuantity, uint256 _ticketCost, uint256 _startDate, uint256 _duration, uint8 _raffleTokenType) public payable {
        uint payAmount = 0;
        if(isSpecialNFT(_nftContract)) {
            payAmount = createSpecialRaffleAmount;
        }
        else {
            payAmount = createNormalRaffleAmount;
        }
        require(msg.value >= payAmount, "Need to pay to create Raffle");
        // transfer the nft from the raffle creator to this contract
        address _tokenAddress;
        if (_raffleTokenType == uint8(RaffleTokenType.POLYDOGE)){
            _tokenAddress = address(0x8A953CfE442c5E8855cc6c61b1293FA648BAE472);
        }
        else if (_raffleTokenType == uint8(RaffleTokenType.SPEPE)){
            _tokenAddress = address(0xfcA466F2fA8E667a517C9C6cfa99Cf985be5d9B1);
        }
        else {
            _tokenAddress = address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
        }
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            abi.encode(_ticketQuantity, _ticketCost, _startDate, _duration, RaffleTokenType(_raffleTokenType), _tokenAddress, payAmount)
        );
    }

    // triggered after transfer of NFT was successful
    function onERC721Received(address /* _operator */, address /* _from */, uint256 _tokenId, bytes memory data) public returns (bytes4) {
        (uint256 _ticketQuantity, uint256 _ticketCost, uint256 _startDate, uint256 _duration,  RaffleTokenType _tokenType, address _tokenAddress, uint256 _payAmount) = abi.decode(data, (uint256, uint256, uint256, uint256, RaffleTokenType, address, uint256));

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
            _startDate,
            _duration,
            _tokenType,
            _tokenAddress,
            _payAmount,
            RaffleStatus.ONGOING,
            _tickets,
            _winner
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

    // returns whether the given NFT is a 'special' NFT
    function isSpecialNFT(IERC721 NFTaddress) view internal returns (bool) {
        return specialNFTS[address(NFTaddress)];
    }

    // get all raffles
    function getAllRaffles() public view returns (Raffle[] memory) {
        return raffles;
    }

    // get raffle ID using a specific NFT id and the raffle owner
    function getRaffleIndex(address _creator, address _nftContract, uint256 _nftId) public view returns(uint256) {
        uint256 _raffleId = raffles.length;
        for (uint256 i=0; i<raffles.length; i++) {
            if(raffles[i].creator == _creator && raffles[i].nftContractAddress == _nftContract && raffles[i].nftId == _nftId) {
                _raffleId = i;
            }
        }
        return _raffleId;
    }
    
    // cancels the given raffle - only callable if there have been no tickets purchased
    function cancelRaffle(uint256 _raffleId) public {
        Raffle memory _raffle = raffles[_raffleId];
        require(isRaffleExist(_raffleId), "Raffle doesn't exist!");
        require(_raffle.tickets.length == 0 && _raffle.status == RaffleStatus.ONGOING, "a ticket has already been purchased or the raffle has already started!");
        require(msg.sender == _raffle.creator, "You are not the creator!");
        
        IERC721(_raffle.nftContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _raffle.nftId,
            abi.encode()
        );
        raffles[_raffleId].status = RaffleStatus.CANCELLED;
    }

    // returns whether the raffle exists
    function isRaffleExist(uint256 _raffleId) view internal returns (bool) {
        return raffles.length > _raffleId;
    }



    // enter raffle allows users to purchase a ticket - checks that the tickets being purchased are the correct currency and correct amount is being sent
    function purchaseTickets(uint256 _raffleId, uint256 ticketCount) public payable {
        require(isRaffleExist(_raffleId), "Raffle doesn't exist!");
        require(uint256(raffles[_raffleId].status) == uint256(RaffleStatus.ONGOING), "Raffle no longer active");
        require(raffles[_raffleId].tickets.length + ticketCount <= raffles[_raffleId].ticketQuantity, "Ticket is full");

        if (raffles[_raffleId].tokenType == RaffleTokenType.MATIC){
            require(msg.value >= raffles[_raffleId].ticketCost * ticketCount, "Ticket price not paid");
        }
        else{
            require(IERC20(raffles[_raffleId].tokenAddress).transferFrom(msg.sender, address(this), raffles[_raffleId].ticketCost * ticketCount), "Token transfer failed");
        }

        totalTicketBalance[raffles[_raffleId].tokenAddress] += raffles[_raffleId].ticketCost * ticketCount;
        enterRaffle(_raffleId, ticketCount);
    }


    // stores the purchases of raffle tickets and handles sold out cases
    function enterRaffle(uint256 raffleId, uint256 ticketCount) internal {
        for (uint256 i = 0; i < ticketCount; i++) {
            raffles[raffleId].tickets.push(msg.sender);
        }
        if (raffles[raffleId].tickets.length == raffles[raffleId].ticketQuantity) {
            raffles[raffleId].status = RaffleStatus.PENDING_COMPLETION;
            endRaffle(raffleId);
        }
    }

    // get tickets purchased
    function getTickets(uint256 _raffleId) public view returns(address[] memory){
        return raffles[_raffleId].tickets;
    }

    // gets the total purchase volume of tickets that have not been distributed
    function getCurrentBalance(address currencyAddress) public view returns (uint256) {
        return totalTicketBalance[currencyAddress];
    }

    // gets the current amount of 'stuck' tokens for a given currency
    function getCurrentStuckBalance(address currencyAddress) public view returns (uint256) {
        uint256 totalBalance = IERC20(currencyAddress).balanceOf(address(this)); 
        uint256 stuckBalance = totalBalance - totalTicketBalance[currencyAddress];

        return stuckBalance;
    }



    // called when time expires on the raffle - onlyOwner
    function timeExpired(uint256 raffleId) public onlyOwner{
        require(msg.sender == managerAddress, "You are not manger!");
        require(uint256(raffles[raffleId].status) == uint256(RaffleStatus.ONGOING), "Raffle status is not Ongoing");
        raffles[raffleId].status = RaffleStatus.PENDING_COMPLETION;
        endRaffle(raffleId);
    }

    // called to end the raffle - either through time expired or total tickets being purchased
    function endRaffle(uint256 _raffleId) public {
        require(uint256(raffles[_raffleId].status) == uint256(RaffleStatus.PENDING_COMPLETION), "Raffle status is not Pending Completion!");
        // raffle timer ends with no tickets purchased - there is no emit here
        if(raffles[_raffleId].tickets.length == 0) {
            raffles[_raffleId].status = RaffleStatus.CANCELLED;
            IERC721(raffles[_raffleId].nftContractAddress).safeTransferFrom(
                address(this),
                raffles[_raffleId].creator,
                raffles[_raffleId].nftId,
                abi.encode()
            );
        }
        else {
            chooseWinner(_raffleId);
        }
    }

    // calls Chainlink to choose a random winning entry - what happens if link is not enough? Can we just recall this whenever we want?
    function chooseWinner(uint256 _raffleId) internal {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - top up to contract complete raffle");

        bytes32 requestId = requestRandomness(keyHash, fee, uint256(keccak256(abi.encodePacked(_raffleId, uint256(0)))));
        randomnessRequestToRaffle[requestId] = _raffleId;
        raffles[_raffleId].status = RaffleStatus.GETTING_WINNER;
    }

    // once a random entry is selected - distribute the funds to partners and raffle creator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        Raffle storage raffle = raffles[randomnessRequestToRaffle[requestId]];
        uint256 winnerIndex = randomness % raffle.tickets.length;
        raffle.winner = raffle.tickets[winnerIndex];
        raffle.status = RaffleStatus.COMPLETE;
        distributionFunds(randomnessRequestToRaffle[requestId]);
        emit RaffleComplete(randomnessRequestToRaffle[requestId], raffle.tickets[winnerIndex]);
    }
    
    // handles distribution of funds and transfer of NFT to winning wallet
    function distributionFunds(uint256 _raffleId) internal {
        IERC721(raffles[_raffleId].nftContractAddress).transferFrom(
            address(this),
            raffles[_raffleId].winner,
            raffles[_raffleId].nftId
        );
        payable(walletF).transfer(raffles[_raffleId].chargeAmount);

        uint256 incomeAmount = raffles[_raffleId].ticketCost * raffles[_raffleId].tickets.length;
        totalTicketBalance[raffles[_raffleId].tokenAddress] -= incomeAmount;

        if (raffles[_raffleId].tokenType == RaffleTokenType.MATIC) {
            payable(raffles[_raffleId].creator).transfer(incomeAmount * rewardCreator / 100);
            payable(walletA).transfer(incomeAmount * rewardA / 100);
            payable(walletB).transfer(incomeAmount * rewardB / 100);
            payable(walletC).transfer(incomeAmount * rewardC / 100);
            payable(walletD).transfer(incomeAmount * rewardD / 100);
            payable(walletE).transfer(incomeAmount * rewardE / 100);
            payable(walletF).transfer(incomeAmount * rewardF / 100);
        }
        else {
            IERC20(raffles[_raffleId].tokenAddress).transfer(raffles[_raffleId].creator, incomeAmount * rewardCreator / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletA, incomeAmount * rewardA / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletB, incomeAmount * rewardB / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletC, incomeAmount * rewardC / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletD, incomeAmount * rewardD / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletE, incomeAmount * rewardE / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletF, incomeAmount * rewardF / 100);
        }
    }

    function withdrawExtraTokens(address currency) public onlyOwner {
        uint256 stuckBalance = getCurrentStuckBalance(currency);
        require(stuckBalance > 0, "No extra tokens to withdraw");
        require(IERC20(currency).transfer(msg.sender, stuckBalance), "Token transfer failed");
    }

    event RaffleCreated(uint256 id, address creater);
    event TicketsPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event RaffleComplete(uint256 id, address winner);
}