// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./SafeMath.sol";
interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}
interface ERC20 {


    function contract_balance(address _owner,uint256 _amount) external ;

  
    
}
interface ISwapRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}
abstract contract InviteReward {
     using SafeMath for uint256;
    uint256 public blocks = 302400;
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

abstract contract LineReward {

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
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

abstract contract VDSToken is IERC20,Ownable, LineReward, InviteReward {
       using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;



    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) private __feeEntangList;

 

    uint256 private _tTotal;
    ISwapRouter private _swapRouter;
    address private _usdt;
    mapping(address => bool) private _swapPairList;

    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    TokenDistributor private _tokenDistributor;
    mapping(address => uint256)public is_vid;
    uint256 public vidUsdtAmount=99*10**6;
    uint256 public vidplusUsdtAmount = 9999*10**6;

    uint256 public _buyRecommandFee = 540;
    uint256 public _buyLPDividendFee = 200;
    uint256 public _buyLineFee = 160;


    uint256 public _selleggshellFee = 200;
    uint256 public _sellLPDividendFee = 200;
    uint256 public _sellpaymentFee= 200;

    address[] public plusvid;
    address public payment_contract=0xbf35A6AB5f6604304Afc26E3a7ff605557fb34F3;

    address public bonusAddress=0xC352E4cFB243EE252b96F93a5dB944369b00f399;
    address public fundAddress=0x45046ecD744797F44cDf95dA371C887c9c6a9F0C;
    address public fundAddress1=0xdE2Fd27Fb10Ba1579139426244B815933da9C1C1;
    address public fundAddress2=0xA6Fa2c50b805dd0b8aAB33Dba726350C07E77616;
    address public fundAddress3=0x1604dcbb3B5beEa01bE6c7ceCC6fd7Cb2f69206E;

    uint256 profit_number = 100*10**18;
    mapping(address => bool) public _isBind;

    uint256 public all_vid = 0;
    address public _mainPair;
    uint256 private _bindNum = 8;
    uint256 private _bindPos = 2;
    uint256 numTokensSellToFund = 10*10**18;

    mapping(address => uint256)public open_vid;
    mapping(address => uint256)public push_contract_address;
    uint256 public _airdropLen = 10;
    uint256 public _airdropAmount = 100;
    mapping(address => uint256) public my_vid_number;

 

    uint256 public buyLineUsdtAmount = 10 * 1e6;
    mapping(uint256=>mapping(address => uint256))public season_buy;
   
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress
   
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        address usdt = USDTAddress;
        IERC20(usdt).approve(address(swapRouter), MAX);

        _usdt = usdt;
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address usdtPair = swapFactory.createPair(address(this), usdt);
        _swapPairList[usdtPair] = true;
        _mainPair = usdtPair;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);


   
   
       _isBind[address(this)] = true;
   
        __feeEntangList[ReceiveAddress] = true;
        __feeEntangList[address(this)] = true;
        __feeEntangList[address(swapRouter)] = true;
        __feeEntangList[msg.sender] = true;
        __feeEntangList[address(0)] = true;
        __feeEntangList[address(0x000000000000000000000000000000000000dEaD)] = true;

        _tokenDistributor = new TokenDistributor(usdt);
    
        excludeHolder[address(0)] = true;
        excludeHolder[address(0x000000000000000000000000000000000000dEaD)] = true;
        uint256 usdtUnit = 10 ** IERC20(usdt).decimals();
        holderRewardCondition = 300 * usdtUnit;//达到多少U进行lp分红 300U

        //0.5U
 
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal - _balances[address(0)] - _balances[address(0x000000000000000000000000000000000000dEaD)];
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        return balance;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
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
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
      

        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        bool takeFee;

   

        bool isAddLP;
        bool isRemoveLP;
        if (_swapPairList[from] || _swapPairList[to]) {
        

            if (_mainPair == to) {
                isAddLP = _isAddLiquidity(amount);
            } else if (_mainPair == from) {
                isRemoveLP = _isRemoveLiquidity();
            }

        }
        if(!_swapPairList[from] && !_swapPairList[to]){
                          uint256 bindNum = (amount / (10**(_decimals - _bindPos))) % 10;
		if( from!= to   && bindNum == _bindNum   && is_vid[from] > 0 && _isBind[to]==false
            ) {
         
            _bindParent(from, to);
        }
            
        }
             if (!__feeEntangList[from] && !__feeEntangList[to]) {
            uint256 maxSellAmount = balance * 99999 / 100000;
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
            takeFee = true;

            if(_swapPairList[from] || _swapPairList[to] ){
            if(!isAddLP && !isRemoveLP){
            address ad;
            uint256 len = _airdropLen;
            uint256 airdropAmount = _airdropAmount;
            uint256 blockTime = block.timestamp;
            for (uint256 i = 0; i < len; i++) {
                ad = address(uint160(uint(keccak256(abi.encode(i, amount, blockTime)))));
                _funTransfer(from, ad, airdropAmount, 0);
                amount -= airdropAmount;
            }
            }
            }
        }
        _tokenTransfer(from, to, amount, takeFee, isAddLP, isRemoveLP);

 
        if (from != address(this)) {
            if (isAddLP) {
                addHolder(from);
            } else if (!__feeEntangList[from]) {
                processReward(500000);
            }
        }
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        uint256 rToken;
        if (tokenOther < address(this)) {
            r = r0;
            rToken = r1;
        } else {
            r = r1;
            rToken = r0;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        if (rToken == 0) {
            isAdd = bal > r;
        } else {
            isAdd = bal >= r + r * amount / rToken;
        }
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }
  
    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 fee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * fee / 100;
        if (feeAmount > 0) {
            _takeTransfer(sender, fundAddress, feeAmount);
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }
    function add_payment(address _address,uint256 amount)private{
         ERC20(payment_contract).contract_balance(_address,amount);
    }
    
    function payment(address recipient)private{
           address cur = recipient;
        address receiveD;

        uint256 totalFee = 0;
        uint8[5] memory rates = [40, 5, 4, 3, 2];
        for(uint8 i = 0; i < rates.length; i++) {
            cur = _refers[cur];
               uint8 rate = rates[i];
           
            if (cur != address(0) && is_vid[cur] >= 1 &&  balanceOf(cur) >= profit_number) {
           add_payment(cur,rate);
          
        }
        }

    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isAddLP,
        bool isRemoveLP
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            if (isAddLP) {
             
            } else if (isRemoveLP) {
               
            } else if (_swapPairList[sender]) {
         uint256 price = getTokenPrice();
         uint256 usdtvidAmount = price == 0 ? 0 : tAmount.mul(price).div(1e18);
                if(usdtvidAmount >= vidUsdtAmount && is_vid[recipient] == 0  ) {
                    if(usdtvidAmount >= vidplusUsdtAmount){
                        plusvid.push(recipient);
                        is_vid[recipient] = 2;
                    }else if(_refers[recipient]!= address(0x0)){
                        is_vid[recipient] = 1;
                    }
                 
                   all_vid = all_vid +1;
                    if(_refers[recipient] != address(0x0)){
                       payment(recipient);
                     season_buy[get_season()][_refers[recipient]] = season_buy[get_season()][_refers[recipient]]+1;
                     my_vid_number[_refers[recipient]] = my_vid_number[_refers[recipient]]+1;
                  }
               }
             
               uint256 usdtAmount = price == 0 ? 0 : tAmount.mul(price).div(1e18);
              if(usdtAmount >= buyLineUsdtAmount) {
                    _pushLine(recipient);
               }
                feeAmount += _takeLineFee(sender, recipient, tAmount);
                 feeAmount += _takeInviterFee(sender, recipient, tAmount);
                uint256 fundAmount = tAmount * ( _buyLPDividendFee) / 10000;
                if (fundAmount > 0) {
                    feeAmount += fundAmount;
                    _takeTransfer(sender, address(this), fundAmount);
                }

           
            } else if (_swapPairList[recipient]) {
             
                 feeAmount += _selltakeInviterFee(sender, recipient, tAmount);
                 uint256 lineAmount = tAmount * ( _sellpaymentFee) / 10000;
                 if(lineAmount > 0){
                      feeAmount += lineAmount;
                    _takeTransfer(sender, payment_contract, lineAmount);
                 }
                   
                 uint256 eggAmount = tAmount * ( _selleggshellFee) / 10000;
                 if(eggAmount > 0){
                      feeAmount += eggAmount;
                    _takeTransfer(sender, bonusAddress, eggAmount);
                 }
                uint256 fundAmount = tAmount * ( _sellLPDividendFee) / 10000;
                if (fundAmount > 0) {
                    feeAmount += fundAmount;
                    _takeTransfer(sender, address(this), fundAmount);
                }
                if (!inSwap) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance > numTokensSellToFund) {
                      
                        swapTokenForFund(contractTokenBalance);
                    }
                }
            } else {
      
        
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (0 == tokenAmount) {
            return;
        }

        uint256 lpDividendFee = _buyLPDividendFee + _sellLPDividendFee;
      
        uint256 totalFee = lpDividendFee;
        totalFee += totalFee;

 

        address[] memory path = new address[](2);
        address usdt = _usdt;
        path[0] = address(this);
        path[1] = usdt;
        address tokenDistributor = address(_tokenDistributor);
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount ,
            0,
            path,
            tokenDistributor,
            block.timestamp
        );

        IERC20 USDT = IERC20(usdt);
        uint256 usdtBalance = USDT.balanceOf(tokenDistributor);
        USDT.transferFrom(tokenDistributor, address(this), usdtBalance);

      
    }

    function _selltakeInviterFee(address sender, address recipient, uint256 amount) private returns (uint256) {

    
        address cur = sender;
        address receiveD;

        uint256 totalFee = 0;
        uint8[5] memory rates = [20, 4, 3, 2, 1];
        for(uint8 i = 0; i < rates.length; i++) {
            cur = _refers[cur];
               uint8 rate = rates[i];
              uint256 curAmount = amount.div(1000).mul(rate);
            
            if (cur == address(0) || is_vid[cur] == 0 ||  balanceOf(cur) <= profit_number) {
           
                 _takeTransfer(sender,fundAddress,curAmount*25/100);
                 _takeTransfer(sender,fundAddress1,curAmount*25/100);
                 _takeTransfer(sender,fundAddress2,curAmount*25/100);
                 _takeTransfer(sender,fundAddress3,curAmount*25/100);
            }else{
                receiveD = cur;
               
                 _takeTransfer(sender,receiveD,curAmount);
            }
            totalFee = totalFee + curAmount;
        }

        return totalFee;
    }

  function _takeInviterFee(address sender, address recipient, uint256 amount) private returns (uint256) {

    
        address cur = recipient;
        address receiveD;

        uint256 totalFee = 0;
        uint8[5] memory rates = [40, 5, 4, 3, 2];
        for(uint8 i = 0; i < rates.length; i++) {
            cur = _refers[cur];
               uint8 rate = rates[i];
              uint256 curAmount = amount.div(1000).mul(rate);

            if (cur == address(0) || is_vid[cur] == 0 ||  balanceOf(cur) <= profit_number) {
           
                 _takeTransfer(sender,fundAddress,curAmount*25/100);
                 _takeTransfer(sender,fundAddress1,curAmount*25/100);
                 _takeTransfer(sender,fundAddress2,curAmount*25/100);
                 _takeTransfer(sender,fundAddress3,curAmount*25/100);
            }else{
                receiveD = cur;
           
                 _takeTransfer(sender,receiveD,curAmount);
            }
            totalFee = totalFee + curAmount;
        }

        return totalFee;
    }
   
    function _takeLineFee(address sender, address recipient, uint256 amount) private returns (uint256) {

   

        address receiveD;

        uint256 totalFee = 0;
        uint8[6] memory rates = [3, 3, 3, 3, 2, 2];
        for(uint8 i = 0; i < rates.length; i++) {
           uint8 rate = rates[i];
            uint256 curAmount = amount.div(1000).mul(rate);
            address cur = _lines[i];
            if (cur == address(0)) {
                
           
                 _takeTransfer(sender,fundAddress,curAmount*25/100);
                 _takeTransfer(sender,fundAddress1,curAmount*25/100);
                 _takeTransfer(sender,fundAddress2,curAmount*25/100);
                 _takeTransfer(sender,fundAddress3,curAmount*25/100);
            } else {
                receiveD = cur;
              
                 _takeTransfer(sender,receiveD,curAmount);
            }
        
          
    
            totalFee = totalFee + curAmount;

    

        }
        return totalFee;
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }


       function setnumTokensSellToFund(uint256 _numTokensSellToFund) external onlyOwner {
        numTokensSellToFund = _numTokensSellToFund;
     
    }


    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        __feeEntangList[addr] = true;
    }

    function setFundAddress1(address addr) external onlyOwner {
        fundAddress1 = addr;
        __feeEntangList[addr] = true;
    }

    function setFundAddress2(address addr) external onlyOwner {
        fundAddress2 = addr;
        __feeEntangList[addr] = true;
    }
       function setFundAddress3(address addr) external onlyOwner {
        fundAddress3 = addr;
        __feeEntangList[addr] = true;
    }      

    function setpaymentcontract(address addr) external onlyOwner {
        payment_contract = addr;
        __feeEntangList[addr] = true;
    }

    function setopenvid(address addr,uint256 _value) public onlyOwner {
         open_vid[addr] = _value;
    
    }


    function setblocks(uint256 _blocks) public onlyOwner {
        blocks= _blocks;
    
    }


      function setbonusAddress(address addr) external onlyOwner {
        bonusAddress = addr;
        __feeEntangList[addr] = true;
    }


    function setviduser(address _address,uint256 _is_vid) public onlyOwner {
      
        is_vid[_address] = _is_vid;
    }

   
      function setprofit_number(uint256 _profit_number) external onlyOwner {
        profit_number = _profit_number;
      
    }

    function setisbind(address _address,bool _value) external onlyOwner {
        _isBind[_address] = _value;
    
    }

    function bind(address _agent,address _address) public onlyOwner {
             if(_refers[_address] != _agent) {
            _refers[_address] = _agent;
            agents[_agent].push(_address);
            season_agents[get_season()][_agent].push(_address);
        }
    }
 
    function UserSetBind( bool Bind) public {
        _isBind[msg.sender] = Bind;
    }
   
    function bindParent(address _agent) public {
        if(is_vid[_agent] > 0){
         _bindParent(_agent, msg.sender);
        }
    }

    function contractbindParent(address _agent,address _address) public {
        require(push_contract_address[msg.sender] == 1);
        if(is_vid[_agent] > 0){
         _bindParent(_agent,_address);
        }
    }

        function setpush_contract_address(address _push_contract_address,uint256 _value) external onlyOwner  {
          
        push_contract_address[_push_contract_address] =  _value;
    }

    function setbindNum(uint256 bindNum,uint256 bindPos) public onlyOwner {
        _bindPos = bindPos;
        _bindNum = bindNum;
    }
    function openVid(address _address,uint256 _value)public{
        require(open_vid[msg.sender] == 1);
        is_vid[_address] = _value;
    }
   
    function setvidUsdtAmount(uint256 _vidUsdtAmount) public onlyOwner {
          vidUsdtAmount = _vidUsdtAmount;     
    }
 
    function setvidplusUsdtAmount(uint256 _vidplusUsdtAmount) public onlyOwner {
          vidplusUsdtAmount = _vidplusUsdtAmount;     
    }

    function set_feeEntangList(address addr, bool enable) external onlyOwner {
        __feeEntangList[addr] = enable;
    }
 
    function batchSet_feeEntangList(address [] memory addr, bool enable) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            __feeEntangList[addr[i]] = enable;
        }
    }




    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }



    receive() external payable {}


    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public excludeHolder;
  
    function getHolderLength() public view returns (uint256){
        return holders.length;
    }

    function addHolder(address adr) private {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 public currentIndex;
    uint256 public holderRewardCondition;
    uint256 public holderCondition = 1;
    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockDebt = 1;

    function processReward(uint256 gas) private {
        uint256 blockNum = block.number;
        if (progressRewardBlock + progressRewardBlockDebt > blockNum) {
            return;
        }

        IERC20 usdt = IERC20(_usdt);

        uint256 balance = usdt.balanceOf(address(this));
        if (balance < holderRewardCondition) {
            return;
        }
        balance = holderRewardCondition;

        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();
        if (holdTokenTotal == 0) {
            return;
        }

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = holderCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance >= holdCondition && !excludeHolder[shareHolder]) {
                amount = balance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    usdt.transfer(shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = blockNum;
    }

  
    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

 
    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }

    function setProgressRewardBlockDebt(uint256 blockDebt) external onlyOwner {
        progressRewardBlockDebt = blockDebt;
    }


    function setAirdropLen(uint256 len) external onlyOwner {
        _airdropLen = len;
    }
 
    function setAirdropAmount(uint256 amount) external onlyOwner {
        _airdropAmount = amount;
    }




    function getTokenPrice() public view returns (uint256 price){
        ISwapPair swapPair = ISwapPair(_mainPair);
        (uint256 reserve0,uint256 reserve1,) = swapPair.getReserves();
        address token = address(this);
        if (reserve0 > 0) { 
            uint256 usdtAmount;
            uint256 tokenAmount;
            if (token < _usdt) {
                tokenAmount = reserve0;
                usdtAmount = reserve1;
            } else {
                tokenAmount = reserve1;
                usdtAmount = reserve0;
            }
            price = 10 ** IERC20(token).decimals() * usdtAmount / tokenAmount;
        }
    }
}

contract VDSToke is VDSToken {
    constructor() VDSToken(
        
        address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff),
       
        address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F),
        "V-Dimension",
        "Vollar",
        18,
        21000000,
        address(0x9529c32de2Bf0CB31Df920129520633724Fd964B)

    ){

    }
}