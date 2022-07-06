// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./FixtureBetReader.sol";
import "./interfaces/IStorage.sol";

contract UserFixtureBetReader is FixtureBetReader {
    struct UserViewFixture {
        string stringId;
        uint256 prosPool;
        uint256 consPool;
        uint256 bettersAmount;
        bool won;
        bool isFinished;
        Outcome outcome;
        uint256 betAmount;
        uint256 betGains;
    }

    constructor(address storageAddress) FixtureBetReader(storageAddress) {
    }

    function getWonUserBetByFixtureId(string memory _fixtureStringId)
        external
        view
        returns (UserViewFixture memory)
    {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        require(
            _stringEquals(IStorage(storage_address).getIdToFixtureStringId(fixtureId), _fixtureStringId),
            "Fixture does not exist"
        );
        require(
            (IStorage(storage_address).getIdToFixtureBetsAmount(fixtureId,
                IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId), msg.sender) != 0),
            "Bet does not exist"
        );

        return
            UserViewFixture(
                IStorage(storage_address).getIdToFixtureStringId(fixtureId),
                IStorage(storage_address).getIdToFixturePoolSizes(fixtureId, IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId)),
                IStorage(storage_address).getTotalLostPool(fixtureId, IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId)),
                (IStorage(storage_address).getIdToFixtureBettersLength(fixtureId, Outcome.HOME)+
                    IStorage(storage_address).getIdToFixtureBettersLength(fixtureId, Outcome.AWAY) +
                    IStorage(storage_address).getIdToFixtureBettersLength(fixtureId, Outcome.TIE)),
                IStorage(storage_address).getIdToFixtureBetsWon(fixtureId, IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId), msg.sender),
                IStorage(storage_address).getIdToFixtureIsFinished(fixtureId),
                IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId),
                IStorage(storage_address).getIdToFixtureBetsAmount(fixtureId,
                    IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId), msg.sender),
                IStorage(storage_address).getIdToFixtureBetsGains(fixtureId,
                    IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId), msg.sender)
            );
    }

    function getBetsByResult(bool _won) external view returns (UserViewFixture[] memory) {
        uint256 fixtureIdsLength = IStorage(storage_address).getFixtureIdsLength();
        uint256 resLength = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (IStorage(storage_address).getIdToFixtureIsFinished(id)) {
                if (
                    (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) &&
                    (IStorage(storage_address).getIdToFixtureBetsWon(id, Outcome.HOME, msg.sender) == _won)
                ) {
                    resLength++;
                }
                if (
                    (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) &&
                    (IStorage(storage_address).getIdToFixtureBetsWon(id, Outcome.AWAY, msg.sender) == _won)
                ) {
                    resLength++;
                }
                if (
                    (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) &&
                    (IStorage(storage_address).getIdToFixtureBetsWon(id, Outcome.TIE, msg.sender) == _won)
                ) {
                    resLength++;
                }
            }
        }

        UserViewFixture[] memory result = new UserViewFixture[](resLength);

        uint256 counter = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (IStorage(storage_address).getIdToFixtureIsFinished(id)) {
                if (
                    (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) &&
                    (IStorage(storage_address).getIdToFixtureBetsWon(id, Outcome.HOME, msg.sender) == _won)
                ) {
                    result[counter] = _getUserViewFixture(i, Outcome.HOME, msg.sender);
                    counter++;
                }
                if (
                    (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) &&
                    (IStorage(storage_address).getIdToFixtureBetsWon(id, Outcome.AWAY, msg.sender) == _won)
                ) {
                    result[counter] = _getUserViewFixture(i, Outcome.AWAY, msg.sender);
                    counter++;
                }
                if (
                    (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) &&
                    (IStorage(storage_address).getIdToFixtureBetsWon(id, Outcome.TIE, msg.sender) == _won)
                ) {
                    result[counter] = _getUserViewFixture(i, Outcome.TIE, msg.sender);
                    counter++;
                }
            }
        }
        return result;
    }

    // Returns all bets (finished and ongoing) for the caller
    function getAllBetsByUser() external view returns (UserViewFixture[] memory) {
        UserViewFixture[] memory finishedBets = getBetsByFinishing(true);
        UserViewFixture[] memory ongoingBets = getBetsByFinishing(false);

        UserViewFixture[] memory result = new UserViewFixture[](
            finishedBets.length + ongoingBets.length
        );
        uint256 counter = 0;

        for (uint256 i = 0; i < finishedBets.length + ongoingBets.length; i++) {
            if (counter < finishedBets.length) {
                result[counter] = finishedBets[i];
            } else {
                result[counter] = ongoingBets[i];
            }
            counter++;
        }

        return result;
    }

    function getBetsByFinishing(bool _isFinished) public view returns (UserViewFixture[] memory) {
        uint256 fixtureIdsLength = IStorage(storage_address).getFixtureIdsLength();
        uint256 resLength = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (IStorage(storage_address).getIdToFixtureIsFinished(id) == _isFinished) {
                if (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) {
                    resLength++;
                }
                if (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) {
                    resLength++;
                }
                if (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) {
                    resLength++;
                }
            }
        }

        UserViewFixture[] memory result = new UserViewFixture[](resLength);

        uint256 counter = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (IStorage(storage_address).getIdToFixtureIsFinished(id) == _isFinished) {
                if (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) {
                    result[counter] = _getUserViewFixture(i, Outcome.HOME, msg.sender);
                    counter++;
                }
                if (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) {
                    result[counter] = _getUserViewFixture(i, Outcome.AWAY, msg.sender);
                    counter++;
                }
                if (IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) {
                    result[counter] = _getUserViewFixture(i, Outcome.TIE, msg.sender);
                    counter++;
                }
            }
        }
        return result;
    }

    function _getUserViewFixture( 
        uint256 i,
        Outcome _outcome,
        address _better
    ) private view returns (UserViewFixture memory) {
        uint256 id = IStorage(storage_address).getFixtureIds(i);
        string memory stringId = IStorage(storage_address).getIdToFixtureStringId(id);
        uint256 prosPool = IStorage(storage_address).getIdToFixturePoolSizes(id, _outcome);
        uint256 consPool = IStorage(storage_address).getTotalLostPool(id, _outcome);
        uint256 bettersAmount = (IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.HOME) +
            IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.AWAY) +
            IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.TIE));
        bool won = IStorage(storage_address).getIdToFixtureBetsWon(id, _outcome, _better);
        bool isFinished = IStorage(storage_address).getIdToFixtureIsFinished(id);
        uint256 betAmount = IStorage(storage_address).getIdToFixtureBetsAmount(id, _outcome, _better);
        uint256 betGains = IStorage(storage_address).getIdToFixtureBetsGains(id, _outcome, _better);
        return
            UserViewFixture(
                stringId,
                prosPool,
                consPool,
                bettersAmount,
                won,
                isFinished,
                _outcome,
                betAmount,
                betGains
            );
    }

    function _stringEquals(string memory first, string memory second)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(first)) == keccak256(abi.encodePacked(second));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interfaces/IStorage.sol";
