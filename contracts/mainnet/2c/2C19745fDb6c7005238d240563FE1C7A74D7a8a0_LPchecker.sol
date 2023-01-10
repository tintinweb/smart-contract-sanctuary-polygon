//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Address.sol";

/*
*
* MIT License
* ===========
*
* Copyright financesauce (c) 2022
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

contract LPchecker {

    function checkLP(address _token) public view returns(bool){
        require (_token != address(0), "address 0");
        require (Address.isContract(_token) == true, "not a contract");
        (bool domain,) = _token.staticcall(abi.encodeWithSignature("DOMAIN_SEPARATOR()"));
        (bool minimum,) = _token.staticcall(abi.encodeWithSignature("MINIMUM_LIQUIDITY()"));
        (bool permit,) = _token.staticcall(abi.encodeWithSignature("PERMIT_TYPEHASH()"));
        (bool factory,) = _token.staticcall(abi.encodeWithSignature("factory()"));
        (bool kLast,) = _token.staticcall(abi.encodeWithSignature("kLast()"));
        (bool price0,) = _token.staticcall(abi.encodeWithSignature("price0CumulativeLast()"));
        (bool price1,) = _token.staticcall(abi.encodeWithSignature("price1CumulativeLast()"));
        (bool token0,) = _token.staticcall(abi.encodeWithSignature("token0()"));
        (bool token1,) = _token.staticcall(abi.encodeWithSignature("token1()"));
        if (
            (domain == true) &&
            (minimum == true) &&
            (permit == true) &&
            (factory == true) &&
            (kLast == true) &&
            (price0 == true) &&
            (price1 == true) &&
            (token0 == true) &&
            (token1 == true)
        ){return true;}
        return false;
    }

    function isToken(address _token) external view returns(bool){
        require (_token != address(0), "address 0");
        require (Address.isContract(_token) == true, "not a contract");
        (bool name,) = _token.staticcall(abi.encodeWithSignature("name()"));
        (bool symbol,) = _token.staticcall(abi.encodeWithSignature("symbol()"));
        (bool decimals,) = _token.staticcall(abi.encodeWithSignature("decimals()"));
        (bool totalSupply,) = _token.staticcall(abi.encodeWithSignature("symbol()"));
        if (checkLP(_token)){return false;}
        else{
            if (
                (name == true) &&
                (symbol == true ) &&
                (decimals == true ) &&
                (totalSupply == true )
            ){return true;}
        return false;}
    }

}