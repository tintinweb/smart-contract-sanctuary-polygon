// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Model.sol";

contract Router {

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts)  {}

  function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts){}

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts){}
  
  function WETH() external pure returns (address){}
}


contract Haiex is Pausable, Ownable {

    Router  private  router;

    address private  WETH;
    ERC20  public USDToken ;

    struct Stable {
        Model   tokenAddress;
        uint     price;
        uint256  tokenReserve;
        bool     tradable;
    }

    enum Operation {
        ADD,
        SUB
    }

    Stable[] public stables;

    uint256 public  fees; 
    uint256 public  tradeFees; 
    // mapping(address => uint) feesPartition;


    address public  admin;
    address public  manager;
    
    uint priceFloatDigit = 1000000;

    mapping(address => bool) taxesFreeHolder;
 
    constructor()   { 
     
        admin = owner();
        manager = owner();
        fees =  50;        //=> 50/100    = 0.5%
        tradeFees = 50;    //=> 50/100    = 0.5%
        taxesFreeHolder[owner()] = true;

        router = Router(0xE3D8bd6Aed4F159bc8000a9cD47CffDb95F96121);
        WETH = 0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9;
    }  



    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
 
    modifier onlyManager() {
        require(msg.sender == manager, "unauthorized: not manager");
        _;
    }

    modifier onlyManagerOrOwner() {
        require(msg.sender == manager||msg.sender == owner(), "unauthorized: not owner or manager");
        _;
    }

  
    function changeRouter(address routerAddr) public onlyOwner returns (bool) {
        router = Router(routerAddr);
        return true;
    }


    function changeWETH(address wethAddr) public onlyOwner returns (bool) {
        WETH = wethAddr;
        return true;
    }

    function changeUSD(address usdToken) public onlyManagerOrOwner returns (bool) {
        require(usdToken != address(0), "Stable1 doest not exist");
        USDToken = ERC20(usdToken);
        return true;
    }

    function changeFee(uint256 fee_) public onlyManagerOrOwner returns (bool) {
        require(fee_ >= 0 , "Cannot be less than zero");
        fees = fee_;
        return true;
    }

    // function addBeneficiary(address beneficiary, uint amount) public onlyManagerOrOwner returns (bool) {
    //     require(usdToken != address(0), "Beneficiary cannot be null");
    //     require(amount >= 0 , "Cannot be less than zero");
    //     require(amount < 500 , "Cannot be more than 5%");

    //     feesPartition[beneficiary] = amount;
        
    //     return true;
    // }


    function changeAdmin(address admin_) public onlyOwner returns (bool) {
        require(admin_ != address(0) , "Collector can't be null");
        admin = admin_;
        return true;
    }


    function changeManager(address manager_) public onlyOwner returns (bool) {
        require(manager_ != address(0) , "Manager can't be null");
        manager = manager_;
        return true;
    }


    // =====================================================================================================

    // =================================================Stables Coin Management====================================================


    function addTaxesFreeHolder(address holder) public onlyOwner {
        taxesFreeHolder[holder] = true;
    }

    function removeTaxesFreeHolder(address holder) public onlyOwner {
        taxesFreeHolder[holder] = false;
    }

    function addStable(Model _tokenAddress, uint _priceInit, uint256  _tokenReserve, bool _tradable ) onlyOwner public returns (bool) {

        uint stablesLength = stables.length;

        Stable memory stable = Stable({tokenAddress:_tokenAddress, price:_priceInit, tokenReserve: _tokenReserve, tradable: _tradable });

        stables.push(stable);

        if(stables.length > stablesLength)
            return true;
    
        return false;
    }

    function removeStableByAddress(Model addr) onlyOwner public returns (uint) {
        uint stablesLength = stables.length;
        Stable memory stable;

        for(uint i;  i < stablesLength ; i++ )
        {
            if(stables[i].tokenAddress == addr){

                stable = stables[stablesLength-1];
                stables[stablesLength-1] = stables[i];
                stables[i] = stable;
                stables.pop();

                return stables.length;
            }
                
        }

        return stables.length;

    }

    function getStableByAddress(Model addr) public view returns ( Stable memory) {

        Stable memory stable;

        for(uint i;  i < stables.length; i++ )
        {
            if(stables[i].tokenAddress == addr){
                stable = stables[i];
                return (stable);
            }
                
        }

      return stable; 

    }

    function updateStableByAddress(Model _tokenAddress, uint _price, uint256  _tokenReserve, bool _tradable) onlyOwner public returns (bool)  {

    
        Stable memory stable;  

        stable.tokenAddress = _tokenAddress;
        stable.price = _price;
        stable.tokenReserve = _tokenReserve;
        stable.tradable = _tradable;

        for(uint i;  i < stables.length; i++ )
        {
            if(stables[i].tokenAddress == _tokenAddress){
                 stables[i] = stable;
                return true;
            }  
        }

        return false;

    }

    function updateStablePrice(Model _tokenAddress, uint _price) public onlyManagerOrOwner returns (bool) {
       
        require(_price > 0, "Price must be > 0");
      

        for(uint i;  i < stables.length; i++ )
        {
            if(stables[i].tokenAddress == _tokenAddress){

                 stables[i].price = _price;
              
                return true;
            }  
        }

        return false;
    }

    function updateStableReserve(Model _tokenAddress, uint  _amount, Operation  operat) internal  returns (bool)  {


        for(uint i;  i < stables.length; i++ )
        {
            if(stables[i].tokenAddress == _tokenAddress){
                if(operat == Operation.ADD)
                 stables[i].tokenReserve = add(stables[i].tokenReserve, _amount);
                else
                 stables[i].tokenReserve = sub(stables[i].tokenReserve, _amount);

                return true;
            }  
        }

        return false;

    }




    // =====================================================================================================

    // =================================================Stables Converter===================================

    function stableTrade(address _stable1, address _stable2, uint256 amount) public  whenNotPaused returns (bool) {

    
     
        //Initialize ERC20 token
        Model stableCoin1 = Model(_stable1);
        Model stableCoin2 = Model(_stable2);

        //Get stable information
        Stable memory stable1 = getStableByAddress(stableCoin1);
        Stable memory stable2 = getStableByAddress(stableCoin2);



        //Get sender balance
        uint senderBalance = stableCoin1.balanceOf(msg.sender);
        

        //Check amount, Balance, allowance, token price, existence
        require(_stable1 != address(0), "Stable1 doest not exist");
        require(_stable2 != address(0), "Stable2 doest not exist");
        require(amount > 0, "Amount can't be zero");
        require(senderBalance >= amount, "Token not enough");
        require(stableCoin1.allowance(msg.sender, address(this)) >= amount, "Allowance not enough");
        require(stable1.price > 0, "Stable1 Price has not been define");
        require(stable2.price > 0, "Stable2 Price has not been define");


        //Fist step convert Stable1 to USD

        uint256 usd = mul(div(amount, stable1.price), priceFloatDigit);
         //Smart contract Burn those tokens  
        stableCoin1.burnFrom(msg.sender, amount);
       
        //Decrease usd reserve allocate to  Stable1
        updateStableReserve(stable1.tokenAddress, usd, Operation.SUB);


        bool freeTaxe = taxesFreeHolder[msg.sender];

        uint taxes = 0;

        if(!freeTaxe){
        //Calculate Taxes
         taxes  = div(mul(usd, tradeFees), 10**4); 
        if(USDToken.balanceOf(address(this))> div(taxes, 2)){
             USDToken.transfer(address(manager), div(taxes, 2));
         }
      
        }
    
        //Get Tax
        uint usdr = usd - taxes;

    
        //Second step convert USD to Stable2

        uint256 tokens = div(mul(usdr, stable2.price), priceFloatDigit);
        //Smart contract Mint the Stable2
        stableCoin2.mint(msg.sender, tokens);
        //Update reserve allocate to  Stable2
        updateStableReserve(stable2.tokenAddress, usdr, Operation.ADD);


        //Operation successful
        return true;
    }

    function buyStable(address tokenAddress, uint256 usdAmount) public  whenNotPaused returns (bool) {

        //Initialize ERC20 token
        Model stableCoin = Model(tokenAddress);


        //Get stable information
        Stable memory stable = getStableByAddress(stableCoin);
        

        //Check amount USD, Balance, allowance, token price
        require(usdAmount > 0, "Usd amount can't be zero");
        require(USDToken.balanceOf(msg.sender) >= usdAmount, "Token not enough");
        require(USDToken.allowance(msg.sender, address(this)) >= usdAmount, "Allowance not enough");
        require(stable.price > 0, "Price has not been define");


        bool freeTaxe = taxesFreeHolder[msg.sender];

        uint taxes = 0;

        if(!freeTaxe){
            //Calculate Taxes
            taxes  = div(mul(usdAmount,fees), 10**4); 

            if(USDToken.balanceOf(address(this))> div(taxes, 2)){
              USDToken.transfer(address(manager), div(taxes, 2));
            }
           
        }

    
        //Get Tax
        uint usdAfterTaxed = sub(usdAmount, taxes);
        //Get token amount to send after tax
        uint tokens = div(mul(usdAfterTaxed, stable.price), priceFloatDigit);

     
        //Tranfer USD from the sender to the smart contract
        USDToken.transferFrom(msg.sender, address(this), usdAmount);

 
        
        //Update reserve allocate to this stable
        updateStableReserve(stableCoin, usdAfterTaxed, Operation.ADD);

      
        //Smart contract Mint the token
        stableCoin.mint(msg.sender, tokens);
    

        return true;
    }

    function sellStable(address tokenAddress, uint256 tokenAmount) public whenNotPaused returns (bool) {

        //Initialize ERC20 token
        Model stableCoin = Model(tokenAddress);
      
        //Get stable information
        Stable memory stable = getStableByAddress(stableCoin);
       
        //Check amount USD, Balance, allowance, token price
        require(tokenAmount > 0, "Amount need to be greater than zero");
        require(stableCoin.balanceOf(msg.sender) >= tokenAmount, "Token not enough");
        require(stableCoin.allowance(msg.sender, address(this)) >= tokenAmount, "Allowance not enough");
        require(stable.price > 0, "Price has not been define");


        uint256 usd = mul(div(tokenAmount, stable.price), priceFloatDigit);

        bool freeTaxe = taxesFreeHolder[msg.sender];

        uint taxes = 0;

        if(!freeTaxe){
        //Calculate Taxes
         taxes  = div(mul(usd,fees), 10**4);

         if(USDToken.balanceOf(address(this))> div(taxes, 2)){
            USDToken.transfer(address(manager), div(taxes, 2));
         }

        }

        uint256 usdAfterTaxed = usd - taxes;

        //Burn those tokens         
        stableCoin.burnFrom(msg.sender, tokenAmount);
     

        //Send USD to the sender
        USDToken.transfer(msg.sender, usdAfterTaxed);

        //Update reserve allocate to this stable
        updateStableReserve(stableCoin, usdAfterTaxed, Operation.SUB);
        //Operation successful

    

       return true;
    }

    function sendStable(address erctoken, address to,  uint256 amount) public whenNotPaused returns (bool) {


        require(amount > 0, "Tokens amount can't be zero");
        require(erctoken != address(0), "ERC20 can't be null address");
        require(to != address(0), "Recipient can't be null address");

        Model ErcToken  = Model(erctoken);
        require(ErcToken.balanceOf(msg.sender) >= amount, "Token not enough");
        

      
        ErcToken.transferFrom(msg.sender, to , amount);

        return true;
    }



    // ===================================================================================================================
    //
    // ==================================================Stables and Ubeswap Swapping=====================================


    function swapStable(address tok_in, address tok_out, address[] memory path,  uint256 amount) public whenNotPaused{


        require(amount > 0, "Amount can't be zero");
        require(tok_in != tok_out, "Can't swap same tokens");

       

        ERC20 token1  = ERC20(tok_in);
     

        Stable memory stable ;
        Model stableToken ;

        if(tok_in != path[0])
        {
            stableToken  = Model(tok_in);
            stable = getStableByAddress(stableToken);
        }

        else if(tok_out != path[path.length-1])
        {
            stableToken  = Model(tok_out);
            stable = getStableByAddress(stableToken);
        }

       
        bool freeTaxe = taxesFreeHolder[msg.sender];

        uint taxes = 0;

     


        // uint usdAmount = amount;

        if( stable.tokenAddress == Model(tok_in)){
               
                
            require(stableToken.balanceOf(msg.sender) >= amount, "Token not enough");
            require(stableToken.allowance(msg.sender, address(this)) >= amount, "Allowance not enough");  



            uint256 usd = mul(div(amount, stable.price), priceFloatDigit); // Convert  to usd

            if(!freeTaxe){
                //Calculate Taxes
                taxes  = div(mul(usd,tradeFees), 10**4);

                if(USDToken.balanceOf(address(this))> div(taxes, 2)){
                     USDToken.transfer(address(manager), div(taxes, 2));
                }
              
            }

            uint256 usdAfterTaxed = usd - taxes; // remove fees total amount

        
            //Get sender TGOUD and Burn them tokens 
            stableToken.burnFrom(msg.sender,  amount);

            //Allow Quickswap to use the amount of usd
            USDToken.approve(address(router), usdAfterTaxed);

            //Swap the USD to token
            router.swapExactTokensForTokens(
            usdAfterTaxed,
            0,
            path,
            msg.sender,
            block.timestamp
            );

            //Update reserve allocate to this stable
            updateStableReserve(stableToken, usd, Operation.SUB);

        }
        else if( stable.tokenAddress ==  Model(tok_out)){
              
            token1.transferFrom(
            msg.sender,
            address(this),
            amount
            );

            //Allow uniswap to use the amount of usd
            token1.approve(address(router), amount);

            //Swap the token to USD 
             uint[] memory  amounts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
            );

            uint amountOut = amounts[amounts.length-1];
       
            if(!freeTaxe){
             //Calculate Taxes
             taxes  = div(mul(amountOut,tradeFees), 10**4); 

               if(USDToken.balanceOf(address(this))> div(taxes, 2)){
                     USDToken.transfer(address(manager), div(taxes, 2));
               }
            
            }


            uint256 usdAfterTaxed = amountOut - taxes;

            uint256 tokens = div(mul(usdAfterTaxed, stable.price), priceFloatDigit);


            stableToken.mint(msg.sender, tokens);
            // //Transfer tax
            USDToken.transfer(address(manager), div(taxes, 2));

            updateStableReserve(stableToken, usdAfterTaxed, Operation.ADD);

        }
        else{
            //Transfer token1 to the smart Contract
            token1.transferFrom(
            msg.sender,
            address(this),
            amount
            );
       
            if(!freeTaxe){
                //Calculate Taxes
                taxes  = div(mul(amount,tradeFees), 10**4);
                if(token1.balanceOf(address(this))> div(taxes, 2)){
                    token1.transfer(address(manager), div(taxes, 2));
                }

            }
         
            uint256 amountAfterTaxed = amount - taxes;

            //Allow Quickswap to use the amount of usd
            token1.approve(address(router), amountAfterTaxed);

            //Swap the USD to token
            router.swapExactTokensForTokens(
            amountAfterTaxed,
            0,
            path,
            msg.sender,
            block.timestamp
            );
        }
       
    }
 
    function swapEstimation(address[] memory path,  uint256 amount) public view returns(uint[] memory amounts){

        return router.getAmountsOut(amount, path);
    }
 
    function getUSDReserve() public view  returns(uint256){
            return USDToken.balanceOf(address(this));
    }

    function getStableReserve(Model _tokenAddress) public view returns(uint256){
            

            for(uint i;  i < stables.length; i++ )
            {
                if(stables[i].tokenAddress == _tokenAddress){
                    
                    return stables[i].tokenReserve;
                }
                    
            }

            return 0; 
    }

    function emergencyTransferReseve(address recipient) public onlyOwner  returns(bool){
        uint256 balance = USDToken.balanceOf(address(this));
        USDToken.transfer(recipient, balance);
        return true;
    }




    // ===================================================================================================================

    // =======================================================Math function===============================================



    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 ) {
        uint256 c = a * b;
        
        assert(a == 0 || c / a == b);
            return c;
    }

    function div(uint256 a, uint256 b) public pure returns (uint256 ) {
        assert(b > 0);
        uint256	c = a / b;
        return c;
    }

   }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Model is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Model", "Model") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}