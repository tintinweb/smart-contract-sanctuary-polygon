/**
 *Submitted for verification at polygonscan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

//import "hardhat/console.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract Property{
    using SafeERC20 for IERC20;
    address SushiSwapRouterAddr = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(SushiSwapRouterAddr);
    event rateLog(address tokenAddr, uint256 rate);
    // event mortAmount(address recipient, address tokenAddr, uint256 rate);

    event setCollateralListLog(address tokenAddr,uint decimal,uint mortRate,uint liquRate,uint state);
    event settokenUSDAddrLog(address oldAddr,uint oldDecinal,address newAddr,uint newDecinal);
    event setInteRateLog(uint inteRate,uint newInteRate);

    bool stateFrozen;
    bool notFrozenState;
    //??????
    modifier notFrozen()
    {
        require(notFrozenState, "STATE_IS_FROZEN");
        _;
    }

    //have bug
    function getPath(address tokenIn,address tokenOut)public pure returns(address[] memory){
        //0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619  WETH or WBNB 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
        address pathM = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

        address[] memory path = new address[](3);
        path[0] = tokenIn;
        if (tokenIn == pathM) {
            path[1] = tokenOut;
        }else{
            path[1] = pathM;
            path[2] = tokenOut;
        }
        return path;
    }

    //???????????????????????????token??????A??????B??????????????????B?????????amountOut
    function sushiGetSwapTokenAmountOut(
        address[] memory path,
        uint amountIn
    ) public view virtual returns (uint) {
        uint amountOut = sushiRouter.getAmountsOut(
            amountIn,
            path
        )[path.length - 1];
        return amountOut;
    }

    //??????????????????In?????????Out???Out???????????????????????????????????????approve
    function sushiSwapper(address[] memory path,uint amountIn) private returns(uint){
        uint amountOut = sushiGetSwapTokenAmountOut(path,amountIn);
        sushiRouter.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + 300
        );
        return amountOut;
    }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//?????????????????????
    mapping(address=>collaListPa) public collaList;//???????????????
    struct collaListPa{
        uint decimal;//??????
        string name;//
        uint mortRate;//?????????
        uint liquRate;//?????????
        uint inteRate;//8??????????????????  54794520547945
        uint apyRate;//?????????
        uint state;//???????????? 0:????????????1?????????
    }
    uint rateDeno = 1000000000000000000;
    function setCollateralList(
        address tokenAddr,//???????????????
        string memory name,
        uint decimal,
        uint mortRate,
        uint liquRate,
        uint apyRate,
        uint state
    )public {
        require(tokenAddr != tokenUSDAddrOut, "CANNOT_BE_USD");
        collaList[tokenAddr].name = name;
        collaList[tokenAddr].decimal = decimal;
        collaList[tokenAddr].mortRate = mortRate;
        collaList[tokenAddr].liquRate = liquRate;
        collaList[tokenAddr].state = state;
        collaList[tokenAddr].apyRate = apyRate;
        collaList[tokenAddr].inteRate = apyRate/1095;
        emit setCollateralListLog(tokenAddr,decimal,mortRate,liquRate,state);
    }

//??????????????????
    address public tokenUSDAddrOut;
    uint public tokenUSDAddrOutDecimal;
    mapping(address=>tokenUSDListPar) public tokenUSDList;
    struct tokenUSDListPar{
        address tokenUSDAddrOut;
        uint tokenUSDAddrOutDecimal;
        string name;
    }
    function settokenUSDAddr(address newtokenUSDAddr,uint newtokenUSDAddrOutDecimal,string memory newName) public{
        emit settokenUSDAddrLog(tokenUSDAddrOut,tokenUSDAddrOutDecimal,newtokenUSDAddr,newtokenUSDAddrOutDecimal);
        tokenUSDAddrOut = newtokenUSDAddr;
        tokenUSDAddrOutDecimal = newtokenUSDAddrOutDecimal;

        tokenUSDList[newtokenUSDAddr].tokenUSDAddrOut = newtokenUSDAddr;
        tokenUSDList[newtokenUSDAddr].tokenUSDAddrOutDecimal = newtokenUSDAddrOutDecimal;
        tokenUSDList[newtokenUSDAddr].name = newName;
    }

//???????????????
    uint public inteRate_t;//54794520547945
    uint public inteRateDeno = 1000000000000000000;
    uint public inteRateCreateTime;
    function setInteRate(uint newInteRate) public {
        //???????????????????????????8????????????????????????????????????????????????
        //?????????restInteTime???8???????????????  28800
        require(block.timestamp < inteRateCreateTime + 28800 || inteRateCreateTime==0,"MUST_RESTINTETIME");
        //????????????
        emit setInteRateLog(inteRate_t,newInteRate);
        inteRate_t = newInteRate;
        inteRateCreateTime = block.timestamp;
    }

    //???????????????????????????????????????????????????8????????????????????????????????????????????????
    function restInteTime(uint start, uint end) public {
        //??????????????????
        for (uint i=start; i<=end; i++){
            if (contList[i].contState == 0){
                uint interestConfirmRest = getInterest(i,0);
                if (interestConfirmRest>0) {
                    contList[i].interestConfirm += interestConfirmRest;
                    contList[i].interestTime = block.timestamp;
                }
            }
        }
        inteRateCreateTime = block.timestamp;
    }

    //????????????
    function transferToExchange(address tokenAddr,uint256 amount)public returns (bool){
        IERC20 token = IERC20(tokenAddr);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender,address(this),amount);
        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
        require(exchangeBalanceAfter == exchangeBalanceBefore + amount,"INCORRECT_AMOUNT_TRANSFERRED");
        return true;
    }

//?????????????????????????????????????????????approve???this.address
    //?????????
    mapping(address=>user) public users;
    struct user{
        userAssetPar[] userAsset;//????????????
        uint[] userContList;//??????????????????
        uint userCreateTime;//????????????
    }
    struct userAssetPar{
        address tokenaddr;
        uint amount;
    }

    //????????????
    uint public loanContractAmount;

    //?????????
    mapping(uint=>contListPar) public contList;
    struct contListPar{
        address userAddr;//????????????
        address mortAddr;//???????????????
        address tokenUSDAddr;//????????????????????????
        uint mortAmount;//??????????????????
        uint tokenUSDAmount;//????????????????????????
        uint interestTime;//??????????????????????????????????????????????????????
        uint interestConfirm;//?????????????????????????????????????????????
        contUpdateListPar[] contUpdateList;//????????????
        uint contState;//?????????????????????0???0?????????1???????????????????????????????????????2???????????????????????????3???????????????
        uint createTime;
    }
    struct contUpdateListPar{
        uint updateType;//?????????????????????0???0??????????????????1????????????2????????????3?????????????????????4?????????
        uint mortAmount;//???????????????
        uint tokenUSDAmount;//??????????????????
        uint mortRate;//?????????
        // uint interestConfirm;//????????????
        uint createTime;
    }

    function depositToken(
        address tokenAddr,
        uint amount
    )public{
        // console.log("start ",tokenAddr);
        //????????????????????????????????????????????????
        require(collaList[tokenAddr].state != 0,"MORTGAGE_INVALID");
        // console.log("collaList[tokenAddr].state is  ",collaList[tokenAddr].state);
        //transfer?????????????????????????????????
        IERC20(tokenAddr).safeTransferFrom(msg.sender,address(this),amount);
        // console.log("transferFrom end ",tokenAddr);
        //????????????????????????????????????
        uint mortRate = collaList[tokenAddr].mortRate;
        // console.log("mortRate is ",mortRate);
        //?????????????????????
        uint tokenOutAmount = sushiGetSwapTokenAmountOut(getPath(tokenAddr,tokenUSDAddrOut),amount);
        // console.log("tokenOutAmount is ",tokenOutAmount);
        //??????????????????
        uint tokenCollateraAmount = tokenOutAmount * rateDeno/mortRate;
        // console.log("tokenCollateraAmount is ",tokenCollateraAmount);
        require(tokenCollateraAmount!=0,"TOKENOUTAMOUNT_TOO_LOW");

        uint isUser = users[msg.sender].userCreateTime;
        // console.log("isUser is ",isUser);
        if (isUser==0) {//???????????????
            users[msg.sender].userCreateTime = block.timestamp;
        }
        // console.log("users[msg.sender].userCreateTime is ",users[msg.sender].userCreateTime);
        
        //????????????
        setUserAsset(msg.sender,tokenUSDAddrOut,tokenCollateraAmount,0);
        //??????????????????????????????????????????
        bool contStateTemp = true;
        //????????????
        uint contId;
        uint contUpdatelistNum;
        // console.log("users[msg.sender].userContList.length is ",users[msg.sender].userContList.length);
        for (uint i=0; i<users[msg.sender].userContList.length;i++) {
            // console.log("i is ",i);
            contId = users[msg.sender].userContList[i];
            // console.log("contId is ",contId);
            address mortAddr = contList[contId].mortAddr;
            // console.log("mortAddr is ",mortAddr);
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            // console.log("tokenUSDAddr is ",tokenUSDAddr);
            uint stateTemp = contList[contId].contState;
            // console.log("stateTemp is ",stateTemp);
            if (mortAddr==tokenAddr && tokenUSDAddr==tokenUSDAddrOut && stateTemp<=1){
                // console.log("contStateTemp is ",contStateTemp);
                //??????
                contStateTemp = false;
                contList[contId].contUpdateList[contUpdatelistNum].updateType = 1;
                //?????????????????? ????????????0.06??? rate=54794520547  94520,20?????? 100000000000000000000
                contList[contId].interestConfirm = getInterest(contId,1);
                // console.log("contList[contId].interestConfirm is ",contList[contId].interestConfirm);

                break;
            }
        }
        //?????????
        if (contStateTemp){
            // console.log("contStateTemp is ",contStateTemp);
            contId = loanContractAmount;
            // console.log("contId is ",contId);
            contList[contId].userAddr = msg.sender;
            // console.log("contList[contId].userAddr is ",contList[contId].userAddr);
            contList[contId].mortAddr = tokenAddr;
            // console.log("contList[contId].mortAddr is ",contList[contId].mortAddr);
            contList[contId].tokenUSDAddr = tokenUSDAddrOut;
            // console.log("contList[contId].tokenUSDAddr is ",contList[contId].tokenUSDAddr);
            contList[contId].createTime = block.timestamp;
            // console.log("contList[contId].createTime is ",contList[contId].createTime);
            loanContractAmount ++;//???????????????1
            // console.log("loanContractAmount is ",loanContractAmount);
            users[msg.sender].userContList.push(contId);//??????????????????????????????
            //console.log("users[msg.sender].userContList is ",users[msg.sender].userContList.length);
        }
        contList[contId].interestTime = block.timestamp;
        contList[contId].mortAmount += amount;
        contList[contId].tokenUSDAmount += tokenCollateraAmount;
        contList[contId].contState = 0;

        contUpdateListPar memory m;
        m.mortAmount = amount;
        m.tokenUSDAmount = tokenCollateraAmount;
        m.mortRate = mortRate;
        m.createTime = block.timestamp;
        contList[contId].contUpdateList.push(m);
        
        //?????????????????????????????????????????????????????????
        // emit depositTokenLog(msg.sender,contId,contStateTemp,tokenAddr,amount,);
    }

    //????????????????????????eth,matic

    function setUserAsset(address userAddr,address tokenAddr,uint amount,uint addsub) public {
        bool isTrue;uint num;uint assetAmount;
        (isTrue,num,assetAmount) = getUserAssetToken(userAddr,tokenAddr);
        if (amount>0){
            if (isTrue){
                if (addsub == 0){
                    users[userAddr].userAsset[num].amount += amount;
                }else if(addsub == 1){
                    users[userAddr].userAsset[num].amount -= amount;
                }
            }else{
                userAssetPar memory m;
                m.tokenaddr = tokenAddr;
                m.amount = amount;
                users[userAddr].userAsset.push(m);
            }
        }
    }

    function getUserAssetToken(address userAddr,address tokenAddr) public view returns(bool,uint,uint){
        for (uint i=0; i<users[userAddr].userAsset.length; i++){
                if (users[userAddr].userAsset[i].tokenaddr == tokenAddr){
                    return (true,i,users[userAddr].userAsset[i].amount);
                }
            }
        return (false,0,0);
    }
    
    //??????????????????
    function getInterest(uint contId,uint addNum) public view returns(uint){
        return contList[contId].tokenUSDAmount * ((block.timestamp - contList[contId].interestTime) / 3600 / 8 + addNum) * collaList[contList[contId].mortAddr].inteRate/rateDeno;
    }

    //??????
    function repayment(uint contId,uint amount) public {
        //??????????????????
        require(contList[contId].userAddr == msg.sender, "NOT_CONTRACT");
        require(contList[contId].createTime != 0, "CONTRACT_NOT_EXIST");
        require(contList[contId].contState == 0, "CONTRACT_FINISH");
        address tokenAddr = contList[contId].tokenUSDAddr;
        uint assetAmount;
        (,,assetAmount) = getUserAssetToken(msg.sender,tokenAddr);
        require(assetAmount >= amount, "ASSET_INSUFFICIENT");
        uint tokenUSDAmount = contList[contId].tokenUSDAmount;
        // uint interestAmount = contList[contId].interestConfirm + getInterest(contId);
        contList[contId].interestConfirm += getInterest(contId,0);
        contList[contId].interestTime = block.timestamp;

        contUpdateListPar memory m;
        m.updateType = 2;
        m.createTime = block.timestamp;

        if (amount >= tokenUSDAmount + contList[contId].interestConfirm){
            //????????????
            setUserAsset(msg.sender,tokenAddr,(tokenUSDAmount + contList[contId].interestConfirm),1);

            contList[contId].tokenUSDAmount = 0;
            contList[contId].interestConfirm = 0;
            contList[contId].contState = 1;//???????????????????????????????????????
            //????????????
            m.tokenUSDAmount = (tokenUSDAmount + contList[contId].interestConfirm);
        }else{
            //??????????????????
            if (amount>=tokenUSDAmount){
                contList[contId].tokenUSDAmount = 0;
                contList[contId].interestConfirm -= amount-tokenUSDAmount;
            }else{
                contList[contId].tokenUSDAmount -= amount;
            }
            setUserAsset(msg.sender,tokenAddr,amount,1);
            m.tokenUSDAmount = amount;
        }
        contList[contId].contUpdateList.push(m);
    }

    //???????????????
    function redeem(uint contId,uint amount) public {
        //?????????????????????
        require(contList[contId].userAddr == msg.sender, "NOT_CONTRACT_SELF");
        require(contList[contId].mortAmount >= amount, "AMOUNT_INSUFFICIENT");
        require(contList[contId].contState > 0, "AMOUNT_INSUFFICIENT");

        address mortAddr = contList[contId].mortAddr;
        IERC20(mortAddr).safeTransfer(msg.sender,amount);

        contList[contId].mortAmount -= amount;
    }


    //??????????????????????????????
   function getUserAsset(address userAddr) public view returns(string memory){
        uint lengthNum = users[userAddr].userAsset.length;
        string memory asset = '[';
        for (uint i=0; i<lengthNum; i++){
            //console.log("i  ", i);
            address tokenAddr = users[userAddr].userAsset[i].tokenaddr;
            uint amount = users[userAddr].userAsset[i].amount;

            asset = string(abi.encodePacked(asset,"{"));

            asset = string(abi.encodePacked(asset,'"address":"'));
            asset = string(abi.encodePacked(asset,addressToSting(tokenAddr)));
            asset = string(abi.encodePacked(asset,'",'));

            asset = string(abi.encodePacked(asset,'"name":"'));
            string memory name = tokenUSDList[tokenAddr].name;
            asset = string(abi.encodePacked(asset,name));
            asset = string(abi.encodePacked(asset,'",'));

            asset = string(abi.encodePacked(asset,'"amount":"'));
            asset = string(abi.encodePacked(asset,uint2str(amount)));
            asset = string(abi.encodePacked(asset,'",'));

            asset = string(abi.encodePacked(asset,'"decimal":"'));
            uint decimal = tokenUSDList[tokenAddr].tokenUSDAddrOutDecimal;
            asset = string(abi.encodePacked(asset,uint2str(decimal)));
            asset = string(abi.encodePacked(asset,'"'));
            if (i==lengthNum-1){
                asset = string(abi.encodePacked(asset,'}'));
            }else{
                asset = string(abi.encodePacked(asset,'},'));
            }
        }
        asset = string(abi.encodePacked(asset,']'));
        return asset;
    }

    //??????????????????
    function getContract(address userAddr) public view returns(string memory){
        uint lengthNum = users[userAddr].userContList.length;
        string memory conList = '[';
        for (uint i=0;i<lengthNum;i++){
            uint contId = users[userAddr].userContList[i];
            address mortAddr = contList[contId].mortAddr;
            address tokenAddr = contList[contId].mortAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenAmount = contList[contId].tokenUSDAmount;
            uint mortDecimal = collaList[mortAddr].decimal;
            uint tokenDecimal = tokenUSDList[contList[contId].tokenUSDAddr].tokenUSDAddrOutDecimal;
            uint liquRate = collaList[mortAddr].liquRate;
            uint mortRate = collaList[mortAddr].mortRate;

            conList = string(abi.encodePacked(conList,"{"));

            conList = string(abi.encodePacked(conList,'"id":'));
            conList = string(abi.encodePacked(conList,uint2str(contId)));
            conList = string(abi.encodePacked(conList,','));

            conList = string(abi.encodePacked(conList,'"address":'));
            conList = string(abi.encodePacked(conList,addressToSting(mortAddr)));
            conList = string(abi.encodePacked(conList,','));
            
            conList = string(abi.encodePacked(conList,'"mortAmount":'));
            conList = string(abi.encodePacked(conList,uint2str(mortAmount * rateDeno/mortDecimal)));
            conList = string(abi.encodePacked(conList,','));

            conList = string(abi.encodePacked(conList,'"tokenAmount":'));
            conList = string(abi.encodePacked(conList,uint2str(tokenAmount * rateDeno/tokenDecimal)));
            conList = string(abi.encodePacked(conList,','));

            uint USDAmount = sushiGetSwapTokenAmountOut(getPath(mortAddr,tokenAddr),mortAmount);
            conList = string(abi.encodePacked(conList,'"USDAmount":'));
            conList = string(abi.encodePacked(conList,uint2str(USDAmount * rateDeno/tokenDecimal)));
            conList = string(abi.encodePacked(conList,','));

            uint factorH = (USDAmount * rateDeno/tokenAmount - liquRate) * rateDeno / (mortRate - liquRate);
            if (factorH>rateDeno) {factorH = rateDeno;}
            conList = string(abi.encodePacked(conList,'"factor":'));
            conList = string(abi.encodePacked(conList,uint2str(factorH)));
            conList = string(abi.encodePacked(conList,','));

            uint debt = collaList[mortAddr].apyRate;
            conList = string(abi.encodePacked(conList,'"debt":'));
            conList = string(abi.encodePacked(conList,uint2str(debt)));
            
            if (i==lengthNum-1){
                conList = string(abi.encodePacked(conList,'}'));
            }else{
                conList = string(abi.encodePacked(conList,'},'));
            }
        }
        conList = string(abi.encodePacked(conList,']'));
        return conList;
    }


    //???????????????????????????
    function getAllToken(address tokenAddr, address toAddr, uint amount) public {
        IERC20(tokenAddr).safeTransfer(toAddr,amount);
    }

    //????????????????????????
    function liquidateList(uint start,uint end)public view returns(uint[] memory){
        require(end>=start);
        require(end<=loanContractAmount);
        uint[] memory reLiqui;
        uint j;
        for (uint i=start; i<=end; i++){
            if(isLiqui(i)){
                reLiqui[j] = i;
                j++;
            }
        }
        return reLiqui;
    }

    //?????????????????????????????????
    function isLiqui(uint contId)private view returns(bool){
        if (contList[contId].contState == 0){
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenUSDAmount = contList[contId].tokenUSDAmount;
            uint interAmount = contList[contId].interestConfirm + getInterest(contId,0);
            //?????????????????????
            uint tokenOutAmount = sushiGetSwapTokenAmountOut(getPath(mortAddr,tokenUSDAddr),mortAmount);
            if (tokenOutAmount * rateDeno/collaList[mortAddr].liquRate < tokenUSDAmount + interAmount){
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }

    //??????
    function liquiContract(uint contId) public {
        if (contList[contId].contState == 0){
            address userAddr = contList[contId].userAddr;
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenUSDAmount = contList[contId].tokenUSDAmount;
            uint interAmount = contList[contId].interestConfirm + getInterest(contId,0);
            
            IERC20(mortAddr).safeApprove(SushiSwapRouterAddr,mortAmount);
            uint amountOut = sushiSwapper(getPath(mortAddr,tokenUSDAddr),mortAmount);
            if (amountOut>=tokenUSDAmount+interAmount){
                //???????????????????????????
                setUserAsset(userAddr,tokenUSDAddr,amountOut-tokenUSDAmount-interAmount,1);
            }else{
                //????????????????????????

            }
            //????????????
            contList[contId].contState = 3;//????????????
            contList[contId].mortAmount = 0;
            contList[contId].tokenUSDAmount = 0;
            contList[contId].interestConfirm = 0;
        }
    }

    //address to string
    function addressToSting(address addr) internal pure returns(string memory){
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i=0;i<20;i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 *leftValue;
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue+48) : bytes1(leftValue+87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue+48) : bytes1(rightValue+87);
            stringBytes[2*i+3] = rightChar;
            stringBytes[2*i+2] = leftChar;
        }
        return string(stringBytes);
    }
    //uint to string
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}