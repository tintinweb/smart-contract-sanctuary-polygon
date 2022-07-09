// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./RootedToken.sol";
import "./Owned.sol";
import "./EliteToken.sol";
import "./MarketGeneration.sol";
import "./MarketDistribution.sol";
import "./LazarusPit.sol";
import "./RootedTransferGate.sol";
import "./EliteFloorCalculator.sol";
import "./EliteFloorCalculatorV1.sol";
import "./FeeSplitter.sol";
import "./LiquidityController.sol";
import "./StakingToken.sol";
import "./RoyaltyPump.sol";
import "./TokenTimelock.sol";

contract MGEFactory is Owned {
address factory;
//WETH MATIC MAINNET
IERC20 wrappedToken = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

modifier onlyFactory {
    require(msg.sender == factory || msg.sender == owner);
    _;
}
function setFactory(address _factory) public ownerOnly() {
    factory = _factory;
}
function createMGE(address _factoryAddress) public onlyFactory() returns(MarketGeneration) {
   MarketGeneration newGen = new MarketGeneration(_factoryAddress);
   newGen.setController(_factoryAddress);
   return newGen;
}

function createMGD(address _factoryAddress) public onlyFactory() returns(MarketDistribution) {
    MarketDistribution newDist = new MarketDistribution(_factoryAddress);
    newDist.setController(_factoryAddress);
    return newDist;
}
 
    
}