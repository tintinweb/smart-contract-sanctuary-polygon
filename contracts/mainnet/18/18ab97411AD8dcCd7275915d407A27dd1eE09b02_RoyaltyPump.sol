// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IWrappedERC20.sol";
import "./IGatedERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./TokensRecoverable.sol";
import './IPancakeRouter02.sol';
import './IPancakeFactory.sol';
import "./IWBNB.sol";
import "./RootedTransferGate.sol";

contract RoyaltyPump is TokensRecoverable
{


    //money comes in as matic
    //49% of incoming matic goes to liquidity for musician token
    //1% goes to liquidity controller for signed token
    //50% goes to musician staking
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public devAddress;  
    mapping (address => bool) public royaltyCollector;
    
    address public immutable deployerAddress;
    IPancakeRouter02 public immutable router;
    IPancakeFactory public immutable factory;
    IWrappedERC20 public immutable chainToken;
    address public signedLiquidityController;
    address public artistToken;
    address public stakingContract;
    IERC20 public artistLP;
    RootedTransferGate gate;

    mapping (IGatedERC20 => uint256) public burnRates;
    mapping (IGatedERC20 => uint256) public sellRates;
    mapping (IGatedERC20 => uint256) public keepRates;

    mapping (IGatedERC20 => address[]) public chainTokenFeeCollectors;
    mapping (IGatedERC20 => uint256[]) public chainTokenFeeRates;

    mapping (IGatedERC20 => address[]) public rootedTokenFeeCollectors;
    mapping (IGatedERC20 => uint256[]) public rootedTokenFeeRates;
    uint256 public totalRoyaltiesCollected;

    constructor(address _devAddress, IPancakeRouter02 _router, address _signedLiquidityController, address _stakingContract, address _artistToken, RootedTransferGate _gate)
    {
        deployerAddress = msg.sender;
        devAddress = _devAddress;
        royaltyCollector[msg.sender] = true;
        router = _router;
        chainToken = IWrappedERC20(_router.WETH());   
        signedLiquidityController = _signedLiquidityController;
        stakingContract = _stakingContract;
        artistToken = _artistToken;
        IPancakeFactory _factory = IPancakeFactory(_router.factory());
        factory = _factory;
        artistLP = IERC20(_factory.getPair(_router.WETH(), address(artistToken)));
        gate = _gate;
        

        artistLP.approve(address(_router), (uint256(-1)));
        IERC20(_artistToken).approve((address(_router)), uint256(-1));
        IWrappedERC20(_router.WETH()).approve((address(_router)), uint256(-1));

    }
    modifier onlyRoyaltyCollector()
    {
        require(royaltyCollector[msg.sender] || msg.sender == devAddress);
        _;
    }
    function setDevAddress(address _devAddress) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        devAddress = _devAddress;
    }
    function setRoyaltyCollector(address _royaltyCollector) public
    {
        require (msg.sender == deployerAddress || msg.sender == devAddress, "Not a deployer or dev address");
        royaltyCollector[_royaltyCollector] = true;
    }
   
    //rates out of 10,000
    function depositRoyalties() public payable onlyRoyaltyCollector() 
    {
        require (msg.value > 0, "Must deposit some amount");
        totalRoyaltiesCollected = totalRoyaltiesCollected + msg.value;
        uint256 stakingRate = 5000;
        uint256 signedRate = 100;
        uint256 liquidityRate = 4900;

        uint256 stakingAmount = msg.value * stakingRate / 10000;
        uint256 signedAmount = msg.value * signedRate / 10000;
        uint256 liquidityAmount = msg.value * liquidityRate / 10000;

        IWBNB(address(chainToken)).deposit{ value: address(this).balance}();

        //chainToken.transfer(stakingContract, stakingAmount);
        chainToken.transfer(signedLiquidityController, signedAmount);

        uint256 amountToSpend = liquidityAmount.div(2);
        
        buyArtistToken(amountToSpend);
        uint256 amountForStaking = buyArtistToken(stakingAmount);
        IERC20(artistToken).transfer(stakingContract, amountForStaking);
        gate.setUnrestricted(true);
        addLiq(chainToken.balanceOf(address(this)));
        gate.setUnrestricted(false);
    }
    //rates out of 10,000

//todo make below private
    function buyArtistToken(uint256 amountToSpend) private returns (uint256)
    {
        uint256[] memory amounts = router.swapExactTokensForTokens(amountToSpend, 0, buyPath(), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }
    function addLiq(uint256 chainTokenAmount) private
    {
        router.addLiquidity(address(chainToken), address(artistToken), chainTokenAmount, IERC20(artistToken).balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function buyPath() private view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(chainToken);
        path[1] = address(artistToken);
        return path;
    }
}