import "./interfaces/ITypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FixtureBetReader is ITypes, Ownable {
    event UpdateStorage(address indexed newStorage);

    struct ViewIndexFixture {
        string stringId;
        uint256 totalPool;
        uint256 bettersAmount;
        bool isFinished;
    }

    struct ViewFixture {
        string stringId;
        uint256 prosPool;
        uint256 consPool;
        uint256 bettersAmount;
        bool won;
        bool isFinished;
        Outcome outcome;
        uint256 betAmount;
        uint256 betGains;
    }

    address internal storage_address;

    constructor(address storageAddress) {
        storage_address = storageAddress;
        emit UpdateStorage(storageAddress);
    }

    function setStorageAddress(address storageAddress) external onlyOwner{
        storage_address = storageAddress;
        emit UpdateStorage(storageAddress);
    }

    // Returns all bets (finished and ongoing) present in the service
    function getAllBets() external view returns (ViewIndexFixture[] memory) {
        uint256 fixtureIdsLength = IStorage(storage_address).getFixtureIdsLength();

        ViewIndexFixture[] memory result = new ViewIndexFixture[](fixtureIdsLength);

        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            result[i] = ViewIndexFixture(
                IStorage(storage_address).getIdToFixtureStringId(id),
                IStorage(storage_address).getIdToFixtureTotalPoolSize(id),
                (IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.HOME) +
                    IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.AWAY) +
                    IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.TIE)),
                IStorage(storage_address).getIdToFixtureIsFinished(id)
            );
        }

        return result;
    }

    function getBetsByFixtureId(string memory _fixtureStringId)
        external
        view
        returns (ViewFixture[] memory)
    {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));

        ViewFixture[] memory result = new ViewFixture[](3);

        uint256 counter = 0;

        result[counter] = ViewFixture(
            IStorage(storage_address).getIdToFixtureStringId(fixtureId),
            IStorage(storage_address).getIdToFixturePoolSizes(fixtureId, Outcome.HOME),
            IStorage(storage_address).getTotalLostPool(fixtureId, Outcome.HOME),
            IStorage(storage_address).getIdToFixtureBettersLength(fixtureId, Outcome.HOME),
            (IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId) == Outcome.HOME),
            IStorage(storage_address).getIdToFixtureIsFinished(fixtureId),
            Outcome.HOME,
            IStorage(storage_address).getIdToFixtureBetsAmount(fixtureId, Outcome.HOME, msg.sender),
            IStorage(storage_address).getIdToFixtureBetsGains(fixtureId, Outcome.HOME, msg.sender)
        );
        counter++;

        result[counter] = ViewFixture(
            IStorage(storage_address).getIdToFixtureStringId(fixtureId),
            IStorage(storage_address).getIdToFixturePoolSizes(fixtureId, Outcome.AWAY),
            IStorage(storage_address).getTotalLostPool(fixtureId, Outcome.AWAY),
            IStorage(storage_address).getIdToFixtureBettersLength(fixtureId, Outcome.AWAY),
            (IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId) == Outcome.AWAY),
            IStorage(storage_address).getIdToFixtureIsFinished(fixtureId),
            Outcome.AWAY,
            IStorage(storage_address).getIdToFixtureBetsAmount(fixtureId, Outcome.AWAY, msg.sender),
            IStorage(storage_address).getIdToFixtureBetsGains(fixtureId, Outcome.AWAY, msg.sender)
        );
        counter++;

        result[counter] = ViewFixture(
            IStorage(storage_address).getIdToFixtureStringId(fixtureId),
            IStorage(storage_address).getIdToFixturePoolSizes(fixtureId, Outcome.TIE),
            IStorage(storage_address).getTotalLostPool(fixtureId, Outcome.TIE),
            IStorage(storage_address).getIdToFixtureBettersLength(fixtureId, Outcome.TIE),
            (IStorage(storage_address).getIdToFixtureWinningOutcome(fixtureId) == Outcome.TIE),
            IStorage(storage_address).getIdToFixtureIsFinished(fixtureId),
            Outcome.TIE,
            IStorage(storage_address).getIdToFixtureBetsAmount(fixtureId, Outcome.TIE, msg.sender),
            IStorage(storage_address).getIdToFixtureBetsGains(fixtureId, Outcome.TIE, msg.sender)
        );

        return result;
    }

    function getActiveBets() external view returns (ViewFixture[3][] memory) {
        uint256 fixtureIdsLength = IStorage(storage_address).getFixtureIdsLength();
        uint256 activeCount = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (!IStorage(storage_address).getIdToFixtureIsFinished(id)) {
                activeCount++;
            }
        }
        ViewFixture[3][] memory result = new ViewFixture[3][](activeCount);
        uint256 curIndex = 0;

        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (!IStorage(storage_address).getIdToFixtureIsFinished(id)) {
                result[curIndex] = [
                    ViewFixture(
                        IStorage(storage_address).getIdToFixtureStringId(id),
                        IStorage(storage_address).getIdToFixturePoolSizes(id, Outcome.HOME),
                        IStorage(storage_address).getTotalLostPool(id, Outcome.HOME),
                        IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.HOME),
                        (IStorage(storage_address).getIdToFixtureWinningOutcome(id) == Outcome.HOME),
                        IStorage(storage_address).getIdToFixtureIsFinished(id),
                        Outcome.HOME,
                        IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender),
                        IStorage(storage_address).getIdToFixtureBetsGains(id, Outcome.HOME, msg.sender)
                    ),
                    ViewFixture(
                        IStorage(storage_address).getIdToFixtureStringId(id),
                        IStorage(storage_address).getIdToFixturePoolSizes(id, Outcome.AWAY),
                        IStorage(storage_address).getTotalLostPool(id, Outcome.AWAY),
                        IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.AWAY),
                        (IStorage(storage_address).getIdToFixtureWinningOutcome(id) == Outcome.AWAY),
                        IStorage(storage_address).getIdToFixtureIsFinished(id),
                        Outcome.AWAY,
                        IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender),
                        IStorage(storage_address).getIdToFixtureBetsGains(id, Outcome.AWAY, msg.sender)
                    ),
                    ViewFixture(
                        IStorage(storage_address).getIdToFixtureStringId(id),
                        IStorage(storage_address).getIdToFixturePoolSizes(id, Outcome.TIE),
                        IStorage(storage_address).getTotalLostPool(i,  Outcome.TIE),
                        IStorage(storage_address).getIdToFixtureBettersLength(id, Outcome.TIE),
                        (IStorage(storage_address).getIdToFixtureWinningOutcome(id) == Outcome.TIE),
                        IStorage(storage_address).getIdToFixtureIsFinished(id),
                        Outcome.TIE,
                        IStorage(storage_address).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender),
                        IStorage(storage_address).getIdToFixtureBetsGains(id, Outcome.TIE, msg.sender)                    
                    )
                ];
                curIndex++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.14;

