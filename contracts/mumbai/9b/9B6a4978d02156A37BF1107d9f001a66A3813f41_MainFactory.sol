// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../core/MainContract.sol";

contract MainFactory{

    uint256 public ctr = 0;

    mapping ( uint256 => address ) public MainAddr;

    function createMain ( ) external {
        ctr = ctr + 1;
        MainContract M1 = new MainContract( );
        MainAddr[ctr] = address(M1);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./BaseContract.sol";

contract MainContract is BaseContract {

    // bytes4( keccak256 ( setA(uint256 ,uint256 ) )

    //0x7aa9a3d5
    function setA( uint256 _a , uint256 _b ) external {
        setFunctionA( _a , true , _b );
    }

    //0xf3180546
    function setB( uint256 _a , uint256 _b ) external {
        setFunctionA( _a , false , _b );
    }


    function callAny (address addr , bytes4 _selector  , uint256 _a , uint256 _b ) external returns( bool ) {
        ( bool success , ) = addr.call(
            abi.encodeWithSelector(
                _selector,
                _a,
                _b
            )
        );
        return success;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract BaseContract {

    struct contractStruct{
        uint256 val1;
    }

    mapping ( uint256 => contractStruct ) public map3;

    function setFunctionA(
        uint256 _a,
        bool _b,
        uint256 _c
    ) internal  returns( bool ){
        if ( _b == true ){
            map3[_a].val1 = _c * _c;
        }else{
            map3[_a].val1 = _c + 2;
        }
        return true;
    }

    function setFunctionB(
        uint256 _a,
        bool _b,
        uint256 _c
    ) private returns( bool ){
        if ( _b == true ){
            map3[_a].val1 = _c * _c;
        }else{
            map3[_a].val1 = _c + 2;
        }
        return true;
    }

    function setBA( uint256 _a , uint256 _b ) internal {
        setFunctionB( _a , true , _b );
    }

    function setBB( uint256 _a , uint256 _b ) internal {
        setFunctionB( _a , false , _b );
    }

}