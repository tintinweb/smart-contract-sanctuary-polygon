pragma solidity ^0.7.6;

// SPDX-License-Identifier: Apache License 2.0

import "./Suite.sol";
import "./ISuiteList.sol";
import "../IPredictionPool.sol";
import "../IEventLifeCycle.sol";
import "../ILeverage.sol";
import "../Common/IERC20.sol";

contract SuiteFactory is Ownable {
    ISuiteList public _suiteList;
    IERC20 public _commissionToken;
    uint256 public _commissionAmount;

    constructor(address token, uint256 amount) {
        _commissionToken = IERC20(token);
        _commissionAmount = amount;
    }

    event SuiteDeployed(
        string suiteName,
        address suiteAddress,
        address suiteOwner
    );

    event CommissionChanged(uint256 newValue);

    function deploySuite(
        string memory suiteName,
        address collateralTokenAddress
    ) external returns (address) {
        require(
            _suiteList._whiteList() != address(0),
            "WhiteList address not defined"
        );
        require(bytes(suiteName).length > 0, "Parameter suiteName is null");
        require(
            _commissionToken.balanceOf(msg.sender) >= _commissionAmount,
            "You don't have enough commission tokens for the action"
        );
        require(
            _commissionToken.allowance(msg.sender, address(this)) >=
                _commissionAmount,
            "Not enough delegated commission tokens for the action"
        );

        Suite suite = new Suite(
            suiteName,
            collateralTokenAddress,
            _suiteList._whiteList()
        );

        emit SuiteDeployed(suiteName, address(suite), msg.sender);

        require(
            _commissionToken.transferFrom(
                msg.sender,
                address(this),
                _commissionAmount
            ),
            "Transfer commission failed"
        );

        suite.transferOwnership(msg.sender);
        _suiteList.addSuite(address(suite), msg.sender);

        return address(suite);
    }

    function setSuiteList(address suiteListAddress) external onlyOwner {
        _suiteList = ISuiteList(suiteListAddress);
    }

    function setCommission(uint256 amount) external onlyOwner {
        _commissionAmount = amount;
        emit CommissionChanged(amount);
    }

    function setComissionToken(address token) external onlyOwner {
        _commissionToken = IERC20(token);
    }

    function withdrawComission() public onlyOwner {
        uint256 balance = _commissionToken.balanceOf(address(this));
        require(
            _commissionToken.transfer(msg.sender, balance),
            "Unable to transfer"
        );
    }

    function enablePendingOrders(address suiteAddress) external {
        Suite suite = Suite(suiteAddress);
        address suiteOwner = suite.owner();

        require(suiteOwner == msg.sender, "Caller should be suite owner");

        address predictionPoolAddress = suite.contracts(
            1 // id for PREDICTION_POOL
        );

        require(
            predictionPoolAddress != address(0),
            "You must create PredictionPool contract"
        );

        address pendingOrdersAddress = suite.contracts(
            3 // id for PENDING_ORDERS
        );

        require(
            pendingOrdersAddress != address(0),
            "You must create PendingOrders contract"
        );

        address eventLifeCycleAddress = suite.contracts(
            2 // id for EVENT_LIFE_CYCLE
        );

        require(
            eventLifeCycleAddress != address(0),
            "You must create EventLifeCycle contract"
        );

        IPredictionPool ipp = IPredictionPool(predictionPoolAddress);
        IEventLifeCycle elc = IEventLifeCycle(eventLifeCycleAddress);

        require(
            (ipp._blackBought() == 0 && ipp._whiteBought() == 0),
            "The action is not available while there are orders in the PredictionPool"
        );

        ipp.changeOrderer(pendingOrdersAddress);
        ipp.setOnlyOrderer(true);

        elc.setPendingOrders(pendingOrdersAddress, true);
    }

    function enableLeverage(address suiteAddress) external {
        Suite suite = Suite(suiteAddress);
        address suiteOwner = suite.owner();

        require(suiteOwner == msg.sender, "Caller should be suite owner");

        address eventLifeCycleAddress = suite.contracts(
            2 // id for EVENT_LIFE_CYCLE
        );

        require(
            eventLifeCycleAddress != address(0),
            "You must create EventLifeCycle contract"
        );

        address leverageAddress = suite.contracts(
            4 // id for LEVERAGE
        );

        require(
            leverageAddress != address(0),
            "You must create Leverage contract"
        );

        IEventLifeCycle elc = IEventLifeCycle(eventLifeCycleAddress);
        elc.setLeverage(leverageAddress, true);
    }

    function leverageChangeMaxUsageThreshold(
        address suiteAddress,
        uint256 percent
    ) external {
        Suite suite = Suite(suiteAddress);
        address suiteOwner = suite.owner();

        require(suiteOwner == msg.sender, "Caller should be suite owner");

        address leverageAddress = suite.contracts(
            4 // id for LEVERAGE
        );

        require(
            leverageAddress != address(0),
            "You must create Leverage contract"
        );

        ILeverage levc = ILeverage(leverageAddress);

        levc.changeMaxUsageThreshold(percent);
    }

    function leverageChangeMaxLossThreshold(
        address suiteAddress,
        uint256 percent
    ) external {
        Suite suite = Suite(suiteAddress);
        address suiteOwner = suite.owner();

        require(suiteOwner == msg.sender, "Caller should be suite owner");

        address leverageAddress = suite.contracts(
            4 // id for LEVERAGE
        );

        require(
            leverageAddress != address(0),
            "You must create Leverage contract"
        );

        ILeverage levc = ILeverage(leverageAddress);

        levc.changeMaxLossThreshold(percent);
    }
}