import "./ITypes.sol";

interface IStorage is ITypes {
    function setSupervisor(address) external;

    function setWriter(address) external;

    function setFeePercentage(uint256) external;

    function setInvolvementPercentageBase(uint256) external;

    function setServiceWallet(address) external;

    function claimServiceFee() external;

    function claimPartOfServiceFee(uint256) external;

    function declareOutcomeAndDistributeWinnings(string calldata, Outcome) external;

    function calculateGains(
        uint256,
        Outcome,
        address
    ) external view returns (uint256, uint256);

    function getTotalLostPool(uint256, Outcome) external view returns (uint256);

    function getFixtureIds() external view returns (uint256[] memory);

    function getFixtureIds(uint256 i) external view returns (uint256);

    function getFixtureIdsLength() external view returns (uint256);

    function getIdToFixtureStringId(uint256) external view returns (string memory);

    function getIdToFixtureIsFinished(uint256) external view returns (bool);

    function getIdToFixtureWinningOutcome(uint256) external view returns (Outcome);

    function getIdToFixtureTotalPoolSize(uint256) external view returns (uint256);

    function getIdToFixturePoolSizes(uint256, Outcome) external view returns (uint256);

    function getIdToFixtureBetters(uint256, Outcome) external view returns (address[] memory);

    function getIdToFixtureBettersLength(uint256, Outcome) external view returns (uint256);

