// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Storage.sol";


contract AdminStorage is Storage {
    event UpdateSupervisor(address indexed newSupervisor);
    event UpdateFeePercentage(uint256 newFee);

    constructor(address serviceWalletAddress, address supervisor) Storage(serviceWalletAddress, supervisor) {}

    function setSupervisor(address newSupervisor) public onlyOwner {
        _supervisor = newSupervisor;
        emit UpdateSupervisor(newSupervisor);
    }

    function setFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0 && _newFee <= 10000, "Fee is invalid");
        _feePercentage = _newFee;
        emit UpdateFeePercentage( _newFee);
    }

    function setInvolvementPercentageBase(uint256 _newInvolvementBase) external onlyOwner {
        _involvementPercentageBase = _newInvolvementBase;
    }

    function setServiceWallet(address _newServiceWallet) external onlyOwner {
        _serviceWalletAddress = payable(_newServiceWallet);
    }

    function claimServiceFee() external onlyOwner {
        require((_serviceWalletAddress != address(0x0)), "Service wallet is not set");
        require((_accumulatedFee != 0), "Fee was already claimed");
        
        (bool success, ) = _serviceWalletAddress.call{value: _accumulatedFee}("");
        require(success, "Transfer failed.");

        _accumulatedFee = 0;
    }

    function claimPartOfServiceFee(uint256 _amount) external onlyOwner {
        require((_serviceWalletAddress != address(0x0)), "Service wallet is not set");
        require((_accumulatedFee != 0), "Fee was already claimed");
        require((_amount > 0), "Amount should be greater then 0");
        require((_accumulatedFee >= _amount), "Not enough means");

        _accumulatedFee -= _amount;
        (bool success, ) = _serviceWalletAddress.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function declareOutcomeAndDistributeWinnings(
        string calldata _fixtureStringId,
        Outcome _outcome
    ) external onlyOwner {
        require(checkOutcomeValidity(_outcome), "Invalid outcome");
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        Fixture storage fixture = idToFixture[fixtureId];
        fixture.isFinished = true;
        fixture.winningOutcome = _outcome;

        for (uint256 i = 0; i < fixture.betters[_outcome].length; i++) {
            fixture.bets[_outcome][fixture.betters[_outcome][i]].won = true;
            (uint256 fee, uint256 gains) = calculateGains(
                fixtureId,
                _outcome,
                fixture.betters[_outcome][i]
            );
            fixture.bets[_outcome][fixture.betters[_outcome][i]].gains = gains;
            _accumulatedFee += fee;
        }
    }

    function calculateGains(
        uint256 _fixtureId,
        Outcome _outcome,
        address _better
    ) public view returns (uint256, uint256) {
        Fixture storage fixture = idToFixture[_fixtureId];

        uint256 bet = fixture.bets[_outcome][_better].amount;
        uint256 lostPool = getTotalLostPool(_fixtureId, _outcome);
        uint256 gains = _involvementPercentageBase * bet * lostPool;
        uint256 pureGains = (gains * (_percentageBase - _feePercentage)) /
            fixture.poolSizes[_outcome];

        uint256 serviceFee = ((gains * _feePercentage) / fixture.poolSizes[_outcome]) /
            (_percentageBase * _involvementPercentageBase);

        return (
            serviceFee,
            uint256(bet + pureGains / (_percentageBase * _involvementPercentageBase))
        );
    }

    function getTotalLostPool(uint256 _fixtureId, Outcome _outcome) public view returns (uint256) {
        if (_outcome == Outcome.HOME) {
            return
                idToFixture[_fixtureId].poolSizes[Outcome.AWAY] +
                idToFixture[_fixtureId].poolSizes[Outcome.TIE];
        } else if (_outcome == Outcome.AWAY) {
            return
                idToFixture[_fixtureId].poolSizes[Outcome.HOME] +
                idToFixture[_fixtureId].poolSizes[Outcome.TIE];
        } else {
            return 
                idToFixture[_fixtureId].poolSizes[Outcome.HOME] +
                idToFixture[_fixtureId].poolSizes[Outcome.AWAY];
        }
    }

    function checkOutcomeValidity(Outcome _outcome) public pure returns (bool) {
        return
            (Outcome.HOME == _outcome) || (Outcome.AWAY == _outcome) || (Outcome.TIE == _outcome);
    }

    function pushFixtureIds(uint256 id) external onlySupervisor {
        _fixtureIds.push(id);
    }

    function setIdToFixtureStringId(uint256 id, string memory stringId) external onlySupervisor {
        idToFixture[id].stringId = stringId;
    }

    function setIdToFixtureIsFinished(uint256 id, bool isFinished) external onlySupervisor {
        idToFixture[id].isFinished = isFinished;
    }

    function setIdToFixtureWinningOutcome(uint256 id, Outcome winningOutcome) external onlySupervisor {
        idToFixture[id].winningOutcome = winningOutcome;
    }

    function setIdToFixtureTotalPoolSize(uint256 id, uint256 totalPoolSize) external onlySupervisor {
        idToFixture[id].totalPoolSize = totalPoolSize;
    }

    function setIdToFixturePoolSizes(uint256 id, Outcome outcome, uint256 poolSize) external onlySupervisor {
        idToFixture[id].poolSizes[outcome] = poolSize;
    }

    function pushIdToFixtureBetters(uint256 id, Outcome outcome, address address_) external onlySupervisor {
        idToFixture[id].betters[outcome].push(address_);
    }

    function setIdToFixtureBetsGains(uint256 id, Outcome outcome, address address_, uint256 gains) external onlySupervisor {
        idToFixture[id].bets[outcome][address_].gains = gains;
    }

    function setIdToFixtureBetsWon(uint256 id, Outcome outcome, address address_, bool won) external onlySupervisor {
        idToFixture[id].bets[outcome][address_].won = won;
    }

    function setIdToFixtureBetsBetter(uint256 id, Outcome outcome, address address_) external onlySupervisor {
        idToFixture[id].bets[outcome][address_].better = address_;
    }

    function setIdToFixtureBetsAmount(uint256 id, Outcome outcome, address address_, uint256 amount) external onlySupervisor {
        idToFixture[id].bets[outcome][address_].amount = amount;
    }

    function addIdToFixturePoolSizes(uint256 id, Outcome outcome, uint256 poolSize) external onlySupervisor {
        idToFixture[id].poolSizes[outcome] += poolSize;      
    }

    function addIdToFixtureTotalPoolSize(uint256 id, uint256 value) external onlySupervisor {
        idToFixture[id].totalPoolSize += value;
    }

    function addIdToFixtureBetsAmount(uint256 id, Outcome outcome, address address_, uint256 amount) external onlySupervisor {
        idToFixture[id].bets[outcome][address_].amount += amount;
    }

    /*function setIdToFixtureBetters(uint256 id, Outcome outcome) external onlySupervisor {
        idToFixture[id].betters[outcome];
    }

    function setIdToFixtureBets(uint256 id, Outcome outcome, address address_) external onlySupervisor {
        idToFixture[id].bets[outcome][address_];
    }*/
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStorage.sol";

abstract contract Storage is IStorage, Ownable {
    uint256 internal _feePercentage = 200;
    uint256 internal _percentageBase = 10000;
    uint256 internal _involvementPercentageBase = 10e18;
    uint256 internal _accumulatedFee;

    address payable internal _serviceWalletAddress;

    uint256[] internal _fixtureIds;
    mapping(uint256 => Fixture) internal idToFixture;

    address internal _supervisor;

    constructor(address serviceWalletAddress, address supervisor) {
        _serviceWalletAddress = payable(serviceWalletAddress);
        _supervisor = supervisor;
    }

    modifier onlySupervisorOrOwner() {
        require(msg.sender == _supervisor || msg.sender == owner(), "Not supervisor or owner");
        _;
    }

    modifier onlySupervisor() {
        require(msg.sender == _supervisor, "Not supervisor");
        _;
    }

    function getFeePercentage() external view onlyOwner returns (uint256) {
        return _feePercentage;
    }

    function getPercentageBase() external view onlyOwner returns (uint256) {
        return _percentageBase;
    }

    function getInvolvementPercentageBase() external view onlyOwner returns (uint256) {
        return _involvementPercentageBase;
    }

    function getAccumulatedFee() external view returns (uint256) {
        return _accumulatedFee;
    }

    function getFee() external view onlyOwner returns (address) {
        return _serviceWalletAddress;
    }

    function getFixtureIds() external view onlySupervisor returns (uint256[] memory) {
        return _fixtureIds;
    }

    function getFixtureIds(uint256 i) external view onlySupervisor returns (uint256) {
        return _fixtureIds[i];
    }

    function getFixtureIdsLength() external view onlySupervisor returns (uint256) {
        return _fixtureIds.length;
    }

    function getIdToFixtureStringId(uint256 id) external view returns (string memory) {
        return idToFixture[id].stringId;
    }

    function getIdToFixtureIsFinished(uint256 id) external view returns (bool) {
        return idToFixture[id].isFinished;
    }

    function getIdToFixtureWinningOutcome(uint256 id) external view returns (Outcome) {
        return idToFixture[id].winningOutcome;
    }

    function getIdToFixtureTotalPoolSize(uint256 id) external view returns (uint256) {
        return idToFixture[id].totalPoolSize;
    }

    function getIdToFixturePoolSizes(uint256 id, Outcome outcome) external view returns (uint256) {
        return idToFixture[id].poolSizes[outcome];
    }

    function getIdToFixtureBetters(uint256 id, Outcome outcome) external view returns (address[] memory) {
        return idToFixture[id].betters[outcome];
    }

    function getIdToFixtureBettersLength(uint256 id, Outcome outcome) external view returns (uint256) {
        return idToFixture[id].betters[outcome].length;
    }

    function getIdToFixtureBets(uint256 id, Outcome outcome, address address_) external view returns (Bet memory) {
        return idToFixture[id].bets[outcome][address_];
    }

    function getIdToFixtureBetsGains(uint256 id, Outcome outcome, address address_) external view returns (uint256) {
        return idToFixture[id].bets[outcome][address_].gains;
    }

    function getIdToFixtureBetsWon(uint256 id, Outcome outcome, address address_) external view returns (bool) {
        return idToFixture[id].bets[outcome][address_].won;
    }

    function getIdToFixtureBetsAmount(uint256 id, Outcome outcome, address address_) external view returns (uint256) {
        return idToFixture[id].bets[outcome][address_].amount;
    }

    function getIdToFixtureBetsBetter(uint256 id, Outcome outcome, address address_) external view returns (address) {
        return idToFixture[id].bets[outcome][address_].better;
    }
    
    function getSupervisor() external view onlyOwner returns (address) {
        return _supervisor;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.14;

import "./ITypes.sol";

interface IStorage is ITypes {
    function setSupervisor(address) external;

    function setFeePercentage(uint256) external;

    function setInvolvementPercentageBase(uint256) external;

    function setServiceWallet(address) external;
    
    function claimServiceFee() external;

    function claimPartOfServiceFee(uint256) external;

    function declareOutcomeAndDistributeWinnings(string calldata, Outcome) external;

    function calculateGains(uint256, Outcome, address) external view returns (uint256, uint256);

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

    function getIdToFixtureBets(uint256, Outcome, address) external view returns (Bet memory);

    function getIdToFixtureBetsGains(uint256, Outcome, address) external view returns (uint256);

    function getIdToFixtureBetsWon(uint256, Outcome, address) external view returns (bool);

    function getIdToFixtureBetsAmount(uint256, Outcome, address) external view returns (uint256);

    function getIdToFixtureBetsBetter(uint256, Outcome, address) external view returns (address);

    function pushFixtureIds(uint256) external;

    function setIdToFixtureStringId(uint256, string memory) external;

    function setIdToFixtureIsFinished(uint256, bool) external;

    function setIdToFixtureWinningOutcome(uint256, Outcome) external;

    function setIdToFixtureTotalPoolSize(uint256, uint256) external;

    function setIdToFixturePoolSizes(uint256, Outcome, uint256) external;

    function setIdToFixtureBetsGains(uint256, Outcome, address, uint256) external;

    function setIdToFixtureBetsWon(uint256, Outcome, address, bool) external;

    function setIdToFixtureBetsBetter(uint256, Outcome, address) external;

    function setIdToFixtureBetsAmount(uint256, Outcome, address, uint256) external;

    //function setIdToFixtureBetters(uint256, Outcome) external;

    //function setIdToFixtureBets(uint256, Outcome, address) external;

    function pushIdToFixtureBetters(uint256, Outcome, address) external;

    function addIdToFixturePoolSizes(uint256, Outcome, uint256) external;

    function addIdToFixtureTotalPoolSize(uint256, uint256) external;

    function addIdToFixtureBetsAmount(uint256, Outcome, address, uint256) external;

    
    function checkOutcomeValidity(Outcome) external pure returns (bool);
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