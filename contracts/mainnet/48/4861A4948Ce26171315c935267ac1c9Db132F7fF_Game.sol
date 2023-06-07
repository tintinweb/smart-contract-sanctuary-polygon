/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

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
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for ////important
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
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _manager;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _manager = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            _owner == _msgSender() || _manager == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function manager() private view returns (address) {
        return _manager;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        returns (uint16, uint32, bytes32[] memory);

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    function createSubscription() external returns (uint64 subId);

    function getSubscription(
        uint64 subId
    )
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    function requestSubscriptionOwnerTransfer(
        uint64 subId,
        address newOwner
    ) external;

    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    function addConsumer(uint64 subId, address consumer) external;

    function removeConsumer(uint64 subId, address consumer) external;

    function cancelSubscription(uint64 subId, address to) external;

    function pendingRequestExists(uint64 subId) external view returns (bool);
}

contract Game is VRFConsumerBaseV2, Ownable {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 immutable keyHash;
    address public immutable linkToken;

    uint32 callbackGasLimit = 150000;

    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint public randomWordsNum;
    uint256 private totalFee=0;

    address[] public players;

    bool public gameStarted;
    mapping(uint256 => address) public ticket;
    uint public gameId;

    address public recentWinner;
    address payable public _wallet;


    event GameStarted(uint gameId);
    event PlayerJoined(uint gameId, address player);
    event GameEnded(uint gameId, address winner);

    constructor(
        uint64 subscriptionId,
        address _linkToken
    ) VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0xAE975071Be8F8eE67addBC1A82488F1C24858067
        );
        s_subscriptionId = subscriptionId;

        keyHash = 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;
        linkToken = _linkToken;
        _wallet = payable(0x78EBA672681f893620707027caA7F07361cAC103);

        gameStarted = false;
    }

    receive() external payable {}

    function startGame() public {
        require(!gameStarted, "The Game has started");

        players = new address[](0);

        gameStarted = true;

        gameId += 1;

        emit GameStarted(gameId);
    }

    function joinGame() public payable {
        require(gameStarted, "The Game has not kicked off");
        require(players.length < 2, "The Game is Filled Up!");
        uint256 currentFee = 10*msg.value/11;
        if (ticket[currentFee] != 0x0000000000000000000000000000000000000000) {
            require(
                ticket[currentFee] != msg.sender,
                "This user has already bought same ticket"
            );

            players.push(ticket[currentFee]);
            players.push(msg.sender);
            totalFee=totalFee+msg.value/11;           
            getRandomWinner(2 * currentFee);
            ticket[currentFee] = 0x0000000000000000000000000000000000000000;
        } else {
            ticket[currentFee] = msg.sender;
            totalFee=totalFee+msg.value/11;

            emit PlayerJoined(gameId, msg.sender);
        }
    }

    function getPlayersLenth() public view returns (uint) {
        return players.length;
    }

    function getRandomWinner(uint256 fee) internal returns (address) {
        requestRandomWords();

        uint256 winnerIndex = randomWordsNum % 2;

        recentWinner = players[winnerIndex];

        (bool success, ) = recentWinner.call{value: fee}("");
        require(success, "Could not send ether");
        gameStarted = false;

        emit GameEnded(gameId, recentWinner);
        startGame();
        return recentWinner;
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId; // requestID is a uint.
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        randomWordsNum = _randomWords[0]; // Set array-index to variable, easier to play with
        emit RequestFulfilled(_requestId, _randomWords);
    }

    // to check the request status of random number call.
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "Contract has no bnb");
        _wallet.transfer(address(this).balance);
    }
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Contract has no bnb");
        _wallet.transfer(totalFee);
        totalFee=0;
    }

    function setWalletReceiver(address payable newWallet) external onlyOwner {
        _wallet = newWallet;
    }
    function setSubscriptionId(uint64 newSubscriptionId) external onlyOwner{
        s_subscriptionId=newSubscriptionId;
    }
}