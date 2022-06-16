// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interfaces/IStorage.sol";
import "./interfaces/ITypes.sol";


contract FixtureBetWriter is ITypes {
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

    function placeBet(address storageAddress, string calldata _fixtureStringId, Outcome _outcome) external payable {
        require(IStorage(storageAddress).checkOutcomeValidity(_outcome), "Invalid outcome");
        require(msg.value > 0, "Cannot place zero-value bet");

        uint256 fixtureId = _checkAndGetFixtureId(storageAddress, _fixtureStringId);
        // TODO: TBD the case for _stringEquals(idToFixture[fixtureId].stringId, ""))
        if (IStorage(storageAddress).getIdToFixtureTotalPoolSize(fixtureId) == 0) {
            IStorage(storageAddress).pushFixtureIds(fixtureId);
        }

        IStorage(storageAddress).setIdToFixtureStringId(fixtureId, _fixtureStringId);
        if (IStorage(storageAddress).getIdToFixtureBetsBetter(fixtureId, _outcome, msg.sender) == address(0)) {
            IStorage(storageAddress).pushIdToFixtureBetters(fixtureId, _outcome, msg.sender);
            IStorage(storageAddress).setIdToFixtureBetsBetter(fixtureId, _outcome, msg.sender);
        }

        IStorage(storageAddress).addIdToFixturePoolSizes(fixtureId, _outcome, msg.value);
        IStorage(storageAddress).addIdToFixtureTotalPoolSize(fixtureId, msg.value);
        IStorage(storageAddress).addIdToFixtureBetsAmount(fixtureId, _outcome, msg.sender, msg.value);
    }

    function claimBet(address storageAddress, string calldata _fixtureStringId, Outcome _outcome) external {
        uint256 fixtureId = uint256(keccak256(abi.encodePacked(_fixtureStringId)));
        uint256 gains = IStorage(storageAddress).getIdToFixtureBetsGains(fixtureId, _outcome, msg.sender);
        require(IStorage(storageAddress).getIdToFixtureIsFinished(fixtureId), "Match was not ended");
        require(IStorage(storageAddress).checkOutcomeValidity(_outcome), "Outcome doesn't exist");
        require(IStorage(storageAddress).getIdToFixtureBetsWon(fixtureId, _outcome, msg.sender), "Bet does not won");
        require((gains != 0), "Bet already claimed");

        IStorage(storageAddress).setIdToFixtureBetsGains(fixtureId, _outcome, msg.sender, 0);
        (bool success, ) = payable(msg.sender).call{value: gains}("");
        require(success, "Transfer failed.");
    }

    // TODO: Check if require() throws out of caller function
    function _checkAndGetFixtureId(address storageAddress, string calldata _fixtureStringId)
        internal
        view
        returns (uint256)
    {
        require(
            !IStorage(storageAddress).getIdToFixtureIsFinished(uint256(keccak256(abi.encodePacked(_fixtureStringId)))),
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