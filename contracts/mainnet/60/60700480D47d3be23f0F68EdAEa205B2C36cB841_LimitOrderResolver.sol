pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT

import {Helpers} from "./helpers.sol";

/**
 * @title LimitOrderResolver.
 * @dev Resolver for Limit Order Swap on Uni V3.
 */
contract LimitOrderResolver is Helpers {

    function nftsToClose(
        uint256[] memory tokenIds_
    )
        public
        view
        returns (bool[] memory result_)
    {

        for( uint i=0; i<tokenIds_.length; i++){

            if( limitCon_.nftToOwner(tokenIds_[i]) != address(0)){

                (
                    address token0_,
                    address token1_,
                    uint24 fee_,
                    int24 tickLower_,
                    int24 tickUpper_
                ) = getPositionInfo(tokenIds_[i]);

                (int24 currentTick_) = getCurrentTick(token0_, token1_, fee_);

                if( limitCon_.token0to1(tokenIds_[i]) && currentTick_ > tickUpper_){
                    result_[i] = true;
                }
                if( (!limitCon_.token0to1(tokenIds_[i])) && currentTick_ < tickLower_){
                    result_[i] = true;
                }
            }
        }
    }
}

pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT
import "./interface.sol";
import "./libraries/PoolAddress.sol";

contract Helpers {

    INonfungiblePositionManager constant public nftManager = 
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Factory constant public factory = 
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniLimitOrder public limitCon_ = 
        IUniLimitOrder(0x94F401fAD3ebb89fB7380f5fF6E875A88E6Af916);

    function getPoolAddress(
        address token0,
        address token1,
        uint24 fee
    )
        internal 
        view 
        returns (address poolAddr) 
    {
        poolAddr = PoolAddress.computeAddress(
        nftManager.factory(),
        PoolAddress.PoolKey({ token0: token0, token1: token1, fee: fee }));
    }

    function getCurrentTick(
        address token0_,
        address token1_, 
        uint24 fee_
    )
        public
        view
        returns (int24 currentTick_)
    {
        IUniswapV3PoolState poolState_ = IUniswapV3PoolState(getPoolAddress(token0_, token1_, fee_));
        (
            ,
            currentTick_,
            , 
            , 
            ,
            , 
        ) = poolState_.slot0();

    }

    function getPositionInfo(uint256 tokenId_) 
        public 
        view 
        returns(
            address token0_,
            address token1_,
            uint24 fee_,
            int24 tickLower_,
            int24 tickUpper_)
    {

        (
                    ,
                    ,
                    token0_,
                    token1_,
                    fee_,
                    tickLower_,
                    tickUpper_,
                    ,
                    ,
                    ,
                    ,
                ) = nftManager.positions(tokenId_);
    }

}

pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT

interface IUniswapV3Factory{

      function getPool( address tokenA, address tokenB, uint24 fee) external view returns (address pool);
        
}

interface IUniswapV3PoolState{

    function slot0() external view returns 
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

}

interface IPeripheryImmutableState {

    function factory() external view returns (address);

}

interface INonfungiblePositionManager is IPeripheryImmutableState{

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    
}
interface IUniLimitOrder {

    function nftToOwner(uint256) external view returns (address);

    function token0to1(uint256) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({ token0: tokenA, token1: tokenB, fee: fee });
    }

    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}