// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./FixtureBet.sol";

contract FixtureHelper is FixtureBet {
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

    struct ViewIndexFixture {
        string stringId;
        uint256 totalPool;
        uint256 bettersAmount;
        bool isFinished;
    }

    function getWonUserBetByFixtureId(string memory _fixtureStringId)
        external
        view
        returns (UserViewFixture memory)
    {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        require(
            _stringEquals(idToFixture[fixtureId].stringId, _fixtureStringId),
            "Fixture does not exist"
        );
        require(
            (idToFixture[fixtureId]
            .bets[idToFixture[fixtureId].winningOutcome][msg.sender].amount != 0),
            "Bet does not exist"
        );

        return
            UserViewFixture(
                idToFixture[fixtureId].stringId,
                idToFixture[fixtureId].poolSizes[idToFixture[fixtureId].winningOutcome],
                getTotalLostPool(fixtureId, idToFixture[fixtureId].winningOutcome),
                (idToFixture[fixtureId].betters[Outcome.HOME].length +
                    idToFixture[fixtureId].betters[Outcome.AWAY].length +
                    idToFixture[fixtureId].betters[Outcome.TIE].length),
                idToFixture[fixtureId].bets[idToFixture[fixtureId].winningOutcome][msg.sender].won,
                idToFixture[fixtureId].isFinished,
                idToFixture[fixtureId].winningOutcome,
                idToFixture[fixtureId]
                .bets[idToFixture[fixtureId].winningOutcome][msg.sender].amount,
                idToFixture[fixtureId]
                .bets[idToFixture[fixtureId].winningOutcome][msg.sender].gains
            );
    }

    function getBetsByResult(bool _won) external view returns (UserViewFixture[] memory) {
        uint256 resLength = 0;
        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            if (idToFixture[_fixtureIds[i]].isFinished) {
                if (
                    (idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].amount != 0) &&
                    (idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].won == _won)
                ) {
                    resLength++;
                }
                if (
                    (idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].amount != 0) &&
                    (idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].won == _won)
                ) {
                    resLength++;
                }
                if (
                    (idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].amount != 0) &&
                    (idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].won == _won)
                ) {
                    resLength++;
                }
            }
        }

        UserViewFixture[] memory result = new UserViewFixture[](resLength);

        uint256 counter = 0;
        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            if (idToFixture[_fixtureIds[i]].isFinished) {
                if (
                    (idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].amount != 0) &&
                    (idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].won == _won)
                ) {
                    result[counter] = _getUserViewFixture(i, Outcome.HOME, msg.sender);
                    counter++;
                }
                if (
                    (idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].amount != 0) &&
                    (idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].won == _won)
                ) {
                    result[counter] = _getUserViewFixture(i, Outcome.AWAY, msg.sender);
                    counter++;
                }
                if (
                    (idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].amount != 0) &&
                    (idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].won == _won)
                ) {
                    result[counter] = _getUserViewFixture(i, Outcome.TIE, msg.sender);
                    counter++;
                }
            }
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
            idToFixture[fixtureId].stringId,
            idToFixture[fixtureId].poolSizes[Outcome.HOME],
            getTotalLostPool(fixtureId, Outcome.HOME),
            idToFixture[fixtureId].betters[Outcome.HOME].length,
            (idToFixture[fixtureId].winningOutcome == Outcome.HOME),
            idToFixture[fixtureId].isFinished,
            Outcome.HOME,
            idToFixture[fixtureId].bets[Outcome.HOME][msg.sender].amount,
            idToFixture[fixtureId].bets[Outcome.HOME][msg.sender].gains
        );
        counter++;

        result[counter] = ViewFixture(
            idToFixture[fixtureId].stringId,
            idToFixture[fixtureId].poolSizes[Outcome.AWAY],
            getTotalLostPool(fixtureId, Outcome.AWAY),
            idToFixture[fixtureId].betters[Outcome.AWAY].length,
            (idToFixture[fixtureId].winningOutcome == Outcome.AWAY),
            idToFixture[fixtureId].isFinished,
            Outcome.AWAY,
            idToFixture[fixtureId].bets[Outcome.AWAY][msg.sender].amount,
            idToFixture[fixtureId].bets[Outcome.AWAY][msg.sender].gains
        );
        counter++;

        result[counter] = ViewFixture(
            idToFixture[fixtureId].stringId,
            idToFixture[fixtureId].poolSizes[Outcome.TIE],
            getTotalLostPool(fixtureId, Outcome.TIE),
            idToFixture[fixtureId].betters[Outcome.TIE].length,
            (idToFixture[fixtureId].winningOutcome == Outcome.TIE),
            idToFixture[fixtureId].isFinished,
            Outcome.TIE,
            idToFixture[fixtureId].bets[Outcome.TIE][msg.sender].amount,
            idToFixture[fixtureId].bets[Outcome.TIE][msg.sender].gains
        );

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

    // Returns all bets (finished and ongoing) present in the service
    function getAllBets() external view returns (ViewIndexFixture[] memory) {
        ViewIndexFixture[] memory result = new ViewIndexFixture[](_fixtureIds.length);

        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            result[i] = ViewIndexFixture(
                idToFixture[_fixtureIds[i]].stringId,
                idToFixture[_fixtureIds[i]].totalPoolSize,
                (idToFixture[_fixtureIds[i]].betters[Outcome.HOME].length +
                    idToFixture[_fixtureIds[i]].betters[Outcome.AWAY].length +
                    idToFixture[_fixtureIds[i]].betters[Outcome.TIE].length),
                idToFixture[_fixtureIds[i]].isFinished
            );
        }

        return result;
    }

    function getActiveBets() external view returns (ViewFixture[3][] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            if (!idToFixture[_fixtureIds[i]].isFinished) {
                activeCount++;
            }
        }
        ViewFixture[3][] memory result = new ViewFixture[3][](activeCount);
        uint256 curIndex = 0;

        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            if (!idToFixture[_fixtureIds[i]].isFinished) {
                result[curIndex] = [
                    ViewFixture(
                        idToFixture[_fixtureIds[i]].stringId,
                        idToFixture[_fixtureIds[i]].poolSizes[Outcome.HOME],
                        getTotalLostPool(_fixtureIds[i], Outcome.HOME),
                        idToFixture[_fixtureIds[i]].betters[Outcome.HOME].length,
                        (idToFixture[_fixtureIds[i]].winningOutcome == Outcome.HOME),
                        idToFixture[_fixtureIds[i]].isFinished,
                        Outcome.HOME,
                        idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].amount,
                        idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].gains
                    ),
                    ViewFixture(
                        idToFixture[_fixtureIds[i]].stringId,
                        idToFixture[_fixtureIds[i]].poolSizes[Outcome.AWAY],
                        getTotalLostPool(_fixtureIds[i], Outcome.AWAY),
                        idToFixture[_fixtureIds[i]].betters[Outcome.AWAY].length,
                        (idToFixture[_fixtureIds[i]].winningOutcome == Outcome.AWAY),
                        idToFixture[_fixtureIds[i]].isFinished,
                        Outcome.AWAY,
                        idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].amount,
                        idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].gains
                    ),
                    ViewFixture(
                        idToFixture[_fixtureIds[i]].stringId,
                        idToFixture[_fixtureIds[i]].poolSizes[Outcome.TIE],
                        getTotalLostPool(_fixtureIds[i], Outcome.TIE),
                        idToFixture[_fixtureIds[i]].betters[Outcome.TIE].length,
                        (idToFixture[_fixtureIds[i]].winningOutcome == Outcome.TIE),
                        idToFixture[_fixtureIds[i]].isFinished,
                        Outcome.TIE,
                        idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].amount,
                        idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].gains
                    )
                ];
                curIndex++;
            }
        }

        return result;
    }

    function getBetsByFinishing(bool _isFinished) public view returns (UserViewFixture[] memory) {
        uint256 resLength = 0;
        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            if (idToFixture[_fixtureIds[i]].isFinished == _isFinished) {
                if (idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].amount != 0) {
                    resLength++;
                }
                if (idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].amount != 0) {
                    resLength++;
                }
                if (idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].amount != 0) {
                    resLength++;
                }
            }
        }

        UserViewFixture[] memory result = new UserViewFixture[](resLength);

        uint256 counter = 0;
        for (uint256 i = 0; i < _fixtureIds.length; i++) {
            if (idToFixture[_fixtureIds[i]].isFinished == _isFinished) {
                if (idToFixture[_fixtureIds[i]].bets[Outcome.HOME][msg.sender].amount != 0) {
                    result[counter] = _getUserViewFixture(i, Outcome.HOME, msg.sender);
                    counter++;
                }
                if (idToFixture[_fixtureIds[i]].bets[Outcome.AWAY][msg.sender].amount != 0) {
                    result[counter] = _getUserViewFixture(i, Outcome.AWAY, msg.sender);
                    counter++;
                }
                if (idToFixture[_fixtureIds[i]].bets[Outcome.TIE][msg.sender].amount != 0) {
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
        string memory stringId = idToFixture[_fixtureIds[i]].stringId;
        uint256 prosPool = idToFixture[_fixtureIds[i]].poolSizes[_outcome];
        uint256 consPool = getTotalLostPool(_fixtureIds[i], _outcome);
        uint256 bettersAmount = (idToFixture[_fixtureIds[i]].betters[Outcome.HOME].length +
            idToFixture[_fixtureIds[i]].betters[Outcome.AWAY].length +
            idToFixture[_fixtureIds[i]].betters[Outcome.TIE].length);
        bool won = idToFixture[_fixtureIds[i]].bets[_outcome][_better].won;
        bool isFinished = idToFixture[_fixtureIds[i]].isFinished;
        uint256 betAmount = idToFixture[_fixtureIds[i]].bets[_outcome][_better].amount;
        uint256 betGains = idToFixture[_fixtureIds[i]].bets[_outcome][_better].gains;
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FixtureBet is Ownable {
    using SafeMath for uint256;

    enum Outcome {
        DEFAULT,
        HOME,
        AWAY,
        TIE
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

    struct Bet {
        bool won;
        uint256 gains;
        uint256 amount;
        address better;
    }

    uint256 internal _feePercentage = 200;
    uint256 internal _percentageBase = 10000;
    uint256 internal _involvementPercentageBase = 10e18;
    uint256 internal _accumulatedFee = 0;

    address payable internal _serviceWalletAddress;

    uint256[] internal _fixtureIds;
    mapping(uint256 => Fixture) public idToFixture;

    modifier onlyExistingOutcome(Outcome _outcome) {
        require(_checkOutcomeValidity(_outcome), "Invalid outcome");
        _;
    }

    function declareOutcomeAndDistributeWinnings(
        string calldata _fixtureStringId,
        Outcome _outcome
    ) external onlyOwner onlyExistingOutcome(_outcome) {
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

    function placeBet(string calldata _fixtureStringId, Outcome _outcome)
        external
        payable
        onlyExistingOutcome(_outcome)
    {
        require(msg.value > 0, "Cannot place zero-value bet");

        uint256 fixtureId = _checkAndGetFixtureId(_fixtureStringId);
        // TODO: TBD the case for _stringEquals(idToFixture[fixtureId].stringId, ""))
        if (idToFixture[fixtureId].totalPoolSize == 0) {
            _fixtureIds.push(fixtureId);
        }

        idToFixture[fixtureId].stringId = _fixtureStringId;
        if (idToFixture[fixtureId].bets[_outcome][msg.sender].better == address(0)) {
            idToFixture[fixtureId].betters[_outcome].push(msg.sender);
            idToFixture[fixtureId].bets[_outcome][msg.sender].better = msg.sender;
        }

        idToFixture[fixtureId].poolSizes[_outcome] += msg.value;
        idToFixture[fixtureId].totalPoolSize += msg.value;
        idToFixture[fixtureId].bets[_outcome][msg.sender].amount += msg.value;
    }

    function claimBet(string calldata _fixtureStringId, Outcome _outcome) external payable {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        uint256 gains = idToFixture[fixtureId].bets[_outcome][msg.sender].gains;
        require(idToFixture[fixtureId].isFinished, "Match was not ended");
        require(_checkOutcomeValidity(_outcome), "Outcome doesn't exist");
        require(idToFixture[fixtureId].bets[_outcome][msg.sender].won, "Bet does not won");
        require((gains != 0), "Bet already claimed");

        (bool success, ) = payable(msg.sender).call{value: gains}("");
        require(success, "Transfer failed.");
        idToFixture[fixtureId].bets[_outcome][msg.sender].gains = 0;
    }

    function claimServiceFee() external payable onlyOwner {
        require((_serviceWalletAddress != address(0x0)), "Service wallet is not set");
        require((_accumulatedFee != 0), "Fee was already claimed");

        (bool success, ) = _serviceWalletAddress.call{value: _accumulatedFee}("");
        require(success, "Transfer failed.");

        _accumulatedFee = 0;
    }

    function claimPartOfServiceFee(uint256 _amount) external payable onlyOwner {
        require((_serviceWalletAddress != address(0x0)), "Service wallet is not set");
        require((_accumulatedFee != 0), "Fee was already claimed");
        require((_amount > 0), "Amount should be greater then 0");
        require((_accumulatedFee >= _amount), "Not enough means");

        (bool success, ) = _serviceWalletAddress.call{value: _amount}("");
        require(success, "Transfer failed.");

        _accumulatedFee -= _amount;
    }

    function setFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0 && _newFee <= 10000, "Fee is invalid");
        _feePercentage = _newFee;
    }

    function setInvolvementPercentageBase(uint256 _newInvolvementBase) external onlyOwner {
        _involvementPercentageBase = _newInvolvementBase;
    }

    function setServiceWallet(address _newServiceWallet) external onlyOwner {
        _serviceWalletAddress = payable(_newServiceWallet);
    }

    function getFeePercentage() external view onlyOwner returns (uint256) {
        return _feePercentage;
    }

    function getInvolvementPercentageBase() external view onlyOwner returns (uint256) {
        return _involvementPercentageBase;
    }

    function getFee() external view onlyOwner returns (address) {
        return _serviceWalletAddress;
    }

    function getAccumulatedFee() external view returns (uint256) {
        return _accumulatedFee;
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

    // TODO: Check if require() throws out of caller function
    function _checkAndGetFixtureId(string calldata _fixtureStringId)
        internal
        view
        returns (uint256)
    {
        require(
            !idToFixture[uint256(keccak256(abi.encodePacked(_fixtureStringId)))].isFinished,
            "Match has ended"
        );
        return uint256(keccak256(abi.encodePacked(_fixtureStringId)));
    }

    function _checkOutcomeValidity(Outcome _outcome) internal pure returns (bool) {
        return
            (Outcome.HOME == _outcome) || (Outcome.AWAY == _outcome) || (Outcome.TIE == _outcome);
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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