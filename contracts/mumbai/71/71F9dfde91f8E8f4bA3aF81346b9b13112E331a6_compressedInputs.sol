/**
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
        // require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        // require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint txFee = 10000 - fee ;
        uint amountInWithFee = amountIn.mul(txFee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract compressedInputs{

    address public Owner;
    mapping(uint256 => address) public id2tokenAddress;
    mapping(address => uint256) public tokenAddress2id;

    constructor() {
        Owner = msg.sender;

        // native token (i.e ether/bnb etc..) [ Id = 0 ]
        id2tokenAddress[0] = address(0);
        tokenAddress2id[address(0)] = 0;
    }

    modifier onlyOwner {
        require(msg.sender == Owner, "Sorry! only Owner can execute this function");
        _;
    }    

    address public constant wmatic = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    uint256 private nextIndex = 1;

    uint256 private constant var_6_Mask = 0x00000000000000000000000000000000000000000000000000ff000000000000;
    uint256 private constant var_5_Mask = 0x000000000000000000000000000000000000000000000000ff00000000000000;
    uint256 private constant var_4_Mask = 0x0000000000000000000000000000000000000000000000ff0000000000000000;
    uint256 private constant var_3_Mask = 0x00000000000000000000000000000000000000000000ff000000000000000000;
    uint256 private constant var_2_Mask = 0x000000000000000000000000000000000000000000ff00000000000000000000;
    uint256 private constant var_1_Mask = 0x0000000000000000000000000000000000000000ff0000000000000000000000;

    uint256 private constant address_3_Mask = 0x000000000000000000000000000000000000000000000000000000000000ffff;
    uint256 private constant address_2_Mask = 0x00000000000000000000000000000000000000000000000000000000ffff0000;
    uint256 private constant address_1_Mask = 0x0000000000000000000000000000000000000000000000000000ffff00000000;

    uint256 private constant amount_Out_Mask = 0x00000000000000000000ffffffffffffffffffff000000000000000000000000;
    uint256 private constant amount_In_Mask = 0xffffffffffffffffffff00000000000000000000000000000000000000000000;
    // address private constant pair_address_Mask = 0xffffffffffffffffffffffffffffffffffffffff;
    // address private constant pair_address2_Mask = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    

    function registerToken(address[] memory tokenAddress) external onlyOwner {
        for(uint index = 0; index<tokenAddress.length; index++){
            require(tokenAddress2id[tokenAddress[index]] == 0, "Already Registered!");
            tokenAddress2id[tokenAddress[index]] = nextIndex;
            id2tokenAddress[nextIndex] = tokenAddress[index];
            nextIndex+=1;
        }
    }

    function decodeNoFee(uint256 data, address pair) external {

        // address _address_3 = id2tokenAddress[(data & address_3_Mask)];
        // address _address_2 = id2tokenAddress[((data & address_2_Mask) >> 16)];
        // address _address_1 = id2tokenAddress[((data & address_1_Mask) >> 32)];

        // uint256 _base = (data & var_6_Mask) >> 48;
        uint256 _fee = (data & var_5_Mask) >> 56;
        // uint256 _var_4 = (data & var_4_Mask) >> 64;
        // uint256 _var_3 = (data & var_3_Mask) >> 72;
        // uint256 _var_2 = (data & var_2_Mask) >> 80;
        // uint256 _fee = (data & var_1_Mask) >> 88;
        uint256 _amount_Out = (data & amount_Out_Mask) >> 96;
        uint256 _amount_In = (data & amount_In_Mask) >> 176;
        
        // address _pair_address = pair;
        
        (uint112  reserve0, uint112  reserve1, ) = IUniswapV2Pair(pair).getReserves(); 
        uint amounts = (_amount_In * (10000 - _fee) * reserve1) / ((reserve0 * 10000) + (_amount_In * (10000 - _fee)));
        require(_amount_Out <= amounts, 'E1');
        TransferHelper.safeTransfer(wmatic, pair, _amount_In);
        IUniswapV2Pair(pair).swap( 0, amounts, address(this), new bytes(0));
        


    }
    function decodeNoFee2(uint256 data) external {

        // address _address_3 = id2tokenAddress[(data & address_3_Mask)];
        // address _address_2 = id2tokenAddress[((data & address_2_Mask) >> 16)];
        address _pairAddress_1 = id2tokenAddress[((data & address_1_Mask) >> 32)];

        // uint256 _base = (data & var_6_Mask) >> 48;
        uint256 _fee = (data & var_5_Mask) >> 56;
        // uint256 _var_4 = (data & var_4_Mask) >> 64;
        // uint256 _var_3 = (data & var_3_Mask) >> 72;
        // uint256 _var_2 = (data & var_2_Mask) >> 80;
        // uint256 _var_1 = (data & var_1_Mask) >> 88;
 
        uint256 _amount_Out = (data & amount_Out_Mask) >> 96;
        uint256 _amount_In = (data & amount_In_Mask) >> 176;
        (uint256  reserve0, uint256  reserve1, ) = IUniswapV2Pair(_pairAddress_1).getReserves(); 
        uint amounts = (_amount_In * (10000 - _fee) * reserve1) / ((reserve0 * 10000) + (_amount_In * (10000 - _fee)));
        // uint256 amounts = UniswapV2Library.getAmountOut(_amount_In, reserve0, reserve1, _fee);
        require(_amount_Out <= amounts, 'E1');
        TransferHelper.safeTransfer(wmatic, _pairAddress_1, _amount_In);
        IUniswapV2Pair(_pairAddress_1).swap( 0, amounts, address(this), new bytes(0));
        
        
    }





    // function LowFeeSwapBase0(address pairAddress, uint256 reserve0, uint256 reserve1, uint amountIn, uint amountsOut, uint _fee) internal {  

    //     uint256 amounts = UniswapV2Library.getAmountOut(amountIn, reserve0, reserve1, _fee);
    //     require(amountsOut <= amounts, 'E1');
    //     TransferHelper.safeTransfer(wmatic, pairAddress, amountIn);
    //     IUniswapV2Pair(pairAddress).swap( 0, amounts, address(this), new bytes(0));
    //     // require(msg.sender==creator||Owners[msg.sender], 'Sorry: Access Denied!'); 
 
    // }

    // function LowFeeSwapBase1(address pairAddress, uint256 reserve0, uint256 reserve1, uint amountIn, uint amountsOut, uint _fee) internal {
       
    //     uint256 amounts = UniswapV2Library.getAmountOut(amountIn, reserve1, reserve0, _fee);
    //     require(amountsOut <= amounts, 'E1');
    //     TransferHelper.safeTransfer(wmatic, pairAddress, amountIn);
    //     IUniswapV2Pair(pairAddress).swap(amounts, 0, address(this), new bytes(0));
    //     // require(msg.sender==creator||Owners[msg.sender], 'Sorry: Access Denied!'); 
    // }    
}