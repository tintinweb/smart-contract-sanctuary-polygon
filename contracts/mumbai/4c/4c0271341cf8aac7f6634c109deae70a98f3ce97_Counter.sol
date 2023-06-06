/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/AutomationBase.sol


pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/AutomationCompatible.sol


pragma solidity ^0.8.0;



abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: docs.chain.link/samples/Automation/AutomationCounter.sol


pragma solidity ^0.8.7;


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


  //  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  //  event Transfer(address indexed from, address indexed to, uint tokens);

mapping
    (address => uint256) balances;

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


contract Lillypool is IERC20 {

    string public constant name = "Lillypool";
    string public constant symbol = "Lypool";
    uint8 public constant decimals = 18;
    address payable public owner ;
    uint256 public n_user;
    address payable  [] public staff;
    uint256 certificate_value = 1000000000000000;
    uint256 certificate_cost = 25000000000000000;

    mapping (uint => cert_buyer) public CERTIF;
    
    // each cert to obtain eth
    struct cert_buyer {
        uint256  NFT_token;
        bool avaiable;
        address  _address;
    }

    uint256 public next_certificate = 0;
    mapping(address => mapping (address => uint256)) allowed;

        

   // event Transfer(address indexed from, address indexed to, uint tokens);
    event Transfer_ownership(address owner, address new_owner);
    event change_lill_mint(uint lilly_mint, uint new_lilly_mint);
    event change_staff (address payable [] staff, address payable [] _newstaff);
    event change_burn_add (address payable burn_address, address payable new_burn_address);
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    /// address to burn
    address payable public burn_address;
    address payable public lilly_bank;
    address public certificate_address;
    uint public cost_to_play;

    using SafeMath  for uint256;

    bool public retire_auth;


   constructor(uint256 _totalsupply, address payable [] memory _staff, address payable _burn_addr, address payable _lilly_bank, uint _certificate_value) public {
    
    staff = _staff;
    owner = payable(msg.sender);
    totalSupply_ = _totalsupply * (10**18);
    burn_address = _burn_addr;
    lilly_bank = _lilly_bank;
    //balances[msg.sender] = totalSupply_;
    balances[address(this)] = totalSupply_/2;
    balances[owner] = totalSupply_/2;
    certificate_value = _certificate_value;
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




    // set_certificate_address

    function set_certificate_address (address certif_address) public returns (bool){
        require(msg.sender == owner ||  check_staff(payable(msg.sender)));
        certificate_address = certif_address;
        return(true);

    }

    // function to set cost to buy

    function set_certificate_cost(uint256 certif_cost) public returns (bool){
        require(msg.sender == owner ||  check_staff(payable(msg.sender)));
        certificate_cost = certif_cost;
        return(true);
    }

    // function to set certificate value

    function set_certificate_value(uint256 certif_value) public returns (bool){
        require(msg.sender == owner ||  check_staff(payable(msg.sender)));
        certificate_value= certif_value;
        return(true);
    }


    // authorize withdraw

    function authorize_withdraw ( bool authorize) public returns (bool){
                require(msg.sender == owner ||  check_staff(payable(msg.sender)));
                retire_auth = authorize;
    }


    uint256 public length__ = 0;
    ////function update certificate
    function certificate_update(uint256 [] memory _NFT_token, bool [] memory _avaiable, address [] memory __address) public returns (bool) {   
        require(msg.sender== owner || check_staff(payable(msg.sender)));
       for (uint j = 0 ; j< _avaiable.length; j++){
                    CERTIF[j].NFT_token = _NFT_token[j];
                    CERTIF[j].avaiable = _avaiable[j];
                    CERTIF[j]._address = __address[j];
        }
        length__ ==  _avaiable.length;
        return(true);

    }

    function certificate_update_2(uint256  _NFT_token, bool _avaiable, address __address) public returns (bool) {   
        require(msg.sender== owner || check_staff(payable(msg.sender)));
       
                    CERTIF[next_certificate].NFT_token = _NFT_token;
                    CERTIF[next_certificate].avaiable = _avaiable;
                    CERTIF[next_certificate]._address = __address;
        next_certificate = next_certificate + 1 ;
        
        return(true);

    }


    ///withdraw ethereum

    function withdraw_ethereum() public returns (bool) {   
        require(retire_auth , "withdraw paused");

        for (uint256 i = 0; i< length__ + 1; i++){
                if(CERTIF[i]._address == msg.sender){
                    if(CERTIF[i].avaiable == true){
                        uint256 value_ = CERTIF[i].NFT_token * certificate_value;
                        sendWithCall(value_ , payable(msg.sender));
                        //CERTIF[i].NFT_token = 0;
                        CERTIF[i].avaiable = false;
                    }

                }
        }

    }

    function withdraw_ethereum_2() public returns (bool) {   
        
        require(retire_auth , "withdraw paused");

        for (uint256 i = 0; i< next_certificate; i++){
                if(CERTIF[i]._address == msg.sender){
                    if(CERTIF[i].avaiable == true){
                        uint256 value_ = CERTIF[i].NFT_token * certificate_value;
                        sendWithCall(value_ , payable(msg.sender));
                        //CERTIF[i].NFT_token = 0;
                        CERTIF[i].avaiable = false;
                    }

                }
        }

    }

    function view_received_eth(address payable receiver_) public view returns(uint256 received){
            uint256 received_ = 0;
            for (uint256 i=0; i < next_certificate; i++){
                if(CERTIF[i]._address == receiver_){
                    if(CERTIF[i].avaiable  == false){

                        received_ = received_ + CERTIF[i].NFT_token;
                    }
               }
            }


        return received_;

    }






    function withdraw_ethereum_3(address payable receiver_) public returns (bool) {   
        require(msg.sender == owner || check_staff(payable(msg.sender)));
        require(retire_auth , "withdraw paused");

        for (uint256 i = 0; i< next_certificate; i++){
                if(CERTIF[i]._address == receiver_){
                    if(CERTIF[i].avaiable == true){
                        uint256 value_ = CERTIF[i].NFT_token * certificate_value;
                        sendWithCall(value_ , receiver_);
                        //CERTIF[i].NFT_token = 0;
                        CERTIF[i].avaiable = false;
                    }

                }
        }

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


    /// function to burn lilly

    function burn_lilly(uint256 burnable) public returns (bool){

        transfer(burn_address , burnable);
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


    function transferownership(address payable new_receiver) public returns (bool){
        require(msg.sender == owner);
        emit Transfer_ownership(msg.sender , new_receiver);
        owner = new_receiver;
        return true;
    }
    
    receive () external payable {}
    
    fallback() external payable {}

    function sendWithCall (uint256 _value, address payable receiver__) public returns(bytes memory) {
          (bool success , bytes memory data) = payable(receiver__).call{value:_value}("");
          require(success , "Call failed");

          return data;

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

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol


/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract Counter is  AutomationCompatibleInterface  {
    /**
     * Public counter variable
     */
    uint public counter;
    uint public num_test=0;

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint public immutable interval;
    uint public lastTimeStamp;
    address payable receiver;


    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint updateInterval, address payable _receiver) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        owner = msg.sender;

        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        receiver = _receiver;
        counter = 0;
    }


    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    mapping(address => bool) public approvedMinters;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == owner || approvedMinters[msg.sender], "Only owner or approved minter can call this function");
        _;
    }





    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Invalid spender");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

 /*   function mint(address _to, uint256 _value) public onlyMinter {   /////this is the error Onlyminter for the chainlink address ----- ****** 5555555 
        require(_to != address(0), "Invalid recipient");

        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
    } */

    function mint(address _to, uint256 _value) public {   /////this is the error Onlyminter for the chainlink address ----- ****** 5555555 
        require(_to != address(0), "Invalid recipient");

        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    function addMinter(address _minter) public onlyOwner {
        approvedMinters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        approvedMinters[_minter] = false;
    }




    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
            mint(receiver,5);
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }
}