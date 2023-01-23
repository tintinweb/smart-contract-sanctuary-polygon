/**
 *Submitted for verification at polygonscan.com on 2023-01-23
*/

// hevm: flattened sources of src/vault/exchangeAdapters/UniV3Adapter.sol

pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

////// src/vault/exchangeAdapters/BaseExchangeAdapter.sol
/* pragma solidity ^0.7.0; */

contract BaseExchangeAdapter {
    address public exchange;
    address spender;

    // error NOT_IMPLEMENTED();
    
    constructor(address _exchange, address _spender) {
        exchange = _exchange;
        spender = _spender;
    }   

    function getTradeData(
        address fromToken, 
        address toToken, 
        uint256 amount, 
        uint256 minReceive, 
        bytes calldata data
    ) external virtual view returns(address _exchange, uint256 _value, bytes memory _transaction) {
        // revert NOT_IMPLEMENTED(); 
        revert("NOT_INITALIZED");
    }

    function getSpender() external virtual view returns (address) {
        return spender;
    }
}

////// src/vault/exchangeAdapters/UniV3Adapter.sol
/* pragma solidity ^0.7.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./BaseExchangeAdapter.sol"; */ 

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
}

contract UniV3Adapter is BaseExchangeAdapter {

    address admin;
    mapping(address => mapping(address => uint24)) public fee; //fee-tier

    modifier onlyAdmin {
        require(msg.sender == admin, "NOT_AUTHORIZED");
        _;
    }

    constructor(
        address _exchange, 
        address _admin,
        address[] memory _tokenA,
        address[] memory _tokenB,
        uint24[] memory _fee
    ) BaseExchangeAdapter(_exchange, _exchange) {
        admin = _admin;

        for(uint256 i=0; i<_tokenA.length; i++) {
            fee[_tokenA[i]][_tokenB[i]] = _fee[i];
            fee[_tokenB[i]][_tokenA[i]] = _fee[i];
        }
    }

    function getTradeData(
        address fromToken, 
        address toToken, 
        uint256 amount, 
        uint256 minReceive, 
        bytes calldata data) 
    external override view returns(address _exchange, uint256 _value, bytes memory _transaction){
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: fromToken,
            tokenOut: toToken,
            fee: fee[fromToken][toToken],
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: minReceive, 
            sqrtPriceLimitX96: 0
        });

        return (exchange, 0, abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))",
            params
        ));
    }

    ///@param _bothSides Whether to use same fee-tier pool for both side swaps
    function setUniPoolFee(address _tokenA, address _tokenB, uint24 _fee, bool _bothSides) 
    external onlyAdmin {
        if(_bothSides) {
            fee[_tokenA][_tokenB] = _fee;
            fee[_tokenB][_tokenA] = _fee;
        } else {
            fee[_tokenA][_tokenB] = _fee;
        }
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }
}