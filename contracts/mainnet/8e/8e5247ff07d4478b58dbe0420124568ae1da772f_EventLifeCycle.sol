/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// File: contracts/ILeverage.sol

pragma solidity ^0.7.4;


interface ILeverage {
    function eventStart(uint256 eventId) external;

    function eventEnd(uint256 eventId) external;

    function changeMaxUsageThreshold(uint256 percent) external;

    function changeMaxLossThreshold(uint256 percent) external;
}

// File: contracts/IPendingOrders.sol

pragma solidity ^0.7.4;


interface IPendingOrders {
    function eventStart(uint256 _eventId) external;

    function eventEnd(uint256 _eventId) external;

    function createOrder(
        uint256 _amount,
        bool _isWhite,
        uint256 _eventId
    ) external;

    function cancelOrder(uint256 orderId) external;

    function _eventContractAddress() external view returns (address);

    function _predictionPool() external view returns (address);

    function withdrawCollateral() external returns (uint256);
}

// File: contracts/Eventable.sol

pragma solidity ^0.7.4;


interface Eventable {
    function submitEventStarted(uint256 currentEventPriceChangePercent)
        external;

    function submitEventResult(int8 _result) external;
}

// File: contracts/EventLifeCycle.sol

pragma solidity ^0.7.4;




