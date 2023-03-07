/* ============================================= DEFI HUNTERS DAO ================================================================
                                           https://defihuntersdao.club/                                                                                                             
----------------------------------------------------------------------------------------------------------------------------------
#######    #######    ######       ####                  ######   #########  ######    #####  #### ########  ###   #####   #######  
 ##   ###   ##   ###     ###      ### ###               ### ###   #  ##  ##     ###      #    ###      #      ###    ##  ###   ###  
 ##    ##   ##    ##    ## ##    ##     ##             ##     #   #  ##  ##    ## ##     #  ###        #      ####   ##  ##     ##  
 ##     ##  ##     ##  ##  ##   ##       #              ###          ##       ##  ##     ####          #      ## ##  ##  #          
 ##     ##  ##     ##  #######  ##       ##               #####      ##       #######    ######        #      ##  ## ##  #   ###### 
 ##     #   ##     #  ##    ##   ##     ##             ##     ##     ##      ##    ##    #   ###       #      ##  #####  #      ##  
 ##   ###   ##   ###  ##     ##  ###   ###             ##    ###     ##      ##     ##   #    ##       #      ##   ####  ###    ##  
########   ########  ####   ####   #####               ########    #######  ####   #########   ### ########  #####  ###    #######  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./admin.sol";


interface ITxs
{
    function TxsAdd(address addr,uint256 amount,string memory name,uint256 id1,uint256 id2)external returns(uint256);
    function TxsCount(address addr)external returns(uint256);
    function EventAdd(uint256 txcount,address addr,uint256 user_id,uint256 garden,uint256 level,uint256 amount,string memory name)external returns(uint256);

}
interface IToken
{
    function approve(address spender,uint256 amount)external;
    function allowance(address owner,address spender)external view returns(uint256);
    function balanceOf(address addr)external view returns(uint256);
    function decimals() external view  returns (uint8);
    function name() external view  returns (string memory);
    function symbol() external view  returns (string memory);
    function totalSupply() external view  returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
//    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast);
}

contract DDAOStakingLP is admin
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event eLog(uint256 nn,string name,uint256 value);

    address public lp_ddao_weth;
    address public lp_gnft_weth;
    address public lp_gnft_usdc;
    address public lp_weth_usdc;

    uint256 public DeployTime = block.timestamp;
//    uint256 public constant RewardCalcTime = 3600;
    uint256 public constant RewardCalcTime = 60;
    uint256 public RewardStartTime;

    mapping(uint8 => uint256)public BalanceLP;

//    bool public AdminUnstakeAllow = false;
    bool public AdminUnstakeAllow = true;

    uint256 public UpdateTime = block.timestamp;
    mapping(uint256 => uint256)public Exited;


    struct stake_struct
    {
	address addr;
	uint256 koef;
    }
    mapping (uint8 => stake_struct)public StakeLP;
    mapping (uint8 => mapping(uint256 => uint256))public StakeAmount;
    mapping (uint8 => uint256)public StakeAmountLastTime;

	address public TxAddr = 0xB7CC7b951DAdADacEa3A8E227F25cd2a45c64284;
	address[] public Users;
	address public TokenAddress;
	event StakeLog(string name,address addr,uint256 time,uint256 amount, uint256 frozen,uint256 unlock);

    struct user_struct
    {
	address addr;
	bool set;
	uint256 time;
    }
    mapping(address => user_struct)public UserSet;
    address[] public UserList;

	constructor() 
	{
	

	DeployTime = block.timestamp;
	RewardStartTime = Utime(DeployTime);


	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	Admins.push(_msgSender());
	AdminAdd(0x208b02f98d36983982eA9c0cdC6B3208e0f198A3);
	if(_msgSender() != 0x80C01D52e55e5e870C43652891fb44D1810b28A2)
	AdminAdd(0x80C01D52e55e5e870C43652891fb44D1810b28A2);
	AdminAdd(0xdCB7Bf063D73FA67c987f459D885b3Df86061548);

	    if(block.chainid == 137)
	    {
		// DDAO
		TokenAddress = 0x90F3edc7D5298918F7BB51694134b07356F7d0C7;
                lp_ddao_weth = 0xfC067766349d0960bdC993806EA2E13fcFC03C4D;
                lp_gnft_weth = 0x03B67a0cE884E806673CC92e9A1C4A77D5BC770B;
                lp_gnft_usdc = 0x3fd0CC5f7Ec9A09F232365bDED285e744E0446e2;
                lp_weth_usdc = 0x34965ba0ac2451A34a0471F04CCa3F990b8dea27;

	    }

	    if(block.chainid == 80001)
	    {
                lp_ddao_weth = 0xCB92a252907E21fB0c7A88C7E9de0BbE8d158B1e;
                lp_gnft_weth = 0x55267F9e60Bb86e7D3e442F06eE458F766496220;
                lp_gnft_usdc = 0x2Ec0c97061D2E7a342B6fab39d4544eE3bcFC5e4;

	    }
	    if(block.chainid == 31337)
	    {
                lp_ddao_weth = 0x34156Ba6Fa6af8970c7c506aC484a63da8A52f1A;
                lp_gnft_weth = 0x2CD61c9206A14177986221CcBEE516DD5f2bBE30;
                lp_gnft_usdc = 0x42F97E37c5CbAba02b7022Ab8B00209E5919bBc6;

	    }
	StakeLP[1].addr = lp_ddao_weth;
	StakeLP[2].addr = lp_gnft_weth;
	StakeLP[3].addr = lp_gnft_usdc;

	}

    function TxsAddrChange(address addr)public onlyAdmin
    {
	require(TxAddr != addr,"This address already set");
	TxAddr = addr;
    }
    // End: Admin functions

    function AddCoin()public payable returns(bool)
    {
	return true;
    }
    function name()public pure returns(string memory)
    {
	return "DDAO LPStaking";
    }
    function symbol() public pure returns(string memory)
    {
	return "lpDDAO";
    }
    function decimals()public view returns(uint8)
    {
	return IToken(TokenAddress).decimals();
    }
    function totalSupply()public view returns(uint256)
    {
	return IToken(TokenAddress).balanceOf(address(this));
    }

    function RateDDAO()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_ddao_weth).getReserves();
	rate = 10**18 * r1 / r2;
	rate *= RateWETH();
	rate /= 10**18;
	
    }

    function RateGNFT()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_gnft_weth).getReserves();
	rate = 10**18 * r1 / r2;
	rate *= RateWETH();
	rate /= 10**18;
	
    }

    function RateGNFT2()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_gnft_usdc).getReserves();
	rate = 10**18 * r1 / r2;
	rate *= 10**12;
	
    }

    function RateWETH()public view returns(uint256 rate)
    {
	uint256 r1;
	uint256 r2;
	(r1,r2,) = IToken(lp_weth_usdc).getReserves();
	rate = 10**18 * 10**12 * r1 / r2;
    }
    function getReserves(address addr)public view returns(uint256 r1,uint256 r2,uint32 time)
    {
	(r1,r2,time) = IToken(addr).getReserves();
    }
    function Stake(address addr,address lp,uint256 amount,uint256 interval)public
    {
	uint8 grp;
	uint256 nn;
	address lp2;
	require(interval == 90 ||interval == 180 || interval == 360 || interval == 720,"Interval must be 90,180, 360 or 720 days");
	require(lp == StakeLP[1].addr || lp == StakeLP[2].addr || lp == StakeLP[3].addr,"Unknown address of LP.");
	if(addr == address(0))addr = _msgSender();
	if(lp == StakeLP[1].addr){lp2 = StakeLP[1].addr;grp = 1;}
	if(lp == StakeLP[2].addr){lp2 = StakeLP[2].addr;grp = 2;}
	if(lp == StakeLP[3].addr){lp2 = StakeLP[3].addr;grp = 3;}

	require(IToken(lp2).allowance(_msgSender(),address(this)) >= amount,"Check allowance from you LP to this contract.");

	IToken(lp).transferFrom(_msgSender(),address(this),amount);

	nn = StakeNum[addr]*1 + 1;
	StakeNum[addr] = nn;
	StakeUser[addr][nn].nn 		= nn;
	StakeUser[addr][nn].owner 	= addr;
	StakeUser[addr][nn].lp 		= lp;
	StakeUser[addr][nn].grp 	= grp;
	StakeUser[addr][nn].amount 	= amount;
	StakeUser[addr][nn].time 	= block.timestamp;
	StakeUser[addr][nn].interval 	= interval;

	BalanceLP[grp] += amount;
	StakeAmount[grp][Utime(0)] = BalanceLP[grp];
	if(UserSet[addr].set == false)
	{
	    UserSet[addr].set = true;
	    UserSet[addr].addr = addr;
	    UserSet[addr].time = block.timestamp;
	    UserList.push(addr);
	}
	UpdateTime = block.timestamp;
	StakeAllNum++;
	StakeAll[StakeAllNum].addr = addr;
	StakeAll[StakeAllNum].nn = nn;

    }
    function StakeAmountAllShow(uint8 grp)public view returns(uint256[] memory)
    {
	uint256 nn = 0;
	uint256 start = RewardStartTime;
	uint256 i;
	uint256 last = Utime(0);
	uint256 l;
	l = (last - start) / RewardCalcTime;
	uint256[] memory out = new uint256[](2 * l);
	for(i=start;i<=last;i+=RewardCalcTime)
	{
	    out[nn++] = i;
	    out[nn++] = StakeAmount[grp][i];
	}
	return out;
    }
    function Unstake(uint256 nn)public
    {
	address addr = _msgSender();
	uint256 amount = StakeUser[addr][nn].amount;
	require(StakeUser[addr][nn].closed == false,"This position already unstaked.");
	require(StakeUser[addr][nn].time + StakeUser[addr][nn].interval * RewardCalcTime <= block.timestamp || AdminUnstakeAllow,"You try unstake locked tokens. Check interval.");


	StakeUser[addr][nn].closed = true;
	StakeUser[addr][nn].closed_time = block.timestamp;
	BalanceLP[StakeUser[addr][nn].grp] -= amount;
	StakeAmount[StakeUser[addr][nn].grp][Utime(0)] = BalanceLP[StakeUser[addr][nn].grp];

	IToken(StakeUser[addr][nn].lp).transfer(_msgSender(),amount);
	UpdateTime = block.timestamp;
	UnstakeAllNum++;
	UnstakeAll[UnstakeAllNum].addr = addr;
	UnstakeAll[UnstakeAllNum].nn = nn;
    }
    struct stake_struct2
    {
	uint256 nn;
	address owner;
	uint8   grp;
	address lp;
	uint256 amount;
	uint256 time;
	uint256 interval;
	bool closed;
	uint256 closed_time;
	uint256 claim_time;
//	uint256 claimed;
    }
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))public Claimed;
    struct stake_all_struct
    {
	address addr;
	uint256 nn;
    }
    mapping(uint256 => stake_all_struct)public StakeAll;
    mapping(uint256 => stake_all_struct)public UnstakeAll;
    uint256 public StakeAllNum;
    uint256 public UnstakeAllNum;

    uint256[] public StakeUserNum;
    mapping(address => uint256) public StakeNum;
    mapping(address => mapping(uint256 => stake_struct2)) public StakeUser;

    uint256 public RewardNum = 0;
    struct reward_struct
    {
	address tkn;
	uint256 amount;
	uint256 start_time;
	uint256 interval;
	bool stoped;
	bool hidden;
	bool exited;
	address owner;
	uint256 stoped_time;	
	uint256 hidden_time;
	uint256 koef1;
	uint256 koef2;
	uint256 koef3;
//	uint256 claimed;
    }
    mapping(uint256 => reward_struct)public RewardData;
    mapping(uint256 => uint256)public RewardClaimed;
    function RewardAdd(address tkn,uint256 amount,uint256 interval)public 
    {
	require(IToken(tkn).allowance(_msgSender(),address(this)) >= amount,"Check allowance from you tokens's to this contract.");
	require(interval >= 5,"Minimal interval is 5");
	require(interval <= 180,"Maximum interval is 180");
	RewardNum++;
	RewardData[RewardNum].tkn 	= tkn;
	RewardData[RewardNum].amount 	= amount;
	RewardData[RewardNum].owner 	= _msgSender();
	RewardData[RewardNum].interval 	= interval;
	RewardData[RewardNum].start_time 	= block.timestamp;
	RewardData[RewardNum].stoped_time 	= block.timestamp;
	RewardData[RewardNum].stoped 	= true;

	IToken(tkn).transferFrom(_msgSender(),address(this),amount);
	UpdateTime = block.timestamp;
    }
    function RewardStop(uint256 num, bool true_or_false)public onlyAdmin
    {
	require(RewardData[num].exited == false,"This reward alredyt exit.");
	require(RewardData[num].stoped != true_or_false,"This reward already has this state.");
	RewardData[RewardNum].stoped = true_or_false;
	RewardData[RewardNum].stoped_time = true_or_false?block.timestamp:0;
	UpdateTime = block.timestamp;
    }
    function RewardHide(uint256 num, bool true_or_false)public onlyAdmin
    {
	require(RewardData[num].hidden != true_or_false,"This reward already has this state.");
	RewardData[RewardNum].hidden = true_or_false;
	RewardData[RewardNum].hidden_time = true_or_false?block.timestamp:0;
	UpdateTime = block.timestamp;
    }
    function RewardKoef(uint256 num,uint256 koef1,uint256 koef2,uint256 koef3)public onlyAdmin
    {
	require(RewardData[num].exited == false,"This reward alredyt exit.");
        require(RewardData[num].koef1 == 0 && RewardData[num].koef2 == 0 && RewardData[num].koef3 == 0,"Coefficients already set.");
        RewardData[num].koef1 = koef1;
        RewardData[num].koef2 = koef2;
        RewardData[num].koef3 = koef3;
	RewardData[num].stoped 	= false;
	UpdateTime = block.timestamp;
    }

    function RewardExit(uint256 num,address addr)public onlyAdmin
    {
	require(RewardData[num].exited == false,"This reward alredyt exit.");
	if(addr == address(0))addr = RewardData[num].owner;
	uint256 amount;
	RewardData[num].exited = true;
	RewardData[num].stoped_time = block.timestamp;
	
	amount = RewardData[num].amount - RewardClaimed[num];
	if(amount > 0)
	{
	IToken(RewardData[num].tkn).transfer(addr,amount);
	Exited[num] = amount;
	}
	UpdateTime = block.timestamp;
    }


//    function RewardSummaryOnTime(uint8 grp,uint256 num,uint256 time)public view returns(uint256 out,uint256 i2,uint256 t2,uint256 t,uint256 koef,uint256 time2)
    function RewardSummaryOnTime(uint8 grp,uint256 num,uint256 time)public view returns(uint256 out)
    {
//	if(RewardData[num].hidden == true)return (0,0,0,0,0,0);
	if(RewardData[num].hidden == true)return 0;

	if(time == 0)time = Utime(block.timestamp);
	uint256 i;

	uint256 t;
	uint256 t2;
	uint256 koef;
	t = Utime(RewardData[num].start_time);
	t2  = RewardData[num].start_time + RewardData[num].interval * RewardCalcTime;
	if(RewardData[num].stoped == true)t2 = RewardData[num].stoped_time;
	t2 = Utime(t2);
	if(grp == 1)koef = RewardData[num].koef1;
	if(grp == 2)koef = RewardData[num].koef2;
	if(grp == 3)koef = RewardData[num].koef3;

	for(i = t;i < t2;i += RewardCalcTime)
	{
	    if(i == time)
	    {
		out = RewardData[num].amount / RewardData[num].interval * koef / (RewardData[num].koef1 + RewardData[num].koef2 + RewardData[num].koef3);
		//i2 = i;
		break;
	    }
	}
	//time2 = time;
    }
    function Utime(uint256 time)public view returns(uint256 out)
    {
	if(time == 0)time = block.timestamp;
	out = time / RewardCalcTime * RewardCalcTime + RewardCalcTime;
    }
    
    function BalanceStaked(address addr,uint8 grp)public view returns(uint256)
    {
	uint256 b;
	uint256 nn;
	for(nn=1;nn <= StakeNum[addr];nn++)
	{
	    if(StakeUser[addr][nn].grp == grp)
	    {
		if(StakeUser[addr][nn].closed == false)
	        b += StakeUser[addr][nn].amount;
	    }
	}
	return b;
    }
    function BalanceWallet(address addr,uint256 flag)public view returns(uint256,uint256,uint256[] memory)
    {
	uint256 r;
	uint256 r2;
	uint256 amount = 0;
	uint256 nn = 0;
	uint256[] memory out = new uint256[](8*3 + 3);
	uint256 b;
	uint256 t;
	uint256 a;

	// ddao_weth
	out[nn++] = uint256(uint160(StakeLP[1].addr));
	if(flag == 1)
	t = BalanceStaked(addr,1);
	else
	t = IToken(StakeLP[1].addr).balanceOf(addr);
	a = IToken(StakeLP[1].addr).totalSupply();
	b = 10**18 * t / a;
	out[nn++] = a;
	out[nn++] = t;
	out[nn++] = b;
	(r,,) = IToken(StakeLP[1].addr).getReserves();
	out[nn++] = r;
	r2 = RateWETH();
	out[nn++] = r2;
	r *= 2;
	r *= r2;
	r /= 10**18;
	out[nn++] = r;
	out[nn++] = r * b / 10**18;

	amount += r * b / 10**18;


	// gnft_weth
	out[nn++] = uint256(uint160(StakeLP[2].addr));
	if(flag == 1)
	t = BalanceStaked(addr,2);
	else
	t = IToken(StakeLP[2].addr).balanceOf(addr);
	a = IToken(StakeLP[2].addr).totalSupply();
	b = 10**18 * t / a;
	out[nn++] = a;
	out[nn++] = t;
	out[nn++] = b;
	(r,,) = IToken(StakeLP[2].addr).getReserves();
	out[nn++] = r;
	r2 = RateWETH();
	out[nn++] = r2;
	r *= 2;
	r *= r2;
	r /= 10**18;
	out[nn++] = r;
	out[nn++] = r * b / 10**18;
	amount += r * b / 10**18;

	// gnft_usdc
	out[nn++] = uint256(uint160(StakeLP[3].addr));
	if(flag == 1)
	t = BalanceStaked(addr,3);
	else
	t = IToken(StakeLP[3].addr).balanceOf(addr);
	a = IToken(StakeLP[3].addr).totalSupply();
	b = 10**18 * t / a;
	out[nn++] = a;
	out[nn++] = t;
	out[nn++] = b;
	(r,,) = IToken(StakeLP[3].addr).getReserves();
	r *= 10**12;
	out[nn++] = r;
	r2 = 10**18;
	out[nn++] = r2;
	r *= 2;
	r *= r2;
	r /= 10**18;
	out[nn++] = r;
	out[nn++] = r * b / 10**18;
	amount += r * b / 10**18;

	r = RateDDAO();
	r2 = 10**18 * amount / r;
	out[nn++] = amount;
	out[nn++] = r;
	out[nn++] = r2;

	return (amount,r2,out);
    }
    function balanceOf(address addr)public view returns(uint256)
    {
	uint256 out;
//	(out,,) = BalanceWallet(addr,1);
	(,out,) = BalanceWallet(addr,1);
	return out;
    }
    struct reward_num_by_addr_struct
    {
	uint256 stake_all;
	uint256 stake;
	uint256 reward;
	uint256 nn;
	uint8 grp;
    }
//    function transfer(address addr,uint256 amount)public
    function transfer(address,uint256)public
    {
	require(false,"This is not a transferable token. To change the balance, go to https://app.defihuntersdao.clud");
    }
//    function transferFrom(address from,address addr,uint256 amount)public
    function transferFrom(address,address,uint256)public
    {
	require(false,"This is not a transferable token. To change the balance, go to https://app.defihuntersdao.clud");
    }
//    function approve(address spender,address addr,uint256 amount)public
    function approve(address,address,uint256)public
    {
	require(false,"This is not a transferable token. To change the balance, go to https://app.defihuntersdao.clud");
    }
//    function allowance(address owner,address spender)public pure returns(uint256)
    function allowance(address,address)public pure returns(uint256)
    {
	return 0;
    }

//    function RewardNumByAddr(uint256 num,address addr,uint256 nn,uint256 time)public view returns(uint256,uint256,uint256[] memory)
    function RewardNumByAddr(uint256 num,address addr,uint256 nn,uint256 time)public view returns(uint256)
    {
	if(StakeUser[addr][nn].closed)return 0;
	if(RewardData[num].exited)return 0;
	uint256 amount;
	uint256 time2;
	if(time == 0)time = Utime(block.timestamp);
	reward_num_by_addr_struct memory res;
	//res.nn = 0;
	uint256 i;
//	uint256 t = Utime(DeployTime);
	uint256 t;
//	t = Utime(RewardData[num].start_time) + RewardCalcTime;
	t = Utime(RewardData[num].start_time);

	if(RewardData[num].stoped)
	time2 = Utime(RewardData[num].stoped_time);
	else
	time2 = t + RewardData[num].interval * RewardCalcTime;

	if(time > time2)time = time2;
        //uint256 l = (time - t) / RewardCalcTime;
	//uint256[] memory out = new uint256[](l*7+1);
	//out[res.nn++] = l;

	uint256 t2;
	res.grp = StakeUser[addr][nn].grp;
        amount = StakeUser[addr][nn].amount;
	for(i = t;i <= time;i += RewardCalcTime)
	{

	    if(i == t)
	    res.stake_all = StakeByGroupByTime(res.grp,i,0,0);
	    else
	    res.stake_all = StakeByGroupByTime(res.grp,i,res.stake_all,i-RewardCalcTime);

	    //out[res.nn++] = i;
	    if(res.stake_all > 0)
	    {

	    //out[res.nn++] = res.stake_all;


//	    if(StakeUser[addr][nn].closed)amount = 0;
	    //out[res.nn++] = amount;

//	    res.stake = amount * 10**18 / res.stake_all;
	    res.stake = amount * 10**24 / res.stake_all;
	    //out[res.nn++] = res.stake;

//	    (t2,,,,,) = RewardSummaryOnTime(res.grp,num,i);
	    t2 = RewardSummaryOnTime(res.grp,num,i);
	    //out[res.nn++] = t2;
//	    t2 = t2 * res.stake / 10**18;
	    t2 = t2 * res.stake / 10**24;
	    res.reward += t2;

	    //out[res.nn++] = t2;
	    //out[res.nn++] = res.reward;
	    }
	    else
	    {
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    //out[res.nn++] = 0;
	    }
	}
//	res.reward -= StakeUser[addr][nn].claimed;
	res.reward -= Claimed[addr][nn][num];
	//return (res.reward,l,out);
	return (res.reward);
    }
    function StakeListByGroup(uint8 grp)public view returns(uint256[] memory)
    {
	uint256 nn = 0;
	uint256 time = Utime(block.timestamp);
	uint256 i;
	uint256 t = Utime(DeployTime);
	uint256 l = (time - t) / RewardCalcTime + 1;
	uint256[] memory out = new uint256[](l*2+1);
	out[nn++] = l;
	uint256 last = 0;

	for(i = t;i <= time;i += RewardCalcTime)
	{
	    out[nn++] = i;
	    if(StakeAmount[grp][i] != 0)last = StakeAmount[grp][i];
	    out[nn++] = last;
	}

	return out;
	
    }
    function StakeByGroupByTime(uint8 grp,uint256 time,uint256 last,uint256 last_time)public view returns(uint256)
    {
	uint256 time_end = Utime(block.timestamp);
	uint256 i;
	uint256 t;
	if(last_time == 0)
	t = Utime(DeployTime);
	else
	t = last_time;
//	uint256 last = 0;

	for(i = t;i <= time_end;i += RewardCalcTime)
	{
	    if(StakeAmount[grp][i] != 0)last = StakeAmount[grp][i];
	    if(i==time)return last;
	}

	return 0;
	
    }

    function ClaimReward(uint256 num,uint256 nn)public returns(uint256)
    {
	address addr = _msgSender();
	uint256 time = Utime(block.timestamp);
	require(StakeUser[addr][nn].claim_time < time,"Reward on this period already claimed.");


	uint256 amount;
//	(amount,,) = RewardNumByAddr(num,addr,nn,time);
	amount = RewardNumByAddr(num,addr,nn,time);
	StakeUser[addr][nn].claim_time = time;
//	StakeUser[addr][nn].claimed += amount;
	Claimed[addr][nn][num] += amount;
	RewardClaimed[num] += amount;
//	RewardData[num].claimed += amount;
	if(amount > 0)
	IToken(RewardData[num].tkn).transfer(addr,amount);
	UpdateTime = block.timestamp;
	return amount;
    }
    function ClaimRewardMulti(uint256 num)public returns(uint256)
    {
	uint256 amount = 0;
	uint256 i;
	address addr = _msgSender();
	uint256 l = StakeNum[addr];
	for(i = 1; i <= l;i++)
	{
	    amount += ClaimReward(num,i);
	}
	UpdateTime = block.timestamp;
	return amount;
    }
    function AdminUnstakeAllowChange(bool true_or_false)public onlyAdmin
    {
	AdminUnstakeAllow = true_or_false;
    }
    function PeriodStepView(uint256 time)public view returns(uint256 out)
    {
	if(time == 0)time = block.timestamp;
	out = PeriodTimeView(time);
	out /= RewardCalcTime;
	out += 1;
    }
    function PeriodTimeView(uint256 time)public view returns(uint256 out)
    {
	if(time == 0)time = block.timestamp;
	out = Utime(time) - RewardStartTime;
    }
    function Blk()public view returns(uint256)
    {
        return block.number;
    }
    function BlkTime()public view returns(uint256)
    {
        return block.timestamp;
    }
    function UserListCount()public view returns(uint256)
    {
	return UserList.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract admin is AccessControl
{

    using SafeERC20 for IERC20;

        // Start: Admin functions
        event adminModify(string txt, address addr);
        address[] Admins;
        modifier onlyAdmin()
        {
                require(IsAdmin(_msgSender()), "Access for Admin only");
                _;
        }
        function IsAdmin(address account) public virtual view returns (bool)
        {
                return hasRole(DEFAULT_ADMIN_ROLE, account);
        }
        function AdminAdd(address account) public virtual onlyAdmin
        {
                require(!IsAdmin(account),'Account already ADMIN');
                grantRole(DEFAULT_ADMIN_ROLE, account);
                emit adminModify('Admin added',account);
                Admins.push(account);
        }
        function AdminDel(address account) public virtual onlyAdmin
        {
                require(IsAdmin(account),'Account not ADMIN');
                require(_msgSender()!=account,'You can`t remove yourself');
                revokeRole(DEFAULT_ADMIN_ROLE, account);
                emit adminModify('Admin deleted',account);
        }
    function AdminList()public view returns(address[] memory)
    {
        return Admins;
    }
    function AdminGetCoin(uint256 amount) public onlyAdmin
    {
	if(amount == 0)
	amount = address(this).balance;
        payable(_msgSender()).transfer(amount);
    }

    function AdminGetToken(address tokenAddress, uint256 amount) public onlyAdmin
    {
        IERC20 ierc20Token = IERC20(tokenAddress);
        if(amount == 0)
        amount = ierc20Token.balanceOf(address(this));
        ierc20Token.safeTransfer(_msgSender(), amount);
    }
    // End: Admin functions

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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