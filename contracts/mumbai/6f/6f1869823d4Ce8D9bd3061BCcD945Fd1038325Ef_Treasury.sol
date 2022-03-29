pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./models/Game.sol";

contract Treasury is Ownable, ReentrancyGuard {
    uint public WIN_FEE = 3.5 ether;
    uint public LOSE_FEE = 7 ether;
    uint public TOTAL_PERCENTAGE = 100 ether;
    uint public MAX_WAGER = 250 ether;
    uint public NFT_FEE = 42 ether;
    uint public VAULT_FEE = 58 ether;
    uint public DEFAULT_BALANCE = 100 ether;

    bool public TAKE_FEE;
    bool public DOUBLE_RETURN;

    address public TREASURY_OWNER;
    address public TEAM_VAULT;
    address public NFT_VAULT;

    uint public TeamVaultBalance;
    uint public NFTVaultBalance;
    uint public FeeBalance;

    uint public GameIndexer;

    mapping(uint => Game) public Games;
    mapping(address => uint) NFTPerAddress;
    mapping(address => uint) ClaimedNFTFee;

    event GameWagerSet(uint gameId, uint wager);
    event GameStateSet(uint gameId, uint state);
    event GameEnded(uint gameId, uint gameResult);
    event Received(address sender, uint value);

    /**
     * @dev Modifier to give TREASURY_OWNER access to specific functions
    */
    modifier TreasuryOwner() {
        require(TREASURY_OWNER == _msgSender(), "Error: Sender is not the treasury owner");
        _;
    }

    constructor(
        address _treasuryOwner,
        address _teamVault,
        address _nftVault,
        uint _defaultBalance)
    {
        TREASURY_OWNER = _treasuryOwner;
        TEAM_VAULT = _teamVault;
        NFT_VAULT = _nftVault;

        DOUBLE_RETURN = false;
        TAKE_FEE = true;

        DEFAULT_BALANCE = _defaultBalance;
    }

    /**
     * @dev Receive ChainToken when Treasury is running low
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Owner function for setting MAX_WAGER value
     * @param _newWager the new MAX_WAGER value
    */
    function SetMaxWager(uint _newWager) onlyOwner() external {
        MAX_WAGER = _newWager;
    }

    /**
     * @dev Owner function for setting TREASURY OWNER
     * @param _newOwner new address of treasury
    */
    function SetTreasuryOwner(address _newOwner) onlyOwner() external {
        TREASURY_OWNER = _newOwner;
    }

    /**
     * @dev Owner function for setting TEAM_VAULT
     * @param _newVault new address of TEAM_VAULT
    */
    function SetTeamVault(address _newVault) onlyOwner() external {
        TEAM_VAULT = _newVault;
    }

    /**
     * @dev Owner function for setting NFT_VAULT
     * @param _newVault new address of NFT_VAULT
    */
    function SetNFTVault(address _newVault) onlyOwner() external {
        NFT_VAULT = _newVault;
    }

    /**
     * @dev Owner function for setting DEFAULT_BALANCE
     * @param _newBalance set DEFAULT_BALANCE
    */
    function SetDefaultBalance(uint _newBalance) onlyOwner() external {
        require(_newBalance > DEFAULT_BALANCE, "Error: Default balance must be greater than current balance");
        DEFAULT_BALANCE = _newBalance;
    }

    /**
     * @dev Owner function for toggling DOUBLE_RETURN
    */
    function ToggleDoubleReturn() onlyOwner() external returns(bool) {
        DOUBLE_RETURN = !DOUBLE_RETURN;
        return DOUBLE_RETURN;
    }

    /**
     * @dev Owner function for toggling TAKE_FEE
    */
    function ToggleTakeFee() onlyOwner() external returns(bool) {
        TAKE_FEE = !TAKE_FEE;
        return TAKE_FEE;
    }

    /**
     * @dev Owner function to distribute the fees back to the NFTVault and TeamVault
    */
    function DistributeFees() nonReentrant onlyOwner() external {
        require(TAKE_FEE == true, "Error: Take Fee is not enabled");
        require(FeeBalance > 0, "Error: Fee balance is 0");
        require(address(this).balance > 0, "Error: Treasury balance is 0");
        require(address(this).balance >= FeeBalance, "Error: Treasury balance is less than fee balance");

        uint leftFeeBalance = address(this).balance - FeeBalance;

        // Distribute what's left to Team and NFT vaults
        uint teamVault = leftFeeBalance * VAULT_FEE / TOTAL_PERCENTAGE;
        uint nftVault = leftFeeBalance * NFT_FEE / TOTAL_PERCENTAGE;
        // Add balance to TeamVault
        TeamVaultBalance += teamVault;
        // Add balance to NFTVault
        NFTVaultBalance += nftVault;
    }

    /**
     * @dev Owner function for transferring the TeamVaultBalance to the TEAM_VAULT Address
    */
    function WithdrawTeamVault() nonReentrant onlyOwner() external {
        require(TeamVaultBalance > 0, "Error: TeamVaultBalance is 0");
        uint teamVault = TeamVaultBalance;
        TeamVaultBalance = 0;
        (bool success, ) = TEAM_VAULT.call{value:teamVault}('Transfer TeamVaultBalance balance to TEAM_VAULT');
        require(success, "Error: Transfer to TEAM_VAULT failed");
    }

    /**
     * @dev Owner function for resetting Treasury balance to DEFAULT_BALANCE
    */
    function SetTreasuryBalanceToDefault() nonReentrant onlyOwner() external {
        require(address(this).balance > 0, "Error: Treasury is 0");
        require(address(this).balance >= DEFAULT_BALANCE, "Error: Treasury balance is less than default balance");
        uint treasuryBalance = address(this).balance - DEFAULT_BALANCE;
        (bool success, ) = TEAM_VAULT.call{value:treasuryBalance}('Transfer treasuryBalance to TEAM_VAULT');
        require(success, "Error: Transfer to TEAM_VAULT failed");
    }

    /**
     * @dev Function for checking if a game exists and return Game
     * @param _gameId the id of the game
     * @return Game
    */
    function GetGame(uint _gameId) nonReentrant external returns(Game memory) {
        _validGame(_gameId);
        _requireState(_gameId, 1); // game state 1: wager set
        return Games[_gameId];
    }

    /**
     * @dev Function to start a game and set wager
     * @param _gameAction action that player plays: 0 ROCK, 1 PAPER, 2 SCISSOR
     * @return gameId the new gameId for player
    */
    function SetWager(uint _gameAction) nonReentrant external payable returns(uint gameId) {
        require(address(_msgSender()).balance >= msg.value, "Error: Not enough ChainToken in wallet");
        require(msg.value > 0, "Error: Can't set 0 as wager");
        require(msg.value <= MAX_WAGER, "Error: Wager can't be more than MAX_WAGER");

        GameIndexer += 1;
        gameId = GameIndexer;
        Games[gameId].Id = gameId;
        Games[gameId].PlayerAddress = _msgSender();
        Games[gameId].Wager = msg.value;
        Games[gameId].Result = 0; // unknown result
        Games[gameId].State = 1; // wager is set
        Games[gameId].GameAction = _gameAction;
        Games[gameId].Exists = true;

        // Emit GameWagerSet
        emit GameWagerSet(gameId, Games[gameId].Wager);
        emit GameStateSet(gameId, 1);
        return gameId;
    }

    /**
     * @dev TreasuryOwner function for updating the game
     * When player loses, update the state of the game in this function
     * This way the player does not have to call the GameResult function = les gas
     * @param _gameId the id of the game
     * @param _result the result of the game
     * @return gameId the gameId
    */
    function UpdateGame(uint _gameId, uint _result) TreasuryOwner() nonReentrant external returns(uint) {
        _validGame(_gameId);
        _requireState(_gameId, 1);  // game state 1: wager set

        // Congratulations
        if (_result == 0) {
            Games[_gameId].Result = 1;
            Games[_gameId].State = 2; // game updated
            emit GameStateSet(_gameId, 2);
        } else if (_result == 1) {
            // The dev team wins :)
            Games[_gameId].Result = 2;
            // When the contract balance is running low, and TAKE_FEE is set to false
            // the gameFee wont be transferred to the Team and NFT vault, so we can keep the game running
            uint gameFee = Games[_gameId].Wager * LOSE_FEE / TOTAL_PERCENTAGE;
            if (TAKE_FEE) {
                // Add balance to TeamVault and NFTVault
                // Doing this here so player doesn't have to pay gas when they lose
                uint teamVault = gameFee * VAULT_FEE / TOTAL_PERCENTAGE;
                uint nftVault = gameFee * NFT_FEE / TOTAL_PERCENTAGE;
                // Add balance to TeamVault
                TeamVaultBalance += teamVault;
                // Add balance to NFTVault
                NFTVaultBalance += nftVault;
            } else {
                // Add to FeeBalance to keep track of Fees that stays in the Treasury contract
                FeeBalance += gameFee;
            }

            // update game state
            Games[_gameId].State = 3; // game ended
            emit GameStateSet(_gameId, 3); // game ended
            emit GameEnded(_gameId, Games[_gameId].Result);
        } else if (_result == 2) {
            // besTIEs
            Games[_gameId].Result = 3;
            Games[_gameId].State = 2; // game updated
            emit GameStateSet(_gameId, 2);
        }

        return _gameId;
    }

    /**
     * @dev When a player wins or result is tie. Player calls this function for doubling or return the wager
     * @param _gameId the id of the game
     * @return gameId the gameId
    */
    function GameResult(uint _gameId) nonReentrant external returns(uint) {
        require(Games[_gameId].PlayerAddress == _msgSender(), "Error: Sender is not player of the game");
        _validGame(_gameId);
        _requireState(_gameId, 2); // game state 2: game updated

        uint wager = Games[_gameId].Wager;
        // Player doubles the money :)
        if (Games[_gameId].Result == 1) {
            uint result = wager * 2;

            // DOUBLE THE MONEY: LFG
            if (DOUBLE_RETURN) {
                result *= 2;
            }

            uint gameFee = result * WIN_FEE / TOTAL_PERCENTAGE;
            uint fromTreasury = result - gameFee;

            require(address(this).balance >= fromTreasury, "Error: Not enough ChainToken in contract for payout");
            (bool success, ) = Games[_gameId].PlayerAddress.call{value:fromTreasury}('Transfer back double wager');
            require(success, "Error: Returning back wager to player failed");
        } else if (Games[_gameId].Result == 3) {
            // Better luck next time for both of us
            (bool success, ) = Games[_gameId].PlayerAddress.call{value:wager}('Transfer back wager');
            require(success, "Error: Returning back wager to player failed");
        }

        Games[_gameId].State = 3; // game ended

        emit GameStateSet(_gameId, 3); // game ended
        emit GameEnded(_gameId, Games[_gameId].Result);
        return _gameId;
    }

    /**
     * @dev Private function to check if game exists
     * @param _gameId the id of the game
    */
    function _validGame(uint _gameId) private {
        require(Games[_gameId].Exists, "Error: Game doesn't exist");
    }

    /**
     * @dev Private function to check if game has the right state for execution
     * @param _gameId the id of the game
     * @param _step the required state of the game
    */
    function _requireState(uint _gameId, uint _step) private {
        require(Games[_gameId].State == _step, "Error: Game state don't match");
    }
}

pragma solidity ^0.8.12;

struct Game{
    uint Id;
    address PlayerAddress;
    uint Result; // 0 unknown, 1 win, 2 lose, 3 tie
    uint GameAction; // 0 ROCK, 1 PAPER, 2 SCISSORS
    uint Wager;
    uint State; // 0 init, 1 wager set, 2 results set, 3 game played
    bool Exists;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}