/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGReward {
    function updateVIPBlockWithPermit(address account,uint256 timer) external returns (bool);
}

interface IPLGDeposit {
    function depositWithMATIC(address account,address referral) external payable returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }

    modifier forRole(string memory str) {
        require(checkpermit(msg.sender,str),"Permit Revert!");
        _;
    }
}

contract PLGDepositorTOKEN is permission {
    
    address public owner;

    IPLGFactory factory;
    IDEXRouter router;

    uint256 public PLGCostUnlocker = 50 * 1e18;

    bool locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
        router = IDEXRouter(factory.getAddr("quick_router"));
    }

    function unlockLevelWithPLG(address account) public returns (bool) {
        IERC20(factory.getAddr("plg_token")).transferFrom(msg.sender,address(0xdead),PLGCostUnlocker);
        IPLGReward(factory.getAddr("plg_refreward")).updateVIPBlockWithPermit(account,type(uint256).max);
        return true;
    }

    function depositWithPLG(address account,address referral,uint256 amount,uint256 slippage,uint256 denominator) public noReentrant() returns (bool) {
        address[] memory path = new address[](2);
        path[0] = factory.getAddr("plg_token");
        path[1] = router.WETH();
        uint[] memory amountIn = router.getAmountsIn(amount,path);
        uint256 amountAfterSlippage = amountIn[0] * slippage / denominator;
        IERC20(factory.getAddr("plg_token")).transferFrom(msg.sender,address(this),amountAfterSlippage);
        IERC20(factory.getAddr("plg_token")).approve(address(router),amountAfterSlippage);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountAfterSlippage,
            amount,
            path,
            address(this),
            block.timestamp
        );
        uint256 refundToken = IERC20(factory.getAddr("plg_token")).balanceOf(address(this));
        if(refundToken>0){ IERC20(factory.getAddr("plg_token")).transfer(msg.sender,refundToken); }
        IPLGDeposit(factory.getAddr("plg_depositETH")).depositWithMATIC{ value: amount }(account,referral);
        _clearStuckBalance(factory.getAddr("plg_pool"));
        return true;
    }

    function buyPLG(address account,uint256 slippage,uint256 denominator) public payable noReentrant() returns (bool) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = factory.getAddr("plg_token");
        uint[] memory amountOut = router.getAmountsOut(msg.value,path);
        uint256 amountAfterSlippage = amountOut[1] * slippage / denominator;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(    
            amountAfterSlippage,
            path,
            address(account),
            block.timestamp
        );
        return true;
    }

    function sellPLG(address account,uint256 amount,uint256 slippage,uint256 denominator) public noReentrant() returns (bool) {
        address[] memory path = new address[](2);
        path[0] = factory.getAddr("plg_token");
        path[1] = router.WETH();
        uint[] memory amountIn = router.getAmountsIn(amount,path);
        uint256 amountAfterSlippage = amountIn[0] * slippage / denominator;
        IERC20(factory.getAddr("plg_token")).transferFrom(msg.sender,address(this),amountAfterSlippage);
        IERC20(factory.getAddr("plg_token")).approve(address(router),amountAfterSlippage);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountAfterSlippage,
            amount,
            path,
            address(account),
            block.timestamp
        );
        return true;
    }

    function updatePLGCostUnlocker(uint256 amount) public forRole("owner") returns (bool) {
        PLGCostUnlocker = amount;
        return true;
    }
    
    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      _clearStuckBalance(owner);
      return true;
    }

    function _clearStuckBalance(address receiver) internal {
      (bool success,) = receiver.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
    }

    function grantRole(address adr,string memory role) public forRole("owner") returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public forRole("owner") returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public forRole("owner") returns (bool) {
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    receive() external payable {}
}