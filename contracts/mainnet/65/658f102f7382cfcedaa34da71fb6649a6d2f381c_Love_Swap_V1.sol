/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

pragma solidity 0.6.0;

contract Love_Swap_V1 {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using address_make_payable for address;
    
    address superMan;
    address aRouter;
    address bRouter;
    address WMATICAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    
    constructor (address _bRouter, address _aRouter) public {
        superMan = address(tx.origin);
        bRouter = _bRouter;
        aRouter =_aRouter;

    }
    
    function getBRouter() public view returns(address) {
        return bRouter;
    }
    
    function getARouter() public view returns(address) {
        return aRouter;
    }
    
    
    function getSuperMan() public view returns(address) {
        return superMan;
    }
    
    function setBRouter(address _bRouter) public onlyOwner {
        bRouter = _bRouter;
    }
    
    function setARouter(address _aRouter) public onlyOwner {
        aRouter = _aRouter;
    }
    
    function setSuperMan(address _newMan) public onlyOwner {
        superMan = _newMan;
    }
    // arouter:ETH->tonken,brouter:tonken->ETH
    function doitForA(uint256 ethAmount,address tokenAddress) public payable onlyOwner{
        uint256 ethBefore = address(this).balance;
        address[] memory data = new address[](2);
        data[0] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        data[1] = address(tokenAddress);
        ARouter(aRouter).swapExactETHForTokens.value(ethAmount)(0,data,address(this),block.timestamp);
        uint256 tokenMiddle = ERC20(tokenAddress).balanceOf(address(this));

        ERC20(tokenAddress).safeApprove(bRouter, tokenMiddle);
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        BRouter(bRouter).swapExactTokensForETH(tokenMiddle,1,path,address(this),block.timestamp);
        require(address(this).balance >= ethBefore, "ETH not enough"); 
    }


    // brouter:ETH->tonken,arouter:tonken->ETH
    function doitForB(uint256 ethAmount,address tokenAddress) public payable onlyOwner{
        uint256 ethBefore = address(this).balance;
        address[] memory data = new address[](2);
        data[0] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        data[1] = address(tokenAddress);
        BRouter(bRouter).swapExactETHForTokens.value(ethAmount)(0,data,address(this),block.timestamp);
        uint256 tokenMiddle = ERC20(tokenAddress).balanceOf(address(this));

        ERC20(tokenAddress).safeApprove(aRouter, tokenMiddle);
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        ARouter(aRouter).swapExactTokensForETH(tokenMiddle,1,path,address(this),block.timestamp);
        require(address(this).balance >= ethBefore, "ETH not enough"); 
    }

    function doitFora(uint256 ethAmount,address tokenAddress) public payable onlyOwner{
        address[] memory data = new address[](2);
        data[0] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        data[1] = address(tokenAddress);
        ARouter(aRouter).swapExactETHForTokens.value(ethAmount)(0,data,address(this),block.timestamp);
        uint256 tokenMiddle = ERC20(tokenAddress).balanceOf(address(this));
        ERC20(tokenAddress).safeApprove(bRouter, tokenMiddle);
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        BRouter(bRouter).swapExactTokensForETH(tokenMiddle,1,path,address(this),block.timestamp);
    }


    // brouter:ETH->tonken,arouter:tonken->ETH
    function doitForb(uint256 ethAmount,address tokenAddress) public payable onlyOwner{  
        address[] memory data = new address[](2);
        data[0] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        data[1] = address(tokenAddress);
        BRouter(bRouter).swapExactETHForTokens.value(ethAmount)(0,data,address(this),block.timestamp);
        uint256 tokenMiddle = ERC20(tokenAddress).balanceOf(address(this));

        ERC20(tokenAddress).safeApprove(aRouter, tokenMiddle);
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        ARouter(aRouter).swapExactTokensForETH(tokenMiddle,1,path,address(this),block.timestamp);
    }


    function moreETH() public payable {
        
    }
    
    function turnOutToken(address token, uint256 amount) public onlyOwner{
        ERC20(token).safeTransfer(superMan, amount);
    }
    
    function turnOutETH(uint256 amount) public onlyOwner {
        address payable addr = superMan.make_payable();
        addr.transfer(amount);
    }
    
    function getGasFee(uint256 gasLimit) public view returns(uint256){
        return gasLimit.mul(tx.gasprice);
    }
    
    function getTokenBalance(address token) public view returns(uint256) {
        return ERC20(token).balanceOf(address(this));
    }
    
    function getETHBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    modifier onlyOwner(){
        require(address(msg.sender) == superMan, "No authority");
        _;
    }
    
    receive() external payable{}
}


interface ARouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}


interface BRouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}