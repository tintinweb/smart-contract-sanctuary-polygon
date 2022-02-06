// SPDX-License-Identifier: GNU Affero
pragma solidity ^0.6.0;

import "EnumerableSet.sol";

import "IStrategyFacade.sol";

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;
}

/// @title Facade contract for Gelato Resolver contract
/// @author Tesseract Finance, Chimera
contract StrategyFacade is IStrategyFacade {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal availableStrategies;
    uint256 public totalStrats;
    address public resolver;
    address public owner;
    uint256 public interval;
    uint256 public lastBlock;

    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);
    event ResolverContractUpdated(address resolver);
    event ErrorHandled(bytes indexed reason, address indexed strategy);

    modifier onlyResolver() {
        require(
            msg.sender == resolver,
            "StrategyFacade: Only Gelato Resolver can call"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "StrategyFacade: Only owner can call");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setResolver(address _resolver) public onlyOwner {
        resolver = _resolver;

        emit ResolverContractUpdated(_resolver);
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setInterval(uint256 _interval) public onlyOwner {
        interval = _interval;
    }

    function addStrategy(address _strategy) public onlyOwner {
        require(
            !availableStrategies.contains(_strategy),
            "StrategyFacade::addStrategy: Strategy already added"
        );

        availableStrategies.add(_strategy);
        lastBlock = block.timestamp;
        totalStrats++;

        emit StrategyAdded(_strategy);
    }

    function getStrategy(uint256 i) public view returns (address strat) {
        strat = availableStrategies.at(i);
    }

    function removeStrategy(address _strategy) public onlyOwner {
        require(
            availableStrategies.contains(_strategy),
            "StrategyFacade::removeStrategy: Strategy already removed"
        );

        availableStrategies.remove(_strategy);

        emit StrategyRemoved(_strategy);
    }

    function gelatoCanHarvestAny(uint256 _callCost)
        public
        view
        returns (bool canExec)
    {
        if (lastBlock + interval > block.timestamp) {
            canExec = false;
            return canExec; // enforce minimal interval
        }

        uint256 callable = 0;
        for (uint256 i; i < availableStrategies.length(); i++) {
            address currentStrategy = availableStrategies.at(i);
            if (StrategyAPI(currentStrategy).harvestTrigger(_callCost)) {
                callable++;
            }
        }

        if (callable > 0) {
            canExec = true;
        } else {
            canExec = false;
        }
        return canExec;
    }

    function checkHarvest(uint256 _callCost)
        public
        view
        override
        returns (bool canExec, address strategy)
    {
        for (uint256 i; i < availableStrategies.length(); i++) {
            address currentStrategy = availableStrategies.at(i);
            if (StrategyAPI(currentStrategy).harvestTrigger(_callCost)) {
                return (canExec = true, strategy = currentStrategy);
            }
        }

        return (canExec = false, strategy = address(0));
    }

    function harvest(address _strategy) public override onlyResolver {
        try StrategyAPI(_strategy).harvest() {} catch (bytes memory reason) {
            emit ErrorHandled(reason, _strategy);
        }
    }

    function harvestAll(uint256 _callCost) public override onlyResolver {
        for (uint256 i; i < availableStrategies.length(); i++) {
            address currentStrategy = availableStrategies.at(i);
            if (StrategyAPI(currentStrategy).harvestTrigger(_callCost)) {
                harvest(currentStrategy);
            }
        }
        lastBlock = block.timestamp;
    }

    function checkAll(uint256 _callCost)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = gelatoCanHarvestAny(_callCost);
        execPayload = abi.encodeWithSelector(
            IStrategyFacade.harvestAll.selector,
            _callCost
        );
    }

    function check(uint256 _callCost)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        (bool _canExec, address _strategy) = checkHarvest(_callCost);

        canExec = _canExec;

        execPayload = abi.encodeWithSelector(
            IStrategyFacade.harvest.selector,
            address(_strategy)
        );
    }
}