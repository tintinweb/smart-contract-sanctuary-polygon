/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: UNLICENSED
// File: UserRecord.sol


pragma solidity ^0.8.7;

/**
 * @dev Interface for ERC20 token (pasted from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol")
 */

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
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
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title UserRecord
 * @author ZentrixLab
 */
contract UserRecord {
    
    // Event for 
    event RevokedAccess(address addr, uint256 time);

    // owner of the smart contract
    address private _owner;

    // all addresses
    address[] public allAddresses;

    // array of all addresses that have allowed field set to true
    address[] public allowedAddresses;

    // array of all addresses that have allowed field set to false
    DataWithTime[] public notAllowedAddresses;

    // data stored on chain for each address
    struct Data {
        bytes32 hash;
        bool allowed;
        uint256 time;
    }

    // mapping address to data struct
    mapping(address => Data) public record;

    /**
     * @dev struct that represents input data
     * @param addr address of the wallet
     * @param hash bytes32 hash made of set of images in database
     */
    struct InputData {
        address addr;
        bytes32 hash;
    }

    // format for returning address with timestamp
    struct DataWithTime {
        address addr;
        uint256 time;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner can call function");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Function used to change owner of the contract
     */
    function changeOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Adds new users to record and updates allowedAddresses array, can be called only by owner
     * @param newUsers array of InputData structs that contains user address string and status boolean
     * @notice newUsers should be passed as [["addressString", true/false, "image hash"], ["addressString", true/false, "image hash"]] from TypeScript
     */
    function add(InputData[] calldata newUsers) external onlyOwner {
        for (uint256 i = 0; i < newUsers.length; ++i) {
            _addUser(newUsers[i]);
        }
        _updateAllowed();
    }

    // /**
    //  * @dev revokes access to images of addresses in addresses array
    //  * @param addresses array of address strings, should be passesd as ["address1", "address2"] from TypeScript
    //  */
    /*
    function revokeAccess(address[] calldata addresses) external { // onlyOwner
        
        if (msg.sender != _owner) {
            require(msg.sender == addresses[0], "You are not owner of the address");
            require(addresses.length == 1, "You can only change state of your address");
        }
        
        for (uint256 i = 0; i < addresses.length; ++i) {
            _revokeAccess(addresses[i]);
        }

        _updateAllowed();
    }
    */

    function revokeAccess() external {
        require(record[msg.sender].hash != 0, "Address not on the blockchain");
        _revokeAccess(msg.sender);
        emit RevokedAccess(msg.sender, block.timestamp);
        _updateAllowed();
    }

    /**
     * @dev Getter for allowedAddresses array that contains all addresses that allowed access to their pictures
     * @return Array of address strings
     */
    function fetch() external view returns (address[] memory) {
        return allowedAddresses;
    }

    /**
     * @dev Function that returns array of arrays with address and time when address has revoked acces
     */
    function fetchRevoked() external view returns (DataWithTime[] memory) {
        return notAllowedAddresses;
    }

    /**
     * @dev Function that transfer ERC20 tokens from contract owner to everyone that contributed with a valid pictures for model
     * @param validAddresses array of address strings of all users that have valid pictures
     * @param token address string of ERC20 token on Polygon chain that should be send to valid addresses
     * @param amount uint256 number of tokens to transfer to each account (will be multiplied by 1e18)
     * @notice contract owner must have balance of token greater then number of addresses in validAddresses array
     */
    function transferTokens(address[] memory validAddresses, IERC20 token, uint256 amount) external onlyOwner {
        _transferTokens(validAddresses, token, amount);
    }

    // ### Internal functions ###
    /**
     * @dev Adds new user to record
     */
    function  _addUser(InputData calldata user) internal {
        // if address already has been used, then skip it
        // require(record[user.addr].hash == 0, "Already used address");        
        if (record[user.addr].hash == 0) {
            // when new user is added default value for allowed is true
            record[user.addr] = Data(user.hash, true, block.timestamp);
            allAddresses.push(user.addr);
        }
    }

    /**
     * @dev Revokes access permission for address
     */
    function _revokeAccess(address addr) internal {
        record[addr].allowed = false;
        record[addr].time = block.timestamp;
    }

    /**
     * @dev Updates array of allowed addresses 
     */   
    function _updateAllowed() internal {
        // cacheing for gas optimization
        address[] memory _allAddresses = allAddresses;

        delete allowedAddresses;
        delete notAllowedAddresses;
        for (uint256 i = 0; i < _allAddresses.length; i++) {
            if (record[_allAddresses[i]].allowed == true) {
                allowedAddresses.push(_allAddresses[i]);
            } else {
                notAllowedAddresses.push(DataWithTime(_allAddresses[i], record[_allAddresses[i]].time));
            }
        }
    }

    /**
     * @dev Transfer ERC20 tokens from owners address to smart contract and from smart contract to all addresses that have valid images on blockchain
     */
    function _transferTokens(address[] memory validAddresses, IERC20 token, uint256 amount) internal {
        require(token.balanceOf(msg.sender) >= validAddresses.length * 1 ether, "Not enough coins");
	    require(token.allowance(msg.sender, address(this)) >= validAddresses.length, "Not enough allowance");
        for (uint256 i = 0; i < validAddresses.length; i++) {
            bool sent = token.transferFrom(msg.sender, validAddresses[i], amount * 1 ether);
            require(sent, "Transfer from contract to addresses failed");
        }
    }
}