contract EventLifeCycle {
    address public _governanceAddress;
    mapping(address => bool) public _oracleAddresses;
    GameEvent public _queuedEvent =
        GameEvent(0, 0, 0, "q", "q", "q", "q", "q", 0);
    GameEvent public _ongoingEvent =
        GameEvent(0, 0, 0, "q", "q", "q", "q", "q", 0);
    bool public eventIsInProgress = false;
    IPendingOrders public _pendingOrders;
    ILeverage public _leverage;
    bool public _usePendingOrders;
    bool public _useLeverage;

    event GovernanceAddressChanged(address governance);
    event OracleAddressAdded(address oracle);
    event OracleAddressExcluded(address oracle);
    event PredictionPoolAddressChanged(address prediction);
    event GameEventStarted(uint256 time, uint256 eventId);
    event GameEventEnded(int8 result, uint256 eventId);

    Eventable public _predictionPool;

    constructor(
        address governanceAddress,
        address oracleAddress,
        address predictionPoolAddress
    ) {
        _governanceAddress = governanceAddress;
        _oracleAddresses[oracleAddress] = true;
        _predictionPool = Eventable(predictionPoolAddress);
    }

    modifier onlyGovernance() {
        require(
            _governanceAddress == msg.sender,
            "Caller should be Governance"
        );
        _;
    }

    modifier onlyOracle() {
        require(
            _oracleAddresses[msg.sender] == true,
            "Caller should be Oracle"
        );
        _;
    }

    struct GameEvent {
        /* solhint-disable prettier/prettier */
        uint256 priceChangePart;        // in percent
        uint256 eventStartTimeExpected; // in seconds since 1970
        uint256 eventEndTimeExpected;   // in seconds since 1970
        string blackTeam;
        string whiteTeam;
        string eventType;
        string eventSeries;
        string eventName;
        uint256 eventId;
        /* solhint-enable prettier/prettier */
    }

    function addNewEvent(
        uint256 priceChangePart_,
        uint256 eventStartTimeExpected_,
        uint256 eventEndTimeExpected_,
        string calldata blackTeam_,
        string calldata whiteTeam_,
        string calldata eventType_,
        string calldata eventSeries_,
        string calldata eventName_,
        uint256 eventId_
    ) public onlyOracle {
        _queuedEvent.priceChangePart = priceChangePart_;
        _queuedEvent.eventStartTimeExpected = eventStartTimeExpected_;
        _queuedEvent.eventEndTimeExpected = eventEndTimeExpected_;
        _queuedEvent.blackTeam = blackTeam_;
        _queuedEvent.whiteTeam = whiteTeam_;
        _queuedEvent.eventType = eventType_;
        _queuedEvent.eventSeries = eventSeries_;
        _queuedEvent.eventName = eventName_;
        _queuedEvent.eventId = eventId_;
    }

    function startEvent() public onlyOracle returns (uint256) {
        require(
            eventIsInProgress == false,
            "FINISH PREVIOUS EVENT TO START NEW EVENT"
        );
        _ongoingEvent = _queuedEvent;
        GameEvent memory ongoing = _ongoingEvent;
        if (_useLeverage) {
            _leverage.eventStart(ongoing.eventId);
            _pendingOrders.eventStart(ongoing.eventId);
        } else if (_usePendingOrders) {
            _pendingOrders.eventStart(ongoing.eventId);
        }
        _predictionPool.submitEventStarted(ongoing.priceChangePart);
        eventIsInProgress = true;
        emit GameEventStarted(block.timestamp, ongoing.eventId);
        return ongoing.eventId;
    }

    function addAndStartEvent(
        uint256 priceChangePart_, // in 0.0001 parts percent of a percent dose
        uint256 eventStartTimeExpected_,
        uint256 eventEndTimeExpected_,
        string calldata blackTeam_,
        string calldata whiteTeam_,
        string calldata eventType_,
        string calldata eventSeries_,
        string calldata eventName_,
        uint256 eventId_
    ) external onlyOracle returns (uint256) {
        require(
            eventIsInProgress == false,
            "FINISH PREVIOUS EVENT TO START NEW EVENT"
        );
        addNewEvent(
            priceChangePart_,
            eventStartTimeExpected_,
            eventEndTimeExpected_,
            blackTeam_,
            whiteTeam_,
            eventType_,
            eventSeries_,
            eventName_,
            eventId_
        );
        startEvent();

        return eventId_;
    }

    /**
     * Receive event results. Receives result of an event in value between -1 and 1. -1 means
     * Black won,1 means white-won, 0 means draw.
     */
    function endEvent(int8 _result) external onlyOracle {
        require(
            eventIsInProgress == true,
            "There is no ongoing event to finish"
        );
        _predictionPool.submitEventResult(_result);
        uint256 eventId = _ongoingEvent.eventId;

        if (_useLeverage) {
            _pendingOrders.eventEnd(eventId);
            _leverage.eventEnd(eventId);
        } else if (_usePendingOrders) {
            _pendingOrders.eventEnd(eventId);
        }
        emit GameEventEnded(_result, eventId);
        eventIsInProgress = false;
    }

    function changeGovernanceAddress(address governanceAddress)
        public
        onlyGovernance
    {
        require(
            governanceAddress != address(0),
            "New governance address should be not null"
        );
        _governanceAddress = governanceAddress;
        emit GovernanceAddressChanged(governanceAddress);
    }

    function changePredictionPoolAddress(address poolAddress)
        public
        onlyGovernance
    {
        require(
            poolAddress != address(0),
            "New pool address should be not null"
        );
        _predictionPool = Eventable(poolAddress);
        emit PredictionPoolAddressChanged(poolAddress);
    }

    function addOracleAddress(address oracleAddress) public onlyGovernance {
        require(
            oracleAddress != address(0),
            "New oracle address should be not null"
        );
        _oracleAddresses[oracleAddress] = true;
        emit OracleAddressAdded(oracleAddress);
    }

    function excludeOracleAddress(address oracleAddress) public onlyGovernance {
        require(
            oracleAddress != address(0),
            "Oracle address should be not null"
        );
        delete _oracleAddresses[oracleAddress];
        emit OracleAddressExcluded(oracleAddress);
    }

    function setPendingOrders(
        address pendingOrdersAddress,
        bool usePendingOrders
    ) external onlyGovernance {
        _pendingOrders = IPendingOrders(pendingOrdersAddress);
        _usePendingOrders = usePendingOrders;
    }

    function setLeverage(address leverageAddress, bool useLeverage)
        external
        onlyGovernance
    {
        _leverage = ILeverage(leverageAddress);
        _useLeverage = useLeverage;
    }
}