/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

/*  
 * CrazyApez3DMintOnPolygon
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */
pragma solidity 0.8.17;

interface IBEP20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IElkNet {
    function transfer(uint32 chainID, address recipient, uint256 elkAmount, uint256 gas) external;
}

interface IElkRouterMatic {
    function WMATIC() external pure returns (address);
    function swapExactMATICForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForMATIC(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactMATICForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForMATICSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IApeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract CrazyApez3DMintOnPolygon {
    address public constant MRGREEN = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    address public constant BRIDGEWALLET = 0x174Af6E7cd8936597Dfd12988cE037ae4d0A86D7;
    IBEP20 public constant ELK = IBEP20(0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE);
    IElkRouterMatic public constant ELK_ROUTER = IElkRouterMatic(0xf38a7A7Ac2D745E2204c13F824c00139DF831FFf);
    IElkNet public constant ELK_NET = IElkNet(0xb1F120578A7589FD9336315C4dF7d5A5d90173A8);
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant BNB = 0xA649325Aa7C5093d12D6F98EB4378deAe68CE23F;
    IApeRouter01 public constant APEROUTER = IApeRouter01(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    uint256 public mintPriceInBnb = 0.2 ether;
    uint256 public decimals;
    address[] private pathForBuyingElk = new address[](2);
    address[] private pathForBuyingBnb = new address[](2);

    modifier onlyOwner() {if(msg.sender != MRGREEN) return; _;}

    event CrazyApezMintedOnPolygon(address minter, uint256 qty, address referrer);

    constructor() {
        decimals = ELK.decimals();
        pathForBuyingElk[0] = WMATIC;
        pathForBuyingElk[1] = address(ELK);
        pathForBuyingBnb[0] = WMATIC;
        pathForBuyingBnb[1] = BNB;
        ELK.approve(address(ELK_NET), type(uint256).max);
    }

    receive() external payable {}

    function getMintPriceInMatic() public view returns(uint256) {
        return APEROUTER.getAmountsIn(mintPriceInBnb, pathForBuyingBnb)[0];
    }

    function mintCrazyApeOnBsc(address referrer) external payable {
        uint256 mintPriceInMatic = getMintPriceInMatic();
        require(msg.value >= mintPriceInMatic, "Please pay the price");
        if(msg.value>mintPriceInMatic) payable(msg.sender).transfer(msg.value - mintPriceInMatic);
        emit CrazyApezMintedOnPolygon(msg.sender, 1, referrer);
        ELK_ROUTER.swapExactMATICForTokens{value: address(this).balance}(0, pathForBuyingElk, address(this), block.timestamp);
        uint256 elkBalance = ELK.balanceOf(address(this));
        ELK_NET.transfer(56, BRIDGEWALLET, elkBalance, elkBalance - (5 * 10**decimals));
    }

    function mintManyCrazyApeOnBsc(uint256 qty, address referrer) external payable {
        uint256 mintPriceInMatic = getMintPriceInMatic();
        require(msg.value >= qty * mintPriceInMatic, "Please pay the price");
        if(msg.value > qty * mintPriceInMatic) payable(msg.sender).transfer(msg.value - qty * mintPriceInMatic);
        emit CrazyApezMintedOnPolygon(msg.sender, qty, referrer);
        ELK_ROUTER.swapExactMATICForTokens{value: address(this).balance}(0, pathForBuyingElk, address(this), block.timestamp);
        uint256 elkBalance = ELK.balanceOf(address(this));
        ELK_NET.transfer(56, BRIDGEWALLET, elkBalance, elkBalance - (5 * 10**decimals));
    }

    function rescueAnyToken(address token) external onlyOwner {
        IBEP20(token).transfer(MRGREEN, IBEP20(token).balanceOf(address(this)));
    }
    
    function rescueMatic() external onlyOwner {
        payable(MRGREEN).transfer(address(this).balance);
    }

    function setMintPrice(uint256 value) external onlyOwner {
        mintPriceInBnb = value;
    }
}