/**
 *Submitted for verification at polygonscan.com on 2022-12-20
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/IDots.sol

pragma solidity ^0.8.7;

interface IDots {
    enum State {
        // not started yet
        Loading,
        Started,
        Paused,
        Completed
    }

    struct Dot {
        address owner;
        uint256 country;
        uint256 lastPrice;
    }

    struct Game {
        // treasury will be distributed to winners
        uint256 treasury;
        // the state of game
        State state;
        // grid size
        uint256 xWidth;
        // grid size
        uint256 yWidth;
        // increase rate
        uint256 epsilon;
        // every dot claim starts with this price
        uint256 claimBasePrice;
    }

    event Transfer(
        uint256 indexed gameIndex,
        uint256 y,
        uint256 x,
        uint256 price,
        uint256 oldPrice,
        uint256 indexed newCountry,
        uint256 oldCountry
    );

    event GameEnded(uint256 indexed gameIndex, uint256 indexed winnerCountry);
    event VestingSent(address indexed to, uint256 indexed vestingStake, uint256 amount);

    event GameStarted(
        uint256 indexed gameIndex,
        uint256 xWidth,
        uint256 yWidth,
        uint256 epsilon,
        uint256 claimBasePrice
    );
    event GamePaused(uint256 indexed gameIndex);
    event GameResumed(uint256 indexed gameIndex);
    event NewCountriesAdded(uint256 indexed newNumberOfCountries);

    error InvalidGame();
    error GameIsActive();
    error GameIsAlreadyStarted();
    error GameIsNotStarted();
    error GameIsNotPaused();
    error GameIsNotActive();
    error InsufficientBasePrice();
    error InsufficientPrice();
    error UndefinedCoordinates();
    error UndefinedCountry();
    error TxError();
    error NoVesting();

    function getGame(uint256 gameIndex) external view returns (Game memory);
}


// File contracts/VestingContract.sol

pragma solidity ^0.8.7;

abstract contract VestingContract is IDots {
    IDots public dotContract;
    mapping(uint256 => mapping(address => uint256)) public vestingStakes;

    constructor() {
        dotContract = IDots(address(this));
    }

    // @dev We need to keep track of each game's width and height
    function withdrawVesting(uint256 gameIndex) public {
        Game memory game = dotContract.getGame(gameIndex); // Get the information about the game
        if (game.state != State.Completed) revert GameIsActive(); // Check if the game is completed
        uint256 vestingStake = vestingStakes[gameIndex][msg.sender];
        if (vestingStake <= 0) revert NoVesting();
        uint256 totalVestingAmount = game.treasury;
        vestingStakes[gameIndex][msg.sender] = 0;
        uint256 totalValue = (vestingStake * totalVestingAmount) / (game.yWidth * game.xWidth);
        //solhint-disable-next-line
        (bool success, ) = payable(msg.sender).call{ value: totalValue }("");
        if (!success) revert TxError();
        emit VestingSent(msg.sender, vestingStake, totalValue);
    }
}


// File contracts/Dots.sol

pragma solidity ^0.8.7;



contract Dots is IDots, Ownable, VestingContract {
    // current game
    uint256 public activeGameIndex;
    // gameID => country => numberOfDotsOccupiedByCountry
    mapping(uint256 => mapping(uint256 => uint256)) public numberOfDotsOccupiedByCountry;

    // gameID => Y index => X index => Dot
    mapping(bytes32 => Dot) public dots;

    // split every games accounting
    mapping(uint256 => Game) public games;
    // how many country do we have,
    // Countries starts from 1, 0 is Nulland
    uint256 public numberOfCountries = 20;

    function claimLocation(
        uint256 y,
        uint256 x,
        uint256 country
    ) public payable {
        uint256 gameIndex = activeGameIndex;
        bytes32 dotIndex = getDotIndex(activeGameIndex, y, x);
        Dot memory dotMemory = dots[dotIndex];
        Game memory gameMemory = games[gameIndex];

        // check state of current game
        if (gameMemory.state != State.Started) revert GameIsNotActive();
        //check for first claim
        if (msg.value < gameMemory.claimBasePrice) revert InsufficientBasePrice();
        // check for reclaims
        if (msg.value < dotMemory.lastPrice + gameMemory.epsilon) revert InsufficientPrice();
        // validate coordinates
        if (x > gameMemory.xWidth - 1 || y > gameMemory.yWidth - 1) revert UndefinedCoordinates();
        // validate country
        if (country == 0 || country > numberOfCountries) revert UndefinedCountry();

        address lastOwner = dotMemory.owner;
        //decrement number of dot for current country
        if (numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] > 0) {
            numberOfDotsOccupiedByCountry[gameIndex][dotMemory.country] -= 1;
        }
        // increment number of dot for current country
        numberOfDotsOccupiedByCountry[gameIndex][country] += 1;

        Dot storage dot = dots[dotIndex];
        Game storage game = games[gameIndex];

        dot.lastPrice = msg.value;
        dot.owner = msg.sender;
        dot.country = country;

        emit Transfer(gameIndex, y, x, msg.value, dotMemory.lastPrice, country, dotMemory.country);

        //game over if one country claimed every point
        if (numberOfDotsOccupiedByCountry[gameIndex][country] == (gameMemory.xWidth * gameMemory.yWidth)) {
            activeGameIndex++;
            game.state = State.Completed;
            emit GameEnded(gameIndex, country);
        }

        // if it is first claim, claimBasePrice goes to treasury

        if (lastOwner == address(0)) {
            game.treasury += msg.value;
            vestingStakes[activeGameIndex][msg.sender] += 1;
        } else {
            // if it is reclaim, send claimers money to older claimer
            // ex: claimed for 1000 eth, then reclaimer claimed for a 2000 eth
            // then send 2000 eth (- %0.1 fee) to older claimer
            game.treasury += msg.value / 1000;
            vestingStakes[activeGameIndex][msg.sender] += 1;
            vestingStakes[activeGameIndex][lastOwner] -= 1;
            //solhint-disable-next-line
            (bool success, ) = payable(lastOwner).call{ value: (msg.value * 999) / 1000 }("");
            if (!success) revert TxError();
        }
    }

    // start the active game
    function startGame(
        uint256 xWidth,
        uint256 yWidth,
        uint256 claimBasePrice,
        uint256 epsilon
    ) external onlyOwner {
        if (games[activeGameIndex].state != State.Loading) revert GameIsAlreadyStarted();
        games[activeGameIndex] = Game({
            xWidth: xWidth,
            yWidth: yWidth,
            epsilon: epsilon,
            claimBasePrice: claimBasePrice,
            treasury: 0,
            state: State.Started
        });
        emit GameStarted(activeGameIndex, xWidth, yWidth, epsilon, claimBasePrice);
    }

    // pause the active game
    function pauseGame() external onlyOwner {
        if (games[activeGameIndex].state != State.Started) revert GameIsNotStarted();

        games[activeGameIndex].state = State.Paused;
        emit GamePaused(activeGameIndex);
    }

    // resume the active game
    function resumeGame() external onlyOwner {
        if (games[activeGameIndex].state != State.Paused) revert GameIsNotPaused();

        games[activeGameIndex].state = State.Started;
        emit GameResumed(activeGameIndex);
    }

    function setNumberOfCountries(uint256 _numberOfCountries) external onlyOwner {
        numberOfCountries = _numberOfCountries;
        emit NewCountriesAdded(_numberOfCountries);
    }

    function getGame(uint256 gameIndex) external view override returns (Game memory) {
        return games[gameIndex];
    }

    function getDotIndex(
        uint256 gameIndex,
        uint256 y,
        uint256 x
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(gameIndex, y, x));
    }
}