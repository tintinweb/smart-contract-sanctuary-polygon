/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

//FORGE ZAPs
//ZAP to Staking //Zap Out of Staking // Zap zap

pragma solidity ^0.8.0;

contract OwnableAndMods{
    address public owner;
    address [] public moderators;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    modifier OnlyModerators() {
    bool isModerator = false;
    for(uint x=0; x< moderators.length; x++){
    	if(moderators[x] == msg.sender){
		isModerator = true;
		}
		}
        require(msg.sender == owner || isModerator, "Ownable: caller is not the owner/mod");
        _;
    }
}


library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}
interface IERC20 {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    
}

contract GasPump {
    bytes32 private stub;

    modifier requestGas(uint256 _factor) {
        if (tx.gasprice == 0 || gasleft() > block.gaslimit) {
            uint256 startgas = gasleft();
            _;
            uint256 delta = startgas - gasleft();
            uint256 target = (delta * _factor) / 100;
            startgas = gasleft();
            while (startgas - gasleft() < target) {
                // Burn gas
                stub = keccak256(abi.encodePacked(stub));
            }
        } else {
            _;
        }
    }
}
contract SwapRouter {
    function swapExactTokensForTokens(uint256, uint256, address[] memory, address, uint256) public returns (bool){}
    function swapExactETHForTokens(uint256, address[] memory, address, uint256) public payable returns (bool){}
    }
contract LiquidityPool{
    function getReserves() public returns (uint112, uint112, uint32) {}
    function addLiquidity(address, address, uint256, uint256, uint256, uint256 , address, uint256 ) public returns (bool) {}
    function getMiningReward() public view returns (uint) {}
    }
contract ForgeAuctions{
    mapping(uint=>mapping(uint=>uint)) public mapEraDay_Units;  
    uint public currentDay;
    uint public daysPerEra; 
    uint public secondsPerDay;
    uint public nextDayTime;
    function getMiningMinted() public view returns (uint) {}
    function WithdrawEz(address) public {}
    function FutureBurn0xBTCArrays(uint , uint[] memory , address, uint[] memory ) public payable returns (bool) {}
    function FutureBurn0xBTCEasier(uint, uint, uint, address , uint ) public payable returns (bool) {}
    function WholeEraBurn0xBTCForMember(address, uint256) public payable returns (bool){}
    function burn0xBTCForMember(address, uint256) public payable  {}
    }
