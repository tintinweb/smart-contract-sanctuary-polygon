/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.7;
interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns (uint decs);
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

contract RUSD is protected, ERC20 {

    /************************* Types and variables *************************/

    address public Dead = 0x000000000000000000000000000000000000dEaD;

    uint public _decimals = 18;
    uint public _totalSupply = 100 * 10**_decimals;
    string public name = "Reserve USD Token";
    string public ticker = "RUSD";
    mapping(address => uint) balances;

    address public usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;//0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public busd = 0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7;//0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address public usdp = 0x2e1AD108fF1D8C782fcBbB89AAd783aC49586756; //0x8E870D67F660D95d5be530380D0eC0bd388289E1;

    address public router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;//0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public factory;
    IUniswapRouter02 router_contract;
    IUniswapFactory factory_contract;

    mapping(address => bool) public blacklisted;
    mapping(address => uint) public last_tx;
    mapping(address => address) public pair;
    mapping(address => mapping(address => uint)) allowances;

    uint cooldown = 3 seconds;
    bool cooldown_enabled = true;

    /************************* Constructor Function *************************/

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
        balances[owner] = _totalSupply;
        emit Transfer(Dead, owner, _totalSupply);
        router_contract = IUniswapRouter02(router);
        factory = router_contract.factory();
        factory_contract = IUniswapFactory(factory);
        pair[usdt] = factory_contract.createPair(usdt, address(this));
        pair[usdc] = factory_contract.createPair(usdc, address(this));
        pair[busd] = factory_contract.createPair(busd, address(this));
        pair[usdp] = factory_contract.createPair(usdp, address(this));

    }

    /************************* Transfer Functions *************************/

    function _transfer(address from, address to, uint amount) private safe {
        /// @notice Basic security check
        require(balances[from] >= amount, "Not enough funds to transfer");
        require(!blacklisted[from] && !blacklisted[to], "Banned address involved");
        
        /// @notice Check if last tx plus cooldown is less than the actual timestamp
        if(cooldown_enabled) {
            require( (last_tx[from] + cooldown) < block.timestamp, "Cooldown lock");
            last_tx[from] = block.timestamp;
        }

        /// @notice Actual transfer: no taxes on a stablecoin
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);

        /// @notice Checking all the balances
        rebalance_busd();
        rebalance_usdc();
        rebalance_usdp();
        rebalance_usdt();
    }


    /************************* Stake to Earn Functions *************************/

    mapping(address => uint) public total_earnings_public;
    mapping(address => uint) public total_earnings_project;
    mapping(address => uint) public total_withdrawn_project;
    mapping(address => mapping (address => uint)) public stable_shares;
    mapping(address => mapping (address => uint)) public stable_withdrawn;
    mapping(address => uint) public total_stable_shares;
    uint total_token_shares;
    mapping(address => uint) public token_shares;
    mapping(address => uint) public token_withdrawn;

    function contribute_liquidity(address stable, uint qty) public {
        /// @notice Stablecoin check
        require(stable==usdt || stable==usdp || stable==busd || stable==usdc, "Not supported stablecoin");
        /// @notice Normalizing quantities
        uint stable_decimals = ERC20(stable).decimals();
        uint stable_take = qty * stable_decimals;
        uint token_take = qty * _decimals;
        /// @notice Basic security features
        require(qty > 1 * stable_decimals, "Minimum 1 dollar");
        require(ERC20(stable).allowance(msg.sender, address(this)) >= stable_take, "Not enough allowance on stable");
        /// @notice Transferring from the user to the contract
        ERC20(stable).transferFrom(msg.sender, address(this), stable_take);
        /// @notice 6% spread
        uint stable_take_final = (stable_take*96)/100;
        uint token_take_final = (token_take*96)/100;
        /// @notice Calculate earning division
        uint stable_take_remains = stable_take - stable_take_final;
        uint stable_take_project = stable_take_remains/2;
        uint stable_take_public = stable_take_remains - stable_take_project;
        /// @notice Distribute earnings
        total_earnings_project[stable] += stable_take_project;
        total_earnings_public[stable] += stable_take_public;
        total_earnings_project[address(this)] += stable_take_project;
        total_earnings_public[address(this)] += stable_take_public;
        /// @notice Adding liquidity
        router_contract.addLiquidity(stable, address(this), stable_take_final, 0, stable_take_final, 0, address(this), block.timestamp);
        mint_to(token_take_final, pair[stable]);
        mint_to(token_take_final, msg.sender);
        mint_to(stable_take_project, address(this));
        mint_to(stable_take_public, address(this));
        stable_shares[msg.sender][stable] += qty;
        total_stable_shares[stable] += qty;
        token_shares[msg.sender] += qty;
        total_token_shares += qty;
    }

    function my_shares() public view returns (uint[4] memory _stable_shares, uint _token_shares) {
        return(
            [stable_shares[msg.sender][usdt],stable_shares[msg.sender][usdc],stable_shares[msg.sender][busd],stable_shares[msg.sender][usdp]],
             token_shares[msg.sender] 
        );
    }
    function my_earnings() public view returns (uint[4] memory _stable_earnings, uint _token_earnings) {
        uint usdt_perc = (stable_shares[msg.sender][usdt] * 100) / total_stable_shares[usdt];
        uint usdt_earnings = ((total_earnings_public[usdt] * usdt_perc) / 100) - stable_withdrawn[msg.sender][usdt];
        uint usdc_perc = (stable_shares[msg.sender][usdc] * 100) / total_stable_shares[usdc];
        uint usdc_earnings = ((total_earnings_public[usdc] * usdc_perc) / 100) - stable_withdrawn[msg.sender][usdc];
        uint busd_perc = (stable_shares[msg.sender][busd] * 100) / total_stable_shares[busd];
        uint busd_earnings = ((total_earnings_public[busd] * busd_perc) / 100) - stable_withdrawn[msg.sender][busd];
        uint usdp_perc = (stable_shares[msg.sender][usdp] * 100) / total_stable_shares[usdp];
        uint usdp_earnings = ((total_earnings_public[usdp] * usdp_perc) / 100) - stable_withdrawn[msg.sender][usdp];
        uint tkn_perc = (token_shares[msg.sender] * 100) / total_token_shares;
        uint tkn_earnings = ((total_earnings_public[address(this)] * tkn_perc) / 100) - token_withdrawn[msg.sender];
        return(
            [usdt_earnings,usdc_earnings,busd_earnings,usdp_earnings],tkn_earnings);
    }

    function get_project_earnings(address tkn) public onlyAuth() {
        require(tkn==usdt || tkn==usdc || tkn==busd || tkn==usdp || tkn==address(this), "Wrong token");
        uint to_transfer = total_earnings_project[tkn] - total_withdrawn_project[tkn];
        ERC20(tkn).transfer(msg.sender, to_transfer);
        total_withdrawn_project[tkn] += to_transfer;
    }
    
    function get_my_earnings(address tkn) public safe {
        require(tkn==usdt || tkn==usdc || tkn==busd || tkn==usdp || tkn==address(this), "Wrong token");
        (uint[4] memory stables, uint tkn_sh) = my_earnings();
        uint to_transfer;
        if(tkn==usdt) {
            to_transfer = stables[0];
        } else if(tkn==usdc) {
            to_transfer = stables[1];
        } else if(tkn==busd) {
            to_transfer = stables[2];
        } else if(tkn==usdp) {
            to_transfer = stables[3];
        } else if(tkn==address(this)) {
            to_transfer = tkn_sh;
        }
        ERC20(tkn).transfer(msg.sender, to_transfer);
        if(tkn==address(this)) {
            token_withdrawn[msg.sender] += to_transfer;
        } else {
            stable_withdrawn[msg.sender][tkn] += to_transfer;
        }
    }

    /************************* Admin Functions *************************/

    function set_cooldown(uint secs, bool booly) public onlyAuth {
        cooldown_enabled = booly;
        cooldown = secs;
    }

    function blacklist(address to_blacklist, bool booly) public onlyAuth {
        blacklisted[to_blacklist] = booly;
    }

    /************************* Private Functions *************************/

    function mint(uint qty) private {
        _totalSupply += qty;
        balances[address(this)] += qty;
        emit Transfer(Dead, address(this), qty);
    }

    function burn(uint qty) private {
        require(_totalSupply >= qty, "Not enough tokens");
        require(balances[address(this)] >= qty, "Not enough tokens owned");
        _totalSupply -= qty;
        balances[address(this)] -= qty;
        emit Transfer(address(this), Dead, qty);
    }

    function mint_to(uint qty, address to) private {
        _totalSupply += qty;
        balances[to] += qty;
        emit Transfer(Dead, to, qty);
    }

    function burn_to(uint qty, address to) private {
        require(_totalSupply >= qty, "Not enough tokens");
        require(balances[to] >= qty, "Not enough tokens owned");
        _totalSupply -= qty;
        balances[to] -= qty;
        emit Transfer(to, Dead, qty);
    }


    /**************** USDT SECTION ****************/

    function get_reserves_usdt() public view returns(uint112[2] memory _usdc, uint32 usdc_3) {
        (uint112 _usdt_1,uint112 _usdt_2, uint32 _usdt_3) = IUniswapV2Pair(pair[usdt]).getReserves();
        return([_usdt_1,_usdt_2],_usdt_3);

    }

    function rebalance_usdt() private returns(bool succcess) {
        (uint112[2] memory qties, uint32 blockTimestampLast) = get_reserves_usdt();
        uint112 usdt_qty = qties[0];
        uint112 tkn_qty = qties[1];
        if(usdt_qty == tkn_qty) {
            return true;
        } else if(usdt_qty > tkn_qty) {
            uint112 diff = usdt_qty - tkn_qty;
            mint_to(uint(diff), pair[usdt]);
            return false;
        } else if(usdt_qty < tkn_qty) {
            uint112 diff = tkn_qty - usdt_qty;
            burn_to(uint(diff), pair[usdt]);
            return false;
        }
    }

    /**************** USDC SECTION ****************/

    function get_reserves_usdc() public view returns(uint112[2] memory _usdc, uint32 usdc_3) {
        (uint112 _usdc_1,uint112 _usdc_2, uint32 _usdc_3) = IUniswapV2Pair(pair[usdc]).getReserves();
        return([_usdc_1,_usdc_2],_usdc_3);

    }
      function rebalance_usdc() private returns(bool succcess) {
        (uint112[2] memory qties, uint32 blockTimestampLast) = get_reserves_usdc();
        uint112 usdc_qty = qties[0];
        uint112 tkn_qty = qties[1];
        if(usdc_qty == tkn_qty) {
            return true;
        } else if(usdc_qty > tkn_qty) {
            uint112 diff = usdc_qty - tkn_qty;
            mint_to(uint(diff), pair[usdc]);
            return false;
        } else if(usdc_qty < tkn_qty) {
            uint112 diff = tkn_qty - usdc_qty;
            burn_to(uint(diff), pair[usdc]);
            return false;
        }
    }

    /**************** BUSD SECTION ****************/

    function get_reserves_busd() public view returns(uint112[2] memory _busd, uint32 busd_3) {
        (uint112 _busd_1,uint112 _busd_2, uint32 _busd_3) = IUniswapV2Pair(pair[busd]).getReserves();
        return([_busd_1,_busd_2],_busd_3);

    }
    
    function rebalance_busd() private returns(bool succcess) {
        (uint112[2] memory qties, uint32 blockTimestampLast) = get_reserves_busd();
        uint112 busd_qty = qties[0];
        uint112 tkn_qty = qties[1];
        if(busd_qty == tkn_qty) {
            return true;
        } else if(busd_qty > tkn_qty) {
            uint112 diff = busd_qty - tkn_qty;
            mint_to(uint(diff), pair[busd]);
            return false;
        } else if(busd_qty < tkn_qty) {
            uint112 diff = tkn_qty - busd_qty;
            burn_to(uint(diff), pair[busd]);
            return false;
        }
    }

    /**************** USDP SECTION ****************/

    function get_reserves_usdp() public view returns(uint112[2] memory _usdp, uint32 usdp_3) {
        (uint112 _usdp_1,uint112 _usdp_2, uint32 _usdp_3) = IUniswapV2Pair(pair[usdp]).getReserves();
        return([_usdp_1,_usdp_2],_usdp_3);

    }

    function rebalance_usdp() private returns(bool succcess) {
        (uint112[2] memory qties, uint32 blockTimestampLast) = get_reserves_usdp();
        uint112 usdp_qty = qties[0];
        uint112 tkn_qty = qties[1];
        if(usdp_qty == tkn_qty) {
            return true;
        } else if(usdp_qty > tkn_qty) {
            uint112 diff = usdp_qty - tkn_qty;
            mint_to(uint(diff), pair[usdp]);
            return false;
        } else if(usdp_qty < tkn_qty) {
            uint112 diff = tkn_qty - usdp_qty;
            burn_to(uint(diff), pair[usdp]);
            return false;
        }
    }

    /************************* ERC20 Functions *************************/

    function totalSupply() public override view returns (uint _totalSupply_){
        return _totalSupply;
	}
    function balanceOf(address _owner) public override view returns (uint balance){
        return balances[_owner];
	}
    function transfer(address _to, uint _value) public override returns (bool success){
        _transfer(msg.sender, _to, _value);
	}
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success){
        require(allowances[msg.sender][_from] >= _value, "No allowance");
        _transfer(_from, _to, _value);
        allowances[msg.sender][_from] -= _value;
        return true;
	}
    function approve(address _spender, uint _value) public override returns (bool success){
        allowances[_spender][msg.sender] += _value;
        return true;
	}
    function allowance(address _owner, address _spender) public override view returns (uint remaining){
        return allowances[_spender][_owner];
	}
    function decimals() public override view returns (uint decs) {
        return _decimals;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}