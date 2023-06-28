/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
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

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: POC/poc.sol


pragma solidity ^0.8.19;



contract VRFv2DirectFundingConsumer is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) internal s_requests;
    uint256[] public requestIds;
    uint256 private lastRequestId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    address linkAddress = 0xe5377E463C230c3A1e97abdF25aCDAfB51E20cDb; // Address LINK - hardcoded for Mumbai (make updatable)
    address wrapperAddress = 0x756B7775c93C6Fb0ef7207f566402FE1cC87e4Ce; // address WRAPPER - hardcoded for Mumbai (make updatable)

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    function requestRandomWords() external returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].paid > 0, "Request doesn't exist. Please try again.");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }

    function getRandomWordByRequestId(uint256 _requestId) public view returns (uint256[] memory) {
        return s_requests[_requestId].randomWords;
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomWords
        )
    {
        require(s_requests[_requestId].paid > 0, "Request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function checkLinkBalance() external view onlyOwner returns (uint256) {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        return link.balanceOf(address(this));
    }
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

interface IVRFv2DirectFundingConsumer {
    function requestRandomWords() external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled);
    function getRandomWordByRequestId(uint256 _requestId) external view returns (uint256[] memory);
}


contract CustomNFT is ReentrancyGuard {
    struct NFT {
        uint256 nftNumber;
        uint256 timestamp;
        bool paidOrFree;
    }

    struct NFTInfo {
        address nftOwner;
        uint256 timestamp;
        bool paidOrFree;
    }

    struct WinnerDetails {
        uint256 randomWord;
        uint256 winningNftNumber;
        address winningWallet;
        bytes32 claimPrizeTransferHash;
        bool prizeClaimed;
    }

    address payable public raffleOrganizer;
    address internal factoryAddress;

    uint256 public NFTprice;
    uint256 public maxNFTSupply;
    uint256 public freeMintLimit;
    uint256 public freeNFTsClaimed;
    uint256 public nftsMinted;

    uint256 public businessFee = 5;
    address public businessAddress = 0x067F4523f9D623CCbad3EE7d5DfEFe138894B4a5;

    mapping(address => NFT[]) internal nftsOwned;
    mapping(uint256 => address) internal nftOwners;
    mapping(uint256 => bool) private nftExists;
    mapping(address => bool) private isUniqueOwner;
    mapping(uint256 => NFT) internal nfts;
    mapping(address => WinnerDetails) private winners;

    address[] private uniqueOwners;
    uint256[] internal nftNumbers;
    uint256 public prizeAmount;
    uint256 public drawTimeLimit;
    uint256 public requestId;
    IVRFv2DirectFundingConsumer public vrfConsumer;

    bool private randomnessRequested;

    event NFTMinted(uint nftNumbers);

    constructor(
        address payable _raffleOrganizer,
        address _factoryAddress,
        uint256 _NFTprice,
        uint256 _maxNFTSupply,
        uint256 _freeMintLimit,
        uint256 _prizeAmount,
        uint256 _drawTimeLimit
    ) {
        raffleOrganizer = _raffleOrganizer;
        factoryAddress = _factoryAddress;
        NFTprice = _NFTprice;
        maxNFTSupply = _maxNFTSupply;
        freeMintLimit = _freeMintLimit;
        freeNFTsClaimed = 0;
        nftsMinted = 0;
        prizeAmount = _prizeAmount;
        vrfConsumer = IVRFv2DirectFundingConsumer(0x9f1946fc9063995D2BbfB4CD91FE968f5ea9457e); // VRF consumer contract address
        drawTimeLimit = _drawTimeLimit; // Initialize drawTimeLimit variable
    }

    modifier onlyRaffleOrganizer() {
        require(
            msg.sender == raffleOrganizer,
            "This function is reserved for the Raffle Organizer."
        );
        _;
    }

    function mint(address to, bool paid) private {
        nftsMinted++;

        NFT memory newNft = NFT(nftsMinted, block.timestamp, paid);
        nftsOwned[to].push(newNft);
        nftOwners[newNft.nftNumber] = to;
        nftExists[newNft.nftNumber] = true;

        nfts[newNft.nftNumber] = newNft;

        nftNumbers.push(newNft.nftNumber);

        if (!isUniqueOwner[to]) {
            isUniqueOwner[to] = true;
            uniqueOwners.push(to);
        }

        if (nftsMinted >= maxNFTSupply) {
            requestRandomness();
        }

        emit NFTMinted(newNft.nftNumber);
    }

    function mintNFT(uint256 amount) public payable nonReentrant {
        
        uint256 mintAmount = msg.value;
        require(mintAmount > 0, "Amount must be greater than zero");

        uint256 percent95 = ((NFTprice * maxNFTSupply) * (100-businessFee) / 100);
	    uint256 businessFeeAmount = ((NFTprice * maxNFTSupply) * businessFee / 100);

        require(msg.value < percent95, "Price should be less than 95% of revenues");

        uint256 tokenMintAmount = mintAmount - businessFeeAmount;
        require(tokenMintAmount > 0, "Token mint amount must be greater than zero");
        require(businessFeeAmount > 0, "Business amount must be greater than zero");

        require(
            !randomnessRequested,
            "Raffle has already been drawn. Use the getWinner function to see winning ticket number."
        );
        require(
            amount <= 25,
            "You may not buy more than 25 NFTs at once"
        );
        require(
            nftsMinted + amount <= maxNFTSupply,
            "Tickets for this raffle are now sold out."
        );
        uint256 totalCost = (tokenMintAmount + businessFeeAmount);
        require(
            msg.value >= totalCost,
            "Your payment amount was too low. Please check your wallet balance and try again."
        );

        for (uint256 i = 0; i < amount; i++) {
            mint(msg.sender, true);
        }

        // Transfer user amount to user's wallet
        payable(msg.sender).transfer(tokenMintAmount);

        // Transfer business amount to business wallet
        payable(businessAddress).transfer(businessFeeAmount);
        
        /*if (msg.value > totalCost) {
            uint256 overPaymentAmount = msg.value - totalCost;
            payable(msg.sender).transfer(overPaymentAmount);
        }*/
    }

    function freeMintTo(address to) public onlyRaffleOrganizer nonReentrant {
        require(
            !randomnessRequested,
            "This raffle has now concluded."
        );
        require(
            freeNFTsClaimed < freeMintLimit,
            "Free mint limit has been reached."
        );

        freeNFTsClaimed++;

        mint(to, false);
    }

    function uintToString(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";

        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        return string(s);
    }

    function getNFTInfo(uint256 nftNumber) public view returns (string memory, string memory, string memory) {
        require(nftExists[nftNumber], "NFT does not exist");

        string memory nftOwner = _toAsciiString(nftOwners[nftNumber]);
        string memory timestamp = uintToString(nfts[nftNumber].timestamp);
        string memory paid = nfts[nftNumber].paidOrFree ? "paid" : "free";

        return (nftOwner, timestamp, paid);
    }

    function ticketsOwned(uint256 startIndex) public view returns (uint256[] memory) {
        require(nftsOwned[msg.sender].length > startIndex, "Start index is out of range.");

        uint256 count = nftsOwned[msg.sender].length - startIndex;
        if (count > 50) {
            count = 50;
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = nftsOwned[msg.sender][startIndex + i].nftNumber;
        }

        return result;
    }

    function getAllNFTOwners(uint256 page) public view returns (string memory) {
        require(page > 0, "Page number must be greater than 0");
        uint256 start = (page - 1) * 50;
        require(start < uniqueOwners.length, "Page number doesn't exist. Try a lower page number.");

        string memory ownersList = "";
        for (uint256 i = 0; i < 50; i++) {
            if (start + i >= uniqueOwners.length) {
                break;
            }
            ownersList = string(abi.encodePacked(ownersList, _toAsciiString(uniqueOwners[start + i]), ","));
        }

        return ownersList;
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function freeNFTsRemaining() public view returns (uint256) {
        if (freeNFTsClaimed >= freeMintLimit) {
            return 0;
        }
        return freeMintLimit - freeNFTsClaimed;
    }

    function NFTsRemaining() public view returns (uint256) {
        if (nftsMinted >= maxNFTSupply) {
            return 0;
        }
        return maxNFTSupply - nftsMinted;
    }

    function requestRandomness() public {
        require(block.timestamp > drawTimeLimit  || nftsMinted >= maxNFTSupply, "Raffle can't be manually drawn until after the time limit is reached");
        require(!randomnessRequested, "Randomness already requested. Use the getWinner function to view the winning ticket number.");
    
        requestId = vrfConsumer.requestRandomWords();
        randomnessRequested = true;
    }

    function checkRandomWord() public view returns (uint256[] memory) {
        return vrfConsumer.getRandomWordByRequestId(requestId);
    }

    function getWinner() public view returns (uint256) {
        uint256[] memory randomWords = checkRandomWord();
        require(randomWords.length > 0, "Random words is empty");

        uint256 winner = randomWords[0] % nftsMinted + 1;

        return winner;
    }

    function isWinner() public view returns (bool) {
        uint256 winner = getWinner();
        address winnerAddress = nftOwners[winner];
        
        return winnerAddress == msg.sender;
    }

    function claimPrize() public nonReentrant {
        require(isWinner(), "You didn't win this time.");

        WinnerDetails storage winner = winners[msg.sender];

        require(
            !winner.prizeClaimed,
            "Prize has already been successfully claimed."
        );

        uint256 prize =
            prizeAmount <= address(this).balance
                ? prizeAmount
                : address(this).balance;

        winner.randomWord = checkRandomWord()[0];
        winner.winningNftNumber = getWinner();
        winner.winningWallet = msg.sender;
        winner.claimPrizeTransferHash = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, prize)
        );
        winner.prizeClaimed = true;

        (bool success, ) = payable(msg.sender).call{value: prize}("");
        require(success, "Transfer failed.");
    }

    uint public commission;
    uint public commissionWithdrawn;
    bool public drawFinished;
    bool public prizeClaimed;
    
    function finishDraw() public {
        require(msg.sender == raffleOrganizer, "Only the raffle organizer can finish the draw.");
        require(!drawFinished, "Draw has already been finished.");
        require(prizeClaimed, "Prize has not been claimed yet.");

        drawFinished = true;
        commissionWithdrawn = 0;
    }

    function withdrawCommission() public {
        WinnerDetails storage winner = winners[msg.sender];

        require(msg.sender == raffleOrganizer, "Only the raffle organizer can withdraw the commission.");
        require(drawFinished, "Draw has not been finished yet.");
        require(winner.prizeClaimed, "Prize has not been claimed yet.");

        uint commissionAvailable = NFTprice - commissionWithdrawn;
        require(commissionAvailable > 0, "No commission available for withdrawal.");

        commissionWithdrawn += commissionAvailable;
        // Perform the commission withdrawal here
        raffleOrganizer.transfer(commissionAvailable);
    }


    function checkWinnerDetails() public view returns (WinnerDetails memory) {
        return winners[msg.sender];
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////


contract TicketsFactory {
    struct NftRaffleData {
        address raffleContractAddress;
        uint256 nftPrice;
        uint256 maxSupply;
        uint256 freeMintLimit;
        uint256 prizeAmount;
        uint256 timeLimit;
        address owner;
    }

    mapping(uint256 => NftRaffleData) public raffleDataByIndex;
    uint256 public rafflesCount = 0;

    Verification private verificationContract;

    event createCustomNFTEvent( uint256 numberOfWinners, uint256 NFTprice, uint256 maxNFTSupply, uint256 freeMintLimit, uint256 prizeAmount, uint256 drawTimeLimit, uint256 rafflesCount, uint256 maticPrice, uint256 maticAmount, uint256 overpayment, uint256 totalPrizeAmount);

    constructor(address _verificationContractAddress) {
        verificationContract = Verification(_verificationContractAddress);

        // Mainnet Chainlink Aggregator for Matic/USD
        //priceFeed = AggregatorV3Interface(0x8468b2bDCE073A157E560AA4D9CcF6dB1DB98507); // Mainnet
        priceFeed = AggregatorV3Interface(0x0bF499444525a23E7Bb61997539725cA2e928138); // Testnet mumbai

    }

    /**
     * Returns the latest price of Matic in USD.
     */
    function getMaticPriceInUSD() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    AggregatorV3Interface internal priceFeed;

    function createCustomNFT(
        uint256 numberOfWinners,
        uint256 _NFTprice,
        uint256 _maxNFTSupply,
        uint256 _freeMintLimit,
        uint256 _prizeAmount,
        uint256 _drawTimeLimit
        ) public payable {

        // Point 2 Changes - Start 
        uint256 maticPrice = getMaticPriceInUSD(); // Get the current Matic price in USD
        // Calculate the required MATIC amount based on the desired USD cost (in this case, $1)
        uint256 maticAmount = (1 ether) / maticPrice;
        require(msg.value >= maticAmount, "Insufficient MATIC sent"); // Check if enough MATIC was sent
        uint256 overpayment = msg.value - maticAmount;
        
        //require(msg.value >= 1000000 wei, "Insufficient payment, you must pay 1000000 wei to deploy a raffle.");
        //uint256 overpayment = msg.value - 1000000 wei;
        // Point 2 Changes - End 

        // Point 3 Changes - Start 
        require(numberOfWinners >= 1 && numberOfWinners <= 10, "Invalid number of winners");
        require(_prizeAmount > 0, "Invalid prize amount");
        uint256 totalPrizeAmount = numberOfWinners * _prizeAmount;
        require(msg.value >= totalPrizeAmount, "Insufficient funds sent");
        // Point 2 Changes - End
        
        if (overpayment > 0) {
            payable(msg.sender).transfer(overpayment);
        }

        require(verificationContract.isVerifiedAddress(address(this)), "The deployer you are using is cloned may not be safe. Please use the genuine deployer at rafflemint.io");

        CustomNFT newCustomNFT = new CustomNFT(
            payable(msg.sender),
            address(this),
            _NFTprice,
            _maxNFTSupply,
            _freeMintLimit,
            _prizeAmount,
            _drawTimeLimit
        );

        verificationContract.addGenuineRaffleContract(address(newCustomNFT));

        NftRaffleData memory newRaffleData = NftRaffleData({
            raffleContractAddress: address(newCustomNFT),
            nftPrice: _NFTprice,
            maxSupply: _maxNFTSupply,
            freeMintLimit: _freeMintLimit,
            prizeAmount: _prizeAmount,
            timeLimit: _drawTimeLimit,
            owner: msg.sender
        });

        raffleDataByIndex[rafflesCount] = newRaffleData;
        rafflesCount++;

        emit createCustomNFTEvent(numberOfWinners, _NFTprice, _maxNFTSupply, _freeMintLimit, _prizeAmount, _drawTimeLimit, rafflesCount, maticPrice, maticAmount, overpayment, totalPrizeAmount);
        
    }
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

contract Verification {
    address private owner;
    address private verificationAddress;
    address[] private genuineRaffleContracts;

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyVerificationAddress {
        require(msg.sender == verificationAddress, "Caller is not the verification address");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setVerificationAddress(address _verificationAddress) public onlyOwner {
        verificationAddress = _verificationAddress;
    }

    function addGenuineRaffleContract(address _contractAddress) public onlyVerificationAddress {
        genuineRaffleContracts.push(_contractAddress);
    }

    function isVerifiedAddress(address _address) public view returns (bool) {
        return _address == verificationAddress;
    }

    function isGenuineRaffleAddress(address _address) public view returns (bool) {
        for (uint i = 0; i < genuineRaffleContracts.length; i++) {
            if (genuineRaffleContracts[i] == _address) {
                return true;
            }
        }
        return false;
    }
}