/*
 _   _ ______ _____ ___                     _
| \ | ||  ___|_   _/ _ \                   | |
|  \| || |_    | |/ /_\ \_ __ ___ __ _   __| | ___
| . ` ||  _|   | ||  _  | '__/ __/ _` | / _` |/ _ \
| |\  || |     | || | | | | | (_| (_| || (_| |  __/
\_| \_/\_|     \_/\_| |_/_|  \___\__,_(_)__,_|\___|
            v1.3.3
            @author NFTArca.de!
            @title The Drunken Wizard
*/
//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract DrunkenWizard is ReentrancyGuard {
    address[] private players;
    address public admin;
    address public prevContract;
    uint256 public costToPlay;
    uint256 public playerLimit;
    uint256 public sideBetCost;
    uint256 public gbarsEmit;
    uint256[3] private gamePurses;
    address payable[] private winnerAddresses;
    address payable[] private lastWinnerAddresses;
    address[] private lastPlayerAddresses;
    uint256[] private winnerPurses;
    uint256 public gamePrizePool = 0;
    uint256 public sideBetPrizePool = 0;
    string public triWinners = '';
    uint256 public gameNumber = 1;
    uint256[] private winnerIDs;
    uint256 public totalPaymentTokenWon = 0;
    uint256 public totalPaymentTokenSideBetWon = 0;
    uint256 public totalGBarGifted = 0;
    address[] private sideBets;
    address public sideBetWinner;
    mapping(string => uint256) sideBetsCheck;
    string[] private sideBetsPickedNumbers;
    // Set the game availability
    bool gameIsPaused = false;
    IERC20 public paymentToken;
    IERC20 public gbarsToken;
    constructor(
        IERC20 _paymentToken,
        IERC20 _gbarsToken,
        uint256 _costToPlay,
        uint256 _playerLimit,
        uint256 _sideBetCost,
        uint256 _gbarsEmit,
        uint256[3] memory _gamePurses,
        uint256 _gameNumberToStart,
        uint256 _totalPaymentTokenWonStart,
        uint256 _totalPaymentTokenSideBetWonStart,
        uint256 _totalGBarGiftedStart
    ) {
        admin = msg.sender;
        paymentToken = IERC20(_paymentToken);
        gbarsToken = IERC20(_gbarsToken);
        costToPlay = _costToPlay;
        playerLimit = _playerLimit;
        sideBetCost = _sideBetCost;
        gbarsEmit = _gbarsEmit;
        gamePurses = _gamePurses;
        gameNumber = _gameNumberToStart;
        totalPaymentTokenWon = _totalPaymentTokenWonStart;
        totalPaymentTokenSideBetWon = _totalPaymentTokenSideBetWonStart;
        totalGBarGifted = _totalGBarGiftedStart;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }
    function joinGame() public payable nonReentrant {
        // Make sure the game is not paused
        require(gameIsPaused == false , "Game is paused.");
        // require the approval of the sending of the token to the contract
        require(paymentToken.approve(msg.sender, costToPlay), "Must approve the sending of the Payment Token");
        // Transfer the Payment Token to the contract
        require(paymentToken.transferFrom(msg.sender, address(this), costToPlay), "Didn't receive the Payment Token");
        // Limit players to match
        require(players.length < playerLimit, "This match has reached the player limit");
        // Add the person who sent the Payment Token to the players array
        players.push(msg.sender);
        // Add the Payment Token to the gamePrizePool
        gamePrizePool += costToPlay;
    }
    function placeSideBet(uint256 bet1, uint256 bet2, uint256 bet3) public payable nonReentrant {
        // Make sure the game is not paused
        require(gameIsPaused == false , "Game is paused.");
        // require the approval of the sending of the token to the contract
        require(paymentToken.approve(msg.sender, sideBetCost), "Must approve the sending of the Payment Token");
        // require that the sender sends exact Payment Token Amount
        require(paymentToken.transferFrom(msg.sender, address(this), sideBetCost), "Didn't receive the Payment Token");
        // Ensure the bets are
        require(bet1 < playerLimit && bet1 >= 0, "Not a valid bet");
        require(bet2 < playerLimit && bet2 >= 0, "Not a valid bet");
        require(bet3 < playerLimit && bet3 >= 0, "Not a valid bet");
        // Make the bet
        string memory pickedNumbers = append(Strings.toString(bet1), ",", Strings.toString(bet2), ",", Strings.toString(bet3));
        // check to see if the triBet is already placeSideBet
        require(sideBetsCheck[pickedNumbers] <= 0, "TriBet already placed");
        // Add the Payment Token to the pool
        sideBetPrizePool += sideBetCost;
        // Add the side bet to the list
        sideBets.push(msg.sender);
        sideBetsCheck[pickedNumbers] = sideBets.length;
        sideBetsPickedNumbers.push(pickedNumbers);
    }
    // Simple random function that can only be called by admin at random time chosen by them
    function random(uint256 playerCount, uint256 i) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(i, block.difficulty + i, msg.sender))) % playerCount;
    }
    // Admin function to pick a winner and setup the next game
    function pickWinner(uint newCostPerPlayer,uint newTotalPlayerLimit, uint256[3] calldata purses, uint newSideBetCost, uint seed) public onlyOwner nonReentrant {
        // Ensure we have enough players to play
        require(players.length == playerLimit, "Not enough players have entered this Game");
        // Just in case
        require(players.length >= gamePurses.length, "Need at least as many players as there are purses");
        // Make sure we have enough GBAR to award everyone
        require((gbarsToken.balanceOf(address(this)) >= players.length * gbarsEmit), "Don't have enough GBAR to pay everyone. Add GBAR and retry.");
        // Reset TriWinners for new game
        delete triWinners;
        winnerPurses = new uint256[](0);
        sideBetWinner = address(0);
        address payable winner;
        uint winnerCount = 0;
        while (winnerCount < gamePurses.length) {
            uint256 randomWinnerID = random(players.length, seed);
            winner = payable(players[randomWinnerID]);
            bool winnerAlreadyPicked = false;
            for (uint i=0; i < winnerIDs.length; i++) {
                if (randomWinnerID == winnerIDs[i]) {
                    winnerAlreadyPicked = true;
                }
            }
            if (winnerAlreadyPicked == false) {
                winnerAddresses.push(winner);
                winnerIDs.push(randomWinnerID);
                winnerCount++;
                // Add winner list
                if (winnerCount < gamePurses.length){
                    triWinners = append(triWinners,Strings.toString(randomWinnerID),",","","");
                } else {
                    triWinners = append(triWinners,Strings.toString(randomWinnerID),"","","");
                }
            }
            seed += 1;
        }
        // Initialize the house cut
        uint256 houseCut = 100;
        for (uint i = 0; i <= gamePurses.length - 1; i++) {
            if (gamePurses[i] > 0){
                houseCut -= gamePurses[i];
                uint256 winningAmount = (gamePrizePool * gamePurses[i]) / 100;
                // Pay the winners of the game
                paymentToken.transfer(winnerAddresses[i], winningAmount);
                totalPaymentTokenWon = totalPaymentTokenWon + winningAmount;
                // Keep track of the winning amount per winner
                winnerPurses.push(winningAmount);
            }
        }
        // Update the array of winners until next game
        lastWinnerAddresses = winnerAddresses;
        lastPlayerAddresses = players;
        // Get the winner of the side bet if there is one
        if (sideBetsCheck[triWinners] > 0){
            // have to -1 since length of array is value above. Need to be above 0 for resetting (triWinners)
            sideBetWinner = sideBets[sideBetsCheck[triWinners] - 1];
            // Pay the side bet winner
            paymentToken.transfer(sideBetWinner, getSideBetPool());
            totalPaymentTokenSideBetWon = totalPaymentTokenSideBetWon + getSideBetPool();
            // Subtract the amount paid to side bet winner
            sideBetPrizePool = sideBetPrizePool - getSideBetPool();
            // Transfer 10% to house and leave 10% in the pool to start next side bet pool
            uint256 amountToCutHouse = ((sideBetPrizePool * 50) / 100);
            paymentToken.transfer(admin, amountToCutHouse);
            // Subtract the amount paid to house
            sideBetPrizePool = sideBetPrizePool - amountToCutHouse;
        }
        // Pay the house it's cut for future game investment
        paymentToken.transfer(admin, ((gamePrizePool * houseCut) / 100));
        // Transfer GBars to players
        for (uint i = 0; i <= players.length - 1; i++) {
            gbarsToken.transfer(players[i], gbarsEmit);
            totalGBarGifted = totalGBarGifted + gbarsEmit;
        }
        // Setup the next Game
        costToPlay = newCostPerPlayer * 10**18;
        playerLimit = newTotalPlayerLimit;
        gamePurses = purses;
        sideBetCost = newSideBetCost * 10**18;
        delete gamePrizePool;
        resetDiceGame();
        gameNumber = gameNumber + 1;
    }
    function adminUpdateGame(uint newCostPerPlayer,uint newTotalPlayerLimit, uint256[3] calldata purses, uint newSideBetCost) public onlyOwner {
        // Make sure we don't go under what we already have
        require(newTotalPlayerLimit >= players.length, "Player count must be greater than or equal to current amount of players registerd");
        // Setup the current Game
        costToPlay = newCostPerPlayer * 10**18;
        playerLimit = newTotalPlayerLimit;
        gamePurses = purses;
        sideBetCost = newSideBetCost * 10**18;
    }
    function updateAdmin(address newAdmin) public onlyOwner {
        admin = newAdmin;
    }
    function resetDiceGame() internal {
        // Reset the mapping
        for (uint i=0; i< sideBets.length ; i++){
            sideBetsCheck[sideBetsPickedNumbers[i]] = 0;
        }
        delete players;
        delete winnerAddresses;
        delete sideBets;
        delete sideBetsPickedNumbers;
        delete winnerIDs;
    }
    function pauseGame(bool isPaused, bool failSafe) public onlyOwner {
        require((failSafe == true), "ah ah ah, you didn't say the magic word!");
        gameIsPaused = isPaused;
    }
    function changePaymentToken(IERC20 paymentTokenContractAddress) public onlyOwner {
        paymentToken = IERC20(paymentTokenContractAddress);
    }
    function changeGbarsToken(IERC20 gbarsTokenContractAddress) public onlyOwner {
        gbarsToken = IERC20(gbarsTokenContractAddress);
    }
    function initializeSideBetPool(uint256 newSideBetPool) public onlyOwner {
        sideBetPrizePool = newSideBetPool;
    }
    function updateGBarsEmit(uint256 _gbarsEmit) public onlyOwner {
        gbarsEmit = _gbarsEmit;
    }
    function updatePreviousContract(address _prevContract) public onlyOwner {
        prevContract = _prevContract;
    }
    function nukeItFromOrbit(bool failSafe) public onlyOwner nonReentrant {
        require((failSafe == true), "ah ah ah, you didn't say the magic word!");
        // Transfer any Payment Token, GBar and MATIC out of contract in case we need to close and relaunch a new contract
        // This is a pure "Nuke it from orbit" option in case exploit / massive bug is found and we need protect the assets.
        payable(admin).transfer(address(this).balance);
        paymentToken.transfer(admin, paymentToken.balanceOf(address(this)));
        gbarsToken.transfer(admin, gbarsToken.balanceOf(address(this)));
    }
    function isGamePaused() public view returns (bool) {
        return gameIsPaused;
    }
    function getTotalPlayers() public view returns (uint256){
        return players.length;
    }
    function getPlayers() public view returns (address[] memory){
        return players;
    }
    function getWinners() public view returns (address payable[] memory){
        return lastWinnerAddresses;
    }
    function getPreviousPlayers() public view returns (address[] memory){
        return lastPlayerAddresses;
    }
    function getWinnings() public view returns (uint256[] memory){
        return winnerPurses;
    }
    function getPurses() public view returns (uint256[3] memory){
        return gamePurses;
    }
    function getTriBets() public view returns (string[] memory){
        return sideBetsPickedNumbers;
    }
    function getSideBetPool() public view returns (uint256){
        return (sideBetPrizePool * 80) / 100;
    }
    function getSideBetters() public view returns (address[] memory){
        return sideBets;
    }
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}