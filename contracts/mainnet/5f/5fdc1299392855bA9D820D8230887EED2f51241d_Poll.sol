/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: HearUS/Poll.sol


// DEPLOYMENT CODE : Polygon

pragma solidity ^0.8.0;



contract Poll {
    
    constructor( bytes32 _authKey ) public {

        CLevel memory newCLevel = CLevel({
            CLevelAddress : msg.sender,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
        
        authKey     = _authKey;

    }    
    
    modifier onlyCEO {
        address authorized;

        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== msg.sender && CLevels[i].Role==1 && CLevels[i].Status == true){
                authorized = CLevels[i].CLevelAddress;
            }
        }
        require(msg.sender == authorized);
        _;
    }

    modifier onlyCLevel {
        address authorized;

        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== msg.sender){
                authorized = CLevels[i].CLevelAddress;
            }
        }
        require(msg.sender == authorized);
        _;
    }
    
    bytes32 authKey;
    
    
    struct CLevel {
        address CLevelAddress;
        uint256 Role;
        bool Status;
    }

    struct Option {  
        uint256 ID;
        string Title;
        string Desc;
        uint256 Count;
    }
    
    struct Vote {
        address voter;
        uint256 selectedOption;
    }

    CLevel[] public CLevels;
    Option[] public Options;
    Vote[] public Votes;

    
    mapping (address => Vote) public VoterByAddress;


    function addNewCEO (address _newAddress) external onlyCEO{
        CLevel memory newCLevel = CLevel({
            CLevelAddress : _newAddress,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
        emit ROLES (_newAddress,1,true);
    }

    function addNewCLevel (address _newAddress) external onlyCEO{
        CLevel memory newCLevel = CLevel({
            CLevelAddress : _newAddress,
            Role : 2,
            Status : true
        });
        CLevels.push(newCLevel);
        emit ROLES (_newAddress,2,true);
    }

    function deactiveCLevel (address _deactiveAddress) external onlyCEO{
        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== _deactiveAddress){
                CLevels[i].Status = false;
                emit ROLES (_deactiveAddress,CLevels[i].Role,false);
            }
        }
    }


    event ROLES (address user, uint256 role, bool status);
    event WITHDRAWALCOIN  (address indexed _walletAddress, uint256 _amount, uint256 _balance);
    event WITHDRAWALTOKEN (IERC20 indexed _tokenAddress, address indexed _walletAddress,  uint256 _amount, uint256 _balance);

    // sponsored gas voting
    function VoteByAuthkey (bytes32 _authKey, uint256 _selectedOption, address _wallet) external {

        // varify wallet is unique
        require( VoterByAddress[_wallet].voter != _wallet, "This Wallet already voted once");

        require( authKey ==  _authKey, "Incorrect AuthKey");

        Options[_selectedOption].Count +=1;

        Vote memory newVote = Vote({
            voter           : _wallet,
            selectedOption  : _selectedOption
        });

        Votes.push(newVote);
        VoterByAddress[_wallet] = newVote;

    }
    function getTotalOptions () external view returns (uint256){
        return Options.length;
    }
    function getTotalVoters () external view returns (uint256){
        return Votes.length;
    }


    function withdrawalToken (IERC20 _tokenAddress, address _recipient, uint256 _amount) external onlyCLevel() returns (address, uint256){
        
        address recipient = _recipient;
        
        _tokenAddress.approve(address(this), _amount);
        _tokenAddress.transferFrom(address(this), recipient, _amount);
        
        emit WITHDRAWALTOKEN (_tokenAddress, recipient, _amount,address(this).balance);
        return (recipient, _amount);
    }

    function withdrawalCoin (address payable _recipient, uint256 _amount) external onlyCLevel {
        require(_recipient != address(0) && _recipient != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        _recipient.transfer(_amount);
        
        emit WITHDRAWALCOIN (_recipient, _amount, address(this).balance);
    }    


    function resetAuthKey (bytes32 _authKey) external onlyCLevel returns (bytes32) {
        return authKey = _authKey;
    }  

    
    function addOption (uint256 _ID, string memory _Title, string memory _Desc) external onlyCLevel returns (bool) {
        Option memory newOption = Option({
            ID      : _ID,
            Title   : _Title,
            Desc    : _Desc,
            Count   : 0
        });
        Options.push(newOption);

        return true;
    }  


}