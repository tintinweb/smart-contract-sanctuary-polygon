//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISummitRNGModule.sol";



/*
---------------------------------------------------------------------------------------------
--   S U M M I T . D E F I
---------------------------------------------------------------------------------------------


Summit is highly experimental.
It has been crafted to bring a new flavor to the defi world.
We hope you enjoy the Summit.defi experience.
If you find any bugs in these contracts, please claim the bounty (see docs)


Created with love by Architect and the Summit team





---------------------------------------------------------------------------------------------
--   C U S T O M V R F
---------------------------------------------------------------------------------------------


It is also responsible for requesting and receiving the trusted seeds, as well as their decrypted versions after the future block is mined


RANDOM NUMBER GENERATION
    . Webservice queries `nextSeedRoundAvailable` every 5 seconds
    . When true received
    . Webservice creates a random seed, seals it with the trustedSeeder address, and sends it to `receiveSealedSeed`
    . When the futureBlockNumber set in `receiveSealedSeed` is mined, `futureBlockMined` will return true
    . Webservice sends the original unsealed seed to `receiveUnsealedSeed`
*/

contract SummitTrustedSeederRNGModule is Ownable, ISummitRNGModule {
    // ---------------------------------------
    // --   V A R I A B L E S
    // ---------------------------------------
    
    address public cartographer;                                            // Allows cartographer to act as secondary owner-ish
    address public trustedSeeder;                                           // Submits trusted sealed seed when round locks 60 before round end
    address public elevationHelper;                                         // ElevationHelper address
    
    uint256 constant baseRoundDuration = 3600;                              // Duration (seconds) of the smallest round chunk

    uint256 public seedRoundEndTimestamp;                                          // Timestamp the first seed round ends
    uint256 constant seedRoundDurationMult = 1;
    uint256 public seedRound = 0;                                                  // The sealed seed is generated at the top of every hour
    mapping(uint256 => bytes32) sealedSeed;                                 // Sealed seed for each seed round, provided by trusted seeder webservice                                              
    mapping(uint256 => bytes32) unsealedSeed;                               // Sealed seed for each seed round, provided by trusted seeder webservice                                              
    mapping(uint256 => uint256) futureBlockNumber;                          // Future block number for each seed round
    mapping(uint256 => bytes32) futureBlockHash;                            // Future block hash for each seed round


    event SetElevationHelper(address _elevationHelper);
    event SetTrustedSeederAdd(address _trustedSeeder);
    event SetSeedRoundEndTimestamp(uint256 _seedRoundEndTimestamp);



    // ---------------------------------------
    // --   M O D I F I E R S
    // ---------------------------------------

    modifier onlyCartographer() {
        require(msg.sender == cartographer, "Only cartographer");
        _;
    }
    modifier onlyElevationHelper() {
        require(msg.sender != address(0), "ElevationHelper not defined");
        require(msg.sender == elevationHelper, "Only elevationHelper");
        _;
    }
    modifier onlyTrustedSeeder() {
        require(msg.sender == trustedSeeder, "Only trusted seeder");
        _;
    }

    
    // ---------------------------------------
    // --   I N I T I A L I Z A T I O N
    // ---------------------------------------

    /// @dev Creates SummitRandomnessModule contract with cartographer as owner of certain functionality
    /// @param _cartographer Address of main Cartographer contract
    constructor(address _cartographer) {
        require(_cartographer != address(0), "Cartographer missing");
        cartographer = _cartographer;
    }


    /// @dev Set elevationHelper
    /// @param _elevationHelper Address of ElevationHelper contract
    function setElevationHelper(address _elevationHelper)
        public onlyOwner
    {
        require(_elevationHelper != address(0), "ElevationHelper missing");
        elevationHelper = _elevationHelper;
        emit SetElevationHelper(_elevationHelper);
    }


    /// @dev Update trusted seeder
    /// @param _trustedSeeder Address of trustedSeeder
    function setTrustedSeederAdd(address _trustedSeeder)
        public onlyOwner
    {
        require(_trustedSeeder != address(0), "Trusted seeder missing");
        trustedSeeder = _trustedSeeder;
        emit SetTrustedSeederAdd(_trustedSeeder);
    }
    

    /// @dev Update seedRoundEndTimestamp
    /// @param _seedRoundEndTimestamp amount of seedRoundEndTimestamp
    function setSeedRoundEndTimestamp(uint256 _seedRoundEndTimestamp) public override onlyElevationHelper {
        seedRoundEndTimestamp = _seedRoundEndTimestamp;
        emit SetSeedRoundEndTimestamp(_seedRoundEndTimestamp);
    }

    

    // ------------------------------------------------------------------
    // --   R A N D O M N E S S   S E E D I N G
    // ------------------------------------------------------------------


    // Flow of seeding:
    // Webservice queries `nextSeedRoundAvailable` every 5 seconds
    // When true received
    // Webservice creates a random seed, seals it with the trustedSeeder address, and sends it to `receiveSealedSeed`
    // When the futureBlockNumber set in `receiveSealedSeed` is mined, `futureBlockMined` will return true
    // Webservice sends the original unsealed seed to `receiveUnsealedSeed`


    /// @dev Whether the future block has been mined, allowing the unencrypted seed to be received
    function futureBlockMined() public view returns (bool) {
        return sealedSeed[seedRound] != "" &&
            block.number > futureBlockNumber[seedRound] &&
            unsealedSeed[seedRound] == "";
    }


    /// @dev Seed round locked
    function nextSeedRoundAvailable() public view returns (bool) {
        return block.timestamp >= seedRoundEndTimestamp;
    }


    /// @dev Get random number 0-99 inclusive
    function getRandomNumber(uint8 elevation, uint256 roundNumber) public view override returns (uint256) {
        return uint256(keccak256(abi.encode(elevation, roundNumber, unsealedSeed[seedRound], futureBlockHash[seedRound]))) % 100;
    }


    /// @dev When an elevation reaches the lockout phase 60s before rollover, the sealedseed webserver will send a seed
    /// If the webserver goes down (99.99% uptime, 3 outages of 1H each over 3 years) the randomness is still secure, and is only vulnerable to a single round of withheld block attack
    /// @param _sealedSeed random.org backed sealed seed from the trusted address, run by an autonomous webserver
    function receiveSealedSeed(bytes32 _sealedSeed)
        public
        onlyTrustedSeeder
    {
        require(nextSeedRoundAvailable(), "Already sealed seeded");

        // Increment seed round and set next seed round end timestamp
        seedRound += 1;
        seedRoundEndTimestamp += (baseRoundDuration * seedRoundDurationMult);

        // Store new sealed seed for next round of round rollovers
        sealedSeed[seedRound] = _sealedSeed;
        futureBlockNumber[seedRound] = block.number + 1;
    }


    /// @dev Receives the unencrypted seed after the future block has been mined
    /// @param _unsealedSeed Unencrypted seed
    function receiveUnsealedSeed(bytes32 _unsealedSeed)
        public
        onlyTrustedSeeder
    {
        require(unsealedSeed[seedRound] == "", "Already unsealed seeded");
        require(futureBlockMined(), "Future block not reached");
        require(keccak256(abi.encodePacked(_unsealedSeed, msg.sender)) == sealedSeed[seedRound], "Unsealed seed does not match");
        unsealedSeed[seedRound] = _unsealedSeed;
        futureBlockHash[seedRound] = blockhash(futureBlockNumber[seedRound]);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;


interface ISummitRNGModule {
    function getRandomNumber(uint8 elevation, uint256 roundNumber) external view returns (uint256);
    function setSeedRoundEndTimestamp(uint256 _seedRoundEndTimestamp) external;
}

// SPDX-License-Identifier: MIT

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