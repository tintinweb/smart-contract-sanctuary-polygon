/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;



interface IUserProfiles {
    // Updates the amount of tokens an address has won based on the token
    function updateTokensWon(address usrAddress, string memory token, uint256 amount) external;

    // Returns an array of token names that the address has won
    function getTokensWon(address usrAddress) external returns(string[] memory);

    // Returns the total amount of tokens won by token type for a given address
    function getTokensWonAmount(address usrAddress, string calldata token) external returns(uint256);

    // Updates the amount of tokens an address has received from a referral based on the token and referral level [Level0, Level1, Level2]
    function updateGamesPlayed(address usrAddress, uint256 gameID) external;

    // Returns an array of game IDs that an address has played
    function getGamesPlayed(address usrAddress) external returns(uint256[] memory);

    // Returns the amount of games played by an address based on game ID
    function getGamesPlayedAmount(address usrAddress, uint256 gameID) external returns(uint256);

    // Updates the Avatar field stored in the user profile with an image URI
    function updateAvatar(address usrAddress, string calldata _uri) external;

    // Updates the Avatar field stored in the senders profile with an image URI
    function updateMyAvatar(string calldata _uri) external;

    // Updates the URI field stored in the user profile
    function updateURI(address usrAddress, string calldata _uri) external;

    // Updates the URI field stored in the senders profile
    function updateMyURI(string calldata _uri) external;

    // Updates the Bio field stored in the user profile
    function updateBio(address usrAddress, string calldata _bio) external;

    // Updates the Bio field stored in the senders profile
    function updateMyBio(string calldata _bio) external;

    // Returns the URI of an avatar from an address profile
    function getAvatar(address usrAddress) external returns(string memory);

    // Returns the Bio from an address profile
    function getBio(address usrAddress) external returns(string memory);

    // Returns the URI from an address profile
    function getURI(address usrAddress) external returns(string memory);
}
// File: contracts/interfaces/IUserReferrals.sol


pragma solidity ^0.8.2;

interface IUserReferrals {
    // Adds a referral (and their sub referrals) to their referral array in the users profile
    function addReferrer(address usrAddress, address _referrer) external;

    // Returns an array(3) of addresses of who referred and address [Level0, Level1, Level2]
    function getReferrers(address usrAddress) external returns(address[] memory);

    // Returns an array(3) of the amount of referrals an address has received by level [Level0, Level1, Level2]
    function getReferralCount(address usrAddress) external returns(uint256[] memory);

    // Updates the amount of tokens an address has received from a referral based on the token and referral level [Level0, Level1, Level2]
    function updateReferralTokensAmount(address usrAddress, string memory token, uint256 _level, uint256 amount) external;

    // Returns an array of token names that the address has been awarded Referral Tokens for
    function getReferralTokens(address usrAddress) external returns(string[] memory);

    // Returns an array of token amounts based on referral level (0,1,2) that the address has been awarded Referral Tokens for
    function getReferralTokensAmount(address usrAddress, string memory token) external returns(uint256[] memory);
}
// File: contracts/interfaces/ITokens.sol


pragma solidity ^0.8.0;

interface ITokens {
    // Mints a new token
    function mint(address sendTo, uint256 seed) external returns(uint256);

    // Claims all mints that have been awarded and not yet claimed
    function claimMints(address claimee) external;

    // Returns total remaining token amount available to mint
    function tokensRemaining() external returns(uint256);

    // Return an array of Token IDs that are available to claim by address
    function mintsToClaim(address winner) external returns(uint256[] memory);

    // Return an array of Token IDs that have been minted by owner address
    function tokensMintedByOwner(address winner) external returns (uint256[] memory);

    // Returns the URI to the token Metadata
    function tokenURI(uint256 _tokenID) external returns(string memory);

