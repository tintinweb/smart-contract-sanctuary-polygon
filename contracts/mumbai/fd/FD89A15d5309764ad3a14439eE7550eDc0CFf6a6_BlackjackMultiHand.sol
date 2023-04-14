// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Rewards/Claim.sol";
import "../access/Bound.sol";
import "./Rewards/Reward.sol";
import "./priceFeeds/PriceConsumerV3.sol";

contract BlackjackMultiHand is Claim, Bound {
    using SafeERC20 for IERC20;
    PriceConsumerV3 price = new PriceConsumerV3();
    Reward public reward;

    struct Game {
        address bettor;
        uint256 startTime;
        uint8 numOfHands;
        uint8 dealerScore;  
        bool completed;      
    }

    struct Player {
        uint256 betAmount;
        uint8 score;
        uint256 winningAmount;
        bool handConcluded;
    }

    uint256 public currentBetId;
    uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];

    /*
    Cards value is calculated using index of this array
    ["AH","2H","3H","4H","5H","6H","7H","8H","9H","10H","JH","QH","KH","AC","2C","3C","4C","5C","6C","7C","8C","9C","10C","JC","QC","KC","AD","2D","3D","4D","5D","6D","7D","8D","9D","10D","JD","QD","KD","AS","2S","3S","4S","5S","6S","7S","8S","9S","10S","JS","QS","KS",] 
    */

    mapping(uint256 => Game) public gameId;
    mapping(uint256 => mapping(uint8 => Player)) public playerHand;
    mapping(uint256 => mapping(uint8 => uint8[])) private playerCards;
    mapping(uint256 => mapping(uint8 => Player)) public splitPlayerHand;
    mapping(uint256 => mapping(uint8 => uint8[])) private splitPlayerCards;
    mapping(uint256 => uint8[]) private dealerCards;
    mapping(uint256 => bool) public isEther;
    mapping(uint256 => address) public tokenAddress;

    event BetPlaced(uint256 betId, uint256 time, address player, uint256 betAmount);
    event CardsDistribution(uint256 betId, uint8[] initialCards);
    event SplitPlayer(uint256 betId, uint256 pCard2, uint256 spCard2);
    event DoubleDown(uint256 betId, uint256 pCard3);
    event PlayerHit(uint256 betId, uint256 pCard3);
    event DealerSecondCard(uint256 betId, uint256 dCard2);
    event DealerHit(uint256 betId, uint256 dNewCard);
    event BetCompleted(uint8 handIndex, uint256 betId, bool push, uint256 winAmount);

    constructor(address _reward) {
        reward = Reward(_reward);
    }

    modifier playerChecks(uint256 betId, uint8 handIndex) {
        Game memory bet = gameId[betId];
        require(dealerCards[betId].length > 0);
        require(msg.sender == bet.bettor, "Not player");
        require(!bet.completed);
        require(!playerHand[betId][handIndex].handConcluded, "Forbidden");
        _;
    }

    /**
     * @dev For placing the bet.
     * @notice Only whitelisted tokens are allowed for payments.
     * @param amount amount of token user wants to bet. Should approve the contract to use it first.
    */
    function play(uint8 hands, bool isEth, address tokenAddr, uint256 amount) external payable nonReentrant betLimit(isEth, amount, tokenAddr) {
        require(hands <= 6, 'Maximum of 6 hands');
        ++currentBetId;
        Game storage bet = gameId[currentBetId];

        uint betAmount; 
        uint totalBet;
        if(isEth) {
            totalBet = msg.value;
            betAmount = msg.value / hands;
            isEther[currentBetId] = true;
        }
        else{
            totalBet = amount;
            betAmount = totalBet / hands;
            IERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            tokenAddress[currentBetId] = tokenAddr;
        }

        bet.startTime = block.timestamp;
        bet.bettor = msg.sender;
        bet.numOfHands = hands;

        uint8 numOfCards = (hands * 2) + 1;
        uint8[] memory cards = drawCard(currentBetId, numOfCards);
        
        dealerCards[currentBetId].push(cards[numOfCards - 1]);

        for(uint8 i = 0; i < hands; i++) {
            playerHand[currentBetId][i].betAmount = betAmount;
            playerCards[currentBetId][i] = [cards[i*2],cards[(i*2) + 1]];
            calculatePlayer(currentBetId, i);
        }
        emit BetPlaced(currentBetId, bet.startTime, msg.sender, totalBet);
        emit CardsDistribution(currentBetId, cards);
    }   

    //private function used for generating multiple random card values.
    function drawCard(uint256 betId, uint8 numberOfCards) private view returns(uint8[] memory) {
        uint8[] memory cards = new uint8[](numberOfCards);

        for (uint8 i = 0; i < numberOfCards; i++) {
            bytes32 hash = keccak256(abi.encodePacked(block.timestamp, block.number, seedWord, betId, i));
            cards[i] = (uint8(hash[0])% 52);
        }

        return cards;
    }

    //private function used to calculate hand score.
    function calculatePlayer(uint256 betId, uint8 handIndex) private {
        uint8[] memory hand = playerCards[betId][handIndex];
        playerHand[betId][handIndex].score = calculateScore(hand);
    }

    //private function used to calculate split hand score.
    function calculateSplitPlayer(uint256 betId, uint8 handIndex) private {
        uint8[] memory hand = splitPlayerCards[betId][handIndex];
        splitPlayerHand[betId][handIndex].score = calculateScore(hand);
    }

    //private function used to calculate dealer hand score.
    function calculateDealer(uint256 betId) private {
        uint8[] memory hand = dealerCards[betId];
        gameId[betId].dealerScore = calculateScore(hand);
    }

    //private function for calculating score
    function calculateScore(uint8[] memory hand) private view returns(uint8) {
        uint8 numOfAces = 0;
        uint8 playerScore;
        for(uint8 i = 0; i < hand.length; i++ ) {
            uint8 index = uint8(hand[i] % 13);
            uint8 card = cardValues[index];
            playerScore += card;
            if(card == 11) {
                numOfAces++;
            }
            while(numOfAces > 0 && playerScore > 21) {
                playerScore -= 10;
                numOfAces--;
            }
        }
        return playerScore;
    }

    /**
     * @param betId Game id 
     * @notice Split both the cards in each hand and provide one card to each hand and conclude the game.
     */
    function split(uint256 betId, uint8 handIndex) external payable nonReentrant playerChecks(betId, handIndex) {
        Player storage bet = playerHand[betId][handIndex];
        Player storage sBet = splitPlayerHand[betId][handIndex];
        require(playerCards[betId][handIndex].length == 2);
        require(playerCards[betId][handIndex][0] % 13 == playerCards[betId][handIndex][1] % 13, 'Both cards must be same');
        uint betValue = bet.betAmount;
        if(isEther[betId]) {
            require(msg.value == betValue, 'Must match original bet');
        }else {
            IERC20(tokenAddress[betId]).safeTransferFrom(msg.sender, address(this), betValue);
        }
        sBet.betAmount = bet.betAmount;
        splitPlayerCards[betId][handIndex].push(playerCards[betId][handIndex][1]);
        playerCards[betId][handIndex].pop();

        uint8[] memory cards = drawCard(betId, 2);

        playerCards[betId][handIndex].push(cards[0]);
        splitPlayerCards[betId][handIndex].push(cards[1]);

        calculatePlayer(betId, handIndex);
        calculateSplitPlayer(betId, handIndex);
        bet.handConcluded = true;

        emit SplitPlayer(betId, cards[0], cards[1]);
    }

    /**
     * @param amount if the bet is placed using any ERC20 token, player should specify how much amount he wants to increase.
     * @notice amount should not be more than original bet.
     * @notice We will provide one more card to the player and conclude the game.
     * @notice If the total score of the player goes above 21, player busts and loses bet.
     */
    function doubleDown(uint256 betId, uint8 handIndex, uint256 amount) external payable nonReentrant playerChecks(betId, handIndex) {
        Player storage bet = playerHand[betId][handIndex];
        require(playerCards[betId][handIndex].length == 2, 'Not Allowed');
        if(isEther[betId]) {
            require(msg.value <= bet.betAmount && msg.value > 0, 'Should not be more than original bet');
            bet.betAmount += msg.value;
        }
        else{
            require(amount <= bet.betAmount && amount > 0, 'Should not be more than original bet');
            IERC20(tokenAddress[betId]).safeTransferFrom(msg.sender, address(this), amount);
            bet.betAmount += amount;
        }
       
        uint8[] memory cards = drawCard(betId, 1);
        playerCards[betId][handIndex].push(cards[0]); 

        calculatePlayer(betId, handIndex);
        bet.handConcluded = true;

        emit DoubleDown(betId, cards[0]);
    }

    /**
     * @param betId Game id 
     * @notice We provide a pard to the player and calculates his score.
     * @notice If the total score of the player goes above 21, player busts and loses bet.
     * @notice If the total score of the player is equal to 21, we reveal dealer's next card.
     */
    function hit(uint256 betId, uint8 handIndex) external playerChecks(betId, handIndex){
        uint8[] memory cards = drawCard(betId, 1);

        Player storage bet = playerHand[betId][handIndex];
        playerCards[betId][handIndex].push(cards[0]); 

        calculatePlayer(betId, handIndex);
        if(bet.score > 21) {
            bet.handConcluded = true;
        }
        emit PlayerHit(betId, cards[0]);
    }


    /**
     * function used for revealing dealer's second card.
     * @param betId Game id
     * @notice Randomness of the card is based on the cards length of the hand.
     * @notice While the dealer score is less than 17, we provide another card to the dealer.
     * @notice After the dealer's score goes above 16, we will calculate the pay outs.
     */
    function revealDealerCard(uint256 betId) external {
        Game storage bet = gameId[betId];
        require(msg.sender == bet.bettor, "Not player");
        require(!bet.completed);
        uint8[] memory card = drawCard(betId, 1);

        uint8 length = uint8(dealerCards[betId].length + 1);
        uint256 dealerCard2 = card[0] * length;
        while(dealerCard2 > 52) {
            dealerCard2 -= 52;
        }
        uint8 cardValue = uint8(dealerCard2);
        dealerCards[betId].push(cardValue);
        calculateDealer(betId);
        while(bet.dealerScore < 17) {
            dealerHit(betId);
        }
        checkWinner(betId);
        emit DealerSecondCard(betId, cardValue);
    } 

    /**
     * private function called, while the dealer's score is below 17
     * @notice Randomness of the card is based on the cards length of the hand.
     */
    function dealerHit(uint256 betId) private {
        
        uint8[] memory card = drawCard(betId, 1);
        uint8 length = uint8(dealerCards[betId].length + 1);
        uint256 newCard = card[0] * length;
        while(newCard > 52) {
            newCard -= 52;
        }
        uint8 cardValue = uint8(newCard);
        dealerCards[betId].push(cardValue);
        calculateDealer(betId);
        emit DealerHit(betId, cardValue);
    }

    /**
     * private function called when dealer's score goes above 16
     * @notice update total winnings of the player.
     */
    function checkWinner(uint256 betId) private {
        Game storage game = gameId[betId];
        game.completed = true;
        for(uint8 i = 0; i < game.numOfHands; i++) {
            Player storage bet = playerHand[betId][i];
            Player storage sBet = splitPlayerHand[betId][i];
            calculatePayOut(betId, i);
            uint256 winAmount;
            if(splitPlayerCards[betId][i].length > 0){
                calculatePayOut(betId, i); 
                winAmount = bet.winningAmount + sBet.winningAmount;
            }else {
                winAmount = bet.winningAmount;  
            }
            if(isEther[betId]){
                winningsInEther[game.bettor] += winAmount;
            }else{
                winningsInToken[game.bettor][tokenAddress[betId]] += winAmount;
            }
            rewardDistribution(betId);
        }
    }

    // private function used for calculating and updating the winning amount of the player.
    function calculatePayOut(uint256 betId, uint8 handIndex) private {
        bool push = false;
        Game storage bet = gameId[betId];
        Player storage player = playerHand[betId][handIndex];
        if(playerCards[betId][handIndex].length == 2 && player.score == 21 && bet.dealerScore != 21) {
            player.winningAmount = (25 * player.betAmount)/10;
        }else if(player.score > bet.dealerScore || bet.dealerScore > 21) {
            player.winningAmount = 2 * player.betAmount;
        }else if(player.score == bet.dealerScore) {
            push = true;
            player.winningAmount = player.betAmount;
        }  
        emit BetCompleted(handIndex, betId, push, player.winningAmount);     
    }

    //Add the reward balance
    function rewardDistribution(uint256 betId) private {
        Game storage bet = gameId[betId];
        uint betVal = 0;
        for(uint8 i = 0; i < bet.numOfHands; i++) {
            playerHand[currentBetId][i].betAmount += betVal;
        }
        int betValue = int(betVal);
        int payableReward;
        if(isEther[betId]) {
            int ethPrice = price.getLatestPrice();
            int value = ethPrice * betValue;
            payableReward = value / 10 ** 10;
        } else {
            payableReward = betValue / 100;
        }
        reward.updateReward(msg.sender, payableReward);
    }

    //To get cards in a hand
    function getPlayerCards(uint256 betId, uint8 handIndex) external view returns(uint8[] memory) {
        return playerCards[betId][handIndex];
    }

    //To get cards in a split hand
    function getSplitPlayerCards(uint256 betId, uint8 handIndex) external view returns(uint8[] memory) {
        return splitPlayerCards[betId][handIndex];
    }

    //To get dealer's card
    function getDealerCards(uint256 betId) external view returns(uint8[] memory) {
        return dealerCards[betId];
    }    
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../libraries/token/SafeERC20.sol";
import "../../access/Governable.sol";
import "../../libraries/utils/ReentrancyGuard.sol";

