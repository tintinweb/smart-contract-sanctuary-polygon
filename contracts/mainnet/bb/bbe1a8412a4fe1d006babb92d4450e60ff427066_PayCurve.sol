// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { PayCurveInterface } from "./interfaces/PayCurveInterface.sol";

contract PayCurve is 
    PayCurveInterface 
{
    constructor () {}

    /// @notice Returns the value of the curve at x.
    function curvePoint(uint256 x) 
        public 
        pure 
        returns (
            uint256
        ) 
    {
        return x**2;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface PayCurveInterface {
    function curvePoint(uint256 x) 
        external 
        returns (
            uint256
        );
}