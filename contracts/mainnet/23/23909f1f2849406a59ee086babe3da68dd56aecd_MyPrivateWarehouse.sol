pragma solidity >=0.6.6;

import './Interfaces.sol';

contract MyPrivateWarehouse {

    address private _owner;
    function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
    }

    constructor() public {
    address msgSender = _msgSender();
    _owner = msgSender;
    }

     modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _owner = newOwner;
  }

    address wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    function usdctoTokenViamaticAuto(address routeraddress, uint amountIn, address targetToken) public onlyOwner returns(bool, bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](3);
     path[0] = usdc;
     path[1] = wmatic;
     path[2] = targetToken;
     uint amountOutMin = 100000 * amountIn / (4 * usdcPerTokenRate2(routeraddress, targetToken) / 3);
     approve1(routeraddress,amountIn);
     executeExactTokensForTokenscall(routeraddress, amountIn,amountOutMin,path,to,deadline);
    }
     
    function TokentousdcViamaticAuto(address routeraddress, uint amountIn, address targetToken) public onlyOwner returns(bool, bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](3);
     path[0] = targetToken;
     path[1] = wmatic;
     path[2] = usdc;
     uint amountOutMin = (3 * usdcPerTokenRate2(routeraddress,targetToken) / 4) / amountIn / 100000;
     approve2(targetToken,routeraddress,amountIn);
     executeExactTokensForTokenscall(routeraddress, amountIn,amountOutMin,path,to,deadline);
    }

    function usdctoTokenViamaticData(uint amountIn, uint amountOutMin, address targetToken) public view returns(bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](3);
     path[0] = usdc;
     path[1] = wmatic;
     path[2] = targetToken;  
     bytes memory bytesdata = abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline);
     return bytesdata;
    }

     function dragmaticwithusdc(uint amountIn, uint amountOutMin) public view returns(bytes memory){
     address to = msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](2);
     path[0] = usdc;
     path[1] = wmatic;    
     bytes memory bytesdata = abi.encodeWithSignature("swapExactTokensForETH(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline);
     return bytesdata;
    }

    function executeExactTokensForTokenscall(address routeraddress, uint amountIn,uint amountOutMin,address[] memory path,address to,uint deadline) internal {
    (bool success, ) = routeraddress.call(abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline));
     require(success == true, "transaction is failed");
    }

    function approvetoken(address token,address spender,uint amount) internal{
    IERC20(token).approve(spender, amount);
    }

    function approve1(address spender,uint amount) internal {
        if(amount > IERC20(usdc).allowance(address(this),spender)){
            approvetoken(usdc,spender,amount);
        }
    }

    function approve2(address targetToken, address spender, uint amount) internal {
        if(amount > IERC20(targetToken).allowance(address(this),spender)){
            approvetoken(targetToken,spender,amount);
        }
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
         if (source.length == 0) {
             return 0x0;
             }
             assembly {
                 result := mload(add(source, 32))
             }
     }

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin];
        }
        return string(a);    
    }

    function getratewithdecimal5(address routeraddress, uint indecimal, uint outdecimal, uint amountsIn, address[] memory path) internal view returns(uint){
     uint[] memory expectedAmountsOut = UniswapV2Library.getAmountsOut(IUniswapV2Router02(routeraddress).factory(), amountsIn, path);
     uint calculatingwithdecimal5;
     uint i = path.length;
     if(indecimal == outdecimal){         
     calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / expectedAmountsOut[i-1];
     }else if(indecimal > outdecimal){
     calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / (10**(indecimal - outdecimal)) / expectedAmountsOut[i-1]; 
     }else{
      calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] * (10**(outdecimal - indecimal)) / expectedAmountsOut[i-1]; 
     }
     return calculatingwithdecimal5;
    }

    function getstringrate(uint calculatingwithdecimal5) internal pure returns(string memory){
     string memory rawstringrate = toString(calculatingwithdecimal5);
     string memory stringrate1;
     string memory stringrate2;
     string memory stringrate3;
     string memory stringrate;
     uint d = bytes(rawstringrate).length-1;
     if(calculatingwithdecimal5>=10**5){
     stringrate1 = getSlice(0,d-5,rawstringrate);
     stringrate2 = ".";
     stringrate3 = getSlice(d-4,d,rawstringrate);
     stringrate = string(abi.encodePacked(stringrate1,stringrate2,stringrate3));
     }else if(calculatingwithdecimal5>=10**4){
     stringrate2 = "0.";
     stringrate3 = getSlice(0,d,rawstringrate);
     stringrate = string(abi.encodePacked(stringrate2,stringrate3)); 
     }else{
     stringrate2 = "0.0";
     stringrate3 = getSlice(0,d,rawstringrate);
     stringrate = string(abi.encodePacked(stringrate2,stringrate3)); 
     }
     return stringrate;  
    }

    function getpath(uint i, address targetToken) internal view returns(address[] memory){
    address[] memory path = new address[](i);
    if(i==3){
     path[i-3] = usdc;
     path[i-2] = wmatic;
     path[i-1] = targetToken;
    }else if(i==2){
     path[i-2] = usdc;
     path[i-1] = targetToken;
    }
    return path;
    }


    function getusdcPerTokenRate1(address routeraddress, address targetToken) public view returns(string memory) { 
     address[] memory path = getpath(2,targetToken);
     uint indecimal = IERC20(usdc).decimals();
     uint outdecimal = IERC20(targetToken).decimals();
     uint amountsIn = 10**(indecimal);
     uint calculatingwithdecimal5 = getratewithdecimal5(routeraddress, indecimal,outdecimal,amountsIn,path);
     string memory stringrate = getstringrate(calculatingwithdecimal5);
     return stringrate;     
    }

    function getusdcPerTokenRate2(address routeraddress, address targetToken) public view returns(string memory) { 
     address[] memory path = getpath(3,targetToken);
     uint indecimal = IERC20(usdc).decimals();
     uint outdecimal = IERC20(targetToken).decimals();
     uint amountsIn = 10**(indecimal);
     uint calculatingwithdecimal5 = getratewithdecimal5(routeraddress, indecimal,outdecimal,amountsIn,path);
     string memory stringrate = getstringrate(calculatingwithdecimal5);
     return stringrate;     
    }
      
    function usdcPerTokenRate1(address routeraddress, address targetToken) internal view returns(uint) { 
     address[] memory path = getpath(2,targetToken);
     uint indecimal = IERC20(usdc).decimals();
     uint outdecimal = IERC20(targetToken).decimals();
     uint amountsIn = 10**(indecimal);
     uint[] memory expectedAmountsOut = UniswapV2Library.getAmountsOut(IUniswapV2Router02(routeraddress).factory(), amountsIn, path);
     uint calculatingwithdecimal5;
     if(indecimal==outdecimal){
         calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / expectedAmountsOut[1];
     }else if(indecimal<outdecimal){
         calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] * (10**(outdecimal-indecimal)) / expectedAmountsOut[1];
     }else{
         calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / (10**(indecimal-outdecimal)) / expectedAmountsOut[1];
     }
     return calculatingwithdecimal5; 
     }
     
     function usdcPerTokenRate2(address routeraddress, address targetToken) internal view returns(uint) { 
     address[] memory path = getpath(3,targetToken);
     uint indecimal = IERC20(usdc).decimals();
     uint outdecimal = IERC20(targetToken).decimals();
     uint amountsIn = 10**(indecimal);
     uint[] memory expectedAmountsOut = UniswapV2Library.getAmountsOut(IUniswapV2Router02(routeraddress).factory(), amountsIn, path);
      uint calculatingwithdecimal5;
     if(indecimal==outdecimal){
         calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / expectedAmountsOut[2];
     }else if(indecimal<outdecimal){
         calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] * (10**(outdecimal-indecimal)) / expectedAmountsOut[2];
     }else{
         calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / (10**(indecimal-outdecimal)) / expectedAmountsOut[2];
     }
     return calculatingwithdecimal5; 
     }

     function withdraw(address payable to, uint amount) public onlyOwner{
        to.transfer(amount);
    }
    function transferforErc20Tokens(address token, address recipient, uint256 amount) public onlyOwner{
        IERC20(token).transfer(recipient,amount);
    }

     receive() external payable {}
     fallback() external payable {}


}