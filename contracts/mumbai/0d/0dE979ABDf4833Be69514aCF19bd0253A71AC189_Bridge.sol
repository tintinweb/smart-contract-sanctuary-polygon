pragma solidity ^0.8.0;
import "IERC20.sol";
import "SafeMath.sol";
contract Bridge{
    using SafeMath  for uint;
    mapping (address=>uint8) public allowedTokens;
    mapping (address=>uint256) public totalTokensSupply;
    mapping (address=>mapping(address=>uint256)) public totalTokensDepositedByUser;
    mapping (address=>mapping(address=>uint256)) public totalSupplyByOwner;
    mapping (address=>uint256) private  totalReservesForTokens;
    mapping (address=>uint256) public  totalActualReservesForTokens;
     mapping (address=>uint8) public  pausedTokens;
    mapping(address => mapping(uint => uint8)) public processedNonces;
    mapping (address=>address) public TokenToToken;


    address public admin;
    mapping (address=>mapping(address=>uint256)) public userRemainingBalance;
    event LiquidityTransfered(address user,address token,uint amount);

    event Transfer(
    address from,
    address to,
    address token,
    uint amount,
    uint nonce,
    bytes signature
    
  );
   event Recieve(
    address from,
    address to,
    address token,
    uint amount,
    uint nonce,
    bytes signature
    
  );
  event GetRemainingBalance(
      address to,
    address token,
    uint amount
  );

  
    event LiquidityAdded(address user, address token, uint256 amount);
    event LiquidityRemoved(address user, address token, uint256 amount);
    event FeeBurned(address user, address token, uint256 fee);
    constructor(address admin_){
        admin=admin_;
        


    }
    //can pause this function for any disturbance
     function send(address to, uint amount,address token, uint nonce, bytes calldata signature) external {
         require(allowedTokens[token]==1);
         require(pausedTokens[token]==0);
         require(processedNonces[msg.sender][nonce] == 0, 'transfer already processed');
         processedNonces[msg.sender][nonce] = 1;
         require(IERC20(token).transferFrom(msg.sender,address(this),amount));
         totalActualReservesForTokens[token]+=amount;
        //  totalReservesForTokens[token] +=amount;
    
    emit Transfer(
      msg.sender,
      to,
      token,
      amount,
      nonce,
      signature
    );
  }
  //make it pausable
  //also add a trusted user for transactions
  //very important
  function recieve(
    address from, 
    address to, 
    address token,
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      from, 
      to, 
      amount,
      nonce
    )));
    //change this from to trusted user as admin
    require(admin==msg.sender);
    require(recoverSigner(message, signature) == from , 'wrong signature');
    require(processedNonces[from][nonce] == 0, 'transfer already processed');
    userRemainingBalance[to][token] +=amount;
    processedNonces[from][nonce] = 1;
    
    emit Recieve(
      from,
      to,
      token,
      amount,
      nonce,
      signature
      
    );
  }
   function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }

    function addTokensforLiquidity(address token,uint256 amount) external returns(uint liquidity){
        require(allowedTokens[token]==1);
        uint256 reserves=totalReservesForTokens[token];
        totalTokensDepositedByUser[msg.sender][token] +=amount;
        uint256 supply=totalTokensSupply[token];
        if (supply==0)
        { 
           totalSupplyByOwner[msg.sender][token]=amount;
           totalTokensSupply[token]=amount;


        }
        else {
            uint z=amount.mulDiv(supply, reserves);            
            totalSupplyByOwner[msg.sender][token] += z;
            totalTokensSupply[token] += z;


        }
        require(IERC20(token).transferFrom(msg.sender,address(this),amount));
        totalActualReservesForTokens[token]+=amount;
        totalReservesForTokens[token] +=amount;
        emit LiquidityAdded(msg.sender,token,amount);



        

    }
    function removeLiquidityForTokens(address token,uint256 supplyAmount) external {
        require(totalSupplyByOwner[msg.sender][token]>=supplyAmount);
        uint256 reserves=totalReservesForTokens[token];
        uint256 supply=totalTokensSupply[token];
        uint256 liquidity=supplyAmount.mulDiv(reserves,supply);
        if(totalActualReservesForTokens[token]<liquidity){
          liquidity=totalActualReservesForTokens[token];
          supplyAmount=liquidity.mulDiv(supply,reserves);
        }
        // require(totalActualReservesForTokens[token]>=liquidity);
        totalTokensSupply[token] -=supplyAmount;
        totalSupplyByOwner[msg.sender][token] -=supplyAmount;
        totalReservesForTokens[token] -=liquidity;
        totalActualReservesForTokens[token]-=liquidity;
        totalTokensDepositedByUser[msg.sender][token]-=liquidity;
        require(IERC20(token).transfer(msg.sender,liquidity));
        emit LiquidityRemoved(msg.sender,token,liquidity);
        // we can use if statement here to give max return possible from the remaining 
        //amount and deduct only that much supply from that.



    }
    function getEstimatedReturnOnSupply(address user, address token,uint256 supplyAmount)external view returns(uint256 liquidity) {
      require(totalSupplyByOwner[user][token]>=supplyAmount);
        uint256 reserves=totalReservesForTokens[token];
        uint256 supply=totalTokensSupply[token];
         liquidity=supplyAmount.mulDiv(reserves,supply);

    }

    function getFee(address user,address token)public view returns (uint256 fee, uint256 supply,uint256 reserves){
       uint256 amount= totalTokensDepositedByUser[user][token];
       uint256 supplyByOwner = totalSupplyByOwner[user][token];
        reserves=totalReservesForTokens[token];
        supply = totalTokensSupply[token];
       uint256 liquidity= supplyByOwner.mulDiv(reserves,supply) ;
       fee=liquidity-amount;
    //    uint256 value= fee.mulDiv(supply,reserves);
    //    totalSupplyByOwner[user][token] -=value;
    //    totalTokensSupply[token] -=value;
       

    }
    function RecieveFee(address token)external {
        require(totalSupplyByOwner[msg.sender][token]>0);
        (uint256 fee, uint256 supply,uint256 reserves)=getFee(msg.sender, token);
        uint256 value= fee.mulDiv(supply,reserves);
        require(value!=0);
        totalSupplyByOwner[msg.sender][token] -=value;
        totalTokensSupply[token] -=value;
        totalReservesForTokens[token] -=value;
        totalActualReservesForTokens[token] -=value;
        require(IERC20(token).transfer(msg.sender,fee));
        emit FeeBurned(msg.sender, token, fee);

    }





    function addToken(address token1,address token2) external{
        require(msg.sender==admin);
        require(allowedTokens[token1]==0);
        allowedTokens[token1]=1;
        TokenToToken[token1]=token2;
}
function getRemainingBalance(address to,address token)external{
  //also need if statement here
    require(to==msg.sender);
    require(0!=totalActualReservesForTokens[token]);
    require(0!=userRemainingBalance[to][token]);
    uint256 amount;
    if(userRemainingBalance[to][token]<=totalActualReservesForTokens[token]){
      amount=userRemainingBalance[to][token];
    }
    else {
      amount=totalActualReservesForTokens[token];  
    }
    
    require(IERC20(token).transfer(to,amount));
    totalActualReservesForTokens[token] -=amount;
    userRemainingBalance[to][token] -=amount;
    emit GetRemainingBalance(to, token, amount);


}
function sendBackMoneyForUsers(address to,address token,uint256 amount,uint256 nonce,bytes calldata signature) external{
    require(amount<=userRemainingBalance[to][token]);
    require(amount<=totalActualReservesForTokens[token]);
    require(processedNonces[msg.sender][nonce] == 0, 'transfer already processed');
    processedNonces[msg.sender][nonce] = 1;
    userRemainingBalance[to][token] -=amount;
    emit Transfer(
      msg.sender,
      to,
      token,
      amount,
      nonce,
      signature
    );

}
//there should also be a function for the users to send back their money if no much amount is here.


