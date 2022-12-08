pragma solidity ^0.8.4;

import "../security/Pausable.sol";
import "../token/IERC20.sol";

//change file name
contract MaticCrossCoinA is Pausable {
    IERC20 public coinA;

    struct PendingTx {
        uint256 _primaryKey;
        address _sender;
        uint256 _amount;
    }

    PendingTx[] public pendingTx;
    mapping(uint256 => uint256) public pkToIndex; //primary key to index

    uint256 primaryKey = 0;
    mapping(uint256 => bool) pkExist;

    event crossChain(uint256 _primaryKey, address _sender, uint256 _amount);
    event sendCoinA(uint256 _primaryKey, address _sender, uint256 _amount);
    event removePendingTX(
        uint256 _primaryKey,
        address _sender,
        uint256 _amount
    );

    receive() external payable {}

    function setCoinAAddress(address _address) external onlyAdmin {
        coinA = IERC20(_address);
    }

    ///@dev cross chain funciton, need to send coinA token to this contract first
    function crossChainMint(uint256 _amount) external {
        require(coinA.balanceOf(msg.sender) >= _amount, "Not Enough Tokens");

        bool success = coinA.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer Error");

        primaryKey++;

        _addToPendingTransaction(primaryKey, msg.sender, _amount);

        emit crossChain(primaryKey, msg.sender, _amount);
    }

    function removePendingTransaction(uint256 _primaryKey) external onlyAdmin {
        require(pkExist[_primaryKey], "Invalid PK");
        _removeTransaction(_primaryKey);
    }

    /// @dev from server calling this function to send coinA to user
    function crossChainBack(
        uint256 _primaryKey,
        address _address,
        uint256 _amount
    ) external onlyAdmin {
        require(
            coinA.balanceOf(address(this)) >= _amount,
            "Not Enough Balance"
        );

        bool success = coinA.transfer(_address, _amount);
        require(success, "Failed to send CoinA");

        emit sendCoinA(_primaryKey, _address, _amount);
    }

    function getPendingTXLength() external view returns (uint256) {
        return pendingTx.length;
    }

    function withdrawCoinA(uint256 _amount) external onlySuperAdmin {
        coinA.transfer(superAdmin, _amount);
    }

    function _addToPendingTransaction(
        uint256 _primaryKey,
        address _sender,
        uint256 _amount
    ) internal {
        pkToIndex[_primaryKey] = pendingTx.length;
        pendingTx.push(PendingTx(_primaryKey, _sender, _amount));
        pkExist[_primaryKey] = true;
    }

    function _removeTransaction(uint256 _primaryKey) internal {
        uint256 index = pkToIndex[_primaryKey];
        uint256 lastIndex = pendingTx.length - 1;

        // change array
        PendingTx memory originPendingTX = pendingTx[index];
        PendingTx memory lastPendingTX = pendingTx[lastIndex];
        pendingTx[index] = lastPendingTX;
        pendingTx.pop();

        // change mapping
        pkToIndex[lastPendingTX._primaryKey] = index;
        delete pkToIndex[_primaryKey];

        emit removePendingTX(
            _primaryKey,
            originPendingTX._sender,
            originPendingTX._amount
        );
    }
}

pragma solidity >=0.8.0 <0.9.0;

import './AccessControl.sol';

contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with 
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}