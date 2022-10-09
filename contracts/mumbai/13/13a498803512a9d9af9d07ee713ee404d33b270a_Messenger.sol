/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Messaging.sol


pragma solidity >=0.4.22 <0.9.0;


contract Messenger {
    IERC20 public token;
    address private owner;

    uint price;
    uint fee;

    struct Message {
        string message;
        address sender;
        uint date;
        uint time;
        string attachment;
    }

    struct sentMessage {
        string message;
        address recipient;
        uint date;
        uint time;
        string attachment;
    }

    constructor() public {
        token = IERC20(0x69fF763980cFE56c9153565066F518D65b0B70f4);
        owner = msg.sender;
    }

    mapping (address => Message[]) messages;
    mapping (address => sentMessage[]) sentmessages;

    function GetUserTokenBalance() public view returns(uint256){ 
       return token.balanceOf(msg.sender);
    }

     function GetContractTokenBalance() public onlyOwner view returns(uint256){
       return token.balanceOf(address(this));
    }

     function Approvetokens(uint256 _tokenamount) public returns(bool){
       token.approve(address(this), _tokenamount);
       return true;
    }

    function GetAllowance() public view returns(uint256){
       return token.allowance(msg.sender, address(this));
    }

    function AcceptPayment(uint256 _tokenamount) public returns(bool) {
       require(_tokenamount > GetAllowance(), "Please approve tokens before transferring");
       token.transfer(address(this), _tokenamount);
       return true;
    }

    function sendMessage(address _to, string memory _message, uint _date, string memory _attachment) public payable {
        require(msg.value >= price, "Not Paid");
        require(AcceptPayment(fee));
        messages[_to].push(Message({sender: msg.sender, message: _message, date: _date, time: block.timestamp, attachment: _attachment }));
        sentmessages[msg.sender].push(sentMessage({recipient: _to, message: _message, date: _date, time: block.timestamp, attachment: _attachment }));
    }

    function getMessage(uint _index) public view returns (address, string memory, uint, uint, string memory) {
        Message memory message = messages[msg.sender][_index];
        return (message.sender, message.message, message.date, message.time, message.attachment);
    }

    function getSentMessage(uint _index) public view returns (address, string memory, uint, uint, string memory) {
        sentMessage memory message = sentmessages[msg.sender][_index];
        return (message.recipient, message.message, message.date, message.time, message.attachment);
    }

    function getMsgLength() public view returns(uint) {
        return messages[msg.sender].length;
    }

    function getSentMsgLength() public view returns(uint) {
        return sentmessages[msg.sender].length;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed.");
    }

    function setPrices(uint _price, uint _fee) public onlyOwner {
        price = _price;
        fee = _fee;
    }
    
}