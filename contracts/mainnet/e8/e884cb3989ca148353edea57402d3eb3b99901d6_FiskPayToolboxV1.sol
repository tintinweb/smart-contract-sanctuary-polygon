/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface FiskPayToolboxInterface{

    //ERC-20
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);

    //WMATIC
    function deposit() external payable ;
    function withdraw(uint256 wad) external;

    //FiskPay
    function CheckIfAdmin(address addr) external view returns(bool);

    //Trident Router
    function exactInputSingleWithNativeToken(ExactInputSingleParams calldata params) external payable returns (uint256);
    struct ExactInputSingleParams {
        uint256 amountIn;
        uint256 amountOutMinimum;
        address pool;
        address tokenIn;
        bytes data;
    }

    //BentoBox
    function toAmount(address token, uint256 share, bool roundUp) external view returns (uint256);
    function toShare(address token, uint256 amount, bool roundUp) external view returns (uint256);
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;

    //Liquidity Pool
    function getAmountOut(bytes calldata data) external view returns (uint256);
    function getAmountIn(bytes calldata data) external view returns (uint256);
}

contract FiskPayToolboxV1{

    address constant private maticAddress = 0x0000000000000000000000000000000000001010;

    address constant private wMaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    FiskPayToolboxInterface constant private wrapper = FiskPayToolboxInterface(wMaticAddress);

    address constant private fiskAddress = 0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74;
    FiskPayToolboxInterface constant private fisk = FiskPayToolboxInterface(fiskAddress);

    address constant private routerAddress = 0xc5017BE80b4446988e8686168396289a9A62668E;
    FiskPayToolboxInterface constant private router = FiskPayToolboxInterface(routerAddress);

    address constant private bentoAddress = 0x0319000133d3AdA02600f0875d2cf03D442C3367;
    FiskPayToolboxInterface constant private bento = FiskPayToolboxInterface(bentoAddress);

    address constant private liquidityAddress = 0x1e8e058d6267936c92e9d0D83D34B7960daf69B9;
    FiskPayToolboxInterface constant private liquidity = FiskPayToolboxInterface(liquidityAddress);

    bool private locked = false;
    bool private unwrapping = false;

    event Wrap(address indexed wrapper, uint256 amountIn, uint256 amountOut);
    event Unwrap(address indexed unwrapper, uint256 amountIn, uint256 amountOut);
    event Swap(address indexed swapper, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event Burn(address indexed burner, uint256 amount);

    modifier noReentrant() {

        require(locked != true);

        locked = true;
        _;
        locked = false;
    }

    modifier adminOnly() {

        require(fisk.CheckIfAdmin(msg.sender));
        _;
    }


    constructor() {
        
        bento.setMasterContractApproval(address(this), routerAddress, true, 0, 0, 0);
    }


    //WMATIC
    function WrapMatic() payable public noReentrant returns(bool){

        uint256 prebalance = wrapper.balanceOf(address(this));

        wrapper.deposit{value:msg.value}();

        uint256 deltaBalance = wrapper.balanceOf(address(this)) - prebalance;

        require(wrapper.transfer(msg.sender, deltaBalance));

        emit Wrap(msg.sender, msg.value, deltaBalance);

        return true;
    }

    function UnwrapMatic(uint256 amount) public noReentrant returns(bool){

        require(wrapper.allowance(msg.sender, address(this)) >= amount, "Approval Required");

        wrapper.transferFrom(msg.sender, address(this), amount);

        uint256 prebalance = (address(this).balance);

        unwrapping = true;
        wrapper.withdraw(amount);
        unwrapping = false;

        uint256 deltaBalance = (address(this).balance) - prebalance;

        (bool sent,) = payable(msg.sender).call{value : deltaBalance}("");
        require(sent);

        emit Unwrap(msg.sender, amount, deltaBalance);

        return true;
    }


    //Trident Router
    function SwapMaticForFisk(uint256 amount, uint256 slippage, uint256 burn) payable public noReentrant returns(bool){

        require(slippage <= 150);
        require(burn <= 50);

        FiskPayToolboxInterface.ExactInputSingleParams memory params;

        params.amountIn = amount;
        params.amountOutMinimum = ExactMaticForFisk(amount *  (1000 - slippage) / 1000);
        params.pool = liquidityAddress;
        params.tokenIn = address(0);
        params.data = abi.encode(wMaticAddress, address(this), 1);

        uint256 amountOutTotal = router.exactInputSingleWithNativeToken{value:msg.value}(params);
        uint256 senderAmount = amountOutTotal;
        uint256 burnAmount = 0;

        if(burn > 0){

            burnAmount = amountOutTotal * burn / 1000;
            senderAmount -= burnAmount;

            require(fisk.transfer(address(0), burnAmount), "Failed to burn");

            emit Burn(msg.sender, burnAmount);
        }
        
        require(fisk.transfer(msg.sender, senderAmount), "Failed to send");
        
        emit Swap(msg.sender, maticAddress, fiskAddress, msg.value, senderAmount);

        return true;
    }


    //BentoBox
    function _wrappedToUnwrapped(uint256 amount) private view returns(uint256){

        return(bento.toAmount(wMaticAddress, amount, true));
    }

    function _unwrappedToWrapped(uint256 share) private view returns(uint256){

        return(bento.toShare(wMaticAddress, share, true));
    }
    

    //Liquidity Pool
    function ExactFiskForMatic(uint256 inputFisk) public view returns(uint256){
        
        return(_wrappedToUnwrapped(liquidity.getAmountOut(abi.encode(fiskAddress, inputFisk))));
    }
    
    function ExactMaticForFisk(uint256 inputMatic) public view returns(uint256){

        return(liquidity.getAmountOut(abi.encode(wMaticAddress, _unwrappedToWrapped(inputMatic))));
    }
    
    function FiskForExactMatic(uint256 outputMatic) public view returns(uint256){

        return(liquidity.getAmountIn(abi.encode(wMaticAddress, _unwrappedToWrapped(outputMatic)))); 
    }
    
    function MaticForExactFisk(uint256 outputFisk) public view returns(uint256){

        return(_wrappedToUnwrapped(liquidity.getAmountIn(abi.encode(fiskAddress, outputFisk))));
    }


    //Contract Cleanup
    function SweepAndBurn() public adminOnly returns(bool){

        uint256 wrappedBalance = wrapper.balanceOf(address(this));

        if(wrappedBalance > 10**9){

            unwrapping = true;
            wrapper.withdraw(wrappedBalance);
            unwrapping = false;
        }

        uint256 maticBalance = address(this).balance;

        if(maticBalance > 10**9){

            FiskPayToolboxInterface.ExactInputSingleParams memory params;

            params.amountIn = maticBalance;
            params.amountOutMinimum = ExactMaticForFisk(maticBalance *  95 / 100);
            params.pool = liquidityAddress;
            params.tokenIn = address(0);
            params.data = abi.encode(wMaticAddress, address(this), 1);

            router.exactInputSingleWithNativeToken{value:maticBalance}(params);
        }
    
        uint256 fiskBalance = fisk.balanceOf(address(this));

        require(fiskBalance > 0, "No cleanup required");
        require(fisk.transfer(address(0), fiskBalance), "Cleanup failed");

        emit Burn(address(this), fiskBalance);

        return true;
    }

    receive() external payable{
        
        require(unwrapping == true);
    }

    fallback() external{
        
        revert();   
    }
}