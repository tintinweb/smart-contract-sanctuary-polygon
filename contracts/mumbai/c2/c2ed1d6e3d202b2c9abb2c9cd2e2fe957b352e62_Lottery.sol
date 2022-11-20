//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";

/**
 * @title Lottery contract
 * NOTE: Contract use Chainlink Oracle for generating random words
 * Needs to fund subscription and add contract address after deploying as a consumer
 * on https://vrf.chain.link in order to work with VRFv2
 * @dev Lottery ticket is ERC721 token standard and could be bought with LOT ERC-20 tokens
 */
contract Lottery is VRFConsumerBaseV2, ERC721, Ownable {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    VRFCoordinatorV2Interface private _coordinator;
    IERC20 private _lotCoin;
    LOTTERY_STATE private _lotteryState;
    address private _vrfCoordinator;
    bytes32 private _keyHash;
    uint256 private _numberOfTicket;
    uint256 private _ticketPrice;
    uint256 private _lotteryBalance;
    uint256 private _lotteryId;
    uint256 private _percentageWinner;
    uint256 private _percentageOwner;
    uint64 private _subscriptionId;
    uint16 public constant _REQUEST_CONFIRMATIONS = 3;
    uint32 public constant _CALLBACK_GAS_LIMIT = 140000;
    uint32 public constant _NUM_WORDS = 1;
    uint256 public requestId;

    uint256[] private _randomWord;

    // Mapping from number of ticket to participant.
    mapping(uint256 => address) private _userTickets;
    // Mapping from number of lottery to lottery winner.
    mapping(uint256 => address) private _lotteryWinners;

    /**
     * @dev Emitted when new request to VRF coordinator sended
     * @param requestId id of generate randomness request
     */
    event RequestedRandomness(uint256 requestId);

    /**
     * @dev Emitted when VRF coordinator returns a new random word
     * @param requestId id of generate randomness request
     * @param number random number returned from VRF coordinator contract
     */
    event ReceivedRandomness(uint256 requestId, uint256 number);

    /**
     * @dev Emitted when new lottery started
     * @param lotteryId id of lottery
     */
    event NewLotteryStarted(uint256 lotteryId);

    /**
     * @dev Emitted when lottery ended
     * @param lotteryId id of lottery
     * @param winner of this lottery
     */
    event LotteryEnded(uint256 lotteryId, address winner);

    /**
     * @dev Emitted when new percentages of the total balance paid for the
     * winner and owner setted
     * @param percentageWinner_ percentage paid for the winner
     * @param percentageOwner_ percentage paid for the owner
     */
    event PercentagesChanged(
        uint256 percentageWinner_,
        uint256 percentageOwner_
    );

    /**
     * @dev Emitted when a new subscriptionId setted
     */
    event SubscriptionChanged(uint64 subscriptionId);

    /**
     * @dev Emitted when a new participation fee is established
     */
    event ParticipationFeeUpdated(uint256 usdParticipationFee);

    /**
     * @dev Emitted when a new participant appears
     */
    event NewParticipant(address indexed participant, uint256 lotteryId);

    /**
     * @dev vrfCoordinator_ and keyHash_ can be obtained
     * from here: https://docs.chain.link/docs/vrf-contracts/
     *
     * Requirements:
     *
     * - `subscriptionId_` cannot be zero.
     * - `keyHash_` cannot be address zero.
     * - `vrfCoordinator_` cannot be address zero.
     * - `token_` cannot be address zero.
     * - The sum of `percentageWinner_` and `percentageOwner_` must be 100(percent).
     *
     * @param subscriptionId_  can be obtained from here: https://vrf.chain.link
     * @param vrfCoordinator_  VRF coordinator contract address
     * @param keyHash_ The gas lane key hash value, which is the maximum
     * gas price you are willing to pay for a request in wei
     * @param token_ 'LOT' tokem contract address
     * @param percentageWinner_ percentage paid for the winner
     * @param percentageOwner_ percentage paid for the owner
     * @param ticketPrice_ price in 'LOT' tokens for one ticket in order to participate
     */
    constructor(
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        address token_,
        uint256 percentageWinner_,
        uint256 percentageOwner_,
        uint256 ticketPrice_
    ) VRFConsumerBaseV2(vrfCoordinator_) ERC721("LotteryTicket", "ticket") {
        require(subscriptionId_ != 0, "Wrong subscriptionId");
        require(vrfCoordinator_ != address(0), "Wrong vrfCoordinator address");
        require(keyHash_ != 0, "Wrong keyHash");
        require(token_ != address(0), "Wrong token address");
        require(
            percentageWinner_ + percentageOwner_ == 100,
            "Wrong percentages!"
        );
        _coordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        _subscriptionId = subscriptionId_;
        _vrfCoordinator = vrfCoordinator_;
        _keyHash = keyHash_;
        _lotCoin = IERC20(token_);
        _lotteryState = LOTTERY_STATE.CLOSED;
        _percentageWinner = percentageWinner_;
        _percentageOwner = percentageOwner_;
        _ticketPrice = ticketPrice_ * 10**18;
    }

    /**
     * @notice Start new lottery and allow players to buy tickets
     * Only owner could call this function
     * @dev The state of previous lottery is reseted
     *
     * Requirements:
     *
     * - `_lotteryState` must be in `CLOSED` state.
     *
     * Emits a {NewLotteryStarted} event.
     */
    function startLottery() external onlyOwner {
        require(
            _lotteryState == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery"
        );
        _lotteryBalance = 0;
        _numberOfTicket = 0;
        _lotteryState = LOTTERY_STATE.OPEN;
        _lotteryId++;
        _randomWord = new uint256[](0);
        emit NewLotteryStarted(_lotteryId);
    }

    /**
     * @notice ticket price is based on 'LOT' ERC20 standard token
     * Every user could buy multiple tickets
     * @dev Each ticket is ERC721 token
     *
     * Requirements:
     *
     * - It's required to approve _ticketPrice amount of tokens for this contract
     * in order to participate.
     * - `_lotteryState` must be in `OPEN` state.
     *
     * Emits a {NewParticipant} event.
     */
    function participate() external {
        require(
            _lotteryState == LOTTERY_STATE.OPEN,
            "Wait until the next lottery"
        );
        bool success = _lotCoin.transferFrom(
            msg.sender,
            address(this),
            _ticketPrice
        );
        require(success, "Fund transfer of lottery tokens failed");
        _numberOfTicket++;
        _userTickets[_numberOfTicket] = msg.sender;
        _lotteryBalance += _ticketPrice;
        _safeMint(msg.sender, _numberOfTicket);
        emit NewParticipant(msg.sender, _lotteryId);
    }

    /**
     * @notice End lottery function, which calculates the winner and pay the prize
     * Only owner could call this function
     * @dev endLottery() calls _pickWinner(), which in turn calls the
     * requestRandomWords function from VRFv2
     *
     * Requirements:
     *
     * - At least one participant is required to allow owner call this function.
     * - `_lotteryState` must be in `OPEN` state.
     * - `_lotteryBalance` must be equal to or greater than 100 tokens.
     *
     * Emits a {RequestedRandomness} event.
     */
    function endLottery() external onlyOwner {
        require(_lotteryState == LOTTERY_STATE.OPEN, "Can't end lottery yet");
        require(_numberOfTicket > 0, "Can't divide by zero");
        require(_lotteryBalance >= 100, "Lottery balance is too small");
        _lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        _pickWinner();
    }

    /**
     * @notice Function to calculate the winner
     * Only owner could call this function
     * @dev Will revert if subscription is not set and funded
     *
     * Emits a {RequestedRandomness} event.
     */
    function _pickWinner() private {
        require(
            _lotteryState == LOTTERY_STATE.CALCULATING_WINNER,
            "Lottery not ended yet"
        );
        requestId = _coordinator.requestRandomWords(
            _keyHash,
            _subscriptionId,
            _REQUEST_CONFIRMATIONS,
            _CALLBACK_GAS_LIMIT,
            _NUM_WORDS
        );
        emit RequestedRandomness(requestId);
    }

    /**
     * @notice Get random number, pick winner and sent prize to winner
     * @dev Function can be fulfilled only from _vrfcoordinator
     * @param reqId_ requestId for generating random number
     * @param random_ received number from VRFv2
     *
     * Requirements:
     *
     * - The first random word must be higher than zero.
     *
     * Emits a {ReceivedRandomness} event.
     * Emits a {LotteryEnded} event.
     */
    function fulfillRandomWords(
        uint256 reqId_, /* requestId */
        uint256[] memory random_
    ) internal override {
        _randomWord = random_;
        require(_randomWord[0] > 0, "Random number not found");
        uint256 winnerTicket = (_randomWord[0] % _numberOfTicket) + 1;
        _lotteryWinners[_lotteryId] = _userTickets[winnerTicket];
        bool success = _lotCoin.transfer(
            _userTickets[winnerTicket],
            (_lotteryBalance * _percentageWinner) / 100
        );
        require(success, "Transfer of funds to the winner ended in failure");
        success = _lotCoin.transfer(
            owner(),
            (_lotteryBalance * _percentageOwner) / 100
        );
        require(success, "Transfer of funds to the owner ended in failure");
        _lotteryState = LOTTERY_STATE.CLOSED;
        emit ReceivedRandomness(reqId_, random_[0]);
        emit LotteryEnded(_lotteryId, _userTickets[winnerTicket]);
    }

    /**
     * @notice Update the percentages of the total balance paid for the winner and owner
     *
     * Requirements:
     *
     * - The sum of `percentageWinner_` and `percentageOwner_` must be 100(percent).
     *
     * @param percentageWinner_ new percentage for the winner
     * @param percentageOwner_ new percentage for the owner
     *
     * Emits a {PercentagesChanged} event.
     */
    function updatePercentages(
        uint256 percentageWinner_,
        uint256 percentageOwner_
    ) external onlyOwner {
        require(
            percentageWinner_ + percentageOwner_ == 100,
            "Wrong percentages!"
        );
        _percentageWinner = percentageWinner_;
        _percentageOwner = percentageOwner_;
        emit PercentagesChanged(_percentageWinner, _percentageOwner);
    }

    /**
     * @notice Update _subscriptionId
     * @param newSubscriptionId_ new _subscriptionId
     *
     * Emits a {SubscriptionChanged} event.
     */
    function updateSubscriptionId(uint64 newSubscriptionId_)
        external
        onlyOwner
    {
        _subscriptionId = newSubscriptionId_;
        emit SubscriptionChanged(_subscriptionId);
    }

    /**
     * @notice Update Participation Fee
     * @param newTicketPrice_ new price of ticket in 'LOT' tokens
     *
     * Emits a {ParticipationFeeUpdated} event.
     */
    function updateTicketPrice(uint64 newTicketPrice_) external onlyOwner {
        _ticketPrice = newTicketPrice_ * 10**18;
        emit ParticipationFeeUpdated(_ticketPrice);
    }

    /**
     * @dev Returns the percentage of the total balance paid for the winner and owner
     */
    function getPercentages() external view returns (uint256, uint256) {
        return (_percentageWinner, _percentageOwner);
    }

    /**
     * @dev Returns lottery balance of current lottery
     */
    function getLotteryBalance() external view returns (uint256) {
        return _lotteryBalance;
    }

    /**
     * @dev Returns subscription Id
     */
    function getSubscriptionId() external view returns (uint64) {
        return _subscriptionId;
    }

    /**
     * @dev Returns current ticket price
     */
    function getTicketPrice() external view returns (uint256) {
        return _ticketPrice;
    }

    /**
     * @dev Returns address of the ticket owner
     * @param userTicket_ number of ticket in actual lottery
     */
    function getUserFromTicket(uint256 userTicket_)
        external
        view
        returns (address)
    {
        return _userTickets[userTicket_];
    }

    /**
     * @dev Returns the winner's address for a specific lottery
     * @param lotteryId_ number of lottery
     */
    function getlotteryWinner(uint256 lotteryId_)
        external
        view
        returns (address)
    {
        return _lotteryWinners[lotteryId_];
    }

    /**
     * @dev Returns number of tickets from current lottery
     */
    function currentNumberOfTickets() external view returns (uint256) {
        return _numberOfTicket;
    }

    /**
     * @dev Returns current lottery state
     */
    function currentLotteryState() external view returns (LOTTERY_STATE) {
        return _lotteryState;
    }

    /**
     * @dev Returns current lottery ID
     */
    function currentLotteryId() external view returns (uint256) {
        return _lotteryId;
    }

    /**
     * @dev Returns current Random Word
     */
    function currentRandomWord() external view returns (uint256[] memory) {
        return _randomWord;
    }

    /**
     * @dev Returns length of _randomWord array
     */
    function getLength() external view returns (uint256) {
        return _randomWord.length;
    }
}