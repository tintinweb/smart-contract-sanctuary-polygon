/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

pragma solidity 0.8.15;

struct ReserveConfigurationMap {
    uint256 data;
}

interface IPool {
    function getConfiguration(address asset)
    external
    view
    returns (ReserveConfigurationMap memory);
}

contract LiquidationProtocolFeeGetter {

    address internal constant POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    function getLiquidationProtocolFee(address asset) external view returns (uint256) {
        uint256 data = IPool(POOL).getConfiguration(asset).data;
        return (data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >>
      LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }
}