//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.10;

import "FullMath.sol";
import { SafeCast } from "SafeCast.sol";
import { Address } from "Address.sol";
import { ISetToken } from "ISetToken.sol";
import "./KellyManager.sol";

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract KellyResolver {
    using Address for address;

    AggregatorV3Interface internal ethUsdAggregator;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(address _ethUsdAggregator) public {
        ethUsdAggregator = AggregatorV3Interface(_ethUsdAggregator);
    }
    
    // Gelato Resolver Function, can be called by anyone. Only an operator can execute the payload
    function checker(address _setToken) external view returns (bool canExec, bytes memory execPayload) {

        KellyManager kellyManager = KellyManager(ISetToken(_setToken).manager());

        // Has a day passed?
        // solhint-disable-next-line not-rely-on-time
        if( (kellyManager.lastExecuted() + 86400) > block.timestamp ) {
            canExec = false;
            execPayload = bytes("86400 seconds haven't passed yet");
        }
        else if( tx.gasprice > kellyManager.gasLimit() ) {
            canExec = false;
            execPayload = bytes("gas limit exceeded");
        }
        else {

            // Get the current position data
            ISetToken setToken = ISetToken(_setToken);
            address[] memory components = setToken.getComponents();
            int256 collateral = setToken.getTotalComponentRealUnits(components[0]);
            int256 debt = -setToken.getTotalComponentRealUnits(components[1]);
            require(collateral > 0 && debt > 0, "invalid debt or collateral");

            // Get the current collateral price
            (,int256 answer,,,) = ethUsdAggregator.latestRoundData();

            // Convert collateral into debt units
            uint256 scale = 10 ** uint256(AggregatorV3Interface(components[0]).decimals()
                + ethUsdAggregator.decimals() - AggregatorV3Interface(components[1]).decimals());
            int256 ethValue = SafeCast.toInt256(
                FullMath.mulDiv(
                    SafeCast.toUint256(collateral),
                    SafeCast.toUint256(answer),
                    scale
                )
            );

            // What is the value of 1 set token in debt terms
            int256 tokenPrice = ethValue - debt;

            // What is the desired value of the collateral in debt terms
            ethValue = SafeCast.toInt256(
                FullMath.mulDiv(SafeCast.toUint256(tokenPrice), kellyManager.leverage(), 1 ether)
            );
            
            // Get the change in debt and collateral
            debt = debt - ethValue + tokenPrice;
            collateral = collateral - SafeCast.toInt256(
                FullMath.mulDiv(
                    SafeCast.toUint256(ethValue),
                    scale,
                    SafeCast.toUint256(answer)
                )
            );

            // Setup the payload
            canExec = true;
            if( collateral > 0 ) {
                execPayload = abi.encodeWithSelector(
                    KellyManager(ISetToken(_setToken).manager()).operatorExecute.selector,
                    _setToken,
                    IAToken(components[0]).UNDERLYING_ASSET_ADDRESS(),
                    components[1],
                    collateral,
                    FullMath.mulDiv(SafeCast.toUint256(debt), kellyManager.slippage(), 1 ether),
                    "AMMSplitterExchangeAdapter",
                    "");
            }
            else {
                execPayload = abi.encodeWithSelector(
                    KellyManager(ISetToken(_setToken).manager()).operatorExecute.selector,
                    _setToken,
                    components[1],
                    IAToken(components[0]).UNDERLYING_ASSET_ADDRESS(),
                    -debt,
                    FullMath.mulDiv(SafeCast.toUint256(-collateral), kellyManager.slippage(), 1 ether),
                    "AMMSplitterExchangeAdapter",
                    "");
            }
        }        
    }
}