    function getIdToFixtureBets(
        uint256,
        Outcome,
        address
    ) external view returns (Bet memory);

    function getIdToFixtureBetsGains(
        uint256,
        Outcome,
        address
    ) external view returns (uint256);

    function getIdToFixtureBetsWon(
        uint256,
        Outcome,
        address
    ) external view returns (bool);

    function getIdToFixtureBetsAmount(
        uint256,
        Outcome,
        address
    ) external view returns (uint256);

    function getIdToFixtureBetsBetter(
        uint256,
        Outcome,
        address
    ) external view returns (address);

    function pushFixtureIds(uint256) external;

    function setIdToFixtureStringId(uint256, string memory) external;

    function setIdToFixtureIsFinished(uint256, bool) external;

    function setIdToFixtureWinningOutcome(uint256, Outcome) external;

    function setIdToFixtureTotalPoolSize(uint256, uint256) external;

    function setIdToFixturePoolSizes(
        uint256,
        Outcome,
        uint256
    ) external;

    function setIdToFixtureBetsGains(
        uint256,
        Outcome,
        address,
        uint256
    ) external;

    function setIdToFixtureBetsWon(
        uint256,
        Outcome,
        address,
        bool
    ) external;

    function setIdToFixtureBetsBetter(
        uint256,
        Outcome,
        address
    ) external;

    function setIdToFixtureBetsAmount(
        uint256,
        Outcome,
        address,
        uint256
    ) external;

    //function setIdToFixtureBetters(uint256, Outcome) external;

    //function setIdToFixtureBets(uint256, Outcome, address) external;

    function pushIdToFixtureBetters(
        uint256,
        Outcome,
        address
    ) external;

    function addIdToFixturePoolSizes(
        uint256,
        Outcome,
        uint256
    ) external;

    function addIdToFixtureTotalPoolSize(uint256, uint256) external;

    function addIdToFixtureBetsAmount(
        uint256,
        Outcome,
        address,
        uint256
    ) external;

    function checkOutcomeValidity(Outcome) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.14;

interface ITypes {
    enum Outcome {
        DEFAULT,
        HOME,
        AWAY,
        TIE
    }

    struct Bet {
        bool won;
        uint256 gains;
        uint256 amount;
        address better;
    }

    struct Fixture {
        string stringId;
        bool isFinished;
        Outcome winningOutcome;
        uint256 totalPoolSize;
        // TODO: Make computed
        mapping(Outcome => uint256) poolSizes;
        mapping(Outcome => address[]) betters;
        mapping(Outcome => mapping(address => Bet)) bets;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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