pragma solidity ^0.7.4;

// "SPDX-License-Identifier: MIT"

interface IPredictionPool {
    function buyWhite(uint256 maxPrice, uint256 payment) external;

    function buyBlack(uint256 maxPrice, uint256 payment) external;

    function sellWhite(uint256 tokensAmount, uint256 minPrice) external;

    function sellBlack(uint256 tokensAmount, uint256 minPrice) external;

    function changeGovernanceAddress(address governanceAddress) external;

    function _whitePrice() external returns (uint256);

    function _blackPrice() external returns (uint256);

    function _whiteBought() external returns (uint256);

    function _blackBought() external returns (uint256);

    function _whiteToken() external returns (address);

    function _blackToken() external returns (address);

    function _thisCollateralization() external returns (address);

    function _eventStarted() external view returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function FEE() external returns (uint256);

    function init(
        address governanceWalletAddress,
        address eventContractAddress,
        address controllerWalletAddress,
        address ordererAddress,
        bool onlyOrderer
    ) external;

    function changeFees(
        uint256 fee,
        uint256 governanceFee,
        uint256 controllerFee,
        uint256 bwAdditionFee
    ) external;

    function changeOrderer(address newOrderer) external;

    function setOnlyOrderer(bool only) external;
}

pragma solidity ^0.7.4;

// "SPDX-License-Identifier: MIT"

interface ILeverage {
    function eventStart(uint256 eventId) external;

    function eventEnd(uint256 eventId) external;

    function changeMaxUsageThreshold(uint256 percent) external;

    function changeMaxLossThreshold(uint256 percent) external;
}

pragma solidity ^0.7.4;

// pragma abicoder v2;

// "SPDX-License-Identifier: MIT"
interface IEventLifeCycle {
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
    ) external;

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
    ) external returns (uint256);

    function startEvent() external returns (uint256);

    function endEvent(int8 _result) external;

    function _ongoingEvent()
        external
        view
        returns (
            uint256 priceChangePart,
            uint256 eventStartTimeExpected,
            uint256 eventEndTimeExpected,
            string calldata blackTeam,
            string calldata whiteTeam,
            string calldata eventType,
            string calldata eventSeries,
            string calldata eventName,
            uint256 gameEventId
        );

    function _usePendingOrders() external view returns (bool);

    function _pendingOrders() external view returns (address);

    function setPendingOrders(
        address pendingOrdersAddress,
        bool usePendingOrders
    ) external;

    function setLeverage(address leverageAddress, bool useLeverage) external;

    function changeGovernanceAddress(address governanceAddress) external;
}

pragma solidity ^0.7.6;

// SPDX-License-Identifier: Apache License 2.0

import "../Common/Ownable.sol";

contract WhiteList is Ownable {
    mapping(uint8 => address) public _allowedFactories;

    function add(uint8 factoryType, address factoryAddress) external onlyOwner {
        _allowedFactories[factoryType] = factoryAddress;
    }

    function remove(uint8 factoryType) external onlyOwner {
        _allowedFactories[factoryType] = address(0);
    }
}

pragma solidity ^0.7.6;

// SPDX-License-Identifier: Apache License 2.0

import "../Common/Ownable.sol";
import "./WhiteList.sol";

contract Suite is Ownable {
    WhiteList public _whiteList;

    string public _suiteName;
    address public _collateralTokenAddress;
    address public _suiteFactoryAddress;

    modifier onlyWhiteListed(uint8 contractType) {
        require(
            _whiteList._allowedFactories(contractType) == msg.sender,
            "Caller should be in White List"
        );
        _;
    }

    mapping(uint8 => address) public contracts;

    constructor(
        string memory suiteName,
        address collateralTokenAddress,
        address whiteList
    ) {
        require(
            collateralTokenAddress != address(0),
            "Collateral Token Address should not be null"
        );
        require(
            whiteList != address(0),
            "White List Address should not be null"
        );
        _suiteName = suiteName;
        _collateralTokenAddress = collateralTokenAddress;
        _suiteFactoryAddress = msg.sender; // suiteFactory
        _whiteList = WhiteList(whiteList);
    }

    function addContract(uint8 contractType, address contractAddress)
        external
        onlyWhiteListed(contractType)
    {
        contracts[contractType] = contractAddress;
    }
}

pragma solidity ^0.7.6;

// SPDX-License-Identifier: Apache License 2.0

interface ISuiteList {
    function addSuite(address suiteAddress, address suiteOwner) external;

    function deleteSuite(address suiteAddress) external;

    function getSuitePage(uint256 startIndex, uint256 count)
        external
        view
        returns (address[] memory);

    function setSuiteFactory(address factoryAddress) external;

    function _whiteList() external view returns (address);

    function changeSuiteOwner(address suiteAddress, address candidateAddress)
        external;

    function isSuiteOwner(address suiteAddress, address candidateAddress)
        external
        view
        returns (bool);
}

pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}