function getLiquidityFromSupplyOnSecondBlockchain(address token,uint256 supplyAmount)external {
  require(totalSupplyByOwner[msg.sender][token]>=supplyAmount);
        uint256 reserves=totalReservesForTokens[token];
        uint256 supply=totalTokensSupply[token];
        uint256 liquidity=supplyAmount.mulDiv(reserves,supply);
        require(totalReservesForTokens[token]>=liquidity);
        totalTokensSupply[token] -=supplyAmount;
        totalSupplyByOwner[msg.sender][token] -=supplyAmount;
        totalReservesForTokens[token] -=liquidity;
        totalTokensDepositedByUser[msg.sender][token]-=liquidity;
        // require(IERC20(token).transfer(msg.sender,liquidity));
        emit LiquidityTransfered(msg.sender,token,liquidity);


}
//this is successful because either way money is there.
//cant be loose
function PauseTokens(address token)external{
  require(pausedTokens[token]==0);
  require(admin==msg.sender);
  pausedTokens[token]=1;
}
function UnPauseTokens(address token)external{

  require(pausedTokens[token]==1);
  require(admin==msg.sender);
  pausedTokens[token]=0;
}


}
// what to do is 
// k supply wale pe set krdeta hoon kisi ne apni liquidity agar wahan se nikalwani 
// to wo apna supply ki liquidity nikal k udhr send kre idhr se uska khata khatam 
//udhr pesa recieve