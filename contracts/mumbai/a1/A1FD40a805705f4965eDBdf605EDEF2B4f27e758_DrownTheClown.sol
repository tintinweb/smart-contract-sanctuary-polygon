/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/BeerGame.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;




contract DrownTheClown {

    address[] private players;
    address public admin;

    uint256 public costToPlay = 1 ether;
    uint256 public playerLimit = 5;
    uint256 public sideBetCost = 1 ether;
    uint256[3] private gamePurses = [50, 25, 15];
    address payable[] private winnerAddresses;
    address payable[] private lastWinnerAddresses;
    uint256[] private winnerPurses;
    uint256 private gamePrizePool = 0;
    uint256 private sideBetPrizePool = 0;
    string public triWinners = '';
    uint256 public gameNumber = 1;

    address[] private sideBets;
    address public sideBetWinner;
    mapping(string => uint256) sideBetsCheck;
    string[] private sideBetsPickedNumbers;

    address private gpTokenContractAddress = 0x38Ec27c6F05a169e7eD03132bcA7d0cfeE93C2C5;
    IERC20 paymentToken = IERC20(gpTokenContractAddress);


    constructor() {
        admin = msg.sender;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }

    // Set the game availability
    bool gameIsPaused = false;

    function joinGame() public payable{
        // Make sure the game is not game is not paused
        require(gameIsPaused == false , "Game is paused.");

        // Make sure they have the necessary GP to play
        require(paymentToken.allowance(msg.sender, address(this)) >= costToPlay, "Insufficient GP Balance in Wallet");

        //require that the sender sends exactly 50k GP
        require(msg.value == costToPlay, "Must send exactly the right amount of GP");

        // require the approval of the sending of the token to the contract
        require(paymentToken.approve(msg.sender, costToPlay), "Must approve the sending of GP");

        //Admin cannot participate
        require(msg.sender != admin, "Admins are not allowed to play");

        // Limit players to match
        require(players.length < playerLimit, "This match has reached the player limit");

        // Add the person who sent GP to the players array
        players.push(msg.sender);

        // Add the GP to the gamePrizePool
        gamePrizePool += msg.value;
    }

    function placeSideBet(string calldata pickedNumbers) public payable{
        // Make sure the game is not game is not paused
        require(gameIsPaused == false , "Game is paused.");

        // Make sure they have the necessary GP to play
        require(paymentToken.allowance(msg.sender, address(this)) >= sideBetCost, "Insufficient GP Balance in Wallet to place a side bet");

        // require the approval of the sending of the token to the contract
        require(paymentToken.approve(msg.sender, sideBetCost), "Must approve the sending of GP");

        //require that the sender sends exact GP Amount
        require(msg.value == sideBetCost, "Must send exactly the right amount of GP");

        // check to see if the triBet is already placeSideBet
        require(sideBetsCheck[pickedNumbers] <= 0, "TriBet already placed");

        // Add the GP to the pool
        sideBetPrizePool += msg.value;

        // Add the side bet to the list
        sideBets.push(msg.sender);
        sideBetsCheck[pickedNumbers] = sideBets.length;
        sideBetsPickedNumbers.push(pickedNumbers);
    }


    function random(uint256 playerCount, uint256 i) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty + i, msg.sender))) % playerCount;
    }

    //only admin can call this function
    function pickWinner(uint newCostPerPlayer,uint neWTotalPlayerLimit, uint256[3] calldata purses, uint newSideBetCost) public onlyOwner payable {

        require(players.length == playerLimit, "Not enough players have entered this Dice Game");

        require(players.length >= gamePurses.length, "Need at least as many players as there are purses");

        address payable winner;

        // Reset TriWinners for new game
        triWinners = '';
        winnerPurses = new uint256[](0);
        sideBetWinner = 0x0000000000000000000000000000000000000000;


        uint seedNum = 1;
        uint winnerCount = 0;
        while (winnerCount < gamePurses.length) {

            uint256 randomWinnerID = random(players.length, seedNum);
            winner = payable(players[randomWinnerID]);
            bool winnerAlreadyPicked = false;
            for (uint i=0; i < winnerAddresses.length; i++) {
                if (winner == winnerAddresses[i]) {
                    winnerAlreadyPicked = true;
                }
            }

            if (winnerAlreadyPicked == false) {
                winnerAddresses.push(winner);
                winnerCount++;

                // Add to Triforce win
                triWinners = append(triWinners,Strings.toString(randomWinnerID),",");
            }
            seedNum += 1;
        }

        // Initialize the house cut
        uint256 houseCut = 100;

        for (uint i = 0; i <= gamePurses.length - 1; i++) {
            if (gamePurses[i] > 0){
                houseCut -= gamePurses[i];
                uint256 winningAmount = (gamePrizePool * gamePurses[i]) / 100;

                // Pay the winners of the game
                // winnerAddresses[i].transfer(winningAmount);
                paymentToken.transferFrom(address(this), winnerAddresses[i], winningAmount);

                // Keep track of the winning amount per winner
                winnerPurses.push(winningAmount);
            }
        }

        // Update the array of winners until next game
        lastWinnerAddresses = winnerAddresses;

        // Get the winner of the side bet if there is one
        if (sideBetsCheck[triWinners] > 0){
            // have to -1 since length of array is value above. Need to be above 0 for resetting (triWinners)
            sideBetWinner = sideBets[sideBetsCheck[triWinners] - 1];

            // Pay the sidebet winner
            // payable(sideBetWinner).transfer(getSideBetPool());
            paymentToken.transferFrom(address(this), sideBetWinner, getSideBetPool());

            // Transfer 10% to house and leave 10% in the pool to start next side bet pool
            // payable(admin).transfer((sideBetPrizePool - getSideBetPool() * 50) / 100);
            paymentToken.transferFrom(address(this), admin, ((sideBetPrizePool - getSideBetPool() * 50) / 100));
        }

        // Pay the house it's cut for future game investment
        // payable(admin).transfer((gamePrizePool * houseCut) / 100);
        paymentToken.transferFrom(address(this), admin, ((gamePrizePool * houseCut) / 100));

        // Setup the next Game
        costToPlay = newCostPerPlayer * 10**18;
        playerLimit = neWTotalPlayerLimit;
        gamePurses = purses;
        sideBetCost = newSideBetCost * 10**18;
        gamePrizePool = 0;

        resetDiceGame();

        gameNumber = gameNumber + 1;
    }

    function adminUpdateGame(uint newCostPerPlayer,uint neWTotalPlayerLimit, uint256[3] calldata purses, uint newSideBetCost) public onlyOwner {
        // Setup the next Game
        costToPlay = newCostPerPlayer * 10**18;
        playerLimit = neWTotalPlayerLimit;
        gamePurses = purses;
        sideBetCost = newSideBetCost * 10**18;
    }

    function resetDiceGame() internal {
        players = new address payable[](0);
        winnerAddresses = new address payable[](0);

        // Reset the mapping
        for (uint i=0; i< sideBets.length ; i++){
            sideBetsCheck[sideBetsPickedNumbers[i]] = 0;
        }
        sideBets = new address[](0);
        sideBetsPickedNumbers = new string[](0);
    }

    function pauseGame(bool isPaused, bool failSafe) public onlyOwner {
        require((failSafe == true), "ah ah ah, you didn't say the magic word!");
        gameIsPaused = isPaused;
    }

    function changeToken(address tokenContract) public onlyOwner {
        gpTokenContractAddress = tokenContract;
    }

    function emergencyWithdrawal(bool failSafe) public onlyOwner payable{
        require((failSafe == true), "ah ah ah, you didn't say the magic word!");
        // Transfer any GP and ETH out of contract in case we need to close and relaunch a new contract
        payable(admin).transfer(address(this).balance);
        paymentToken.transferFrom(address(this), admin, address(this).balance);
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        // return address(this).balance;
        return paymentToken.balanceOf(address(this));
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

    function getWinnings() public view returns (uint256[] memory){
        return winnerPurses;
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

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
}