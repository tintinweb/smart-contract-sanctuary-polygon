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

    function getWonUserBetByFixtureId(address address_, string memory _fixtureStringId)
        external
        view
        returns (UserViewFixture memory)
    {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        require(
            _stringEquals(IStorage(address_).getIdToFixtureStringId(fixtureId), _fixtureStringId),
            "Fixture does not exist"
        );
        require(
            (IStorage(address_).getIdToFixtureBetsAmount(fixtureId,
                IStorage(address_).getIdToFixtureWinningOutcome(fixtureId), msg.sender) != 0),
            "Bet does not exist"
        );

        return
            UserViewFixture(
                IStorage(address_).getIdToFixtureStringId(fixtureId),
                IStorage(address_).getIdToFixturePoolSizes(fixtureId, IStorage(address_).getIdToFixtureWinningOutcome(fixtureId)),
                IStorage(address_).getTotalLostPool(fixtureId, IStorage(address_).getIdToFixtureWinningOutcome(fixtureId)),
                (IStorage(address_).getIdToFixtureBettersLength(fixtureId, Outcome.HOME)+
                    IStorage(address_).getIdToFixtureBettersLength(fixtureId, Outcome.AWAY) +
                    IStorage(address_).getIdToFixtureBettersLength(fixtureId, Outcome.TIE)),
                IStorage(address_).getIdToFixtureBetsWon(fixtureId, IStorage(address_).getIdToFixtureWinningOutcome(fixtureId), msg.sender),
                IStorage(address_).getIdToFixtureIsFinished(fixtureId),
                IStorage(address_).getIdToFixtureWinningOutcome(fixtureId),
                IStorage(address_).getIdToFixtureBetsAmount(fixtureId,
                    IStorage(address_).getIdToFixtureWinningOutcome(fixtureId), msg.sender),
                IStorage(address_).getIdToFixtureBetsGains(fixtureId,
                    IStorage(address_).getIdToFixtureWinningOutcome(fixtureId), msg.sender)
            );
    }

    function getBetsByResult(address address_, bool _won) external view returns (UserViewFixture[] memory) {
        uint256 fixtureIdsLength = IStorage(address_).getFixtureIdsLength();
        uint256 resLength = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            if (IStorage(address_).getIdToFixtureIsFinished(id)) {
                if (
                    (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) &&
                    (IStorage(address_).getIdToFixtureBetsWon(id, Outcome.HOME, msg.sender) == _won)
                ) {
                    resLength++;
                }
                if (
                    (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) &&
                    (IStorage(address_).getIdToFixtureBetsWon(id, Outcome.AWAY, msg.sender) == _won)
                ) {
                    resLength++;
                }
                if (
                    (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) &&
                    (IStorage(address_).getIdToFixtureBetsWon(id, Outcome.TIE, msg.sender) == _won)
                ) {
                    resLength++;
                }
            }
        }

        UserViewFixture[] memory result = new UserViewFixture[](resLength);

        uint256 counter = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            if (IStorage(address_).getIdToFixtureIsFinished(id)) {
                if (
                    (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) &&
                    (IStorage(address_).getIdToFixtureBetsWon(id, Outcome.HOME, msg.sender) == _won)
                ) {
                    result[counter] = _getUserViewFixture(address_, i, Outcome.HOME, msg.sender);
                    counter++;
                }
                if (
                    (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) &&
                    (IStorage(address_).getIdToFixtureBetsWon(id, Outcome.AWAY, msg.sender) == _won)
                ) {
                    result[counter] = _getUserViewFixture(address_, i, Outcome.AWAY, msg.sender);
                    counter++;
                }
                if (
                    (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) &&
                    (IStorage(address_).getIdToFixtureBetsWon(id, Outcome.TIE, msg.sender) == _won)
                ) {
                    result[counter] = _getUserViewFixture(address_, i, Outcome.TIE, msg.sender);
                    counter++;
                }
            }
        }
        return result;
    }

    // Returns all bets (finished and ongoing) for the caller
    function getAllBetsByUser(address address_) external view returns (UserViewFixture[] memory) {
        UserViewFixture[] memory finishedBets = getBetsByFinishing(address_, true);
        UserViewFixture[] memory ongoingBets = getBetsByFinishing(address_, false);

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

    function getBetsByFinishing(address address_, bool _isFinished) public view returns (UserViewFixture[] memory) {
        uint256 fixtureIdsLength = IStorage(address_).getFixtureIdsLength();
        uint256 resLength = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            if (IStorage(address_).getIdToFixtureIsFinished(id) == _isFinished) {
                if (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) {
                    resLength++;
                }
                if (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) {
                    resLength++;
                }
                if (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) {
                    resLength++;
                }
            }
        }

        UserViewFixture[] memory result = new UserViewFixture[](resLength);

        uint256 counter = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            if (IStorage(address_).getIdToFixtureIsFinished(id) == _isFinished) {
                if (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender) != 0) {
                    result[counter] = _getUserViewFixture(address_, i, Outcome.HOME, msg.sender);
                    counter++;
                }
                if (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender) != 0) {
                    result[counter] = _getUserViewFixture(address_, i, Outcome.AWAY, msg.sender);
                    counter++;
                }
                if (IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender) != 0) {
                    result[counter] = _getUserViewFixture(address_, i, Outcome.TIE, msg.sender);
                    counter++;
                }
            }
        }
        return result;
    }

    function _getUserViewFixture(
        address address_, 
        uint256 i,
        Outcome _outcome,
        address _better
    ) private view returns (UserViewFixture memory) {
        uint256 id = IStorage(address_).getFixtureIds(i);
        string memory stringId = IStorage(address_).getIdToFixtureStringId(id);
        uint256 prosPool = IStorage(address_).getIdToFixturePoolSizes(id, _outcome);
        uint256 consPool = IStorage(address_).getTotalLostPool(id, _outcome);
        uint256 bettersAmount = (IStorage(address_).getIdToFixtureBettersLength(id, Outcome.HOME) +
            IStorage(address_).getIdToFixtureBettersLength(id, Outcome.AWAY) +
            IStorage(address_).getIdToFixtureBettersLength(id, Outcome.TIE));
        bool won = IStorage(address_).getIdToFixtureBetsWon(id, _outcome, _better);
        bool isFinished = IStorage(address_).getIdToFixtureIsFinished(id);
        uint256 betAmount = IStorage(address_).getIdToFixtureBetsAmount(id, _outcome, _better);
        uint256 betGains = IStorage(address_).getIdToFixtureBetsGains(id, _outcome, _better);
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

contract FixtureBetReader is ITypes {
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

    // Returns all bets (finished and ongoing) present in the service
    function getAllBets(address address_) external view returns (ViewIndexFixture[] memory) {
        uint256 fixtureIdsLength = IStorage(address_).getFixtureIdsLength();

        ViewIndexFixture[] memory result = new ViewIndexFixture[](fixtureIdsLength);

        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            result[i] = ViewIndexFixture(
                IStorage(address_).getIdToFixtureStringId(id),
                IStorage(address_).getIdToFixtureTotalPoolSize(id),
                (IStorage(address_).getIdToFixtureBettersLength(id, Outcome.HOME) +
                    IStorage(address_).getIdToFixtureBettersLength(id, Outcome.AWAY) +
                    IStorage(address_).getIdToFixtureBettersLength(id, Outcome.TIE)),
                IStorage(address_).getIdToFixtureIsFinished(id)
            );
        }

        return result;
    }

    function getBetsByFixtureId(address address_, string memory _fixtureStringId)
        external
        view
        returns (ViewFixture[] memory)
    {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));

        ViewFixture[] memory result = new ViewFixture[](3);

        uint256 counter = 0;

        result[counter] = ViewFixture(
            IStorage(address_).getIdToFixtureStringId(fixtureId),
            IStorage(address_).getIdToFixturePoolSizes(fixtureId, Outcome.HOME),
            IStorage(address_).getTotalLostPool(fixtureId, Outcome.HOME),
            IStorage(address_).getIdToFixtureBettersLength(fixtureId, Outcome.HOME),
            (IStorage(address_).getIdToFixtureWinningOutcome(fixtureId) == Outcome.HOME),
            IStorage(address_).getIdToFixtureIsFinished(fixtureId),
            Outcome.HOME,
            IStorage(address_).getIdToFixtureBetsAmount(fixtureId, Outcome.HOME, msg.sender),
            IStorage(address_).getIdToFixtureBetsGains(fixtureId, Outcome.HOME, msg.sender)
        );
        counter++;

        result[counter] = ViewFixture(
            IStorage(address_).getIdToFixtureStringId(fixtureId),
            IStorage(address_).getIdToFixturePoolSizes(fixtureId, Outcome.AWAY),
            IStorage(address_).getTotalLostPool(fixtureId, Outcome.AWAY),
            IStorage(address_).getIdToFixtureBettersLength(fixtureId, Outcome.AWAY),
            (IStorage(address_).getIdToFixtureWinningOutcome(fixtureId) == Outcome.AWAY),
            IStorage(address_).getIdToFixtureIsFinished(fixtureId),
            Outcome.AWAY,
            IStorage(address_).getIdToFixtureBetsAmount(fixtureId, Outcome.AWAY, msg.sender),
            IStorage(address_).getIdToFixtureBetsGains(fixtureId, Outcome.AWAY, msg.sender)
        );
        counter++;

        result[counter] = ViewFixture(
            IStorage(address_).getIdToFixtureStringId(fixtureId),
            IStorage(address_).getIdToFixturePoolSizes(fixtureId, Outcome.TIE),
            IStorage(address_).getTotalLostPool(fixtureId, Outcome.TIE),
            IStorage(address_).getIdToFixtureBettersLength(fixtureId, Outcome.TIE),
            (IStorage(address_).getIdToFixtureWinningOutcome(fixtureId) == Outcome.TIE),
            IStorage(address_).getIdToFixtureIsFinished(fixtureId),
            Outcome.TIE,
            IStorage(address_).getIdToFixtureBetsAmount(fixtureId, Outcome.TIE, msg.sender),
            IStorage(address_).getIdToFixtureBetsGains(fixtureId, Outcome.TIE, msg.sender)
        );

        return result;
    }

    function getActiveBets(address address_) external view returns (ViewFixture[3][] memory) {
        uint256 fixtureIdsLength = IStorage(address_).getFixtureIdsLength();
        uint256 activeCount = 0;
        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            if (!IStorage(address_).getIdToFixtureIsFinished(id)) {
                activeCount++;
            }
        }
        ViewFixture[3][] memory result = new ViewFixture[3][](activeCount);
        uint256 curIndex = 0;

        for (uint256 i = 0; i < fixtureIdsLength; i++) {
            uint256 id = IStorage(address_).getFixtureIds(i);
            if (!IStorage(address_).getIdToFixtureIsFinished(id)) {
                result[curIndex] = [
                    ViewFixture(
                        IStorage(address_).getIdToFixtureStringId(id),
                        IStorage(address_).getIdToFixturePoolSizes(id, Outcome.HOME),
                        IStorage(address_).getTotalLostPool(id, Outcome.HOME),
                        IStorage(address_).getIdToFixtureBettersLength(id, Outcome.HOME),
                        (IStorage(address_).getIdToFixtureWinningOutcome(id) == Outcome.HOME),
                        IStorage(address_).getIdToFixtureIsFinished(id),
                        Outcome.HOME,
                        IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.HOME, msg.sender),
                        IStorage(address_).getIdToFixtureBetsGains(id, Outcome.HOME, msg.sender)
                    ),
                    ViewFixture(
                        IStorage(address_).getIdToFixtureStringId(id),
                        IStorage(address_).getIdToFixturePoolSizes(id, Outcome.AWAY),
                        IStorage(address_).getTotalLostPool(id, Outcome.AWAY),
                        IStorage(address_).getIdToFixtureBettersLength(id, Outcome.AWAY),
                        (IStorage(address_).getIdToFixtureWinningOutcome(id) == Outcome.AWAY),
                        IStorage(address_).getIdToFixtureIsFinished(id),
                        Outcome.AWAY,
                        IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.AWAY, msg.sender),
                        IStorage(address_).getIdToFixtureBetsGains(id, Outcome.AWAY, msg.sender)
                    ),
                    ViewFixture(
                        IStorage(address_).getIdToFixtureStringId(id),
                        IStorage(address_).getIdToFixturePoolSizes(id, Outcome.TIE),
                        IStorage(address_).getTotalLostPool(i,  Outcome.TIE),
                        IStorage(address_).getIdToFixtureBettersLength(id, Outcome.TIE),
                        (IStorage(address_).getIdToFixtureWinningOutcome(id) == Outcome.TIE),
                        IStorage(address_).getIdToFixtureIsFinished(id),
                        Outcome.TIE,
                        IStorage(address_).getIdToFixtureBetsAmount(id, Outcome.TIE, msg.sender),
                        IStorage(address_).getIdToFixtureBetsGains(id, Outcome.TIE, msg.sender)                    
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