    // Returns the total number of tokens that are in the collection
    function getTotalTokensInCollection() external returns(uint256);
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: contracts/SurfsUp.sol









contract DrownTheClown is ReentrancyGuard {

    /*

    EVENTS

    */

    // Write out the round number, winner address, won amount
    event RoundWinner(uint256 roundNumber, address winnerAddress, uint256 winningAmount);


    // NFT Won (ground number, nft token id);
    event RoundNFTAwarded(uint roundNumber, uint tokenID);

    event Received(address, uint);
    event PlayerSPWin(address, uint);
    event PlayerClaim(address, uint);


    // Contract address for User Profile Data
    IUserProfiles public userProfiles;

    // Contract address for User Referral Data
    IUserReferrals public userReferrals;

    // Contract address for User Referral Data
    ITokens public tokens;

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    // Set the game ID
    uint256 gameID = 5;
    string public gamePaymentToken = "MATIC";


    address[] private players;
    address public admin;

    mapping(address => uint256) balanceOf;

    uint256 public costToPlay;
    uint256 public playerLimit;
    uint256 public sideBetCost;
    uint256 public gbarsEmit;
    uint256[3] private gamePurses;
    address[] private winnerAddresses;
    address[] private lastWinnerAddresses;
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
    uint256[] private winnerSelector;

    // Set the game availability
    bool gameIsPaused = false;


    IERC20 public gbarsToken;


    constructor(IERC20 _gbarsToken, uint256 _costToPlay, uint256 _playerLimit, uint256 _sideBetCost, uint256 _gbarsEmit, uint256[3] memory _gamePurses, address _userProfiles, address _userReferrals, address _tokens) {
        admin = msg.sender;
        gbarsToken = IERC20(_gbarsToken);
        costToPlay = _costToPlay;
        playerLimit = _playerLimit;
        sideBetCost = _sideBetCost;
        gbarsEmit = _gbarsEmit;
        gamePurses = _gamePurses;

        userProfiles = IUserProfiles(_userProfiles);
        userReferrals = IUserReferrals(_userReferrals);
        tokens = ITokens(_tokens);
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }


    function joinGame() public payable nonReentrant {

        // Make sure the game is not paused
        require(gameIsPaused == false , "Game is paused.");

        // Transfer the Payment Token to the contract
        require(msg.value == costToPlay, "Incorrect payment amount");

        // Limit players to match
        require(players.length < playerLimit, "This match has reached the player limit");

        // Add the person who sent the Payment Token to the players array
        players.push(msg.sender);

        // Add the Payment Token to the gamePrizePool
        gamePrizePool += costToPlay;

        // Update the user's global profile with amount of games played
        userProfiles.updateGamesPlayed(msg.sender, gameID);
    }

    function placeSideBet(uint256 bet1, uint256 bet2, uint256 bet3) public payable nonReentrant {

        // Make sure the game is not paused
        require(gameIsPaused == false , "Game is paused.");

        // require that the sender sends exact Payment Token Amount
        require(msg.value == sideBetCost, "Incorrect payment amount");

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

        // Make sure there's alway more than 3 players (bad things may happen)
        require(newTotalPlayerLimit > 3, "Need more than 3 players for a game");

        // Reset TriWinners for new game
        delete triWinners;
        winnerPurses = new uint256[](0);
        sideBetWinner = address(0);

        address winner;
        address firstPlace;

        uint256 tokenWon = 0;

        winnerSelector = new uint256[](0);

        // build the winner selector array
        for (uint256 i = 0; i < players.length; i++) {
            winnerSelector.push(i);
        }

        // Get all the NFTs they won and see if they've been awarded
        for (uint256 i = 0; i < 3; i++) {

            // Get the winner spot
            uint256 randomWinnerSpot = random(winnerSelector.length, seed);
            uint256 randomWinnerID = winnerSelector[randomWinnerSpot];

            // Get the winner address from the players array and add to winnners list
            winner = players[randomWinnerID];
            winnerAddresses.push(winner);

            if (i < 2){
                // Replace the spot that one with the one on the end of the array
                winnerSelector[randomWinnerSpot] = winnerSelector[winnerSelector.length-1];

                // Remove the last element but save the last so we don't run out of gas
                winnerSelector.pop();

                // Increment the seed for randomness
                seed += 1;
            }

            // Update the triWinners for Super Pool
            if (winnerAddresses.length < 3){
                triWinners = append(triWinners,Strings.toString(randomWinnerID),",","","");
            } else {
                triWinners = append(triWinners,Strings.toString(randomWinnerID),"","","");
            }
        }

        delete winnerSelector;

        // Initialize the house cut
        uint256 houseCut = gamePrizePool;

        for (uint i = 0; i <= gamePurses.length - 1; i++) {
            if (gamePurses[i] > 0){

                uint256 winningAmount = (gamePrizePool * gamePurses[i]) / 100;

                uint256 totalPaidAfterRef = 0;

                // Pay the referrals if there are any and update the winning amount as adjusted
                (winningAmount, totalPaidAfterRef, houseCut) = payReferrals(winningAmount, winnerAddresses[i], 90);

                // Update winners balance
                balanceOf[winnerAddresses[i]] +=  winningAmount;
                totalPaymentTokenWon += totalPaidAfterRef;

                // Update the user's global profile with their winnings
                userProfiles.updateTokensWon(winnerAddresses[i], gamePaymentToken, winningAmount);

                // Keep track of the winning amount per winner
                winnerPurses.push(winningAmount);

                // Log the winner + amount won
                emit RoundWinner(gameNumber, winnerAddresses[i], winningAmount);
            }
        }

        // Pay the house it's cut for future game investment
        Address.sendValue(payable(admin), houseCut);

        // Set 1st place winner for NFT
        firstPlace = winnerAddresses[0];

        // Update the array of winners until next game
        lastWinnerAddresses = winnerAddresses;
        lastPlayerAddresses = players;

        // Get the winner of the side bet if there is one
        if (sideBetsCheck[triWinners] > 0){

            // have to -1 since length of array is value above. Need to be above 0 for resetting (triWinners)
            sideBetWinner = sideBets[sideBetsCheck[triWinners] - 1];

            // Update side bet winners balance from func that returns 80% of total pool
            uint256 winSideBetPoolBal = getSideBetPool();

            uint256 totalPaidAfterRef = 0;

            // Set the side bet prize pool to 10% of the total value to reserve to the side
            uint256 newSideBetPrizePool = (sideBetPrizePool / 10);

            // House cut starts at 10%
            houseCut = newSideBetPrizePool;

            // Pay the referrals if there are any and update the winning amount as adjusted
            (winSideBetPoolBal, totalPaidAfterRef, houseCut) = payReferrals(winSideBetPoolBal, sideBetWinner, 90);

            // Pay out the winner
            balanceOf[sideBetWinner] +=  winSideBetPoolBal;

            // Add the total paid out
            totalPaymentTokenSideBetWon += totalPaidAfterRef;

            // Initialize the new prie pool
            sideBetPrizePool = newSideBetPrizePool;

            Address.sendValue(payable(admin), houseCut);

            // Send the event
            emit PlayerSPWin(sideBetWinner, winSideBetPoolBal);
        }

        // Transfer GBars to players
        for (uint i = 0; i < players.length; i++) {

            // Update the players GBAR balance to claim
            gbarsToken.transfer(players[i], gbarsEmit);

            // Update the total amount of GBAR gifted
            totalGBarGifted = totalGBarGifted + gbarsEmit;
        }

        // Setup the next Game
        costToPlay = newCostPerPlayer;
        playerLimit = newTotalPlayerLimit;
        gamePurses = purses;
        sideBetCost = newSideBetCost;
        delete gamePrizePool;

        resetGame();

        gameNumber = gameNumber + 1;

        // Send the NFT if available last as to not get DoS'd
        if (tokens.tokensRemaining() > 0){
            tokenWon = tokens.mint(firstPlace, seed);
            emit RoundNFTAwarded(gameNumber, tokenWon);
        }

        
    }


    function payReferrals(uint256 winningAmount, address winner, uint256 percentOfTotalToPay) public returns(uint256, uint256, uint256){

        // Get the winners referrals
        address[] memory referrers = userReferrals.getReferrers(winner);

        // Initialize the total payout value
        uint256 totalPaidOut = winningAmount;

        // Add 10% back to the total amount to figure out the percentages to cut the referrers
        uint256 refCut = ((winningAmount * 10) / percentOfTotalToPay);

        uint256 totalPool = winningAmount + refCut;

        // Give referral bonuses if they have one
        if (referrers.length > 0) {

            // Same as (refCut * 0.015) without decimals
            uint256 refAmountWon = (refCut * 15) / 100;

            // Keep track of all payouts for total to return
            totalPaidOut = refAmountWon;

            // Pay the referrer their 1.5%
            balanceOf[referrers[0]] += refAmountWon;

            // Update the user's global profile with their referral winnings
            userProfiles.updateTokensWon(referrers[0], gamePaymentToken, refAmountWon);

            // Level 2
            if (referrers.length > 1){

                refAmountWon = (refCut * 75) / 1000;

                totalPaidOut += refAmountWon;

                // Pay the referrer their 1%
                balanceOf[referrers[1]] += refAmountWon;

                // Update the user's global profile with their referral winnings
                userProfiles.updateTokensWon(referrers[1], gamePaymentToken, refAmountWon);
            }

            // Level 3
            if (referrers.length > 2){

                refAmountWon = (refCut * 25) / 1000;

                totalPaidOut += refAmountWon;

                // Pay the referrer their 0.5%
                balanceOf[referrers[2]] += refAmountWon;

                // Update the user's global profile with their winnings
                userProfiles.updateTokensWon(referrers[2], gamePaymentToken, refAmountWon);

            }

            // Give player extra 2.5% back for having a referrer
            winningAmount = winningAmount += (refCut * 25) / 100;

            totalPaidOut += winningAmount;
        }

        return(winningAmount, totalPaidOut, (totalPool - totalPaidOut));
    }


    function adminUpdateGame(uint newCostPerPlayer,uint newTotalPlayerLimit, uint256[3] calldata purses, uint newSideBetCost) public onlyOwner {

        // Make sure we don't go under what we already have
        require(newTotalPlayerLimit >= players.length, "Player count must be greater than or equal to current amount of players registerd");

        // Setup the current Game
        costToPlay = newCostPerPlayer;
        playerLimit = newTotalPlayerLimit;
        gamePurses = purses;
        sideBetCost = newSideBetCost;
    }

    function resetGame() internal {
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

    function changeGbarsToken(IERC20 gbarsTokenContractAddress) public onlyOwner {
        gbarsToken = IERC20(gbarsTokenContractAddress);
    }

    function changeTokensContract(address _tokens) public onlyOwner {
        tokens = ITokens(_tokens);
    }

    function initializeSideBetPool(uint256 newSideBetPool) public onlyOwner {
        sideBetPrizePool = newSideBetPool;
    }

    function updateGBarsEmit(uint256 _gbarsEmit) public onlyOwner {
        gbarsEmit = _gbarsEmit;
    }

    function nukeItFromOrbit(bool failSafe) public onlyOwner nonReentrant {
        require((failSafe == true), "ah ah ah, you didn't say the magic word!");
        // Transfer any GBar and MATIC out of contract in case we need to close and relaunch a new contract
        // This is a pure "Nuke it from orbit" option in case exploit / massive bug is found and we need protect the assets.
        Address.sendValue(payable(admin), address(this).balance);
        gbarsToken.transfer(admin, gbarsToken.balanceOf(address(this)));
    }

    function claimWinnings() public nonReentrant {

        // Get the balance of GBAR to transfer
        //        uint256 gbarAmountToClaim = balanceOf[msg.sender];
        //        gbarBalanceOf[msg.sender] = 0;

        // Transfer the GBAR to the player
        //        gbarsToken.transfer(msg.sender, gbarAmountToClaim);

        // Get the amount to claim and set to zero before sending to prevent DOS
        uint256 amountToClaim = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        // Send the paymentToken winnings
        Address.sendValue(payable(msg.sender), amountToClaim);

        emit PlayerClaim(msg.sender, amountToClaim);

        // Claim the NFTs if they've won any
        uint256[] memory mintsToClaim = tokens.mintsToClaim(msg.sender);
        if (mintsToClaim.length > 0){
            tokens.claimMints(msg.sender);
        }
    }

    function getPaymentTokenOwed(address player) public view returns(uint256){
        return balanceOf[player];
    }

    //    function getGBAROwed(address player) public view returns(uint256){
    //        return gbarBalanceOf[player];
    //    }

    function isGamePaused() public view returns (bool) {
        return gameIsPaused;
    }

    function getTotalPlayers() public view returns (uint256){
        return players.length;
    }

    function getPlayers() public view returns (address[] memory){
        return players;
    }

    function getWinners() public view returns (address[] memory){
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