/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

contract IGameWallet {
    function depositFundsFor(address _user, uint _amount) public;
    function addFundsToWalletForUser(address _user, uint[] memory _amounts, bool _payingWithBplots) public;
}

contract IToken {

    function decimals() external view returns(uint8);

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Gets the balance of the specified address.
    * @param account The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address account) external  view returns (uint256);

    /**
    * @dev Transfer token for a specified address
    * @param recipient The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) external returns (bool);
    
     /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) external ;

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
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
    * @dev Transfer tokens from one address to another
    * @param sender address The address which you want to send tokens from
    * @param recipient address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract SendRewards {

    // 
    IGameWallet public Igw;
    address public owner;
    mapping(uint=>bool) public _uniqueId;

    constructor(address _igw) public {
        Igw = IGameWallet(_igw);
        owner = msg.sender;
        whiteListUser(owner);
    }

    event DBPlotSent(address indexed _user, uint _amount, uint _timestamp,uint _id);

    mapping(address => bool) public _allowed;

    function whiteListUser(address _add) public {
        require(msg.sender == owner);
        _allowed[_add] = true;
    }

    function deWhiteListUser(address _add) public {
        require(msg.sender == owner);
        _allowed[_add] = false;
    }

    function giveApproval(address _token, address _spender, uint _amount) public {
        require(_allowed[msg.sender],"Not Allowed");
        IToken(_token).approve(_spender,_amount);
    }

    function transferRewards(address[] memory _users, uint[] memory _rewards, uint _id) public {
        require(_allowed[msg.sender],"Not Allowed");
        require(!_uniqueId[_id],"Already distributed for this id");
        _uniqueId[_id] = true;
        for(uint i=0;i<_users.length;i++) {
            uint[] memory funds = new uint[](3);
            funds[2] = _rewards[i];
            Igw.addFundsToWalletForUser(_users[i],funds,false);
            emit DBPlotSent(_users[i],_rewards[i],now,_id);
        }        
    } 

    function takeFundsOut(address _token, address _to, uint _amount) public {
        require(_allowed[msg.sender],"Not Allowed");
        IToken(_token).transfer(_to,_amount);
    }
}