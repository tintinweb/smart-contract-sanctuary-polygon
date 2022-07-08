// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interfaces/IStorage.sol";
import "./interfaces/ITypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FixtureBetWriter is ITypes, Ownable {
    event UpdateStorage(address indexed newStorage);

    address internal storage_address;

    constructor(address storageAddress) {
        storage_address = storageAddress;
        emit UpdateStorage(storageAddress);
    }

    function setStorageAddress(address storageAddress) external onlyOwner{
        storage_address = storageAddress;
        emit UpdateStorage(storageAddress);
    }

    function placeBet(
        string calldata _fixtureStringId,
        Outcome _outcome
    ) external payable {
        require(IStorage(storage_address).checkOutcomeValidity(_outcome), "Invalid outcome");
        require(msg.value > 0, "Cannot place zero-value bet");

        uint256 fixtureId = _checkAndGetFixtureId(_fixtureStringId);
        // TODO: TBD the case for _stringEquals(idToFixture[fixtureId].stringId, ""))
        if (IStorage(storage_address).getIdToFixtureTotalPoolSize(fixtureId) == 0) {
            IStorage(storage_address).pushFixtureIds(fixtureId);
        }

        IStorage(storage_address).setIdToFixtureStringId(fixtureId, _fixtureStringId);
        if (
            IStorage(storage_address).getIdToFixtureBetsBetter(fixtureId, _outcome, msg.sender) ==
            address(0)
        ) {
            IStorage(storage_address).pushIdToFixtureBetters(fixtureId, _outcome, msg.sender);
            IStorage(storage_address).setIdToFixtureBetsBetter(fixtureId, _outcome, msg.sender);
        }

        IStorage(storage_address).addIdToFixturePoolSizes(fixtureId, _outcome, msg.value);
        IStorage(storage_address).addIdToFixtureTotalPoolSize(fixtureId, msg.value);
        IStorage(storage_address).addIdToFixtureBetsAmount(
            fixtureId,
            _outcome,
            msg.sender,
            msg.value
        );
    }

    function claimBet(
        string calldata _fixtureStringId,
        Outcome _outcome
    ) external {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        uint256 gains = IStorage(storage_address).getIdToFixtureBetsGains(
            fixtureId,
            _outcome,
            msg.sender
        );
        require(
            IStorage(storage_address).getIdToFixtureIsFinished(fixtureId),
            "Match was not ended"
        );
        require(IStorage(storage_address).checkOutcomeValidity(_outcome), "Outcome doesn't exist");
        require(
            IStorage(storage_address).getIdToFixtureBetsWon(fixtureId, _outcome, msg.sender),
            "Bet does not won"
        );
        require((gains != 0), "Bet already claimed");

        IStorage(storage_address).setIdToFixtureBetsGains(fixtureId, _outcome, msg.sender, 0);
        (bool success, ) = payable(msg.sender).call{value: gains}("");
        require(success, "Transfer failed.");
    }

    function claimAllWinningBets() external {
        uint256 fixtureIdsLength = IStorage(storage_address).getFixtureIdsLength();
        uint256 all_gains = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(storage_address).getFixtureIds(i);
            if (IStorage(storage_address).getIdToFixtureIsFinished(id)) {
                Outcome winning_outcome = IStorage(storage_address).getIdToFixtureWinningOutcome(id);
                uint256 gains = IStorage(storage_address).getIdToFixtureBetsGains(
                    id,
                    winning_outcome,
                    msg.sender
                );
                IStorage(storage_address).setIdToFixtureBetsGains(
                    id,
                    winning_outcome,
                    msg.sender,
                    0
                );
                all_gains += gains;
            }
        }
        (bool success, ) = payable(msg.sender).call{value: all_gains}("");
        require(success, "Transfer failed.");
    }

    // TODO: Check if require() throws out of caller function
    function _checkAndGetFixtureId(string calldata _fixtureStringId)
        internal
        view
        returns (uint256)
    {
        require(
            !IStorage(storage_address).getIdToFixtureIsFinished(
                uint256(keccak256(abi.encodePacked(_fixtureStringId)))
            ),
            "Match has ended"
        );
        return uint256(keccak256(abi.encodePacked(_fixtureStringId)));
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