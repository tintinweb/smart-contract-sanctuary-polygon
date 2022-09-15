/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

//SPDX-License-Identifier: GPL-3.0+

pragma solidity ^0.8.12;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}    
}

contract UsdBtcEthToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract CrvToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}    
}

contract DaiToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract CurveSwap
{
	function add_liquidity(uint256[5] memory, uint256) public {}
}

contract CurveGauge
{
	function deposit(uint256) public {}
}

contract CurveMint
{
	function mint(address) public {}
}

contract QuickSwapRouter
{
    function swapExactTokensForTokens(
                 uint,
                 uint,
                 address[] calldata,
                 address,
                 uint
             ) external virtual returns (uint[] memory) {}
}

contract ReiPool
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    //Constants
    string  private constant NAME = "\x52\x65\x69\x20\x50\x6f\x6f\x6c";
    uint256 private constant SWAP_WAITING_SECONDS = 3600;
    uint256 private constant DEPOSIT_FEE = 10; //Deposit fee: 10%
    uint256 private constant AUTO_COMPOUND_FEE = 33; //Auto-compound fee: 33%
    uint256 private constant HARVEST_COOLDOWN_BLOCKS = 28800;
    uint256 private constant STAKING_BLOCK_RANGE = 864000;
    uint256 private constant UNIT_WEI = 1000000000000000000;
    uint256 private constant UPDATE_COOLDOWN_BLOCKS = 28800;
    
    address private constant GO_TOKEN_ADDRESS = 0x98D23ADA1Da268Bc10E2e0d1585C47971C4B89DD;
    address private constant USD_BTC_ETH_TOKEN_ADDRESS = 0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3;
    address private constant CRV_TOKEN_ADDRESS = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
    address private constant DAI_TOKEN_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant MATIC_TOKEN_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant CURVE_SWAP_ADDRESS = 0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8;   
    address private constant CURVE_GAUGE_ADDRESS = 0xBb1B19495B8FE7C402427479B9aC14886cbbaaeE;     
    address private constant CURVE_MINT_ADDRESS = 0xabC000d88f23Bb45525E447528DBF656A9D55bf5;   
    address private constant QUICKSWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        
    GoToken         private constant GO_TOKEN = GoToken(GO_TOKEN_ADDRESS);
    UsdBtcEthToken  private constant USD_BTC_ETH_TOKEN = UsdBtcEthToken(USD_BTC_ETH_TOKEN_ADDRESS);
    CrvToken        private constant CRV_TOKEN = CrvToken(CRV_TOKEN_ADDRESS);
    DaiToken        private constant DAI_TOKEN = DaiToken(DAI_TOKEN_ADDRESS);    
    CurveSwap       private constant CURVE_SWAP = CurveSwap(CURVE_SWAP_ADDRESS);
    CurveGauge		private constant CURVE_GAUGE = CurveGauge(CURVE_GAUGE_ADDRESS);
    CurveMint       private constant CURVE_MINT = CurveMint(CURVE_MINT_ADDRESS);
    QuickSwapRouter private constant QUICKSWAP_ROUTER = QuickSwapRouter(QUICKSWAP_ROUTER_ADDRESS);

    address[] private GO_DAI_PAIR = [GO_TOKEN_ADDRESS, MATIC_TOKEN_ADDRESS, DAI_TOKEN_ADDRESS];        
    address[] private CRV_DAI_PAIR = [CRV_TOKEN_ADDRESS, MATIC_TOKEN_ADDRESS, DAI_TOKEN_ADDRESS];
   
    //State variables
    uint256 private _lastUpdate;
    uint256 private _totalStakingDeposits;
    
    mapping(address => UserData) private _userData;
   
    constructor() {}
    
    function getName() external pure returns (string memory)
    {
        return NAME;
    }
    
    function getRewardsFund() public view returns (uint256)
    {
        return CRV_TOKEN.balanceOf(address(this));
    }
    
    function getTotalStakingDeposits() external view returns (uint256)
    {
        return _totalStakingDeposits;
    }
    
    function getDepositFee() external pure returns (uint256)
    {
        return DEPOSIT_FEE;
    }
    
    function getHarvestCooldownBlocks() external pure returns (uint256)
    {
        return HARVEST_COOLDOWN_BLOCKS;
    }
    
    function getStakingBlockRange() external pure returns (uint256)
    {
        return STAKING_BLOCK_RANGE;
    }
    
    function stakeDai() private
    {
    	//Add liquidity
        uint256 daiAmount = DAI_TOKEN.balanceOf(address(this));    	
    	
    	if (daiAmount > 0)
        {
            DAI_TOKEN.approve(CURVE_SWAP_ADDRESS, daiAmount);
            CURVE_SWAP.add_liquidity([daiAmount, 0, 0, 0, 0], 0);
        }
        
        //Stake on gauge
        uint256 usdBtcEthAmount = USD_BTC_ETH_TOKEN.balanceOf(address(this));
        
        if (usdBtcEthAmount > 0)
        {
        	USD_BTC_ETH_TOKEN.approve(CURVE_GAUGE_ADDRESS, usdBtcEthAmount);
        	CURVE_GAUGE.deposit(usdBtcEthAmount);
        }
    } 
    
    function autoCompound(uint256 crvAmount) private
    {
        require(crvAmount > 0, "ReiPool: CRV amount cannot be 0");
        
        address[] memory crvDaiPairMemory = CRV_DAI_PAIR;
        
        //Swap CRV for DAI
        CRV_TOKEN.approve(QUICKSWAP_ROUTER_ADDRESS, crvAmount);
        QUICKSWAP_ROUTER.swapExactTokensForTokens(crvAmount, 0, crvDaiPairMemory, address(this), block.timestamp + SWAP_WAITING_SECONDS);
        
        //Stake Dai
        stakeDai();
    }
    
    function updateRewardsFund() private
    {
        uint256 elapsedBlocks = block.number - _lastUpdate;
    
        if (elapsedBlocks > UPDATE_COOLDOWN_BLOCKS)
        {
            //Harvest pending CRV
            CURVE_MINT.mint(CURVE_GAUGE_ADDRESS);
            
            uint256 crvAmount = CRV_TOKEN.balanceOf(address(this));
            
            uint256 autoCompoundFeeAmount = crvAmount * AUTO_COMPOUND_FEE / 100;
                
            //Auto-compound
            if (autoCompoundFeeAmount > 0)
                autoCompound(autoCompoundFeeAmount);
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "ReiPool: minimum deposit amount: 100");
        
        GO_TOKEN.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * DEPOSIT_FEE / 100;
        uint256 netAmount = amount - fee;
        
        //Update Rei Pool data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap deposit fee for DAI
        address[] memory goDaiPairMemory = GO_DAI_PAIR;
        
        GO_TOKEN.approve(QUICKSWAP_ROUTER_ADDRESS, fee);
        QUICKSWAP_ROUTER.swapExactTokensForTokens(fee, 0, goDaiPairMemory, address(this), block.timestamp + SWAP_WAITING_SECONDS);
        
        //Stake Dai
        stakeDai();
        
        //Update rewards fund
        updateRewardsFund();
    }

    function withdraw() external
    {
        uint256 blocksStaking = computeBlocksStaking();

        if (blocksStaking > HARVEST_COOLDOWN_BLOCKS)
            harvest();
        
        emergencyWithdraw();
    }
    
    function emergencyWithdraw() public
    {
        uint256 stakingDeposit = _userData[msg.sender].stakingDeposit;
        
        require(stakingDeposit > 0, "ReiPool: withdraw amount cannot be 0");
        
        _userData[msg.sender].stakingDeposit = 0;
 
        GO_TOKEN.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "ReiPool: staking deposit is 0");
    
        uint256 rewardsFund = getRewardsFund();
        
        uint256 userReward = 0;
    
        uint256 blocksStaking = computeBlocksStaking();
        
        if (blocksStaking > 0)
	    {
	        uint256 userBlockRatio = UNIT_WEI;
	    
	        if (blocksStaking < STAKING_BLOCK_RANGE)
	            userBlockRatio = blocksStaking * UNIT_WEI / STAKING_BLOCK_RANGE; 
		    
		    uint256 userDepositRatio = UNIT_WEI;
		    
		    if (_userData[msg.sender].stakingDeposit < _totalStakingDeposits)
		        userDepositRatio = _userData[msg.sender].stakingDeposit * UNIT_WEI / _totalStakingDeposits;
		    
		    uint256 totalRatio = userBlockRatio * userDepositRatio / UNIT_WEI;
		    
		    userReward = totalRatio * rewardsFund / UNIT_WEI;
		}
		
		return userReward;
    }

    function harvest() public 
    {
        require(_userData[msg.sender].stakingDeposit > 0, "ReiPool: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > HARVEST_COOLDOWN_BLOCKS, "ReiPool: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        CRV_TOKEN.transfer(msg.sender, userReward);
    }
    
    function getStakingDeposit() external view returns (uint256)
    {
        UserData memory userData = _userData[msg.sender];
    
        return (userData.stakingDeposit);
    }
    
    function getStakingBlock() external view returns (uint256)
    {
        UserData memory userData = _userData[msg.sender];
    
        return (userData.stakingBlock);
    }
    
    function computeBlocksStaking() public view returns (uint256)
    {
        uint256 blocksStaking = 0;
        
        if (_userData[msg.sender].stakingDeposit > 0)
            blocksStaking = block.number - _userData[msg.sender].stakingBlock;
        
        return blocksStaking;
    }
}