// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./SafeMath.sol";
/*
No hay en BSC ni en Matic Testnet AUG par
Uso eth/usd 0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7



polygon testnet 0x0715A7794a1dc8e42615F059dD6e406A6594651A

polygon produccion AUG/USD 0x0C466540B2ee1a31b441671eac0ca886e051E410
*/
interface QueryInterface {
    function latestTimestamp() external view returns(uint);
    function latestAnswer() external view returns(uint);
    function decimals() external view returns(uint);
}

contract showPrices {
    using SafeMath for uint256;
    address queryAddress;
    address owner;

    constructor(address _queryAddress) {
        queryAddress = _queryAddress;
        owner = msg.sender;
    }
    function changeAddress(address _newAddress) public {
        require(owner==msg.sender,string("Only Owner"));
        queryAddress=_newAddress;
    }
    function getPrice() external view returns (uint) {
        uint _ounces = 283495; // mul x 10000
        uint _gramPrice; 
        _gramPrice = QueryInterface(queryAddress).latestAnswer().div(_ounces);
        _gramPrice = _gramPrice.mul(10000);
        
        return _gramPrice*(1e10);
    }
    function getLastUpdate() external view returns (uint) {
        return QueryInterface(queryAddress).latestTimestamp();
    }
}