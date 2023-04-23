/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/ARandomness.sol

// contracts//ARandomness.sol
pragma solidity 0.8.7;

abstract contract ARandomness {
    function _verify(
        uint256 prime,
        uint256 iterations,
        uint256 proof,
        uint256 seed
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < iterations; ) {
            proof = mulmod(proof, proof, prime);
            unchecked {
                ++i;
            }
        }
        seed %= prime;
        if (seed == proof) return true;
        if (prime - seed == proof) return true;
        return false;
    }
}

// File contracts/interfaces/IDarthitectsWhitelistRaffle.sol

pragma solidity 0.8.7;

interface IDarthitectsWhitelistRaffle {
    // Events
    event NewClient(address indexed clientAddress, uint256 indexed blockNumber);
    event RaffleCreated(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RaffleActivated(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RaffleResumed(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RafflePaused(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RaffleCanceled(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RaffleClosed(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RaffleDrawed(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event RaffleCompleted(
        address indexed owner,
        bytes32 indexed id,
        uint256 indexed blockNumber
    );
    event NewRaffleParticipant(
        address indexed owner,
        bytes32 indexed id,
        address indexed participant,
        uint256 blockNumber
    );

    // structs
    enum RaffleStatus {
        UNDEFINED,
        PENDING_ACTIVATION,
        ACTIVE,
        PAUSED,
        PENDING_DRAW,
        PENDING_CONFIRMATION,
        COMPLETED,
        CANCELED
    }

    struct Raffle {
        uint256 prime;
        uint256 seed;
        uint256 startTime;
        uint256 endTime;
        uint16 iterations;
        uint16 maxParticipants;
        uint16 index;
        uint8 numOfWLSpots;
        uint8 status;
        mapping(address => bool) participantChecks;
        mapping(address => bool) winnerChecks;
        address[] participants;
        address[] winners;
        uint16[] ids;
        string logo;
        string banner;
        string description;
        string website;
    }

    struct RaffleView {
        uint256 prime;
        uint256 seed;
        uint256 startTime;
        uint256 endTime;
        uint16 iterations;
        uint16 maxParticipants;
        uint16 participantCount;
        uint8 numOfWLSpots;
        uint8 status;
        string logo;
        string banner;
        string description;
        string website;
    }

    struct RafflePublicView {
        uint256 startTime;
        uint256 endTime;
        uint16 maxParticipants;
        uint16 participantCount;
        uint8 numOfWLSpots;
        uint8 status;
        string logo;
        string banner;
        string description;
        string website;
    }

    struct RafflePublicStatus {
        uint16 participantCount;
        uint8 status;
    }

    // RAFFLE OWNER OPERATIONS

    /// @dev Create a new raffle / Edit non-activated raffle
    /// @param id Name of the raffle
    /// @param maxParticipants Name of the raffle
    /// @param numOfWLSpots Name of the raffle
    /// @param logo Name of the raffle
    /// @param banner Name of the raffle
    /// @param description Name of the raffle
    /// @param website Name of the raffle
    function create(
        bytes32 id,
        uint16 maxParticipants,
        uint8 numOfWLSpots,
        string calldata logo,
        string calldata banner,
        string calldata description,
        string calldata website
    ) external;

    // Activate the raffle
    function activate(
        bytes32 id,
        uint256 prime,
        uint16 iterations,
        uint256 proof,
        uint256 startTime,
        uint256 endTime
    ) external payable;

    // Resume Raffle Registrations
    function resume(bytes32 id) external;

    // Pause Raffle Registrations
    function pause(bytes32 id) external;

    // Close Raffle Registrations
    function close(bytes32 id) external payable;

    // Cancel Raffle
    function cancel(bytes32 id) external payable;

    // WL Distribution of Raffle Step 1
    function draw(bytes32 id) external payable;

    // WL Distribution of Raffle Step 2
    function confirm(bytes32 id, uint256 proof) external;

    // RAFFLE OWNER VIEWS
    function getMyRaffles() external view returns (bytes32[] memory);

    function getMyRaffle(bytes32 id) external view returns (RaffleView memory);

    // RAFFLE PARTICIPANT OPERATIONS
    function enter(address owner, bytes32 id) external;

    function enterStatus(
        address owner,
        bytes32 id
    ) external view returns (bool);

    function raffleResult(
        address owner,
        bytes32 id
    ) external view returns (bool);

    // PUBLIC VIEWS

    function getRaffle(
        address owner,
        bytes32 id
    ) external view returns (RafflePublicView memory);

    function getRaffleStatus(
        address owner,
        bytes32 id
    ) external view returns (RafflePublicStatus memory);

    function winners(
        address owner,
        bytes32 id
    ) external view returns (address[] memory);

    function isOwner() external view returns (bool);

    // CONTRACT OWNER OPERATIONS

    function getDrawPrice() external view returns (uint256);

    function updateDrawPrice(uint256 newDrawPrice) external;

    function terminate() external;
}

// File contracts/libraries/Randomness.sol

pragma solidity 0.8.7;

library Randomness {
    // memory struct for rand
    struct RNG {
        uint256 seed;
        uint256 nonce;
    }

    /// @dev get a random number
    function getRandom(
        RNG storage rng
    ) external returns (uint256 randomness, uint256 random) {
        return _getRandom(rng, 0, 2 ** 256 - 1, rng.seed);
    }

    /// @dev get a random number
    function getRandom(
        RNG storage rng,
        uint256 randomness
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, 2 ** 256 - 1, rng.seed);
    }

    /// @dev get a random number passing in a custom seed
    function getRandom(
        RNG storage rng,
        uint256 randomness,
        uint256 seed
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, 2 ** 256 - 1, seed);
    }

    /// @dev get a random number in range (0, _max)
    function getRandomRange(
        RNG storage rng,
        uint256 max
    ) external returns (uint256 randomness, uint256 random) {
        return _getRandom(rng, 0, max, rng.seed);
    }

    /// @dev get a random number in range (0, _max)
    function getRandomRange(
        RNG storage rng,
        uint256 randomness,
        uint256 max
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, max, rng.seed);
    }

    /// @dev get a random number in range (0, _max) passing in a custom seed
    function getRandomRange(
        RNG storage rng,
        uint256 randomness,
        uint256 max,
        uint256 seed
    ) external returns (uint256 randomness_, uint256 random) {
        return _getRandom(rng, randomness, max, seed);
    }

    /// @dev fullfill a random number request for the given inputs, incrementing the nonce, and returning the random number
    function _getRandom(
        RNG storage rng,
        uint256 randomness,
        uint256 max,
        uint256 seed
    ) internal returns (uint256 randomness_, uint256 random) {
        // if the randomness is zero, we need to fill it
        if (randomness <= 0) {
            // increment the nonce in case we roll over
            unchecked {
                rng.nonce++;
            }
            randomness = uint256(
                keccak256(
                    abi.encodePacked(
                        seed,
                        rng.nonce,
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
        }
        // mod to the requested range
        random = randomness % max;
        // shift bits to the right to get a new random number
        randomness_ = randomness >>= 4;
    }
}

// File contracts/DarthitectsWhitelistRaffle.sol

// SPDX-License-Identifier: MIT
// contracts//DarthitectsWhitelist.sol
pragma solidity 0.8.7;

//import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
//import "hardhat/console.sol";

contract DarthitectsWhitelistRaffle is
    Ownable,
    ARandomness,
    IDarthitectsWhitelistRaffle
{
    using Randomness for Randomness.RNG;
    Randomness.RNG internal rng;
    mapping(address => bytes32[]) private raffleIds;
    mapping(address => mapping(bytes32 => Raffle)) private raffles;
    address[] private clients;
    uint256 private draw_price = 0 ether;

    constructor(uint256 newDrawPrice) {
        draw_price = newDrawPrice;
    }

    // RAFFLE OWNER OPERATIONS

    // Create a new whitelist
    function create(
        bytes32 id,
        uint16 maxParticipants,
        uint8 numOfWLSpots,
        string calldata logo,
        string calldata banner,
        string calldata description,
        string calldata website
    ) external override {
        require(id != "", "empty id");
        require(maxParticipants > numOfWLSpots, "invalid maxParticipants");
        require(numOfWLSpots > 0, "invalid numOfWLSpots");
        uint256 _clientRaffleCount = raffleIds[msg.sender].length;
        require(_clientRaffleCount < 10, "max raffle count reached");
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.status == uint8(RaffleStatus.UNDEFINED) ||
                raffle.status == uint8(RaffleStatus.PENDING_ACTIVATION),
            "already created"
        );
        if (raffle.status == uint8(RaffleStatus.UNDEFINED)) {
            if (raffleIds[msg.sender].length == 0) {
                clients.push(msg.sender);
                emit NewClient(msg.sender, block.number);
            }
            raffleIds[msg.sender].push(id);
        }
        raffle.logo = logo;
        raffle.banner = banner;
        raffle.description = description;
        raffle.website = website;
        raffle.maxParticipants = maxParticipants;
        raffle.numOfWLSpots = numOfWLSpots;
        raffle.status = uint8(RaffleStatus.PENDING_ACTIVATION);
        (, raffle.seed) = rng.getRandom();
        if (raffle.seed == 1) {
            raffle.seed = 2;
        }
        emit RaffleCreated(msg.sender, id, block.number);
    }

    function activate(
        bytes32 id,
        uint256 prime,
        uint16 iterations,
        uint256 proof,
        uint256 startTime,
        uint256 endTime
    ) external payable override {
        require(prime > 2 ** 128, "invalid prime");
        require(iterations > 2 ** 13, "invalid iterations");
        require(proof > 1, "proof should be gt 1");
        require(startTime > block.timestamp, "invalid startTime");
        if (endTime > 0) {
            require(endTime > startTime + 10 minutes, "invalid endTime");
        }
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.status == uint8(RaffleStatus.PENDING_ACTIVATION),
            "incorrect state"
        );
        require(raffle.seed > 1, "invalid seed");
        // test if prime and iterations works correctly (prime and iterations will be used later for draw op)
        require(
            _verify(prime, iterations, proof, raffle.seed),
            "invalid proof"
        );
        raffle.prime = prime;
        raffle.iterations = iterations;
        raffle.startTime = startTime;
        raffle.endTime = endTime;
        raffle.status = uint8(RaffleStatus.ACTIVE);
        emit RaffleActivated(msg.sender, id, block.number);
    }

    // Start WL Registration of Whitelist
    function resume(bytes32 id) external override {
        Raffle storage raffle = raffles[msg.sender][id];
        require(raffle.status == uint8(RaffleStatus.PAUSED), "incorrect state");
        raffle.status = uint8(RaffleStatus.ACTIVE);
        emit RaffleResumed(msg.sender, id, block.number);
    }

    // Pause WL Registration of Whitelist
    function pause(bytes32 id) external override {
        Raffle storage raffle = raffles[msg.sender][id];
        require(raffle.status == uint8(RaffleStatus.ACTIVE), "incorrect state");
        if (raffle.endTime > 0) {
            require(block.timestamp < raffle.endTime, "already expired");
        }
        raffle.status = uint8(RaffleStatus.PAUSED);
        emit RafflePaused(msg.sender, id, block.number);
    }

    // Close WL Registration of Whitelist
    function close(bytes32 id) external payable override {
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.status == uint8(RaffleStatus.ACTIVE) ||
                raffle.status == uint8(RaffleStatus.PAUSED),
            "incorrect state"
        );
        if (raffle.endTime > 0) {
            require(block.timestamp > raffle.endTime, "not expired yet");
        }
        if (raffle.participants.length > 0) {
            raffle.status = uint8(RaffleStatus.PENDING_DRAW);
        } else {
            raffle.status = uint8(RaffleStatus.COMPLETED);
        }
        emit RaffleClosed(msg.sender, id, block.number);
    }

    // Cancel WhitelistWhitelist
    function cancel(bytes32 id) external payable override {
        uint8 _status = raffles[msg.sender][id].status;
        require(
            _status != uint8(RaffleStatus.UNDEFINED) &&
                _status != uint8(RaffleStatus.CANCELED) &&
                _status != uint8(RaffleStatus.COMPLETED),
            "incorrect state"
        );
        raffles[msg.sender][id].status = uint8(RaffleStatus.CANCELED);
        emit RaffleCanceled(msg.sender, id, block.number);
    }

    // WL Distribution of Whitelist Step 1
    function draw(bytes32 id) external payable override {
        require(msg.value == draw_price, "invalid payment");
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.status == uint8(RaffleStatus.PENDING_DRAW),
            "incorrect state"
        );

        // distribute directly if there are not enough participants
        if (raffle.participants.length <= raffle.numOfWLSpots) {
            raffle.winners = raffle.participants;
            for (uint256 i = 0; i < raffle.winners.length; i++) {
                raffle.winnerChecks[raffle.winners[i]] = true;
            }
            raffle.status = uint8(RaffleStatus.COMPLETED);
            emit RaffleCompleted(msg.sender, id, block.number);
        } else {
            // otherwise generate random seed for the next step
            (, raffle.seed) = rng.getRandom();
            raffle.status = uint8(RaffleStatus.PENDING_CONFIRMATION);
            emit RaffleDrawed(msg.sender, id, block.number);
        }
    }

    // WL Distribution of Whitelist Step 2
    function confirm(bytes32 id, uint256 proof) external override {
        require(proof > 1, "proof should be gt 1");
        Raffle storage raffle = raffles[msg.sender][id];
        require(
            raffle.status == uint8(RaffleStatus.PENDING_CONFIRMATION),
            "incorrect state"
        );
        require(raffle.seed > 1, "invalid seed");
        require(
            _verify(raffle.prime, raffle.iterations, proof, raffle.seed),
            "invalid proof"
        );

        // distribute wl's here
        uint256 _randomness = proof;
        uint256 _random;
        uint256 _numOfParticipants = raffle.participants.length;
        uint8 _numOfSlots = raffle.numOfWLSpots;
        raffle.ids = new uint16[](_numOfSlots);
        raffle.index = 0;
        address[] memory _winners = new address[](_numOfSlots);
        for (uint8 i = 0; i < _numOfSlots; ) {
            (_randomness, _random) = rng.getRandomRange(
                _randomness,
                _numOfParticipants,
                raffle.seed
            );
            uint256 _nextId = _pickRandomUniqueId(raffle, _random, _numOfSlots);
            _winners[i] = raffle.participants[_nextId];
            raffle.winnerChecks[raffle.participants[_nextId]] = true;
            unchecked {
                ++i;
            }
        }
        raffle.winners = _winners;
        raffle.status = uint8(RaffleStatus.COMPLETED);
        emit RaffleCompleted(msg.sender, id, block.number);
    }

    function _pickRandomUniqueId(
        Raffle storage raffle,
        uint256 _random,
        uint256 _numberOfSlots
    ) private returns (uint256 id) {
        uint256 len = _numberOfSlots - raffle.index++;
        require(len > 0, "no ids left");
        uint256 randomIndex = uint256(_random % len);
        id = raffle.ids[randomIndex] != 0
            ? raffle.ids[randomIndex]
            : randomIndex;
        raffle.ids[randomIndex] = uint16(
            raffle.ids[len - 1] == 0 ? len - 1 : raffle.ids[len - 1]
        );
        raffle.ids[len - 1] = 0;
    }

    // RAFFLE OWNER VIEWS
    function getMyRaffles() external view override returns (bytes32[] memory) {
        return raffleIds[msg.sender];
    }

    function getMyRaffle(
        bytes32 id
    ) external view override returns (RaffleView memory) {
        Raffle storage raffle = raffles[msg.sender][id];
        RaffleView memory _raffleView = RaffleView({
            prime: raffle.prime,
            seed: raffle.seed,
            startTime: raffle.startTime,
            endTime: raffle.endTime,
            iterations: raffle.iterations,
            maxParticipants: raffle.maxParticipants,
            participantCount: uint16(raffle.participants.length),
            numOfWLSpots: raffle.numOfWLSpots,
            status: raffle.status,
            logo: raffle.logo,
            banner: raffle.banner,
            description: raffle.description,
            website: raffle.website
        });
        return _raffleView;
    }

    // RAFFLE PARTICIPANT OPERATIONS
    function enter(address ownerAddress, bytes32 id) external override {
        Raffle storage raffle = raffles[ownerAddress][id];
        require(
            raffle.status == uint8(RaffleStatus.ACTIVE),
            "raffle is not active"
        );
        require(raffle.startTime < block.timestamp, "not started yet");
        if (raffle.endTime > 0) {
            require(raffle.endTime > block.timestamp, "expired");
        }
        require(
            raffle.participants.length < raffle.maxParticipants,
            "max candidates reached"
        );
        require(!raffle.participantChecks[msg.sender], "already entered");
        raffle.participantChecks[msg.sender] = true;
        raffle.participants.push(msg.sender);
        emit NewRaffleParticipant(ownerAddress, id, msg.sender, block.number);
    }

    function enterStatus(
        address ownerAddress,
        bytes32 id
    ) external view override returns (bool) {
        Raffle storage raffle = raffles[ownerAddress][id];
        return raffle.participantChecks[msg.sender];
    }

    function raffleResult(
        address ownerAddress,
        bytes32 id
    ) external view override returns (bool) {
        Raffle storage raffle = raffles[ownerAddress][id];
        require(
            raffle.status == uint8(RaffleStatus.COMPLETED),
            "incorrect state"
        );
        return raffle.winnerChecks[msg.sender];
    }

    // PUBLIC VIEWS

    function getDrawPrice() external view override returns (uint256) {
        return draw_price;
    }

    function getRaffle(
        address ownerAddress,
        bytes32 id
    ) external view override returns (RafflePublicView memory) {
        Raffle storage raffle = raffles[ownerAddress][id];
        RafflePublicView memory _rafflePublicView = RafflePublicView({
            startTime: raffle.startTime,
            endTime: raffle.endTime,
            maxParticipants: raffle.maxParticipants,
            participantCount: uint16(raffle.participants.length),
            numOfWLSpots: raffle.numOfWLSpots,
            status: raffle.status,
            logo: raffle.logo,
            banner: raffle.banner,
            description: raffle.description,
            website: raffle.website
        });
        return _rafflePublicView;
    }

    function getRaffleStatus(
        address ownerAddress,
        bytes32 id
    ) external view override returns (RafflePublicStatus memory) {
        Raffle storage raffle = raffles[ownerAddress][id];
        RafflePublicStatus memory _rafflePublicStatus = RafflePublicStatus({
            participantCount: uint16(raffle.participants.length),
            status: raffle.status
        });
        return _rafflePublicStatus;
    }

    function winners(
        address ownerAddress,
        bytes32 id
    ) external view override returns (address[] memory) {
        require(
            raffles[ownerAddress][id].status == uint8(RaffleStatus.COMPLETED),
            "not completed"
        );
        return raffles[ownerAddress][id].winners;
    }

    function isOwner() public view override returns (bool) {
        return owner() == _msgSender();
    }

    // CONTRACT OWNER OPERATIONS

    function updateDrawPrice(uint256 newDrawPrice) external override onlyOwner {
        draw_price = newDrawPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    receive() external payable {
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success);
    }

    fallback() external payable {
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success);
    }

    function terminate() external override onlyOwner {
        selfdestruct(payable(owner()));
    }
}