contract Claim is Governable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public winningsInEther;
    mapping(address => mapping(address => uint256)) public winningsInToken;

    event EthWithdrawn(address indexed player, uint256 indexed amount);
    event TokenWithdrawn(address indexed player, address indexed tokenAddress, uint256 indexed amount);
    event Received(address sender, uint256 indexed message);

    modifier ethBal(uint256 amount) {
        require(reserveInEther() >= amount,'Contract does not have enough balance');
        _;
    }

    modifier tokenBal(address tokenAddress, uint256 amount) {
        require(reserveInToken(tokenAddress) >= amount,'Contract does not have enough balance');
        _;
    }

    //Checks Ether balance of the contract
    function reserveInEther() public view returns (uint256) {
        return address(this).balance;
    }

    //Checks ERC20 Token balance.
    function reserveInToken(address tokenAddress) public view returns(uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //Owner is allowed to withdraw the contract's Ether balance.
    function withdrawEth(address receiver, uint256 amount) private returns(bool) {
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Transfer failed");
        return true;
    }

    //Owner is allowed to withdraw the contract's token balance.
    function withdrawToken(address receiver, address tokenAddress, uint256 amount) private  returns(bool){
        IERC20(tokenAddress).safeTransfer(receiver, amount);
        return true;
    }

    //Allows users to withdraw their Ether winnings.
    function withdrawEtherWinnings(address receiver, uint256 amount) external nonReentrant ethBal(amount) {
        require(winningsInEther[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
        winningsInEther[msg.sender] -= amount;
        withdrawEth(receiver, amount);
        emit EthWithdrawn(msg.sender, amount);
    }

    //Allows users to withdraw their ERC20 token winnings
    function withdrawTokenWinnings(address receiver, address tokenAddress, uint256 amount) external nonReentrant tokenBal(tokenAddress, amount) {
        require(winningsInToken[msg.sender][tokenAddress] >= amount, "You do not have requested winning amount to withdraw");
        winningsInToken[msg.sender][tokenAddress] -= amount;
        withdrawToken(receiver, tokenAddress, amount);
        emit TokenWithdrawn(msg.sender, tokenAddress, amount);
    }

    //Owner is allowed to withdraw the contract's Ether balance.
    function withdrawEther(address receiver, uint256 amount) external onlyGov nonReentrant ethBal(amount) {
        withdrawEth(receiver, amount);
        emit EthWithdrawn(msg.sender, amount);
    }

    //Owner is allowed to withdraw the contract's token balance.
    function tokenWithdraw(address receiver,address tokenAddress, uint256 amount) external onlyGov nonReentrant tokenBal(tokenAddress, amount) {
        withdrawToken(receiver, tokenAddress, amount);
        emit TokenWithdrawn(msg.sender, tokenAddress, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Governable.sol";

contract Bound is Governable {
    address public rewardToken;
    uint256 internal seedWord;
    uint256 public ethMaxBet;
    uint256 public ethMinBet;
    uint256 public tokenMaxBet;
    uint256 public tokenMinBet;

    mapping(address => bool) public whitelistedToken;

    modifier betLimit(bool isEth, uint256 amount, address tokenAddr) {
        if(isEth) {
            require(msg.value >= ethMinBet && msg.value <= ethMaxBet, 'Invalid amount'); 
        } else {
            require(whitelistedToken[tokenAddr], 'Token not allowed for placing bet');
            require(amount >= tokenMinBet && amount <= tokenMaxBet, 'Invalid amount'); 
        }
        _;
    }

    function setEsBetToken(address rewardTokenAddr) external onlyGov {
        rewardToken = rewardTokenAddr;
    }

    function setSeedWord(uint256 seed) external onlyAdmin {
        seedWord = seed;
    }

    function setEthLimit(uint256 min, uint256 max) external onlyAdmin {
        ethMinBet = min;
        ethMaxBet = max;
    }

    function setTokenLimit(uint256 min, uint256 max) external onlyAdmin {
        tokenMinBet = min;
        tokenMaxBet = max;
    }

    function addWhitelistTokens(address ERC20Address) external onlyGov {
        require(!whitelistedToken[ERC20Address], 'Token already whitelisted');
        whitelistedToken[ERC20Address] = true;
    }

    function removeWhitelistTokens(address ERC20Address) external onlyGov {
        require(whitelistedToken[ERC20Address], 'Token is not whitelisted');
        whitelistedToken[ERC20Address] = false;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../access/Governable.sol";

contract Reward is Governable {

    address vester;

    mapping(address => int) public rewards;
    mapping(address => bool) public caller;

    event RewardUpdated(address caller, address recipient, int reward);
    event RewardDeducted(address caller, address recipient, int reward);

    modifier authorisedOnly() {
      require(caller[msg.sender], "Not Authorised");
      _;
    }

    modifier onlyVester() {
        require(msg.sender == vester, "Only vesting contract can call");
        _;
    }

    function setCaller(address contractAddr) external onlyAdmin {
      caller[contractAddr] = true;
    }

    function setVesterAddr(address vesterAddr) external onlyAdmin {
        vester = vesterAddr;
    }

    function updateReward(address recipient, int amount) external authorisedOnly {
        rewards[recipient] += amount;

    emit RewardUpdated(msg.sender, recipient, amount);
    }

    function decreaseRewardBalance(address recipient, int amount) external onlyVester {
        require(msg.sender == vester, "Not Authorised");
        rewards[recipient] -= amount;
        emit RewardDeducted(msg.sender, recipient, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,          
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {

    address public gov;
    mapping (address => bool) public admins;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Only Gov can call");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only Admin can call");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external onlyGov {
        admins[_account] = false;
    }
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
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