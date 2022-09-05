/**
 *Submitted for verification at polygonscan.com on 2022-09-04
*/

// File: contracts/Lilly_Token.sol


pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {
    totalSupply_ = total;
    //balances[msg.sender] = totalSupply_;
    balances[address(this)] = totalSupply_;

    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


contract Lilly is IERC20 {

    string public constant name = "Lilly";
    string public constant symbol = "Lly";
    uint8 public constant decimals = 18;
    address payable public owner ;
    uint256 public n_user;
    address payable  [] public staff;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Transfer_ownership(address owner, address new_owner);
    event change_lill_periodic(uint lilly_increase,  uint new_increase);
    event change_lill_mint(uint lilly_mint, uint new_lilly_mint);
    event change_staff (address payable [] staff, address payable [] _newstaff);
    event change_burn_add (address payable burn_address, address payable new_burn_address);
    event change_lilly_bank(address payable old_bank, address payable new_bank);
    event change_manually_minter (uint old_minter, uint new_minter);
    event change_manually_user (uint old_n_user, uint new_n_user);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    mapping(uint256 => address payable) winner;

    mapping(uint256=> clients) public holder;

    struct clients{
        address _user;

        uint _lilly_avaiable;

        uint _nft_hold;

    }




    mapping(uint256=> minter) public new_entry;

    struct minter{
        address _user;

        uint _lilly_avaiable;
    }


    uint256 totalSupply_;

    uint public lilly_increase;
    uint public lilly_mint;
    uint public n_minter = 0;

    /// address to burn
    address payable public burn_address;
    address payable public lilly_bank;
    uint public cost_to_play;

    using SafeMath  for uint256;


   constructor(uint256 _totalsupply, uint256 _increase, uint256 _lilly_mint, address payable [] memory _staff, address payable _burn_addr, address payable _lilly_bank, uint _cost_to_play) public {
    lilly_mint = _lilly_mint;    
    lilly_increase = _increase;
    staff = _staff;
    owner = msg.sender;
    totalSupply_ = _totalsupply;
    burn_address = _burn_addr;
    lilly_bank = _lilly_bank;
    //balances[msg.sender] = totalSupply_;
    balances[address(this)] = totalSupply_/2;
    balances[owner] = totalSupply_/2;
    cost_to_play = _cost_to_play;

    }

    ////// function burn --> fatta
    /// distribution prize   //// prize reward da rivedere si dovrebbe aggiornare dopo la funzione update holder
    /// pay to play

    // function to look at the staff member

    function check_staff (address payable intern) public view returns (bool test){
        bool test = false;
        for (uint i = 0 ; i<staff.length; i++){
            if(intern == staff[i]){
                test =  true;
            }
        }
        return test;        
    }


    // change staff

    function change_staff_(address payable [] memory _new_staff) public returns (bool){

        require(msg.sender == owner);
        staff = _new_staff;
        emit change_staff(staff, _new_staff);
        return true;
    }



    // change burn address

    function change_burn(address payable new_burn) public returns (bool){
        require (msg.sender == owner);
        burn_address = new_burn;
        emit change_burn_add(burn_address , new_burn);
        return true;
    }

    /// change bank address

    function change_bank (address payable new_bank) public returns (bool){
        require (msg.sender == owner);
        lilly_bank = new_bank;
        emit change_lilly_bank (lilly_bank, new_bank);


    }

    /// function to burn lilly

    function burn_lilly(uint256 burnable) public returns (bool){

        transfer(burn_address , burnable);
        return true;
    }

    /// pay to play

    function pay_to_play () public returns (bool) {
        require(balanceOf(msg.sender)>= cost_to_play, "You dont' have enough Lilly");
        transfer(lilly_bank, cost_to_play);
        return true;

    }


    //// function to change manually the n_user

    function change_n_user (uint new_n_user) public returns (uint256){

        require(msg.sender == owner);
        n_user = new_n_user;
        emit change_manually_user(n_user, new_n_user);
        return(n_user);


    }


    /// function to change manually the n_minter

    function change_n_minter_m (uint new_minter_number) public returns (uint256){

        require(msg.sender == owner);
        n_minter = new_minter_number;
        emit change_manually_minter (n_minter, new_minter_number);
        return (n_minter);
    }



    ////function view avaiable lilly to withdraw by ID
    function check_avaiab (uint256 user_id) public view returns (uint256){
        uint256 cash;
        cash =  holder[user_id]._lilly_avaiable;
        return(cash);
    }

    
    ////function view avaiable lilly to withdraw  by address
    function check_avaiab_address (address payable _address) public view returns (uint256){
        uint256 cash;
        for (uint i = 0 ; i < n_user; i++){
            if ( holder[i]._user == _address){
                        
                        cash =  holder[i]._lilly_avaiable;
            }

        }
        return(cash);
    }


    ///// function to update lilly avaiable for single user and the entire dataset
    function update_holder(address payable[] calldata new_users, uint[] calldata new_nfthold) public returns (bool){
      require(msg.sender == owner || check_staff(msg.sender));
      n_user = new_users.length;
      for (uint256 i = 0; i < new_users.length; i++){
                  
                holder [i] = clients({
                    _user: new_users[i],
                    _nft_hold: new_nfthold[i],
                    _lilly_avaiable: holder[i]._lilly_avaiable + lilly_increase * new_nfthold[i]
                    
               });
       }


        return true;

    }


    /*/// update minter and lilly avaiable old version to delete
    function update_minter(address payable [] calldata minter) public returns (bool){
        require(msg.sender == owner || check_staff(msg.sender));
        bool test = false;
            for (uint256 j; j < minter.length; j++) 
                        for (uint256 i= 0; i< n_user ; i++) {

                                        if(holder[i]._user == minter[j]) {
                                            holder[i]._lilly_avaiable = holder[i]._lilly_avaiable + lilly_mint;
                                            test = true;
                                        }

                        }

        return test;
    }
    */


    //// update minter 2
    function update_minter(address payable [] calldata minter_) public returns (uint welcome_address){
        require(msg.sender == owner || check_staff(msg.sender));
        welcome_address = 0;
        
        bool welcome = false;
            for (uint256 j; j < minter_.length; j++)  {
                bool old_minter= false;
                        for (uint256 i= 0; i< n_minter; i++) {
                                        
                                        if( minter_[j] == new_entry[i]._user) {
                                            old_minter = true;                                                                                                              
                                        }
                        }
                if(old_minter = false){
                   
                            new_entry[n_minter]._user = minter_[j];
                            new_entry[n_minter]._lilly_avaiable = lilly_mint;
                            n_minter = n_minter +1;  
                            welcome_address = welcome_address +1; 
                }

            }

 
    }




    //// prize reward da rivedere si dovrebbe aggiornare dopo la funzione update holder
    function prize_reward(address payable [] calldata winner_, uint256 [] calldata prize_) public returns (bool){
        require(msg.sender == owner || check_staff(msg.sender));
        bool test = false;
            for (uint256 j; j < winner_.length; j++) 
                        for (uint256 i= 0; i< n_user ; i++) {

                                        if(holder[i]._user == winner_[j]) {
                                            holder[i]._lilly_avaiable = holder[i]._lilly_avaiable + prize_[j];
                                            test = true;
                                        }

                        }

        return test;
    }


    ///// function to withdraw lilly
    function withdraw_lilly() public returns (bool){
        for (uint i = 0; i < n_user; i++ ){

            if (msg.sender == holder[i]._user){
                if(check_avaiab(i)>0){
                    lilly_transfer(holder[i]._user, holder[i]._lilly_avaiable);
                    holder[i]._lilly_avaiable=0;
                    return true;
                }
            }
        }

    }



    //// increase lilly mint receiver
    function change_lilly_mint (uint amount) public returns (bool){
        require (msg.sender == owner);
        emit change_lill_mint(lilly_mint, amount);
        lilly_mint = amount;
        return true;
    }

    /// increase lilly periodical release
    function change_increase (uint amount) public returns (bool){
        require(msg.sender == owner);
        emit change_lill_periodic(lilly_increase, amount);
        lilly_increase = amount;
        return true;
    }




    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function prime_transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(msg.sender == owner);
        require(numTokens <= balances[address(this)]);
        balances[address(this)] = balances[address(this)].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(address(this), receiver, numTokens);
        return true;
    }

    function lilly_transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[address(this)]);
        balances[address(this)] = balances[address(this)].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(address(this), receiver, numTokens);
        return true;
    }

    function transferownership(address payable new_receiver) public returns (bool){
        require(msg.sender == owner);
        emit Transfer_ownership(msg.sender , new_receiver);
        owner = new_receiver;
        return true;
    }



    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}