/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Testament.sol


pragma solidity ^0.8.0;



contract Testament{

    address public MyToken = 0xa5060f4A60f0f5977a45B61F29132474C5675e16;
    IERC20 public token = IERC20(MyToken);
    // MyToken public token;
    address public _manager;
    mapping(address=>address) _heir;
    mapping(address=>uint) _balance;
    event Create(address indexed owner, address indexed heir, uint amount);
    event Report(address indexed owner, address indexed heir, uint amount);
    
    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event TransferSent(address _from, address _destAddr, uint256 _amount);

    constructor() payable{
        // token = MyToken(0xa5060f4A60f0f5977a45B61F29132474C5675e16); //Testnet
        // token = MyToken(0xCCBada3d434EFB147c5401DDf0a7E00edF071C4b); // Local
        payable(msg.sender);
        _manager = msg.sender;
    }

    function create(address heir, uint amount) public{
        // uint256 amount = msg.value;
        require(amount>0,"Please Enter Money > 0");
        require(_balance[msg.sender]<=0, "Already Testament.");

        uint256 dexBalance = token.balanceOf(msg.sender);
        require(amount <= dexBalance, concatenate("Not enough tokens in the reserve : ", Strings.toString(dexBalance)));
        token.transferFrom(msg.sender, address(this), amount);

        _heir[msg.sender] = heir;
        _balance[msg.sender] = amount;
        emit Create(msg.sender, heir, amount);
    }

    function getTestament(address owner)public view returns(address heir, uint amount){
        return(_heir[owner],_balance[owner]);
    }

    function reportOfDeath(address owner) public{
        require(msg.sender == _manager, "Your are not Manager");
        require(_balance[owner]>0,"No Testament");
        // payable(_heir[owner]).transfer(_balance[owner]);
        token.transferFrom(_heir[owner], address(this), _balance[owner]);
        emit Report(owner, _heir[owner], _balance[owner]);
        _balance[owner] = 0;
        _heir[owner] = address(0);
    }

    // function mint(address to, uint amount) public{
    //     token.mint(to, amount);
    // }

    function checkBalance() public view returns(address sender, uint amount){
        return(msg.sender, token.balanceOf(address(msg.sender)));
    }

    function checkTokenContractBalance() public view returns(uint amount){
        return(token.balanceOf(address(this)));
    }

    function contractBalance() public view returns(uint amount){
        return(address(this).balance);
    }

    function transferApprove(uint amount) public payable {
        token.approve(msg.sender, amount);
    }

    function transferToContract(uint256 amount) public {
        // token.approve(msg.sender, amount);
        // token.transferFrom(msg.sender,address(this),amount);
        // token.transfer(address(this), msg.value);
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, concatenate("Check the token allowance : ", Strings.toString(allowance)));
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
    }

    function transferToManager(uint amount) public payable{
        // token.approve(msg.sender, amount);
        // token.transferFrom(msg.sender,address(this),amount);
        token.transfer(_manager, amount);
    }

    // function transferTo(uint amount) public payable{
    //     // token.approve(address(this), amount);
    //     // token.transferFrom(msg.sender,address(this),amount);
    //     // token.transfer(to, amount);
    //     require(amount > 0, "You need to sell at least some tokens");
    //     // uint256 allowance = token.allowance(msg.sender, address(this));
    //     // require(allowance >= amount, concatenate("Check the token allowance : ", Strings.toString(allowance)));
    //     // token.approve(msg.sender, amount);
    //     // token.transfer(to, amount);
    //     // token.transferFrom(msg.sender, address(this), amount);
    //     token.sendTo(msg.sender, address(this), amount);
    //     payable(msg.sender).transfer(amount);
    // }

    function checkAllowance(address to) public view returns (uint256 allowance) {
        // token.approve(to, token.balanceOf(address(msg.sender)));
        return allowance = token.allowance(msg.sender, to);
        // return allowance;
    }

    function setApprove(address to) public returns (uint256 balance) {
        token.approve(to, token.balanceOf(address(msg.sender)));
        return token.balanceOf(address(msg.sender));
        // return allowance;
    }

    function concatenate(string memory s1, string memory s2) public pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    function sendCoinToContract() public payable{
        payable(msg.sender).transfer(msg.value);
    }

    function buy(uint amount) public {
        uint256 amountTobuy = amount;
        // uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }
    
    function sell(uint amount) public {
        // uint256 amount = msg.value;
        token.approve(msg.sender, amount);
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, string(abi.encodePacked("Check the token allowance : ", Strings.toString(allowance))));
        token.transferFrom(address(this), msg.sender, amount);
        // token.transferFrom(address(this), msg.sender, amount);
        // msg.sender.transfer(amount);
        payable(msg.sender).transfer(amount);
        emit Sold(amount);
    }

    // function transferOwner(address newOwner) public {
    //     token.transferOwnership(newOwner);
    // }

    function deposit(uint256 amount) external payable {
        token.approve(address(this), amount);
        uint256 balance = token.balanceOf(msg.sender);
        require(amount <= balance, "balance is low");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, string(abi.encodePacked("Check the token allowance : ", Strings.toString(allowance))));
        token.transferFrom(msg.sender, address(this), amount);
        emit TransferSent(msg.sender, address(this), amount);
    }


}