contract ForgeStaking{
    function stakeFor(address, uint128) public payable virtual {}
    
    function getMiningReward() public view returns (uint) {}
    }

  contract ForgeZap is  GasPump, OwnableAndMods
{
    
    using SafeMath for uint;
    using ExtendedMath for uint;
    address public AddressZeroXBTC;
    address public AddressForgeToken;
    // ERC-20 Parameters
    uint256 public extraGas;
    bool runonce = false;
    uint256 oneEthUnit = 1000000000000000000; 
    uint256 one0xBTCUnit =         100000000;
    string public name;
    uint public decimals;

    // ERC-20 Mappings
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    address public zXBitcoinAddress;
    address public ForgeAddress;
    address public Liquidity_PoolAddress;
    address public StakingAddress;
    address public AuctionAddress;
    uint256 public Total0xBTCToRecieve = 0;
    // Public Parameters
     uint public timescalled;
    uint256 public amountZapped; uint public currentDay;
    uint public daysPerEra; uint public secondsPerDay;
    uint public nextDayTime;
    uint public totalBurnt; uint public totalEmitted; uint public TotalForgeToRecieve;
    // Public Mappings
    address ForgeTokenAddress;
    address z0xBitcoinAddress;
    address LPPool0xBTCForge;
    SwapRouter Quickswap;
    ForgeAuctions Forge_Auction;
    ForgeStaking Forge_Staking;
    LiquidityPool LP1; //Forge/0xBTC
    LiquidityPool LP2; //Forge/Polygon
    LiquidityPool LP3; //0xBTC/Polygon
    // Events
        event Zap(uint256 ZeroXBitcoinAmount, uint256 ForgeAmount);
        event Burn(uint256 totalburn, address burnedFor, uint TotalDaysBurned);
    //=====================================CREATION=========================================//

    //testing//

    // Constructor
    
    
    
    // ERC20 Transfer function
    // ERC20 Approve function


       /* function zSetUP1(address token, address _ZeroXBTCAddress, address _Quickswap, address _Staking, address _LP1) public onlyOwner {
        AddressForgeToken = token;
        AddressZeroXBTC = _ZeroXBTCAddress;
        Quickswap = SwapRouter(_Quickswap);
        LP1 = LiquidityPool(_LP1);
        Forge_Staking = ForgeStaking(_Staking);
       */ //ForgeMiningToken = ForgeMiningCT(token);
 //       lastMinted = ForgeMiningToken.getMiningMinted();

      constructor()  {
        AddressForgeToken = address(0xD9BA47C5e9bCD857925A6a1E19094C5d7788169E);
        AddressZeroXBTC = address(0xFe2419430C29be0EC000317E53BaB14836543ec2);
        Forge_Auction = ForgeAuctions(0x539b1601c708614F4F3411290b9Ce98BE0D26a24);
        Quickswap = SwapRouter(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
        LP1 = LiquidityPool(0x870307820C358e4F042E5Bf59229bEB676eB9E83);
        LP3 = LiquidityPool(0x60F03AF8F3ce1c7Ee03Df910F74a32Eed7179d4a);
        Forge_Staking = ForgeStaking(0x2bDd577B962586aB1105C17a9bF32Ab7a3d62Cdb);
    }

    function FullETHtoForgeTEST(uint256 amountInPolygon) public payable returns (bool success){
        uint256 startBal = IERC20(AddressForgeToken).balanceOf(address(this));
        uint112 _reserve0; // 0xBTC ex 2 in getReserves
        uint112 _reserve1; // Forge;
        uint32 _blockTimestampLast;

         (_reserve0, _reserve1, _blockTimestampLast) = LP1.getReserves(); //0xBTC/Forge

         uint256 TotalForgeToRecieve = amountInPolygon / ( _reserve0 + amountInPolygon) * _reserve1;
         TotalForgeToRecieve = TotalForgeToRecieve * 90 / 100; //Must get 90% possibly let this be passed as haircut
         IERC20(AddressForgeToken).approve(address(Quickswap), 9881237367);
    }
    
    function FullETHtoForge(uint256 amountInPolygon, uint256 haircut, address [] memory path, address [] memory path2, address whoToStakeFor) public payable returns (bool success){
        uint256 startBal = IERC20(ForgeTokenAddress).balanceOf(address(this));
        uint112 _reserve0; // 0xBTC ex 2 in getReserves
        uint112 _reserve1; // Forge;
        uint32 _blockTimestampLast;

         (_reserve0, _reserve1, _blockTimestampLast) = LP3.getReserves(); //0xBTC/Forge

         uint256 TotalForgeToRecieve = amountInPolygon / ( _reserve0 + amountInPolygon) * _reserve1;
         TotalForgeToRecieve = TotalForgeToRecieve * 90 / 100; //Must get 90% possibly let this be passed as haircut
     //    Quickswap.swapExactETHForTokens(TotalForgeToRecieve, path,  address(this), deadline{value: web3.toWei(msg.value, 'ether')}); // Swap to Forge from Polygon
        Quickswap.swapExactETHForTokens{value: msg.value}(TotalForgeToRecieve, path,  address(this), block.timestamp + 10000);
        forgeZAP(startBal, path2,  IERC20(z0xBitcoinAddress).balanceOf(address(this)), whoToStakeFor );
	return true;
	}

    function ZeroxBTCToForge(uint256 amountIn0xBTC, uint256 haircut, address whoToStakeFor, address [] memory path, address [] memory path2) public payable returns (bool success) {
        uint256 startBalForge = IERC20(ForgeTokenAddress).balanceOf(address(this));
        uint256 startBal0xBTC = IERC20(z0xBitcoinAddress).balanceOf(address(this));
	//haircut is what % we will loose in a trade if someone frontruns set at 97% in contract now change for public
        uint112 _reserve0; // 0xBTC ex 2 in getReserves
        uint112 _reserve1; // Forge
        uint32 _blockTimestampLast;
        uint256 deadline = block.timestamp + 10000;
         (_reserve0, _reserve1, _blockTimestampLast) = LP3.getReserves(); //0xBTC/Forge

         uint256 TotalForgeToRecieve = amountIn0xBTC / ( _reserve0 + amountIn0xBTC) * _reserve1;
         TotalForgeToRecieve = TotalForgeToRecieve * 90 / 100; //Must get 90% possibly let this be passed as haircut
         Quickswap.swapExactTokensForTokens(amountIn0xBTC, TotalForgeToRecieve, path, address(this), block.timestamp + 10000); //swap to Forge from 0xBTC
        forgeZAP(startBalForge, path2, startBal0xBTC,  whoToStakeFor);
    return true;
    }



    function forgeZAP(uint256 ForgeStart, address [] memory path2, uint256 z0xBTCStart, address WhoToStakeFor ) public returns (bool success){
        uint256 totalForgein = IERC20(ForgeTokenAddress).balanceOf(address(this)) - ForgeStart;
        uint256 HalfForge = totalForgein / 2;
        uint112 _reserve0; // 0xBTC ex 2 in getReserves
        uint112 _reserve1; // Forge
        uint32 _blockTimestampLast;

        //get 50% 0xBTC now
         (_reserve0, _reserve1, _blockTimestampLast) = LP3.getReserves(); //0xBTC/Forge

        uint256 TotalForgeToRecieve = totalForgein / 2 / ( _reserve0 + totalForgein / 2) * _reserve1;

        TotalForgeToRecieve = totalForgein * 90 / 100; //Must get 90% possibly let this be passed as haircut
        Quickswap.swapExactTokensForTokens(totalForgein / 2, TotalForgeToRecieve, path2, address(this), block.timestamp + 10000); //swap to 0xBTC from Forge. Half of total forge
        LP(ForgeStart, z0xBTCStart, WhoToStakeFor);
        return true;
    }

    function LP(uint256 ForgeStart, uint256 z0xBTCStart, address WhoToStakeFor) public returns (bool success){
    	uint256 prevBal = uint128(IERC20(LPPool0xBTCForge).balanceOf(address(this)));
        uint256 total0xBTCin = IERC20(z0xBitcoinAddress).balanceOf(address(this))-z0xBTCStart;
        uint256 totalForgein = IERC20(ForgeAddress).balanceOf(address(this))-ForgeStart;
        //call LP
        LP1.addLiquidity(ForgeAddress, z0xBitcoinAddress, total0xBTCin, totalForgein,  (total0xBTCin*95) /100, totalForgein * 95 /100, address(this), block.timestamp + 1000);
        Forge_Staking.stakeFor(WhoToStakeFor, uint128(IERC20(LPPool0xBTCForge).balanceOf(address(this)) - prevBal));
    return true;
    }



    function stakeForZap(address forWhom, uint128 amount) public returns (bool success) {
         Forge_Staking.stakeFor(forWhom, amount);
         return true;
    }




    function FullETHto0xBTC(uint256 haircut, address [] memory path) public payable returns (bool success){
        uint112 _reserve0; // 0xBTC ex 2 in getReserves
        uint112 _reserve1; // Forge;
        uint32 _blockTimestampLast;

         (_reserve0, _reserve1, _blockTimestampLast) = LP3.getReserves(); //0xBTC/Forge

         uint256 TotalForgeToRecieve = msg.value / ( _reserve0 + msg.value) * _reserve1;
         TotalForgeToRecieve = TotalForgeToRecieve * 90 / 100; //Must get 90% possibly let this be passed as haircut
     //    Quickswap.swapExactETHForTokens(TotalForgeToRecieve, path,  address(this), deadline{value: web3.toWei(msg.value, 'ether')}); // Swap to Forge from Polygon
        Quickswap.swapExactETHForTokens{value: msg.value}(TotalForgeToRecieve, path,  address(this), block.timestamp + 10000);
	return true;
	}
    



    function WholeEraBurn0xBTCForMember(address member, uint256 _0xbtcAmountTotal) public payable returns (bool success)
    {
        address [] memory path;
        uint256 startBal0xBTC = IERC20(z0xBitcoinAddress).balanceOf(address(this));
        FullETHto0xBTC(10, path);
        Forge_Auction.WholeEraBurn0xBTCForMember(member, _0xbtcAmountTotal - startBal0xBTC);
        return true;
    }

    function FutureBurn0xBTCEasier(uint _era, uint startingday, uint totalNumberrOfDays, address _member, uint _0xbtcAmountTotal) public payable returns (bool success)
    {   address [] memory path;
        uint256 startBal0xBTC = IERC20(z0xBitcoinAddress).balanceOf(address(this));
        FullETHto0xBTC(10, path);
        Forge_Auction.FutureBurn0xBTCEasier(_era, startingday, totalNumberrOfDays, _member, _0xbtcAmountTotal);
    
        return true;
    }

    function FutureBurn0xBTCArrays(uint _era, uint[] memory fdays, address _member, uint[] memory _0xbtcAmount) public payable returns (bool success)
    {   
        address [] memory path;
        uint256 startBal0xBTC = IERC20(z0xBitcoinAddress).balanceOf(address(this));
        FullETHto0xBTC(10, path);
       Forge_Auction.FutureBurn0xBTCArrays(_era, fdays, _member, _0xbtcAmount);
        return true;
    }


function OneTeste0(uint256 amountOutMin) public  {
require(IERC20(AddressForgeToken).transferFrom(msg.sender, address(this), 100000000000000), 'transferFrom2 failed.');
}
function OneTeste1(uint256 amountOutMin) public  {
require(IERC20(AddressForgeToken).approve(address(Quickswap), 100 * 10 ** 18), 'approve failed.');
}

function OneTeste2(uint256 amountOutMin) public  {
address[] memory path = new address[](2);
path[0] = AddressForgeToken;
path[1] = AddressZeroXBTC;
SwapRouter(Quickswap).swapExactTokensForTokens(100000000000000, 0, path, address(this), 99999999999999999999);
}

    function ONEburn0xBTCForMember(address member, uint256 _0xbtcAmount) public payable OnlyModerators returns (bool success)  {
        require(block.timestamp > Forge_Auction.nextDayTime() - 10, "Must be near end of auction");
        address [] memory path;
        path = new address[](2);
        path[0] = address(AddressForgeToken);
        path[1] = address(AddressZeroXBTC);
            if(block.timestamp > Forge_Auction.nextDayTime()){
            IERC20(AddressZeroXBTC).transferFrom(msg.sender, address(this), _0xbtcAmount);
            IERC20(AddressZeroXBTC).approve(address(Forge_Auction), 99999999999999999999999);
            Forge_Auction.burn0xBTCForMember(msg.sender, _0xbtcAmount);
            Forge_Auction.WithdrawEz(msg.sender);
            
            uint256 startBalForge = IERC20(AddressForgeToken).balanceOf(msg.sender);
            if(startBalForge != 0){
                
                
                //haircut is what % we will loose in a trade if someone frontruns set at 97% in contract now change for public
                uint112 _reserve0; // 0xBTC ex 2 in getReserves
                uint112 _reserve1; // Forge
                uint32 _blockTimestampLast;
                (_reserve0, _reserve1, _blockTimestampLast) = LP3.getReserves(); //0xBTC/Forge

                Total0xBTCToRecieve = (startBalForge * _reserve1) / ( _reserve0 + startBalForge);
                Total0xBTCToRecieve = Total0xBTCToRecieve * 90 / 100; //Must get 90% possibly let this be passed as haircut
                
                IERC20(AddressForgeToken).approve(address(Quickswap), 999999999999999999999999999999999999);
                
                IERC20(AddressForgeToken).transferFrom(msg.sender, address(this), startBalForge);
                
                Quickswap.swapExactTokensForTokens(startBalForge, 1, path, msg.sender, block.timestamp); //swap to Forge from 0xBTC
                                
            }

        }else{


        }
        return true;            
}
    
    
    
}