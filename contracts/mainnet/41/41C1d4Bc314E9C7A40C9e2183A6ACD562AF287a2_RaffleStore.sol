// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;


//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//import "../../utils/introspection/IERC165.sol";

import "./IERC1155.sol";

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

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
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

contract RaffleStore is IERC721Receiver, IERC1155Receiver, VRFConsumerBase {

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
    enum NFTType {
        ERC721,
        ERC1155
    }
    struct Raffle {
        address creator;
        address nftContractAddress;
        uint256 nftId;
        uint256 ticketQuantity;
        uint256 ticketCost;
        uint256 startDate;
        uint256 duration;
        address tokenAddress;
        uint256 chargeAmount;
        RaffleStatus status;
        NFTType nftType;
        address[] tickets;
        address winner;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        keyHash = _keyHash;
        fee = _fee;
    }

    // map VRF request to raffle
    mapping(bytes32 => uint256) internal randomnessRequestToRaffle;

    mapping (address => bool) public specialNFTS;

    // params for Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;
    Raffle[] public raffles;
    ///////////////////////
    uint256 createNormalRaffleAmount = 10 ** 17;
    uint256 createSpecialRaffleAmount = 5 * 10 ** 16;

    address walletA = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletB = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletC = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);
    address walletD = address(0xf2EEf4B6711b84d11d75632d44aAbc2bF8044D69);

    uint256 rewardCreator = 960;
    uint256 rewardA = 15;
    uint256 rewardB = 10;
    uint256 rewardC = 10;
    uint256 rewardD = 5;

    mapping(address => uint256) ticketsPurchased;
    mapping(address => bool) refundedOwners;

    mapping(address => uint256) public totalTicketBalance;

    // modify the base amounts for starting a raffle vs starting a featured raffle - onlyOwner
    function modifyRaffleCreateAmount(uint256 _specialNFT, uint256 _normalNFT) public onlyOwner{
        createNormalRaffleAmount = _normalNFT;
        createSpecialRaffleAmount = _specialNFT;
    }

    // add a NFT address to the list of special NFTs
    function addSpecialNFT(address _NFTAddress) public {
        specialNFTS[_NFTAddress] = true;
    }

    // modify the distribution of percentages to the partnered collections - onlyOwner
    function modifyRewardAmount(uint256 _rewardCreator, uint256 _rewardA,uint256 _rewardB,uint256 _rewardC,uint256 _rewardD) public onlyOwner{
        rewardCreator = _rewardCreator;
        rewardA = _rewardA;
        rewardB = _rewardB;
        rewardC = _rewardC;
        rewardD = _rewardD;
    }

    // modify the reward wallet for partnered collecitons - onlyOwner
    function modifyRewardWallets(address _walletA, address _walletB, address _walletC, address _walletD) public onlyOwner{
        walletA = _walletA;
        walletB = _walletB;
        walletC = _walletC;
        walletD = _walletD;
    }

    // get the current reward percentages for each partnered wallets
    function getRewardAmounts() public view returns( uint256, uint256, uint256, uint256, uint256 ){
        return (
            rewardCreator,
            rewardA,
            rewardB,
            rewardC,
            rewardD
        );
    }

    // get the current wallets receiving percentages (partners)
    function getRewardWallets() public view returns(address, address, address, address){
        return (
            walletA,
            walletB,
            walletC,
            walletD
        );
    }

    function getTokenAddress(uint8 _raffleTokenType) internal pure returns (address) {
        if (_raffleTokenType == uint8(RaffleTokenType.POLYDOGE)) {
            return address(0x8A953CfE442c5E8855cc6c61b1293FA648BAE472);
        } else if (_raffleTokenType == uint8(RaffleTokenType.SPEPE)) {
            return address(0xfcA466F2fA8E667a517C9C6cfa99Cf985be5d9B1);
        } else {
            return address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
        }
    }




    // starting the raffle - setting the payment amount and transfering the NFT
    function createRaffle721(IERC721 _nftContract, uint256 _nftId, uint256 _ticketQuantity, uint256 _ticketCost, uint256 _startDate, uint256 _duration, uint8 _raffleTokenType, uint8 _nftType) public payable {
        uint payAmount = isSpecialNFT721(_nftContract) ? createSpecialRaffleAmount : createNormalRaffleAmount;
        require(msg.value >= payAmount, "Need to pay to create Raffle");

        // transfer the nft from the raffle creator to this contract
        address _tokenAddress = getTokenAddress(_raffleTokenType);
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            abi.encode(
                _ticketQuantity,
                _ticketCost,
                _startDate,
                _duration,
                _tokenAddress,
                payAmount,
                NFTType(_nftType)
            )
        );
    }

    function onERC721Received(address /* _operator */, address /* _from */, uint256 _tokenId, bytes memory data) public returns (bytes4) {
        (
            uint256 _ticketQuantity,
            uint256 _ticketCost,
            uint256 _startDate,
            uint256 _duration,
            address _tokenAddress,
            uint256 _payAmount,
            NFTType _nftType
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, address, uint256, NFTType));

        createRaffle(_tokenId, _ticketQuantity, _ticketCost, _startDate, _duration, _tokenAddress, _payAmount, _nftType);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function createRaffle1155(IERC1155 _nftContract, uint256 _nftId, uint256 _ticketQuantity, uint256 _ticketCost, uint256 _startDate, uint256 _duration, uint8 _raffleTokenType, uint8 _nftType) public payable {
        uint payAmount = isSpecialNFT1155(_nftContract) ? createSpecialRaffleAmount : createNormalRaffleAmount;
        require(msg.value >= payAmount, "Need to pay to create Raffle");

        // transfer the nft from the raffle creator to this contract
        address _tokenAddress = getTokenAddress(_raffleTokenType);
        _nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            1,
            abi.encode(
                _ticketQuantity,
                _ticketCost,
                _startDate,
                _duration,
                _tokenAddress,
                payAmount,
                NFTType(_nftType)
            )
        );
    }

    function onERC1155Received(address /* _operator */, address /* _from */, uint256 _tokenId, uint256 /* _value */, bytes memory data) public returns (bytes4) {
        (
            uint256 _ticketQuantity,
            uint256 _ticketCost,
            uint256 _startDate,
            uint256 _duration,
            address _tokenAddress,
            uint256 _payAmount,
            NFTType _nftType
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, address, uint256, NFTType));

        createRaffle(_tokenId, _ticketQuantity, _ticketCost, _startDate, _duration, _tokenAddress, _payAmount, _nftType);

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function createRaffle(uint256 _tokenId, uint256 _ticketQuantity, uint256 _ticketCost, uint256 _startDate, uint256 _duration, address _tokenAddress, uint256 _payAmount, NFTType _nftType) internal {
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
            _tokenAddress,
            _payAmount,
            RaffleStatus.ONGOING,
            _nftType,
            _tickets,
            _winner
        );
        // store raffle in state
        raffles.push(_raffle);

        // emit event
        emit RaffleCreated(raffles.length - 1, tx.origin);
    }

    function onERC1155BatchReceived(
        address /* _operator */,
        address /* _from */,
        uint256[] calldata /* _ids */,
        uint256[] calldata /* _values */,
        bytes calldata /* _data */
    ) external pure returns (bytes4) {
        revert("Batch transfers not supported");
    }


    // returns whether the given NFT is a 'special' NFT
    function isSpecialNFT721(IERC721 NFTaddress) view internal returns (bool) {
        return specialNFTS[address(NFTaddress)];
    }
    function isSpecialNFT1155(IERC1155 NFTaddress) view internal returns (bool) {
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

        if (_raffle.nftType == NFTType.ERC721){
            IERC721(_raffle.nftContractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _raffle.nftId,
                abi.encode()
            );
        }
        else{
            IERC1155(_raffle.nftContractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _raffle.nftId,
                1,
                abi.encode()
            );
        }

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

        if (raffles[_raffleId].tokenAddress == address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0)){
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
    function timeExpired(uint256 raffleId) public onlyOwner {
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
            if (raffles[_raffleId].nftType == NFTType.ERC721){
                IERC721(raffles[_raffleId].nftContractAddress).safeTransferFrom(
                    address(this),
                    raffles[_raffleId].creator,
                    raffles[_raffleId].nftId,
                    abi.encode()
                );
            }
            else{
               IERC1155(raffles[_raffleId].nftContractAddress).safeTransferFrom(
                    address(this),
                    raffles[_raffleId].creator,
                    raffles[_raffleId].nftId,
                    1,
                    abi.encode()
                );
            }
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

        if (raffles[_raffleId].nftType == NFTType.ERC721){
            IERC721(raffles[_raffleId].nftContractAddress).transferFrom(
                address(this),
                raffles[_raffleId].winner,
                raffles[_raffleId].nftId
            );
        }
        else{
            IERC1155(raffles[_raffleId].nftContractAddress).safeTransferFrom(
                address(this),
                raffles[_raffleId].winner,
                raffles[_raffleId].nftId,
                1,
                abi.encode()
            );
        }

        payable(walletA).transfer(raffles[_raffleId].chargeAmount);

        uint256 incomeAmount = raffles[_raffleId].ticketCost * raffles[_raffleId].tickets.length;
        totalTicketBalance[raffles[_raffleId].tokenAddress] -= incomeAmount;

        if (raffles[_raffleId].tokenAddress == address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0)) {
            payable(raffles[_raffleId].creator).transfer(incomeAmount * rewardCreator / 1000);
            payable(walletA).transfer(incomeAmount * rewardA / 1000);
            payable(walletB).transfer(incomeAmount * rewardB / 1000);
            payable(walletC).transfer(incomeAmount * rewardC / 1000);
            payable(walletD).transfer(incomeAmount * rewardD / 1000);
        }
        else {
            IERC20(raffles[_raffleId].tokenAddress).transfer(raffles[_raffleId].creator, incomeAmount * rewardCreator / 100);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletA, incomeAmount * rewardA / 1000);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletB, incomeAmount * rewardB / 1000);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletC, incomeAmount * rewardC / 1000);
            IERC20(raffles[_raffleId].tokenAddress).transfer(walletD, incomeAmount * rewardD / 1000);
        }
    }

    function withdrawExtraTokens(address currency) public onlyOwner {
        uint256 stuckBalance = getCurrentStuckBalance(currency);
        require(stuckBalance > 0, "No extra tokens to withdraw");
        require(IERC20(currency).transfer(msg.sender, stuckBalance), "Token transfer failed");
    }

    // change the status of a raffle manually for unregistered errors or situations not accounted for - onlyOwner
    function changeRaffleStatus(uint256 _raffleId, uint8 _raffleStatus) public onlyOwner {
        require(isRaffleExist(_raffleId), "Raffle doesn't exist!");

        raffles[_raffleId].status = RaffleStatus(_raffleStatus);
    }

    // get the total link in the contract
    function getLinkBalance() public view returns( uint256 ){
        return LINK.balanceOf(address(this));
    }

    // cancel a raffle and refund all ticket sales. Should only be called in emergencies when a raffle is functioning in an unexpected manner - onlyOwner
    function emergencyCancel(uint _raffleId) public onlyOwner {
        require(isRaffleExist(_raffleId), "Raffle doesn't exist!");

        Raffle storage raffle = raffles[_raffleId];

        // Transfer the NFT back to the creator
        if (raffle.nftType == NFTType.ERC721){
            IERC721(raffle.nftContractAddress).safeTransferFrom(
                address(this),
                raffle.creator,
                raffle.nftId,
                abi.encode()
            );
        }
        else{
            IERC1155(raffle.nftContractAddress).safeTransferFrom(
                address(this),
                raffle.creator,
                raffle.nftId,
                1,
                abi.encode()
            );
        }

        // Refund all ticket owners
        for (uint256 i = 0; i < raffle.tickets.length; i++) {
            address ticketOwner = raffle.tickets[i];
            ticketsPurchased[ticketOwner] += 1;
        }

        for (uint256 i = 0; i < raffle.tickets.length; i++) {
            address ticketOwner = raffle.tickets[i];
            uint256 refundAmount = ticketsPurchased[ticketOwner] * raffle.ticketCost;

            if (!refundedOwners[ticketOwner]){
                if (raffle.tokenAddress == address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0)) {
                payable(ticketOwner).transfer(refundAmount);
                }
                else {
                    IERC20(raffle.tokenAddress).transfer(ticketOwner, refundAmount);
                }
                refundedOwners[ticketOwner] = true;
            }
        }

        // Update the raffle status to CANCELLED
        raffle.status = RaffleStatus.CANCELLED;
    }

    // only for emergencies where chainLink calls do not work
    function endRaffleManual(uint256 _raffleId, uint256 _winnerIndex) public onlyOwner {
        require(uint256(raffles[_raffleId].status) == uint256(RaffleStatus.PENDING_COMPLETION), "Raffle status is not Pending Completion!");
        // raffle timer ends with no tickets purchased - there is no emit here
        if(raffles[_raffleId].tickets.length == 0) {
            raffles[_raffleId].status = RaffleStatus.CANCELLED;
            if (raffles[_raffleId].nftType == NFTType.ERC721){
                IERC721(raffles[_raffleId].nftContractAddress).safeTransferFrom(
                    address(this),
                    raffles[_raffleId].creator,
                    raffles[_raffleId].nftId,
                    abi.encode()
                );
            }
            else{
               IERC1155(raffles[_raffleId].nftContractAddress).safeTransferFrom(
                    address(this),
                    raffles[_raffleId].creator,
                    raffles[_raffleId].nftId,
                    1,
                    abi.encode()
                );
            }
        }
        else {
            chooseWinnerManual(_raffleId, _winnerIndex);
        }
    }

    function chooseWinnerManual(uint256 _raffleId, uint256 _winnerIndex) internal {
        require(_winnerIndex < raffles[_raffleId].tickets.length, "Invalid winner index");

        raffles[_raffleId].status = RaffleStatus.COMPLETE;
        raffles[_raffleId].winner = raffles[_raffleId].tickets[_winnerIndex];
        distributionFunds(_raffleId);
        emit RaffleComplete(_raffleId, raffles[_raffleId].tickets[_winnerIndex]);
    }

    event RaffleCreated(uint256 id, address creater);
    event TicketsPurchased(uint256 raffleId, address buyer, uint256 numTickets);
    event RaffleComplete(uint256 id, address winner);
}