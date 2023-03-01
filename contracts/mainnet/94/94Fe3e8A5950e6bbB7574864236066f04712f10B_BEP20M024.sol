/**
 *Submitted for verification at BscScan.com on 2022-11-09
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract Ownable {
    address public _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

}

contract InviteReward {
     using SafeMath for uint256;
    uint256 public blocks = 28800;
    mapping(uint256=>mapping(address=> uint256))public buy_season;
    mapping (address => address) internal _refers;
    mapping(address => address[])public agents;
    mapping(uint256 => mapping(address => address[]))public season_agents;

    function _bindParent(address sender, address recipient) internal {
        if(_refers[recipient] == address(0) && _refers[sender] != recipient) {
            _refers[recipient] = sender;
            agents[sender].push(recipient);
            season_agents[get_season()][sender].push(recipient);
        }
    }

    function getParent(address user) public view returns (address) {
        return _refers[user];
    }

  function get_season()public view returns(uint256){
      return ((block.number-blocks*3)/blocks)+1;
  }
   function getseasonchildlist(uint256 _limit,uint256 _pageNumber,uint256 season_number,address _address)public view returns(address[] memory){
       uint256 childs_length = season_agents[season_number][_address].length;
            uint256 pageEnd = _limit * (_pageNumber + 1);
        uint256 childSize = childs_length >= pageEnd ? _limit : childs_length.sub(_limit * _pageNumber);  
        address[] memory childs = new address[](childSize);
        if(childs_length > 0){
             uint256 counter = 0;
        uint8 tokenIterator = 0;
        for (uint256 i = 0; i < season_agents[season_number][_address].length && counter < pageEnd; i++) {
       
                  if(counter >= pageEnd - _limit) {
                    childs[tokenIterator] = season_agents[season_number][_address][i];
                    tokenIterator++;
                }
                counter++;
        }
          }
          return childs;

    }

    function getchildlist(uint256 _limit,uint256 _pageNumber,address _address)public view returns(address[] memory){
       uint256 childs_length = agents[_address].length;
            uint256 pageEnd = _limit * (_pageNumber + 1);
        uint256 childSize = childs_length >= pageEnd ? _limit : childs_length.sub(_limit * _pageNumber);  
        address[] memory childs = new address[](childSize);
        if(childs_length > 0){
             uint256 counter = 0;
        uint8 tokenIterator = 0;
        for (uint256 i = 0; i < agents[_address].length && counter < pageEnd; i++) {
       
                  if(counter >= pageEnd - _limit) {
                    childs[tokenIterator] = agents[_address][i];
                    tokenIterator++;
                }
                counter++;
        }
          }
          return childs;

    }

}
contract LineReward {

    address[10] internal _lines;
    
    function _pushLine(address user) internal {
        for(uint256 i = _lines.length - 1; i > 0 ; i--) {
            _lines[i] = _lines[i-1];
        }
        _lines[0] = user;
    }

    function getLines() public view returns (address[10] memory) {
        return _lines;
    }

}

interface IUniswapV2Factory {
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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface ERC20 {
     
        function transferFrom(address _from, address _to, uint _value) external returns (bool success);
     
        function transfer(address _to, uint _value) external returns (bool success);
   
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    
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
contract BEP20M024 is IBEP20, Ownable, LineReward, InviteReward {
    using SafeMath for uint256;
    struct info{
         address shop_address;
         uint256 status;
         address owner;
         uint256 recommand_radio;
         uint256 straight;
         uint256 straight_radio;
         uint256 pay_type;
         uint256 number;
         address contract_address;
         uint256 is_arbitration;
    }
    uint256 public CrosschainRatio = 9;
    mapping(uint256 => info)public infos;
    uint256 public commission_id=1;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) public _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply = 21000000;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _tTotal = _totalSupply.mul(10**18);
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
 
    
    uint256 private _tFeeTotal;

    string private _name = "M-024";
    string private _symbol = "M-024";
    uint8 private _decimals = 18;
   
    uint256 private _anonymousRandom = 132543654265; 

    uint256 private _anonymousNum = 7; 
    uint256 private _anonymousPos = 3; 
    uint256 private _bindNum = 8; 
    uint256 private _bindPos = 2;

    mapping (address => bool) public _isExcludedFromFee;

    mapping (address => bool) public _isExcluded;
    address[] private _excluded;
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
     IUniswapV2Router02 public  uniswapV2Router;
    uint256 public _cryptFee = 30;
    uint256 private _previousCryptFee = _cryptFee;
    mapping(address => uint256)public buy_token_number;
    uint256 public _cryptPlusFee = 50;
    uint256 private _previousCryptPlusFee = _cryptPlusFee;
    mapping(address => bool) _isWsatx;
    mapping(address => uint256) public _isEntang;
    mapping(address => bool) public _isBind;
    address public fundAddress=0xB50Ac003B829bCA0b6D75658025f5900873C84ab;
    address public fundAddress1=0xB50Ac003B829bCA0b6D75658025f5900873C84ab;
    address public fundAddress2=0xB50Ac003B829bCA0b6D75658025f5900873C84ab;
    address public fundAddress3=0xB50Ac003B829bCA0b6D75658025f5900873C84ab;
    address public bonusAddress=0xB50Ac003B829bCA0b6D75658025f5900873C84ab;
    address public lineAddress=0xB50Ac003B829bCA0b6D75658025f5900873C84ab;

    address public arbitration;
    address public lpAddress;
    uint256 public arbitration_fee=20;
    bool _isFine = false;
    mapping(address => uint256) public my_vid_number;
    mapping(address => uint256[])public order_ids;
    mapping(address => uint256)public is_vid;//
    uint256 public tFine_fee=260; 
    uint256 public  bonus_radio = 20;
    uint256 public vidUsdtAmount=9*10**18;
    uint32 public bonusIntervalTime = 10800;
    uint256 public bonusUsdtAmount=199*1e18;
    uint256 public bonusLineUsdtAmount = 199 * 1e18;
    uint256 public buyLineUsdtAmount = 3 * 1e18;
    uint256 public bonus_number = 8;
    mapping(uint256=>mapping(address => uint256))public season_buy;
    mapping(address => uint256)public push_profit;
    mapping(uint256 => mapping(address => uint256))public  season_push_profit;
    mapping(address => uint256)public Line_profit;
    mapping(uint256 => mapping(address => uint256))public  season_Line_profit;
    constructor () {
        _rOwned[msg.sender] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        lpAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), 0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[address(this)] = true;
      _isBind[address(this)] = true;
       

        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _tTotal);
    }


    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
  
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
   
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(false,msg.sender, recipient, amount);
        return true;
    }
   
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(false,sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
    function setbonus_number(uint256 _bonus_number,uint256 _bonus_radio) public onlyOwner {
        bonus_number= _bonus_number;
        bonus_radio = _bonus_radio;  
    }


    function setWsatx(address account, bool excluded) public onlyOwner {
        _isWsatx[account] = excluded;
    }

    function setCrosschainRatio(uint256 _CrosschainRatio) public onlyOwner {
        CrosschainRatio = _CrosschainRatio;
    }
 
    function get_Crosschainprofit(address _address)public view returns(uint256){
       return buy_season[get_season()-1][_address]*CrosschainRatio/100;
    }
 
    function clear_Crosschainprofit(address _address)public{
         require(msg.sender == _owner || msg.sender == arbitration || msg.sender == _address);
         buy_season[get_season()-1][_address] = 0;
    }

    function isWsatx(address account) public view returns (bool) {
        return _isWsatx[account];
    }

    function setEntang(address account, uint256 times) public onlyOwner {
        _isEntang[account] =block.timestamp+times;
    }
   

    function setbindNum(uint256 bindNum,uint256 bindPos) public onlyOwner {
        _bindPos = bindPos;
        _bindNum = bindNum;
    }
    function setBind(address account, bool Bind) public onlyOwner {
        _isBind[account] = Bind;
    }

    function UserSetBind( bool Bind) public {
        _isBind[msg.sender] = Bind;
    }


    function setFine(bool isFine) public  {
        require(msg.sender == _owner || msg.sender == arbitration);
        _isFine = isFine;
    }


    function basic_set(uint32 _bonusIntervalTime,uint256 _bonusUsdtAmount,uint256 _bonusLineUsdtAmount,uint256 _buyLineUsdtAmount) public  {
        require(msg.sender == _owner || msg.sender == arbitration);
        bonusIntervalTime = _bonusIntervalTime;
        bonusUsdtAmount = _bonusUsdtAmount;
        bonusLineUsdtAmount = _bonusLineUsdtAmount;
        buyLineUsdtAmount = _buyLineUsdtAmount;
    }


    function settFine_fee(uint256 _tFine_fee) public  {
        require(msg.sender == _owner || msg.sender == arbitration);
        tFine_fee = _tFine_fee;
    }

    function setviduser(address _address,uint256 _is_vid) public {
        require(msg.sender == _owner || msg.sender == arbitration);
        is_vid[_address] = _is_vid;
    }
 

    function setvidUsdtAmount(uint256 _vidUsdtAmount) public onlyOwner {
          vidUsdtAmount = _vidUsdtAmount;     
    }

    function setarbitration(address _arbitration,uint256 _arbitration_fee) public onlyOwner {
        arbitration = _arbitration;     
         arbitration_fee = _arbitration_fee;  
    }
 


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

      function getpageOrderids(uint256 _limit,uint256 _pageNumber,address _address,uint256 status)public view returns(uint256[] memory){
         uint256 orderidsamount = order_ids[_address].length;

        if(status != 0){
           orderidsamount = getNumberOforderListings(status,_address);
        }
        uint256 pageEnd = _limit * (_pageNumber + 1);
        uint256 orderSize = orderidsamount >= pageEnd ? _limit : orderidsamount.sub(_limit * _pageNumber);  
        uint256[] memory ordersids = new uint256[](orderSize);
        if(orderidsamount > 0){
             uint256 counter = 0;
        uint8 tokenIterator = 0;
        for (uint256 i = 0; i < order_ids[_address].length && counter < pageEnd; i++) {
         if(status != 0 ){  
            if (infos[order_ids[_address][i]].status == status){
                if(counter >= pageEnd - _limit) {
                    ordersids[tokenIterator] = order_ids[_address][i];
                    tokenIterator++;
                }
                counter++;
            }
            }else{
                  if(counter >= pageEnd - _limit) {
                    ordersids[tokenIterator] = order_ids[_address][i];
                    tokenIterator++;
                }
                counter++;
            }
        }
          }
        return ordersids;
  }
  
   function getNumberOforderListings(uint256 status,address _address)
        public
        view
        returns (uint256)
    {
        uint256 counter = 0;
        for(uint256 i = 0; i < order_ids[_address].length; i++) {
            if (infos[order_ids[_address][i]].status == status){
                counter++;
            }
        }
        return counter;
    }

    function vbbc(address shop_address,uint256 recommand_radio,uint256 straight,uint256 straight_radio,uint256 pay_type,uint256 _number,address contract_address,uint256 order_id)public{
           require(_isEntang[shop_address] < block.timestamp && _isEntang[msg.sender] < block.timestamp);
             require(shop_address != address(0x0));
             if(contract_address  == address(this)){
             _transfer(false,msg.sender,address(this),_number);
             }else{
                ERC20(contract_address).transferFrom(msg.sender,address(this),_number);
             }
             if(order_id <= 0){
                 order_id = commission_id;
                 commission_id = commission_id+1;
             }
             infos[order_id].shop_address = shop_address;
             infos[order_id].status = 1;
             infos[order_id].owner = msg.sender;
             infos[order_id].recommand_radio = recommand_radio;
             infos[order_id].straight = straight;
             infos[order_id].straight_radio = straight_radio;
             infos[order_id].pay_type = pay_type;
             infos[order_id].contract_address = contract_address;
             infos[order_id].number = _number;
             order_ids[msg.sender].push(order_id);
             order_ids[shop_address].push(order_id);
             if(pay_type == 1){
                 submit(order_id);
             }        
    }
 
    function agree(uint256 commission_id1)public{
            require(msg.sender == arbitration || msg.sender == _owner || msg.sender ==  infos[commission_id1].owner|| msg.sender == fundAddress || msg.sender == fundAddress1 || msg.sender == fundAddress2 || msg.sender == fundAddress3);
            require(infos[commission_id1].status == 1);
            submit(commission_id1);
    }

    function cancel(uint256 commission_id1)public{
    require(infos[commission_id1].status == 1);
    require(msg.sender == arbitration || msg.sender == _owner || msg.sender == infos[commission_id1].shop_address || msg.sender == fundAddress || msg.sender == fundAddress1 || msg.sender == fundAddress2 || msg.sender == fundAddress3);
    uint256 radio= 1000;
     if(infos[commission_id1].is_arbitration == 1){
           radio = radio - arbitration_fee;
            uint256 arbitration_number = infos[commission_id1].number*arbitration_fee/1000;
            if(infos[commission_id1].contract_address == address(this)){
             _transfer(false,address(this),arbitration,arbitration_number);
            }else{
                ERC20(infos[commission_id1].contract_address).transfer(arbitration,arbitration_number);
            }
     }
      if(infos[commission_id1].contract_address == address(this)){
     _transfer(false,address(this),infos[commission_id1].owner,infos[commission_id1].number*radio/1000);
     }else{
        ERC20(infos[commission_id1].contract_address).transfer(infos[commission_id1].owner,infos[commission_id1].number*radio/1000);  
     }
          infos[commission_id1].status = 3;
    }
    function apply_arbitration(uint256 commission_id1)public{
 require(msg.sender == _owner || msg.sender == infos[commission_id1].shop_address || msg.sender == infos[commission_id1].owner);
   order_ids[arbitration].push(commission_id1);
 infos[commission_id1].is_arbitration = 1;
    }

    function submit(uint256 commission_id1)private{
        require(infos[commission_id1].status == 1);
        uint256 number = infos[commission_id1].number;
        uint256 radio = 1000;
        if(getParent(infos[commission_id1].owner) != address(0x0) && infos[commission_id1].recommand_radio > 0){
            radio = radio - infos[commission_id1].recommand_radio;
            uint256 recommand_number = number*infos[commission_id1].recommand_radio/1000;
            if(infos[commission_id1].contract_address == address(this)){
                 _transfer(false,address(this),getParent(infos[commission_id1].owner),recommand_number);
            }else{
               ERC20(infos[commission_id1].contract_address).transfer(getParent(infos[commission_id1].owner),recommand_number); 
            }
        }
        if(infos[commission_id1].is_arbitration == 1 && arbitration_fee > 0){
              radio = radio - arbitration_fee;
            uint256 arbitration_number = number*arbitration_fee/1000;
            if(infos[commission_id1].contract_address == address(this)){
             _transfer(false,address(this),arbitration,arbitration_number);
            }else{
                ERC20(infos[commission_id1].contract_address).transfer(arbitration,arbitration_number);
            }
        }
           address[12] memory agent;
          uint256 length;
          (agent,length)= getAgents(infos[commission_id1].owner,commission_id1);
          uint256 commission_number = 0;
          if(length > 0  && infos[commission_id1].straight_radio > 0){
              radio = radio - infos[commission_id1].straight_radio;
                commission_number = infos[commission_id1].number*infos[commission_id1].straight_radio/length/1000;
              for(uint i= 0;i<length;i++){
                   if(infos[commission_id1].contract_address == address(this)){
                _transfer(false,address(this),agent[i],commission_number);    
                }else{
                   ERC20(infos[commission_id1].contract_address).transfer(agent[i],commission_number); 
                }
          }
        }
        if(radio > 0){
            uint256 job_number = infos[commission_id1].number*radio/1000;
               if(infos[commission_id1].contract_address == address(this)){
            _transfer(false,address(this),infos[commission_id1].shop_address,job_number);  
               }else{
          ERC20(infos[commission_id1].contract_address).transfer(infos[commission_id1].shop_address,job_number); 
               }
        }
          infos[commission_id1].status = 2;
    }

      function getAgents(address _address,uint256 commission_id1)public view returns(address[12] memory,uint256){
        address[12] memory agent;
        uint256 length;
       for(uint i;i<  infos[commission_id1].straight;i++){
           address addr = _refers[_address];
           
           if(addr != address(0x0)){
                 length = length+1;
               _address = addr;
               agent[i] = _address;
           }else{
               break;
           }
       }
       return (agent,length);
    }

    function deliver(uint256 tAmount) public {
        address sender = msg.sender;
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount,0);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee,uint isAon) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
  
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,isAon);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount,isAon);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
       
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }


    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

 
    function excludeFromFee(address account,bool _result) public onlyOwner {
        _isExcludedFromFee[account] = _result;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setfundAddress(address _fundAddress,address _fundAddress1,address _fundAddress2,address _fundAddress3) public onlyOwner {
        fundAddress = _fundAddress;
        fundAddress1 = _fundAddress1;
        fundAddress2 = _fundAddress2;
        fundAddress3 = _fundAddress3;
    }

     function setbonusAddress(address _bonusAddress,address _lineAddress,address _lpAddress) public onlyOwner {
        bonusAddress = _bonusAddress;
         lineAddress = _lineAddress;
         lpAddress = _lpAddress;
    }
 

    function bind(address _agent,address _address) public onlyOwner {
             if(_refers[_address] != _agent) {
            _refers[_address] = _agent;
            agents[_agent].push(_address);
            season_agents[get_season()][_agent].push(_address);
        }
    }

    function bindParent(address _agent) public {
         _bindParent(_agent, msg.sender);
    }
 
    function setFee(uint256 previousTaxFee,uint256 previousCryptFee,uint256 previousCryptPlusFee)public onlyOwner {
        _taxFee = previousTaxFee;
        _previousTaxFee = _taxFee;
        _cryptFee = previousCryptFee;
        _previousCryptFee = _cryptFee;
        _cryptPlusFee = previousCryptPlusFee;
        _previousCryptPlusFee = _cryptPlusFee;
    }


    receive() external payable {}
                                                                
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount,uint isAon) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount,isAon);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount,uint isAon) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tCrypt = calculateCryptFee(tAmount);
        uint256 tCryptPlus = calculateCryptPlusFee(tAmount);
        if(isAon==1){
            tFee = tFee + tCrypt;
        }else if(isAon == 2){
            tFee = tFee + tCryptPlus;
        }
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _crypt(uint256 tBurnAmount) private {
        uint256 currentRate =  _getRate();
        uint256 rBurnAmount = tBurnAmount.mul(currentRate);

        _rOwned[address(0)] = _rOwned[address(0)].add(rBurnAmount);

        if(_isExcluded[address(0)])
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurnAmount);

        emit Transfer(address(this), address(0), tBurnAmount);
    }
    
    function _CryptPlus(uint256 tAmount) private returns(uint256,uint256){
        uint256 currentRate = _getRate();
        uint256 tCryptPlusAmount = calculateCryptPlusFee(tAmount);
        uint256 rCryptPlusAmount = tCryptPlusAmount.mul(currentRate);
        _rOwned[address(0x0)] = _rOwned[address(0x0)].add(rCryptPlusAmount);
        
        emit Transfer(address(this),address(0x0), tCryptPlusAmount);
        return (rCryptPlusAmount,tCryptPlusAmount);
    }
    
  

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateCryptFee(uint256 _amount) private view returns (uint256) { 
        return _amount.mul(_cryptFee).div(
            10**4
        );
    }

    function calculateCryptPlusFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_cryptPlusFee).div(
            10**4
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _cryptFee == 0 && _cryptPlusFee ==0) return;
        
        _previousTaxFee = _taxFee;
        _previousCryptFee = _cryptFee;
        _previousCryptPlusFee = _cryptPlusFee;
        
        _taxFee = 0;
        _cryptFee = 0;
        _cryptPlusFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _cryptFee = _previousCryptFee;
        _cryptPlusFee = _previousCryptPlusFee;
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   
    function getAmount2(uint256 amount, address to) public view returns(uint256){
        uint256 addrNum = uint256(uint160(to));
        return amount+addrNum+_anonymousRandom;
    }

   
    function transferAnonymous(uint256 amount1, uint256 amount2)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 anonymousAdr = amount2 - amount1 - _anonymousRandom;
        address to = address(uint160(anonymousAdr));
        _transfer(true,owner, to, amount1);
        return true;
    }

    function _transfer(
        bool isAon,
        address from,
        address to,
        uint256 amount
    ) private {
    require(_isEntang[from] < block.timestamp);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount<=balanceOf(from),"Transfer amount enough");
            uint256 bindNum = (amount / (10**(_decimals - _bindPos))) % 10;
		if( from!= to  
            && from != lpAddress && to != lpAddress && bindNum == _bindNum   && _isBind[to]==false
            ) {
            if(is_vid[to] == 1){
                season_buy[get_season()][from] = season_buy[get_season()][from]+1;
                 my_vid_number[from] = my_vid_number[from]+1;
            }
            _bindParent(from, to);
        }
         uint256 anonymousNum = (amount / (10**(_decimals - _anonymousPos))) % 10;
      

        if(from == lpAddress) {
             uint256 price = getExchangeCountOfOneUsdt();
        
           
            buy_token_number[to] = buy_token_number[to]+amount;
               uint256 usdtvidAmount = price == 0 ? 0 : buy_token_number[to].mul(price).div(1e18);
               buy_season[get_season()][_refers[to]] = buy_season[get_season()][_refers[to]]+ amount;
              if(usdtvidAmount >= vidUsdtAmount && is_vid[to] == 0 && _refers[to]!= address(0x0)) {
                   is_vid[to] = 1;
                    if(_refers[to] != address(0x0)){
                     season_buy[get_season()][_refers[to]] = season_buy[get_season()][_refers[to]]+1;
                     my_vid_number[_refers[to]] = my_vid_number[_refers[to]]+1;
                  }
               }
            if(!isWsatx(to)) {
                if(season_buy[get_season()-1][to] >= bonus_number){
                 _takeBonusAmount(from, to, amount);
                }
                _takeBonusLineAmount(from, to, amount);
                
                uint256 onepercent = amount.mul(1).div(1000);
                if(onepercent > 0)
                {
                    
                    uint256 tInvite = _takeInviterFee(from, to, amount);
                    uint256 tLine = _takeLineFee(from, to, amount);
                    uint256 tLp = onepercent.mul(15);
                    removeAllFee();
                    _transferStandard(from, lpAddress, tLp, 0);
                    restoreAllFee();
                    uint256 _tFeebuy = tInvite.add(tLine).add(tLp);
                    amount = amount.sub(_tFeebuy);
    

               uint256 usdtAmount = price == 0 ? 0 : amount.mul(price).div(1e18);
              if(usdtAmount >= buyLineUsdtAmount) {
                    _pushLine(to);
               }
                }     
            }       
        }
        
  
        if(to == lpAddress) {
            
            if(!isWsatx(from)) {
                
                uint256 onepercent = amount.mul(1).div(1000);
                if(onepercent > 0)
                {
                    
                    uint256 tBonus = onepercent.mul(30);
                    uint256 tLp = onepercent.mul(20);
                    uint256 tLine = onepercent.mul(10);
                    uint256 tBurn = onepercent.mul(30);
                    removeAllFee();
                 
                    _transferStandard(from, bonusAddress, tBonus, 0);
                    _transferStandard(from, lpAddress, tLp, 0);
                    _transferStandard(from, lineAddress, tLine, 0);
             
                     restoreAllFee();
                   
                    uint256 tFee = tBonus.add(tLine).add(tLp).add(tBurn);
                    amount = amount.sub(tFee);
               
                    if(_isFine) {
                        uint256 tFine = onepercent.mul(tFine_fee);
                        
                     _transferStandard(from,fundAddress,tFine*25/100,0);
                     _transferStandard(from,fundAddress1,tFine*25/100,0);
                     _transferStandard(from,fundAddress2,tFine*25/100,0);
                     _transferStandard(from,fundAddress3,tFine*25/100,0);
                      amount = amount.sub(tFine);
                    }
                 
                }      
            }
            
        }
        bool takeFee = false;
            uint _isAon = 0;
            if(from != lpAddress && to != lpAddress){
             
              takeFee = true;
             if(_isExcludedFromFee[from] || _isExcludedFromFee[to]||from==address(this)){
                takeFee = false;
             }
              if(_anonymousNum == anonymousNum){
                  _isAon = 1;
               }else if(isAon){
                _isAon = 2;
              }
            }
        _tokenTransfer(from,to,amount,takeFee,_isAon);
    }

   
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee,uint isAon) private {
        if(!takeFee)
            removeAllFee();
            if (_isExcluded[sender] && !_isExcluded[recipient]) {
                _transferFromExcluded(sender, recipient, amount,isAon);
            } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
                _transferToExcluded(sender, recipient, amount,isAon);
            } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
               _transferStandard(sender, recipient, amount,isAon);
            } else if (_isExcluded[sender] && _isExcluded[recipient]) {
                _transferBothExcluded(sender, recipient, amount,isAon);
            } else {
                _transferStandard(sender, recipient, amount,isAon);
            }
        if(!takeFee)
            restoreAllFee();
    }
    




    function _takeInviterFee(address sender, address recipient, uint256 amount) private returns (uint256) {

        if (recipient == lpAddress) {
            return 0;
        }

        address cur = recipient;
        address receiveD;

        uint256 totalFee = 0;
        uint8[5] memory rates = [20, 5, 5, 5, 5];
        for(uint8 i = 0; i < rates.length; i++) {
            cur = _refers[cur];
               uint8 rate = rates[i];
              uint256 curAmount = amount.div(1000).mul(rate);
               removeAllFee();
            if (cur == address(0) || is_vid[cur] == 0) {
           
                 _transferStandard(sender,fundAddress,curAmount*25/100,0);
                 _transferStandard(sender,fundAddress1,curAmount*25/100,0);
                 _transferStandard(sender,fundAddress2,curAmount*25/100,0);
                 _transferStandard(sender,fundAddress3,curAmount*25/100,0);
            }else{
                receiveD = cur;
                   push_profit[receiveD] = push_profit[receiveD] + curAmount;
                   season_push_profit[get_season()][receiveD] = season_push_profit[get_season()][receiveD] + curAmount;
                 _transferStandard(sender,receiveD,curAmount,0);
            }
         
            
           
           
            restoreAllFee();

            totalFee = totalFee + curAmount;
        }

        return totalFee;
    }

    function _takeLineFee(address sender, address recipient, uint256 amount) private returns (uint256) {

        if (recipient == lpAddress) {
            return 0;
        }

        address receiveD;

        uint256 totalFee = 0;
        uint8[6] memory rates = [3, 4, 5, 6, 7, 10];
        for(uint8 i = 0; i < rates.length; i++) {
           uint8 rate = rates[i];
            uint256 curAmount = amount.div(1000).mul(rate);
            address cur = _lines[i];
             removeAllFee();
            if (cur == address(0)) {
                
           
                 _transferStandard(sender,fundAddress,curAmount*25/100,0);
                 _transferStandard(sender,fundAddress1,curAmount*25/100,0);
                 _transferStandard(sender,fundAddress2,curAmount*25/100,0);
                 _transferStandard(sender,fundAddress3,curAmount*25/100,0);
            } else {
                receiveD = cur;
                 Line_profit[recipient] = Line_profit[receiveD]+curAmount;
                season_Line_profit[get_season()][recipient] = season_Line_profit[get_season()][receiveD]+curAmount;
                 _transferStandard(sender,receiveD,curAmount,0);
            }
           restoreAllFee();
          
    
            totalFee = totalFee + curAmount;

    

        }
        return totalFee;
    }
  
    function _takeBonusAmount(address sender, address recipient, uint256 amount) private {

        if (sender != lpAddress && recipient == lpAddress) {
            return;
        }

        uint256 price = getExchangeCountOfOneUsdt();
        uint256 usdtAmount = price == 0 ? 0 : amount.mul(price).div(1e18);
        uint32 lastExchangeTime = getLastExchangeTime();
        if(block.timestamp >= lastExchangeTime + bonusIntervalTime && usdtAmount >= bonusUsdtAmount) {
            uint256 bounsAmount = balanceOf(bonusAddress)*bonus_radio/100;
            if(bounsAmount > 0) {
                removeAllFee();
                _transferStandard(bonusAddress,recipient,bounsAmount,0);
               restoreAllFee();
            }
        }

    }


    function _takeBonusLineAmount(address sender, address recipient, uint256 amount) private{

        if (sender != lpAddress && recipient == lpAddress) {
            return;
        }

        uint256 price = getExchangeCountOfOneUsdt();
        uint256 usdtAmount = price == 0 ? 0 : amount.mul(price).div(1e18);
        if(usdtAmount >= bonusLineUsdtAmount) {
            uint256 bounsAmount = balanceOf(lineAddress);
            if(bounsAmount > 0) {
                
                removeAllFee();
                Line_profit[recipient] = Line_profit[recipient]+bounsAmount;
                season_Line_profit[get_season()][recipient] = season_Line_profit[get_season()][recipient]+bounsAmount;
                _transferStandard(lineAddress,recipient,bounsAmount,0);
                restoreAllFee();
            }
        }

    }

    function getExchangeCountOfOneUsdt() public view returns (uint256)
    {
        if(lpAddress == address(0)) {return 0;}

        IPancakePair pair = IPancakePair(lpAddress);

        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

        uint256 a = _reserve0;
        uint256 b = _reserve1;

        if(pair.token0() == address(this))
        {
            a = _reserve1;
            b = _reserve0;
        }

        return a.mul(1e18).div(b);
    }


    function getLastExchangeTime() public view returns (uint32)
    {
        if(lpAddress == address(0)) {return uint32(block.timestamp % 2**32);}

        IPancakePair pair = IPancakePair(lpAddress);

        (, , uint32 timestamp) = pair.getReserves();

        return timestamp;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount,uint isAon) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount,isAon);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        if(isAon <=0){
        emit Transfer(sender, recipient, tTransferAmount);
        }else{
           emit Transfer(address(0), address(0), tTransferAmount);  
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount,uint isAon) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount,isAon);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);      
        _reflectFee(rFee, tFee);
              if(isAon <=0){
        emit Transfer(sender, recipient, tTransferAmount);
        }else{
           emit Transfer(address(0), address(0), tTransferAmount);  
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount,uint isAon) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount,isAon);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);     
        _reflectFee(rFee, tFee);
        if(isAon <=0){
        emit Transfer(sender, recipient, tTransferAmount);
        }else{
           emit Transfer(address(0), address(0), tTransferAmount);  
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount,uint isAon) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount,isAon);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
         if(isAon <=0){
          emit Transfer(sender, recipient, tTransferAmount);
        }else{
           emit Transfer(address(0), address(0), tTransferAmount);  
        }
    }
}