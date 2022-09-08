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
import "./ISignedStake.sol";
import "./StakingToken.sol";

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
    
    address public signedStakingContract;
    
    mapping (address => uint256) public totalRoyaltiesCollectedByToken; //map royalties by token address

    constructor(address _devAddress, IPancakeRouter02 _router)
    {
        deployerAddress = msg.sender;
        devAddress = _devAddress;
        royaltyCollector[msg.sender] = true;
        router = _router;
        chainToken = IWrappedERC20(_router.WETH());   
        
       
        IPancakeFactory _factory = IPancakeFactory(_router.factory());
        factory = _factory;
       
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
    //set signed staking contract address
    function setSignedStakingContract(address _signedStakingContract) public onlyRoyaltyCollector()
    {
        signedStakingContract = _signedStakingContract;
    }
    

    function depositRoyaltyAnyToken(address _artistToken, address _artistStaking, address _transGate) public payable onlyRoyaltyCollector(){

        //todo approve router from the LP, approve staking from artist token, approve  router from artist tokenn
        IERC20 artistLP = IERC20(factory.getPair(router.WETH(), address(_artistToken)));
        artistLP.approve(address(router), (uint256(-1)));
        IERC20(_artistToken).approve((address(router)), uint256(-1));
        

         require (msg.value > 0, "Must deposit some amount");
        totalRoyaltiesCollectedByToken[_artistToken] = totalRoyaltiesCollectedByToken[_artistToken] += msg.value;
        uint256 stakingRate = 4000;
        uint256 signedRate = 100;
        uint256 liquidityRate = 4900;
        

        uint256 stakingAmount = msg.value * stakingRate / 10000;
        uint256 signedAmount = msg.value * signedRate / 10000;
        uint256 liquidityAmount = msg.value * liquidityRate / 10000;
        
        ISignedStake(signedStakingContract).depositMatic{value: signedAmount}(); //Good!
        
        IWBNB(address(chainToken)).deposit{ value: address(this).balance}(); //GOOD!

        //chainToken.transfer(stakingContract, stakingAmount);
        //chainToken.transfer(signedLiquidityController, signedAmount);

        uint256 amountToSpend = liquidityAmount.div(2) + stakingAmount; //Good!
        
        buyAnyArtistToken(amountToSpend, _artistToken); //Good!

        addLiquidityAnyToken(_artistToken, _transGate); //fix

        uint256 amountForStaking = IERC20(_artistToken).balanceOf(address(this));
        
        IERC20(_artistToken).transfer(_artistStaking, amountForStaking);
    }

   
    //rates out of 10,000


    function buyAnyArtistToken(uint256 _amountToSpend, address _artistToken) private returns (uint256){
        uint256[] memory amounts = router.swapExactTokensForTokens(_amountToSpend, 0, buyAnyPath(_artistToken), address(this), block.timestamp);
        _amountToSpend = amounts[1];
        return _amountToSpend;
    }
    
    function buyAnyPath(address _token) private view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(chainToken);
        path[1] = _token;
        return path;
    }
    function addLiquidityAnyToken(address _token, address _transGate) private {
        RootedTransferGate(_transGate).setUnrestricted(true);
        addLiqAnyToken(chainToken.balanceOf(address(this)), _token);
        RootedTransferGate(_transGate).setUnrestricted(false);
    }
    function addLiqAnyToken(uint256 chainTokenAmount, address _token) private
    {
        router.addLiquidity(address(chainToken), address(_token), chainTokenAmount, IERC20(_token).balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    
}