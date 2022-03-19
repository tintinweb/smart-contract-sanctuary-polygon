/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface ILiquidity {
    function getTokenPrice() external view returns(uint);
    function getToken0() external view returns(address);
    function getToken1() external view returns(address);
    function swapAndLiquify(uint256 amount) external;
}
interface IHamperBlock {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}
interface ICarterasDesbloqueadas {
    function getCartera(address ad) external view returns(uint);
}
contract Staking {
    event Stake(address, uint, uint);
    event Unstake(address, uint);
    ILiquidity public liquidity;
    ICarterasDesbloqueadas public unlocked_carteras;
    struct hblockStaked {
        uint time;
        uint amount;
        uint tipo;
    }
    uint private minTokensInRewardPoolToStake=5000000*10**18;
    uint public totalInterestPaid=0;
    mapping (address => uint) private totalInterestPaidToWallet;
    uint public totalStaked=0;
    mapping (address => uint) private totalStakedByWallet;
    bool public enableSwapAndLiquify=false;
    uint public minTokensToSwap;
    mapping(address => hblockStaked[]) private wallet_staked_;
    mapping (address => bool) public permitedAddress;
    address private _token;
    address public rewardPoolAddress;
    bool public paused;
    constructor() {
        permitedAddress[msg.sender]=true;
    }
    modifier whenNotPaused() {
        require(paused == false);
        _;
    }
    modifier whenPermited() {
        require(permitedAddress[msg.sender],"Not permited");
        _;
    }
    function setCarterasDesbloquedas(address ad) public whenPermited{
        unlocked_carteras=ICarterasDesbloqueadas(ad);
    }
    function setLiquidityAddress(address ad) public whenPermited {
        liquidity=ILiquidity(ad);
        _token=liquidity.getToken0();
    }
    // Establece si alguien tiene permiso o no para usar determinadas funciones
    function setPermitedAddress(address ad, bool permited) public whenPermited {
        permitedAddress[ad]=permited;
    }
    function setSwapAndLiquify(bool value) public whenPermited {
        enableSwapAndLiquify=value;
    }
    function setMinTokensToSwap(uint value) public whenPermited {
        minTokensToSwap=value;
    }
    function setMinTokensInRewardPoolToStake(uint value) public whenPermited {
        minTokensInRewardPoolToStake=value;
    }
    function setRewardPoolAddress(address ad) public whenPermited {
        rewardPoolAddress=ad;
    }
    // Pausa algunas funciones del contrato
    function pause() public whenPermited {
        paused=true;
    }
    // Restablece algunas funciones pausadas del contrato
    function unpause() public whenPermited {
        paused=false;
    }
    // Obtiene el token que se está usando en el contrato
    function getToken() public view returns (address) {
        return _token;
    }
    function myClaimedEarnings() public view returns (uint){
        return totalInterestPaidToWallet[msg.sender];
    }
    function myStake() public view returns (uint){
        return totalStakedByWallet[msg.sender];
    }
    // Obtiene el balance de tokens por dirección
    function balanceOf(address ad) public view returns (uint){
        uint balanceWithInterest=0;
        for(uint i=0;i<wallet_staked_[ad].length;i++){
            balanceWithInterest+=getAmountWithInterest(wallet_staked_[ad][i]);
        }
        return balanceWithInterest;
    }
    function stakesOf(address ad) public view returns (hblockStaked[] memory){
        return wallet_staked_[ad];
    }
    function getAmountWithInterest(hblockStaked memory staked) public view returns (uint){
        uint time=(block.timestamp-staked.time);
        uint seconds_year=31556952;
        //Garantiza el cálculo para la extracción de fondos a la reward pool de 1 año
        //Después de 1 año se debe hacer unstake y volver a stakear si se quiere
        if(time>seconds_year){
            time=seconds_year;
        }
        uint interest=staked.amount*time*12/(seconds_year*100);
        if(staked.tipo==0){
            interest=staked.amount*time*5/(seconds_year*100);
        }else if(staked.tipo==1){
            interest=staked.amount*time*8/(seconds_year*100);
        }
        return staked.amount+interest;
    }
    function unstake(uint posicion) public {
        require(wallet_staked_[msg.sender].length>posicion, "Error: position doesn't exists");
        hblockStaked memory staked=wallet_staked_[msg.sender][posicion];
        uint seconds_month=2629746;
        require((block.timestamp-staked.time) > (seconds_month*staked.tipo),"Error: Could not unstake yet");
        uint amount_to_paid=getAmountWithInterest(staked);
        IHamperBlock(_token).transfer(msg.sender,amount_to_paid);
        uint sobrante=getAmountWithInterest(hblockStaked(0,staked.amount,staked.tipo))-amount_to_paid;
        IHamperBlock(_token).transfer(rewardPoolAddress,sobrante);
        totalStaked-=staked.amount;
        totalStakedByWallet[msg.sender]-=staked.amount;
        totalInterestPaid+=amount_to_paid-staked.amount;
        totalInterestPaidToWallet[msg.sender]+=amount_to_paid-staked.amount;
        //borrar stake
        uint last=wallet_staked_[msg.sender].length-1;
        if(posicion==last){
            wallet_staked_[msg.sender].pop();
        }else{
            wallet_staked_[msg.sender][posicion]=wallet_staked_[msg.sender][last];
            wallet_staked_[msg.sender].pop();
        }
        tryswap();
        emit Unstake(msg.sender, amount_to_paid);
    }
    receive() external payable {}
    function stake(uint amount,uint tipo) public whenNotPaused {
        require(tipo==0 || tipo==1 || tipo==3, "Error: Type of stake not permited");
        require(getCartera(msg.sender)>0, "Error: Can't stake, need to unlock this investment first");
        uint init_balance=IHamperBlock(_token).balanceOf(msg.sender);
        require( init_balance > amount , "Insuficient Balance");
        uint anualInterest=getAmountWithInterest(hblockStaked(0,amount,tipo))-amount;
        uint init_balance_rewardPool=IHamperBlock(_token).balanceOf(rewardPoolAddress);
        uint viability=init_balance_rewardPool-anualInterest;
        require(viability>minTokensInRewardPoolToStake,"Error: Forbidden stake");
        IHamperBlock(_token).transferFrom(rewardPoolAddress,address(this), anualInterest);
        IHamperBlock(_token).transferFrom(msg.sender,address(this), amount);
        hblockStaked memory staked=hblockStaked(block.timestamp,amount,tipo);
        wallet_staked_[msg.sender].push(staked);
        totalStaked+=amount;
        totalStakedByWallet[msg.sender]+=amount;
        tryswap();
        emit Stake(msg.sender, amount, tipo);
    }
    function tryswap() private{
        if(enableSwapAndLiquify){
            uint enough=IHamperBlock(_token).balanceOf(address(liquidity));
            if(enough>minTokensToSwap){
                liquidity.swapAndLiquify(minTokensToSwap);
            }
        }
    }
    // Última cartera
    function getCartera(address ad) public view returns (uint){
        return unlocked_carteras.getCartera(ad);
    }
    function amountTokensForUSD(uint usd) public view returns(uint){
        return usd*liquidity.getTokenPrice();
    }
    function amountUSDForTokens(uint tokens) public view returns(uint){
        return tokens*10**IHamperBlock(_token).decimals()/liquidity.getTokenPrice();
    }
    function HBLOCKStakedInUSD() public view returns(uint){
        return totalStaked*10**IHamperBlock(_token).decimals()/liquidity.getTokenPrice();
    }
}