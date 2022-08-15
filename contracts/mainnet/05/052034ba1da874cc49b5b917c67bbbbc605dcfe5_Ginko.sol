/**
 *Submitted for verification at polygonscan.com on 2022-08-15
*/

//SPDX-License-Identifier: GPL-3.0+

pragma solidity ^0.8.12;

contract GoToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract ClamToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract UsdToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
}

contract EthereumToken
{
    function approve(address, uint256) external returns (bool) {}
    function balanceOf(address) external view returns (uint256) {}
    function transfer(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}
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

contract GoFarm
{
    function donate(uint256) external {}
}

contract PearlBank
{
    function stake(uint256) external {}
    function claimRewards() external {}
}

contract Ginko
{
    struct UserData 
    { 
        uint256 stakingDeposit;
        uint256 stakingBlock;
    }
    
    //Constants
    string  private constant NAME = "\x47\x69\x6e\x6b\xc5\x8d";
    uint256 private constant SWAP_WAITING_SECONDS = 3600;
    uint256 private constant DEPOSIT_FEE = 10; //Deposit fee: 10%
    uint256 private constant PERFORMANCE_FEE = 1; //Performance fee: 1%
    uint256 private constant AUTO_COMPOUND_FEE = 33; //Auto-compound fee: 33%
    uint256 private constant HARVEST_COOLDOWN_BLOCKS = 28800;
    uint256 private constant STAKING_BLOCK_RANGE = 864000;
    uint256 private constant UNIT_WEI = 1000000000000000000;
    uint256 private constant UPDATE_COOLDOWN_BLOCKS = 28800;
    
    address private constant GO_TOKEN_ADDRESS = 0x98D23ADA1Da268Bc10E2e0d1585C47971C4B89DD;
    address private constant CLAM_TOKEN_ADDRESS = 0xC250e9987A032ACAC293d838726C511E6E1C029d;
    address private constant USD_TOKEN_ADDRESS = 0x236eeC6359fb44CCe8f97E99387aa7F8cd5cdE1f; //USD+
    address private constant ETHEREUM_TOKEN_ADDRESS = 0xA1c57f48F0Deb89f569dFbE6E2B7f46D33606fD4; //MANA
    address private constant MATIC_TOKEN_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant QUICKSWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant GO_FARM_ADDRESS = 0x05C1EC18455dB5edcf1389B8fC215d56B42A15C0;
    address private constant PEARL_BANK_ADDRESS = 0x845EB7730a8D37e8D190Fb8bb9c582038331B48a;
        
    GoToken         private constant GO_TOKEN = GoToken(GO_TOKEN_ADDRESS);
    ClamToken       private constant CLAM_TOKEN = ClamToken(CLAM_TOKEN_ADDRESS);
    UsdToken        private constant USD_TOKEN = UsdToken(USD_TOKEN_ADDRESS);
    EthereumToken   private constant ETHEREUM_TOKEN = EthereumToken(ETHEREUM_TOKEN_ADDRESS);
    QuickSwapRouter private constant QUICKSWAP_ROUTER = QuickSwapRouter(QUICKSWAP_ROUTER_ADDRESS);
    GoFarm          private constant GO_FARM = GoFarm(GO_FARM_ADDRESS);
    PearlBank       private constant PEARL_BANK = PearlBank(PEARL_BANK_ADDRESS);
    
    address[] private ETHEREUM_CLAM_PAIR = [ETHEREUM_TOKEN_ADDRESS, MATIC_TOKEN_ADDRESS, CLAM_TOKEN_ADDRESS];
    address[] private USD_GO_PAIR = [USD_TOKEN_ADDRESS, MATIC_TOKEN_ADDRESS, GO_TOKEN_ADDRESS];
    address[] private USD_CLAM_PAIR = [USD_TOKEN_ADDRESS, MATIC_TOKEN_ADDRESS, CLAM_TOKEN_ADDRESS];
    address[] private USD_ETHEREUM_PAIR = [USD_TOKEN_ADDRESS, MATIC_TOKEN_ADDRESS, ETHEREUM_TOKEN_ADDRESS];
   
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
        return ETHEREUM_TOKEN.balanceOf(address(this)) - _totalStakingDeposits;
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
    
    function buyGoToken(uint256 usdAmount) private
    {
        require(usdAmount > 0, "Ginko: USD+ amount cannot be 0");
    
        address[] memory usdGoPairMemory = USD_GO_PAIR;
        
        //Swap USD+ for Gō
        USD_TOKEN.approve(QUICKSWAP_ROUTER_ADDRESS, usdAmount);
        QUICKSWAP_ROUTER.swapExactTokensForTokens(usdAmount, 0, usdGoPairMemory, address(this), block.timestamp + SWAP_WAITING_SECONDS);
        
        //Donate to Gō farm
        uint256 goAmount = GO_TOKEN.balanceOf(address(this));
        
        if (goAmount > 0)
        {
            GO_TOKEN.approve(GO_FARM_ADDRESS, goAmount);
            GO_FARM.donate(goAmount);
        }
    }
    
    function autoCompound(uint256 usdAmount) private
    {
        require(usdAmount > 0, "Ginko: USD+ amount cannot be 0");
        
        address[] memory usdClamPairMemory = USD_CLAM_PAIR;
        
        //Swap USD+ for CLAM
        USD_TOKEN.approve(QUICKSWAP_ROUTER_ADDRESS, usdAmount);
        QUICKSWAP_ROUTER.swapExactTokensForTokens(usdAmount, 0, usdClamPairMemory, address(this), block.timestamp + SWAP_WAITING_SECONDS);
        
        uint256 clamAmount = CLAM_TOKEN.balanceOf(address(this));
        
        if (clamAmount > 0)
        {
            CLAM_TOKEN.approve(PEARL_BANK_ADDRESS, clamAmount);
            PEARL_BANK.stake(clamAmount);
        }
    }
    
    function updateRewardsFund() private
    {
        uint256 elapsedBlocks = block.number - _lastUpdate;
    
        if (elapsedBlocks > UPDATE_COOLDOWN_BLOCKS)
        {
            //Harvest pending USD+
            PEARL_BANK.claimRewards();
            
            uint256 usdAmount = USD_TOKEN.balanceOf(address(this));
            
            uint256 performanceFeeAmount = usdAmount * PERFORMANCE_FEE / 100;
            uint256 autoCompoundFeeAmount = usdAmount * AUTO_COMPOUND_FEE / 100;
            
            //Buy Gō and donate it to Gō farm
            if (performanceFeeAmount > 0)
                buyGoToken(performanceFeeAmount);
                
            //Auto-compound
            if (autoCompoundFeeAmount > 0)
                autoCompound(autoCompoundFeeAmount);
            
            //Swap USD+ for Ethereum
            usdAmount = USD_TOKEN.balanceOf(address(this));
            
            if (usdAmount > 0)
            {
                address[] memory usdEthereumPairMemory = USD_ETHEREUM_PAIR;
            
                USD_TOKEN.approve(QUICKSWAP_ROUTER_ADDRESS, usdAmount);
                QUICKSWAP_ROUTER.swapExactTokensForTokens(usdAmount, 0, usdEthereumPairMemory, address(this), block.timestamp + SWAP_WAITING_SECONDS);
            }
            
            _lastUpdate = block.number;
        }
    }
    
    function deposit(uint256 amount) external 
    {
        require(amount >= 100, "Ginko: minimum deposit amount: 100");
        
        ETHEREUM_TOKEN.transferFrom(msg.sender, address(this), amount);
        
        uint256 fee = amount * DEPOSIT_FEE / 100;
        uint256 netAmount = amount - fee;
        
        //Update Ginko data
        _userData[msg.sender].stakingDeposit += netAmount;
        _userData[msg.sender].stakingBlock = block.number;
        
        _totalStakingDeposits += netAmount;
        
        //Swap deposit fee for CLAM
        address[] memory ethereumClamPairMemory = ETHEREUM_CLAM_PAIR;
        
        ETHEREUM_TOKEN.approve(QUICKSWAP_ROUTER_ADDRESS, fee);
        QUICKSWAP_ROUTER.swapExactTokensForTokens(fee, 0, ethereumClamPairMemory, address(this), block.timestamp + SWAP_WAITING_SECONDS);
        
        //Deposit CLAM on Pearl Bank
        uint256 clamAmount = CLAM_TOKEN.balanceOf(address(this));
            
        if (clamAmount > 0)
        {
            CLAM_TOKEN.approve(PEARL_BANK_ADDRESS, clamAmount);
            PEARL_BANK.stake(clamAmount);
        }
        
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
        
        require(stakingDeposit > 0, "Ginko: withdraw amount cannot be 0");
        
        _userData[msg.sender].stakingDeposit = 0;
 
        ETHEREUM_TOKEN.transfer(msg.sender, stakingDeposit);
        
        _totalStakingDeposits -= stakingDeposit;
    }

    function computeUserReward() public view returns (uint256)
    {
        require(_userData[msg.sender].stakingDeposit > 0, "Ginko: staking deposit is 0");
    
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
        require(_userData[msg.sender].stakingDeposit > 0, "Ginko: staking deposit is 0");

        uint256 blocksStaking = computeBlocksStaking();

        require(blocksStaking > HARVEST_COOLDOWN_BLOCKS, "Ginko: harvest cooldown in progress");
    
        updateRewardsFund();
        
        uint256 userReward = computeUserReward();
        
        _userData[msg.sender].stakingBlock = block.number;

        ETHEREUM_TOKEN.transfer(msg.sender, userReward);
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