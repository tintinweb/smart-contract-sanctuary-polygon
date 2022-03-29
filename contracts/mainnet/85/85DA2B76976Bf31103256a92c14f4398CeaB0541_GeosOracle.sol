/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

/*
  /$$$$$$                                          /$$          
 /$$__  $$                                        | $$          
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$ | $$ /$$   /$$
| $$ /$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$| $$  | $$
| $$|_  $$| $$$$$$$$| $$  \ $$| $$  \ $$| $$  \ $$| $$| $$  | $$
| $$  \ $$| $$_____/| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$
|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$$$$$$/|  $$$$$$/| $$|  $$$$$$$
 \______/  \_______/ \______/ | $$____/  \______/ |__/ \____  $$
                              | $$                     /$$  | $$
                              | $$                    |  $$$$$$/
                              |__/                     \______/ 
  /$$$$$$                               /$$                     
 /$$__  $$                             | $$                     
| $$  \ $$  /$$$$$$  /$$$$$$   /$$$$$$$| $$  /$$$$$$            
| $$  | $$ /$$__  $$|____  $$ /$$_____/| $$ /$$__  $$           
| $$  | $$| $$  \__/ /$$$$$$$| $$      | $$| $$$$$$$$           
| $$  | $$| $$      /$$__  $$| $$      | $$| $$_____/           
|  $$$$$$/| $$     |  $$$$$$$|  $$$$$$$| $$|  $$$$$$$           
 \______/ |__/      \_______/ \_______/|__/ \_______/           
                                                                
                                                                
                                                               
*/

// SPDX-License-Identifier: GPL-3.int208

pragma solidity ^0.8.0;


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'addition overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'subtraction underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'multiplication overflow');
    }
}

library SWAPLibrary {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SWAPLibrary: same addresses for tokenA and tokenB');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SWAPLibrary: cannot be 0 address');
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = SWAPPair(SWAPFactory(factory).getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SWAPLibrary: input cannot be zero');
        require(reserveA > 0 && reserveB > 0, 'SWAPLibrary: cannot quote based on liquidity');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

interface SWAPPair {
    function getReserves() external view returns (uint256 _res1, uint256 _res2, uint256 _timestamp);
}

interface SWAPFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract GeosOracle{
    // factory address
    address _factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    // polygon USDT
    address _USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    // wrapped matic
    address _WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    // owner address
    address owner;
    // tokens tracker array
    string[] tokens;
    // registerd tokens
    struct RegToken {
        string _tknName;
        address _tknAddr;
        address _tknPair;
    }
    // map the token name to the registeration of the token
    mapping(string => RegToken) _registeredTokens;

    // initialize tokens
    constructor(){
        owner = msg.sender;
    }

    // change factory address must be compatible with interfaces
    function changeFactory(address _newFactory) public {
        require(msg.sender == owner);
        _factory = _newFactory;
    }
    // register any new token, throws if no liquidity pool is found
    function registerToken(string memory _tknName, address _tknAddr) public {
        require(msg.sender == owner, "only owner can register new tokens");
        address _pairAddr = SWAPFactory(_factory).getPair(_USDT, _tknAddr);
        require(_pairAddr != address(0), "No pair exists for this token");
        _registeredTokens[_tknName] = RegToken(_tknName, _tknAddr, _pairAddr);
        tokens.push(_tknName);
    }
    // returns the exchange rate (1 token aganist USDT)
    function getExchangeRate(string calldata _tknName) public view returns(uint256) {
        RegToken memory _tkn = _registeredTokens[_tknName];
        uint256 _oneInToken = uint256(uint8(1) * (10**IERC20(_tkn._tknAddr).decimals()));
        (uint _res1, uint _res2,) = SWAPPair(_tkn._tknPair).getReserves();
        return(SWAPLibrary.quote(_oneInToken, _res1, _res2));
    }
    // returns the exchange value feeded the real amount of tokens (decimals included)
    function FromRealGER(uint256 amount, string calldata _tknName) public view returns(uint256){
        RegToken memory _tkn = _registeredTokens[_tknName];
        (uint _res1, uint _res2,) = SWAPPair(_tkn._tknPair).getReserves();
        return(SWAPLibrary.quote(amount, _res1, _res2));        
    }
    // returns the exchange value feeded human like amount
    function FromHumanGER(uint256 amount, string calldata _tknName) public view returns(uint256){
        RegToken memory _tkn = _registeredTokens[_tknName];
        uint256 _inToken = (amount * (10**IERC20(_tkn._tknAddr).decimals()));
        (uint _res1, uint _res2,) = SWAPPair(_tkn._tknPair).getReserves();
        return(SWAPLibrary.quote(_inToken, _res1, _res2));        
    }

    // helper functions
    // check if a token is supported. i.e: has been previously added
    function isTokenSupported(string memory _tknName) public view returns(bool) {
        return(_registeredTokens[_tknName]._tknPair != address(0));
    }
    // get all the currently supported tokens
    function getAllTokens() public view returns(string[] memory) {
        return(tokens);
    }
}