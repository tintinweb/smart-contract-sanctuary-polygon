/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

// SPDX-License-Identifier: MIT

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

// File: nbridge.sol


pragma solidity >=0.4.16 <0.9.0;


contract NBridge {
    address payable oracleAddr = payable(0x5bC15736B6c98003491e97B7B691f5E60526F26C);
    uint256 public balance;
    mapping (address => bool) public ETHTXIDs;
    mapping (string => bool) public ALGOTXIDs;
    mapping (uint => string) public ASAIDs;
    mapping (uint => bool) public MIGHT_BE_ASA;
    mapping (address => uint) public ASA_ADDRESS;
    mapping (uint => address) public ADDRESS_ASA;

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    event BridgeERC20(string _destAlgorandAddr);

    receive() payable external {
        require(msg.value > 2000000000000000);
        oracleAddr.transfer(2000000000000000);
        balance += (msg.value - 2000000000000000);
        emit TransferReceived(msg.sender, msg.value);
    }


    function NBRGTransferETH(uint amount, address payable destAddr, string memory algotxn) public {
        require(msg.sender == oracleAddr, "Only NBridge can send funds."); 
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount);
        balance -= amount;
        ALGOTXIDs[algotxn] = true;
        emit TransferSent(msg.sender, destAddr, amount);
    }
    
    function NBRGTransferERC20(IERC20 token, address to, uint256 amount, string memory algotxn) public {
        require(msg.sender == oracleAddr, "Only NBridge can send funds."); 
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "There aren't enough ERC20 tokens to do this. Token creator may have stolen them!");
        token.transfer(to, amount);
        ALGOTXIDs[algotxn] = true;
        emit TransferSent(msg.sender, to, amount);
    }

    function SaveTransactionETH(address txid) public {
        require(msg.sender == oracleAddr, "Only NBridge can add a TXID");
        ETHTXIDs[txid] = true;
    }   

    function GetAlgoTransaction(string memory txid) public view returns (bool) {
        return ALGOTXIDs[txid];
    }

    function GetEthTransaction(address txid) public view returns (bool) {
        return ETHTXIDs[txid];
    }

    function VerifyASA(address ercaddress, uint asaid) public payable {
        if(msg.sender == oracleAddr){
            require(MIGHT_BE_ASA[asaid] == true, "Request validation from the contract first");
            ASA_ADDRESS[ercaddress] == asaid;
            ADDRESS_ASA[asaid] == ercaddress;
            MIGHT_BE_ASA[asaid] == false;
        }else{
            require(msg.value == 2000000000000000, "Must cover network fees for NBridge to confirm it");
            require(ASA_ADDRESS[ercaddress] != asaid);
            require(ADDRESS_ASA[asaid] != ercaddress);
            oracleAddr.transfer(2000000000000000);
            MIGHT_BE_ASA[asaid] == true;
        }
    }

    function GetASA(address ercaddress) public view returns (uint) {
        return ASA_ADDRESS[ercaddress];
    }

    function NBridgeERC20(IERC20 token, uint bridgeamount, string memory algorandaddress) public {
        require(bytes(algorandaddress).length == 58, "Must be a valid algorand address length");
        require(bridgeamount > 0, "Token amount must be bigger than 0");
        token.transferFrom(msg.sender, address(this), bridgeamount);
        emit BridgeERC20(algorandaddress);
    }
}